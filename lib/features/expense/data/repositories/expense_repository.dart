import 'dart:async';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../data/database/app_database.dart';
import '../../domain/models/expense_models.dart';

class ExpenseRepository {
  ExpenseRepository(this._database);

  final AppDatabase _database;

  static const List<String> _defaultBanks = <String>[
    'Axis',
    'BOB',
    'SBI',
    'HDFC',
    'Kotak',
  ];

  Future<void> seedDefaults() async {
    await _database.insertCategories(
      AppConstants.defaultCategories
          .map(
            (category) => DbCategoriesCompanion.insert(
              name: category.name,
              iconCodePoint: category.iconCodePoint,
              colorValue: category.colorValue,
            ),
          )
          .toList(growable: false),
    );

    await _database.insertBanks(
      _defaultBanks
          .map((bank) => DbBanksCompanion.insert(name: bank))
          .toList(growable: false),
    );

    await _removeLegacyDemoEntries();
  }

  Stream<List<ExpenseCategory>> watchCategories() {
    return _database.watchCategories().map(
      (rows) => rows
          .map(
            (row) => ExpenseCategory(
              id: row.id,
              name: row.name,
              iconCodePoint: row.iconCodePoint,
              colorValue: row.colorValue,
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<List<BankName>> watchBanks() {
    return _database.watchBanks().map(
      (rows) => rows
          .map((row) => BankName(id: row.id, name: row.name))
          .toList(growable: false),
    );
  }

  Future<void> createCategory({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final categories = await _database.getCategories();
    if (_containsDuplicateName(
      categories.map((category) => category.name),
      trimmed,
    )) {
      return;
    }

    await _database.insertCategory(
      DbCategoriesCompanion.insert(
        name: trimmed,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
      ),
    );
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final categories = await _database.getCategories();
    final hasDuplicate = categories.any(
      (category) =>
          category.id != id &&
          category.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (hasDuplicate) {
      return;
    }

    await (_database.update(
      _database.dbCategories,
    )..where((table) => table.id.equals(id))).write(
      DbCategoriesCompanion(
        name: Value(trimmed),
        iconCodePoint: Value(iconCodePoint),
        colorValue: Value(colorValue),
      ),
    );
  }

  Future<void> deleteCategory(int id) async {
    final categories = await _database.getCategories();
    if (categories.length <= 1) {
      return;
    }

    final fallbackCategory = categories.where((category) => category.id != id);
    if (fallbackCategory.isEmpty) {
      return;
    }

    await (_database.update(
      _database.dbFinanceEntries,
    )..where((table) => table.categoryId.equals(id))).write(
      DbFinanceEntriesCompanion(categoryId: Value(fallbackCategory.first.id)),
    );
    await (_database.delete(
      _database.dbCategories,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> createBank(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final banks = await _database.getBanks();
    if (_containsDuplicateName(banks.map((bank) => bank.name), trimmed)) {
      return;
    }

    await _database.insertBank(DbBanksCompanion.insert(name: trimmed));
  }

  Future<void> updateBank({required int id, required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final banks = await _database.getBanks();
    final hasDuplicate = banks.any(
      (bank) =>
          bank.id != id && bank.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (hasDuplicate) {
      return;
    }

    await _database.updateBankName(bankId: id, name: trimmed);
  }

  Future<void> deleteBank(int id) async {
    await (_database.update(_database.dbFinanceEntries)
          ..where((table) => table.bankId.equals(id)))
        .write(const DbFinanceEntriesCompanion(bankId: Value(null)));
    await _database.deleteBankById(id);
  }

  Future<void> addExpense(ExpenseDraft draft) async {
    await _database.insertEntry(
      DbFinanceEntriesCompanion.insert(
        title: draft.title.trim(),
        amount: draft.amount,
        type: draft.type,
        categoryId: draft.categoryId,
        bankId: Value(draft.bankId),
        entryDate: draft.date,
        paymentMode: draft.paymentMode,
        notes: Value(draft.notes.trim()),
        counterparty: Value(draft.counterparty),
      ),
    );
  }

  Future<void> updateExpense({
    required int id,
    required ExpenseDraft draft,
  }) async {
    await (_database.update(
      _database.dbFinanceEntries,
    )..where((table) => table.id.equals(id))).write(
      DbFinanceEntriesCompanion(
        title: Value(draft.title.trim()),
        amount: Value(draft.amount),
        type: Value(draft.type),
        categoryId: Value(draft.categoryId),
        bankId: Value(draft.bankId),
        entryDate: Value(draft.date),
        paymentMode: Value(draft.paymentMode),
        notes: Value(draft.notes.trim()),
        counterparty: Value(draft.counterparty),
      ),
    );
  }

  Future<void> deleteExpense(int id) async {
    await (_database.delete(
      _database.dbFinanceEntries,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> clearSectionData() async {
    await _database.delete(_database.dbFinanceEntries).go();
    await _database.delete(_database.dbBanks).go();
    await _database.delete(_database.dbCategories).go();
    await seedDefaults();
  }

  Stream<List<ExpenseRecord>> watchEntries({ExpenseEntryFilter? filter}) {
    final query = _entryJoin(filter: filter);
    return query.watch().map(_mapExpenseRows);
  }

  Future<List<ExpenseRecord>> loadEntries({ExpenseEntryFilter? filter}) async {
    final query = _entryJoin(filter: filter);
    final rows = await query.get();
    return _mapExpenseRows(rows);
  }

  Stream<ExpenseDashboardData> watchDashboard({int? bankId}) {
    return watchEntries(filter: ExpenseEntryFilter(bankId: bankId)).map((
      entries,
    ) {
      return ExpenseDashboardData(
        totalCredit: _sum(entries, (entry) => entry.isCredit),
        totalDebit: _sum(entries, (entry) => entry.isDebit),
        totalLent: _sum(entries, (entry) => entry.type == 'lent'),
        totalBorrowed: _sum(entries, (entry) => entry.type == 'borrowed'),
        entries: entries,
      );
    });
  }

  Future<ExpenseAnalyticsData> loadAnalytics({
    required ExpenseAnalyticsWindow window,
    int? bankId,
    DateTime? anchorDate,
  }) async {
    final anchor = anchorDate ?? DateTime.now();
    final range = _resolveRange(window, anchor);
    final entries =
        (await _entryJoin(filter: ExpenseEntryFilter(bankId: bankId)).get())
            .map(_mapExpenseRow)
            .where(
              (entry) =>
                  !entry.date.isBefore(range.start) &&
                  !entry.date.isAfter(range.end),
            )
            .toList(growable: false);

    final expenseEntries = entries
        .where((entry) => entry.type == 'expense')
        .toList(growable: false);
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

    return ExpenseAnalyticsData(
      window: window,
      rangeStart: range.start,
      rangeEnd: range.end,
      totalCredit: _sum(entries, (entry) => entry.isCredit),
      totalDebit: _sum(entries, (entry) => entry.isDebit),
      totalBorrowed: _sum(entries, (entry) => entry.type == 'borrowed'),
      totalLent: _sum(entries, (entry) => entry.type == 'lent'),
      totalExpense: _sum(entries, (entry) => entry.type == 'expense'),
      totalIncome: _sum(entries, (entry) => entry.type == 'income'),
      categoryBreakdown:
          categoryTotals.entries
              .map(
                (entry) => ExpenseCategoryAnalysis(
                  name: entry.key,
                  amount: entry.value,
                  colorValue: categoryColors[entry.key]!,
                ),
              )
              .toList(growable: false)
            ..sort((a, b) => b.amount.compareTo(a.amount)),
      trend: _buildTrend(entries: expenseEntries, range: range, window: window),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _entryJoin({
    ExpenseEntryFilter? filter,
  }) {
    final query =
        (_database.select(_database.dbFinanceEntries)
              ..orderBy(<OrderingTerm Function($DbFinanceEntriesTable)>[
                (table) => OrderingTerm.desc(table.entryDate),
                (table) => OrderingTerm.desc(table.id),
              ]))
            .join(<Join>[
              innerJoin(
                _database.dbCategories,
                _database.dbCategories.id.equalsExp(
                  _database.dbFinanceEntries.categoryId,
                ),
              ),
              leftOuterJoin(
                _database.dbBanks,
                _database.dbBanks.id.equalsExp(
                  _database.dbFinanceEntries.bankId,
                ),
              ),
            ]);

    if (filter != null) {
      if (filter.bankId != null) {
        query.where(_database.dbFinanceEntries.bankId.equals(filter.bankId!));
      }

      if (filter.categoryId != null) {
        query.where(
          _database.dbFinanceEntries.categoryId.equals(filter.categoryId!),
        );
      }

      if (filter.fromDate != null) {
        query.where(
          _database.dbFinanceEntries.entryDate.isBiggerOrEqualValue(
            filter.fromDate!.startOfDay,
          ),
        );
      }

      if (filter.toDate != null) {
        query.where(
          _database.dbFinanceEntries.entryDate.isSmallerOrEqualValue(
            filter.toDate!.endOfDay,
          ),
        );
      }

      switch (filter.flow) {
        case ExpenseFlowFilter.all:
          break;
        case ExpenseFlowFilter.credit:
          query.where(
            _database.dbFinanceEntries.type.isIn(<String>[
              'income',
              'borrowed',
            ]),
          );
          break;
        case ExpenseFlowFilter.debit:
          query.where(
            _database.dbFinanceEntries.type.isIn(<String>['expense', 'lent']),
          );
          break;
      }
    }

    return query;
  }

  List<ExpenseRecord> _mapExpenseRows(List<TypedResult> rows) {
    return rows.map(_mapExpenseRow).toList(growable: false);
  }

  ExpenseRecord _mapExpenseRow(TypedResult row) {
    final entry = row.readTable(_database.dbFinanceEntries);
    final category = row.readTable(_database.dbCategories);
    final bank = row.readTableOrNull(_database.dbBanks);

    return ExpenseRecord(
      id: entry.id,
      title: entry.title,
      amount: entry.amount,
      type: entry.type,
      category: ExpenseCategory(
        id: category.id,
        name: category.name,
        iconCodePoint: category.iconCodePoint,
        colorValue: category.colorValue,
      ),
      date: entry.entryDate,
      paymentMode: entry.paymentMode,
      notes: entry.notes,
      counterparty: entry.counterparty,
      bank: bank == null ? null : BankName(id: bank.id, name: bank.name),
    );
  }

  Future<void> _removeLegacyDemoEntries() async {
    const demoEntries = <_SeededExpenseEntry>[
      _SeededExpenseEntry(
        title: 'Salary credit',
        amount: 48000,
        type: 'income',
        notes: 'Monthly salary',
      ),
      _SeededExpenseEntry(
        title: 'SIP contribution',
        amount: 6000,
        type: 'expense',
        notes: 'Mutual fund SIP',
      ),
      _SeededExpenseEntry(
        title: 'Groceries',
        amount: 1400,
        type: 'expense',
        notes: 'Weekly groceries',
      ),
      _SeededExpenseEntry(
        title: 'Borrowed for repairs',
        amount: 3000,
        type: 'borrowed',
        notes: 'Short term liability',
      ),
      _SeededExpenseEntry(
        title: 'Lent to friend',
        amount: 1800,
        type: 'lent',
        notes: 'Receivable',
      ),
    ];

    for (final demoEntry in demoEntries) {
      await (_database.delete(_database.dbFinanceEntries)..where(
            (table) =>
                table.title.equals(demoEntry.title) &
                table.amount.equals(demoEntry.amount) &
                table.type.equals(demoEntry.type) &
                table.notes.equals(demoEntry.notes),
          ))
          .go();
    }
  }

  double _sum(
    List<ExpenseRecord> entries,
    bool Function(ExpenseRecord entry) predicate,
  ) {
    return entries
        .where(predicate)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  List<ExpenseAnalyticsPoint> _buildTrend({
    required List<ExpenseRecord> entries,
    required _ExpenseDateRange range,
    required ExpenseAnalyticsWindow window,
  }) {
    final buckets = <DateTime, double>{};

    if (window == ExpenseAnalyticsWindow.yearly) {
      for (var month = 1; month <= 12; month++) {
        buckets[DateTime(range.start.year, month)] = 0;
      }
      for (final entry in entries) {
        final bucket = DateTime(entry.date.year, entry.date.month);
        buckets.update(bucket, (value) => value + entry.amount);
      }
      return buckets.entries
          .map(
            (entry) => ExpenseAnalyticsPoint(
              label: AppConstants.monthLabelFormat.format(entry.key),
              amount: entry.value,
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
      buckets.update(entry.date.startOfDay, (value) => value + entry.amount);
    }

    return buckets.entries
        .map(
          (entry) => ExpenseAnalyticsPoint(
            label: window == ExpenseAnalyticsWindow.weekly
                ? DateFormat('E').format(entry.key)
                : DateFormat('d').format(entry.key),
            amount: entry.value,
          ),
        )
        .toList(growable: false);
  }

  _ExpenseDateRange _resolveRange(
    ExpenseAnalyticsWindow window,
    DateTime anchorDate,
  ) {
    switch (window) {
      case ExpenseAnalyticsWindow.weekly:
        return _ExpenseDateRange(anchorDate.startOfWeek, anchorDate.endOfWeek);
      case ExpenseAnalyticsWindow.monthly:
        return _ExpenseDateRange(
          anchorDate.startOfMonth,
          anchorDate.endOfMonth,
        );
      case ExpenseAnalyticsWindow.yearly:
        return _ExpenseDateRange(anchorDate.startOfYear, anchorDate.endOfYear);
    }
  }

  bool _containsDuplicateName(Iterable<String> names, String target) {
    return names.any((name) => name.toLowerCase() == target.toLowerCase());
  }
}

class _ExpenseDateRange {
  const _ExpenseDateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class _SeededExpenseEntry {
  const _SeededExpenseEntry({
    required this.title,
    required this.amount,
    required this.type,
    required this.notes,
  });

  final String title;
  final double amount;
  final String type;
  final String notes;
}
