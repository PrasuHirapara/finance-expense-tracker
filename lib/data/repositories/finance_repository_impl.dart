import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/date_time_x.dart';
import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/repositories/finance_repository.dart';
import '../database/app_database.dart';
import '../mappers/category_mapper.dart';
import '../mappers/finance_entry_mapper.dart';
import '../services/seed_service.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl({
    required AppDatabase database,
    required SeedService seedService,
  }) : _database = database,
       _seedService = seedService;

  final AppDatabase _database;
  final SeedService _seedService;

  @override
  Future<void> seedIfNeeded() => _seedService.seedIfNeeded();

  @override
  Stream<List<FinanceCategory>> watchCategories() {
    return _database.watchCategories().map(
      (models) =>
          models.map((model) => model.toDomain()).toList(growable: false),
    );
  }

  @override
  Future<void> addCategory({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    await _database.insertCategory(
      DbCategoriesCompanion.insert(
        name: name.trim(),
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
      ),
    );
  }

  @override
  Future<void> addEntry(FinanceEntryDraft draft) async {
    await _database.insertEntry(
      DbFinanceEntriesCompanion.insert(
        title: draft.title.trim(),
        amount: draft.amount,
        type: draft.type.storageKey,
        categoryId: draft.categoryId,
        entryDate: draft.date,
        paymentMode: draft.paymentMode,
        notes: Value(draft.notes.trim()),
        counterparty: Value(
          draft.counterparty == null || draft.counterparty!.trim().isEmpty
              ? null
              : draft.counterparty!.trim(),
        ),
      ),
    );
  }

  @override
  Stream<DashboardSnapshot> watchDashboardSnapshot(DateTime anchorDate) {
    return _database.watchAllEntries().asyncMap((models) async {
      final entries = models
          .map((model) => model.toDomain())
          .toList(growable: false);
      final categories = await _database.getCategories();
      final weekStart = anchorDate.startOfWeek;
      final weekEnd = anchorDate.endOfWeek;

      final weeklyEntries = entries
          .where(
            (entry) =>
                !entry.date.isBefore(weekStart) && !entry.date.isAfter(weekEnd),
          )
          .toList(growable: false);

      return DashboardSnapshot(
        todaysExpense: _sumByType(
          entries,
          match: (entry) =>
              entry.type.storageKey == 'expense' &&
              entry.date.isSameDate(anchorDate),
        ),
        weeklyExpense: _sumByType(
          weeklyEntries,
          match: (entry) => entry.type.storageKey == 'expense',
        ),
        weeklyCredit: _sumByType(
          weeklyEntries,
          match: (entry) => entry.type.isCredit,
        ),
        weeklyDebit: _sumByType(
          weeklyEntries,
          match: (entry) => entry.type.isDebit,
        ),
        weeklyBorrowed: _sumByType(
          weeklyEntries,
          match: (entry) => entry.type.storageKey == 'borrowed',
        ),
        weeklyLent: _sumByType(
          weeklyEntries,
          match: (entry) => entry.type.storageKey == 'lent',
        ),
        categoryCount: categories.length,
        recentEntries: entries.take(8).toList(growable: false),
      );
    });
  }

  @override
  Future<AnalyticsReport> getAnalyticsReport({
    required AnalyticsWindow window,
    required DateTime anchorDate,
  }) async {
    final range = _resolveRange(window, anchorDate);
    final entries = (await _database.getEntriesBetween(
      range.start,
      range.end,
    )).map((model) => model.toDomain()).toList(growable: false);

    final expenseEntries = entries
        .where((entry) => entry.type.storageKey == 'expense')
        .toList();

    final categoryTotals = <String, double>{};
    final categoryColors = <String, int>{};

    for (final entry in expenseEntries) {
      categoryTotals.update(
        entry.category.name,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount,
      );
      categoryColors[entry.category.name] = entry.category.colorValue;
    }

    final categoryDistribution =
        categoryTotals.entries
            .map(
              (item) => CategorySpend(
                categoryName: item.key,
                amount: item.value,
                colorValue: categoryColors[item.key]!,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return AnalyticsReport(
      window: window,
      rangeStart: range.start,
      rangeEnd: range.end,
      totalExpense: _sumByType(
        entries,
        match: (entry) => entry.type.storageKey == 'expense',
      ),
      totalIncome: _sumByType(
        entries,
        match: (entry) => entry.type.storageKey == 'income',
      ),
      totalBorrowed: _sumByType(
        entries,
        match: (entry) => entry.type.storageKey == 'borrowed',
      ),
      totalLent: _sumByType(
        entries,
        match: (entry) => entry.type.storageKey == 'lent',
      ),
      totalCredit: _sumByType(entries, match: (entry) => entry.type.isCredit),
      totalDebit: _sumByType(entries, match: (entry) => entry.type.isDebit),
      outstandingLiability: _sumByType(
        entries,
        match: (entry) => entry.type.storageKey == 'borrowed',
      ),
      outstandingReceivable: _sumByType(
        entries,
        match: (entry) => entry.type.storageKey == 'lent',
      ),
      categoryDistribution: categoryDistribution,
      trendPoints: _buildTrendPoints(
        window: window,
        entries: expenseEntries,
        range: range,
      ),
      entries: entries,
    );
  }

  double _sumByType(
    List<FinanceEntry> entries, {
    required bool Function(FinanceEntry entry) match,
  }) {
    return entries
        .where(match)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  List<TrendPoint> _buildTrendPoints({
    required AnalyticsWindow window,
    required List<FinanceEntry> entries,
    required _DateRange range,
  }) {
    final buckets = <DateTime, double>{};

    if (window == AnalyticsWindow.yearly) {
      for (var month = 1; month <= 12; month++) {
        buckets[DateTime(range.start.year, month)] = 0;
      }
      for (final entry in entries) {
        final bucket = DateTime(entry.date.year, entry.date.month);
        buckets.update(bucket, (value) => value + entry.amount);
      }
      return buckets.entries
          .map(
            (item) => TrendPoint(
              period: item.key,
              amount: item.value,
              label: AppConstants.monthLabelFormat.format(item.key),
            ),
          )
          .toList(growable: false);
    }

    var cursor = range.start.startOfDay;
    while (!cursor.isAfter(range.end)) {
      buckets[cursor] = 0;
      cursor = cursor.add(const Duration(days: 1));
    }

    for (final entry in entries) {
      final bucket = entry.date.startOfDay;
      buckets.update(bucket, (value) => value + entry.amount);
    }

    return buckets.entries
        .map(
          (item) => TrendPoint(
            period: item.key,
            amount: item.value,
            label: window == AnalyticsWindow.weekly
                ? DateFormat('E').format(item.key)
                : DateFormat('d').format(item.key),
          ),
        )
        .toList(growable: false);
  }

  _DateRange _resolveRange(AnalyticsWindow window, DateTime anchorDate) {
    switch (window) {
      case AnalyticsWindow.weekly:
        return _DateRange(anchorDate.startOfWeek, anchorDate.endOfWeek);
      case AnalyticsWindow.monthly:
        return _DateRange(anchorDate.startOfMonth, anchorDate.endOfMonth);
      case AnalyticsWindow.yearly:
        return _DateRange(anchorDate.startOfYear, anchorDate.endOfYear);
    }
  }
}

class _DateRange {
  const _DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
