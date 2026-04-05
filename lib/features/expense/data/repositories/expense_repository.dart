import 'dart:async';
import 'dart:math' as math;

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
    await ensureLentCategory();
    await _removeLegacyDemoEntries();
  }

  Future<void> ensureLentCategory() async {
    final categories = await _database.getCategories();
    final hasLentCategory = categories.any(
      (category) => category.name.toLowerCase() == 'lent',
    );
    if (hasLentCategory) {
      return;
    }
    await _database.insertCategory(
      DbCategoriesCompanion.insert(
        name: 'Lent',
        iconCodePoint: AppConstants.lentCategorySeed.iconCodePoint,
        colorValue: AppConstants.lentCategorySeed.colorValue,
      ),
    );
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
    await _database.transaction(() async {
      if (draft.type == 'expense' && draft.splitDraft != null) {
        await _upsertSplitExpense(draft: draft);
        return;
      }
      final entryId = await _insertFinanceEntry(
        draft: draft,
        amount: draft.amount,
        type: draft.type,
      );
      if (draft.type == 'income' && draft.lentResolutionDraft != null) {
        await _applyLentResolution(
          incomeEntryId: entryId,
          incomeAmount: draft.amount,
          resolutionDraft: draft.lentResolutionDraft!,
        );
      }
    });
  }

  Future<void> updateExpense({
    required int id,
    required ExpenseDraft draft,
  }) async {
    await _database.transaction(() async {
      final existingSplit = await _findSplitRecordByEntryId(id);
      if (draft.type == 'expense' && draft.splitDraft != null) {
        await _upsertSplitExpense(
          draft: draft,
          existingExpenseEntryId: id,
          existingSplitRecord: existingSplit,
        );
        return;
      }
      if (existingSplit != null) {
        final splitDraft = await _buildSplitDraft(existingSplit);
        if (splitDraft.hasSettlements) {
          throw StateError(
            'This split expense already has settlements and cannot be converted.',
          );
        }
        await _removeSplitManagement(existingSplit, preserveEntryId: id);
      }
      final linkedSettlements = await _loadSettlementsByIncomeEntryId(id);
      if (linkedSettlements.isNotEmpty) {
        throw StateError(
          'Resolved lent income entries cannot be edited. Delete it to reverse the settlement first.',
        );
      }
      await _updateFinanceEntry(
        entryId: id,
        draft: draft,
        amount: draft.amount,
        type: draft.type,
      );
    });
  }

  Future<void> deleteExpense(int id) async {
    await _database.transaction(() async {
      final linkedSettlements = await _loadSettlementsByIncomeEntryId(id);
      if (linkedSettlements.isNotEmpty) {
        await _rollbackLentResolution(linkedSettlements);
      }
      final splitRecord = await _findSplitRecordByEntryId(id);
      if (splitRecord != null) {
        final splitDraft = await _buildSplitDraft(splitRecord);
        if (splitDraft.hasSettlements) {
          throw StateError(
            'This split has settled shares and cannot be deleted.',
          );
        }
        await _deleteSplitRecord(splitRecord, deleteLinkedEntries: true);
        return;
      }
      await (_database.delete(
        _database.dbFinanceEntries,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<void> clearSectionData() async {
    await _database.delete(_database.dbLentSettlements).go();
    await _database.delete(_database.dbSplitParticipants).go();
    await _database.delete(_database.dbSplitRecords).go();
    await _database.delete(_database.dbFinanceEntries).go();
    await _database.delete(_database.dbBanks).go();
    await _database.delete(_database.dbCategories).go();
    await seedDefaults();
  }

  Stream<List<ExpenseRecord>> watchEntries({ExpenseEntryFilter? filter}) {
    final query = _entryJoin(filter: filter);
    return query.watch().asyncMap(_mapExpenseRows);
  }

  Future<List<ExpenseRecord>> loadEntries({ExpenseEntryFilter? filter}) async {
    final query = _entryJoin(filter: filter);
    return _mapExpenseRows(await query.get());
  }

  Stream<ExpenseDashboardData> watchDashboard({int? bankId}) {
    return watchEntries(filter: ExpenseEntryFilter(bankId: bankId)).map((entries) {
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
    final entries = (await _mapExpenseRows(
      await _entryJoin(filter: ExpenseEntryFilter(bankId: bankId)).get(),
    ))
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

  Future<ExpenseSplitDraft?> loadSplitDraftForEntry(int entryId) async {
    final splitRecord = await _findSplitRecordByEntryId(entryId);
    if (splitRecord == null) {
      return null;
    }
    return _buildSplitDraft(splitRecord);
  }

  Future<List<LentResolutionCandidate>> loadResolvableLentEntries() async {
    final entries = (await loadEntries())
        .where((entry) => entry.type == 'lent')
        .toList(growable: false);
    final candidates = <LentResolutionCandidate>[];
    for (final entry in entries) {
      final splitDraft =
          await loadSplitDraftForEntry(entry.id) ?? _buildSyntheticLentDraft(entry);
      final hasPendingParticipants = splitDraft.participants.any(
        (participant) => !participant.isSelf && !participant.isSettled,
      );
      if (hasPendingParticipants) {
        candidates.add(LentResolutionCandidate(entry: entry, splitDraft: splitDraft));
      }
    }
    candidates.sort((a, b) => b.entry.date.compareTo(a.entry.date));
    return candidates;
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
            _database.dbFinanceEntries.type.isIn(<String>['income', 'borrowed']),
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

  Future<List<ExpenseRecord>> _mapExpenseRows(List<TypedResult> rows) async {
    final baseRecords = rows.map(_mapBaseExpenseRow).toList(growable: false);
    if (baseRecords.isEmpty) {
      return baseRecords;
    }
    final entryIds = baseRecords.map((record) => record.id).toList(growable: false);
    final splitRecords = await _loadSplitRecordsForEntryIds(entryIds);
    final splitSummariesByEntryId = <int, ExpenseSplitSummary>{};
    final splitRecordIds = splitRecords.map((record) => record.id).toList(growable: false);
    final settlementRows = splitRecordIds.isEmpty
        ? <DbLentSettlement>[]
        : await (_database.select(_database.dbLentSettlements)
              ..where((table) => table.splitRecordId.isIn(splitRecordIds)))
            .get();
    final resolutionIncomeIds = (await _loadSettlementsByIncomeEntryIds(entryIds))
        .map((settlement) => settlement.incomeEntryId)
        .toSet();
    final participantsByRecordId = await _loadParticipantsByRecordIds(splitRecordIds);

    for (final splitRecord in splitRecords) {
      final participants =
          participantsByRecordId[splitRecord.id] ?? <DbSplitParticipant>[];
      final summary = ExpenseSplitSummary(
        recordId: splitRecord.id,
        totalAmount: splitRecord.totalAmount,
        pendingLentAmount: _roundMoney(
          participants
              .where((participant) => !participant.isSelf)
              .fold<double>(
                0,
                (sum, participant) =>
                    sum + (participant.amount - participant.settledAmount),
              ),
        ),
        participantCount: participants.length,
        settledParticipantCount: participants
            .where(
              (participant) =>
                  participant.amount - participant.settledAmount <= 0.005,
            )
            .length,
        hasSettlements: settlementRows.any(
          (settlement) => settlement.splitRecordId == splitRecord.id,
        ),
        hasLentParticipants: participants.any((participant) => !participant.isSelf),
        expenseEntryId: splitRecord.expenseEntryId,
        lentEntryId: splitRecord.lentEntryId,
      );
      if (splitRecord.expenseEntryId != null) {
        splitSummariesByEntryId[splitRecord.expenseEntryId!] = summary;
      }
      if (splitRecord.lentEntryId != null) {
        splitSummariesByEntryId[splitRecord.lentEntryId!] = summary;
      }
    }

    return baseRecords
        .map((record) {
          final splitSummary = splitSummariesByEntryId[record.id];
          final isManagedLentEntry =
              splitSummary != null && splitSummary.lentEntryId == record.id;
          final isResolutionIncome = resolutionIncomeIds.contains(record.id);
          final canEdit = !isManagedLentEntry && !isResolutionIncome;
          final canDelete = isManagedLentEntry
              ? false
              : splitSummary == null || !splitSummary.hasSettlements;
          return ExpenseRecord(
            id: record.id,
            title: record.title,
            amount: record.amount,
            type: record.type,
            category: record.category,
            date: record.date,
            paymentMode: record.paymentMode,
            notes: record.notes,
            counterparty: record.counterparty,
            bank: record.bank,
            splitSummary: splitSummary,
            isManagedLentEntry: isManagedLentEntry,
            isResolutionIncome: isResolutionIncome,
            canEdit: canEdit,
            canDelete: canDelete,
          );
        })
        .toList(growable: false);
  }

  ExpenseRecord _mapBaseExpenseRow(TypedResult row) {
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

  Future<List<DbSplitRecord>> _loadSplitRecordsForEntryIds(List<int> entryIds) async {
    if (entryIds.isEmpty) {
      return <DbSplitRecord>[];
    }
    return (_database.select(_database.dbSplitRecords)..where(
          (table) =>
              table.expenseEntryId.isIn(entryIds) | table.lentEntryId.isIn(entryIds),
        ))
        .get();
  }

  Future<Map<int, List<DbSplitParticipant>>> _loadParticipantsByRecordIds(
    List<int> recordIds,
  ) async {
    if (recordIds.isEmpty) {
      return <int, List<DbSplitParticipant>>{};
    }
    final participants = await (_database.select(_database.dbSplitParticipants)
          ..where((table) => table.splitRecordId.isIn(recordIds))
          ..orderBy(<OrderingTerm Function($DbSplitParticipantsTable)>[
            (table) => OrderingTerm.asc(table.sortOrder),
            (table) => OrderingTerm.asc(table.id),
          ]))
        .get();
    final grouped = <int, List<DbSplitParticipant>>{};
    for (final participant in participants) {
      grouped.putIfAbsent(participant.splitRecordId, () => <DbSplitParticipant>[]).add(
        participant,
      );
    }
    return grouped;
  }

  Future<DbSplitRecord?> _findSplitRecordByEntryId(int entryId) {
    return (_database.select(_database.dbSplitRecords)..where(
          (table) =>
              table.expenseEntryId.equals(entryId) |
              table.lentEntryId.equals(entryId),
        ))
        .getSingleOrNull();
  }

  Future<ExpenseSplitDraft> _buildSplitDraft(DbSplitRecord splitRecord) async {
    final participants = await (_database.select(_database.dbSplitParticipants)
          ..where((table) => table.splitRecordId.equals(splitRecord.id))
          ..orderBy(<OrderingTerm Function($DbSplitParticipantsTable)>[
            (table) => OrderingTerm.asc(table.sortOrder),
            (table) => OrderingTerm.asc(table.id),
          ]))
        .get();
    return ExpenseSplitDraft(
      recordId: splitRecord.id,
      expenseEntryId: splitRecord.expenseEntryId,
      lentEntryId: splitRecord.lentEntryId,
      totalAmount: splitRecord.totalAmount,
      participants: participants
          .map(
            (participant) => ExpenseSplitParticipant(
              id: participant.id,
              name: participant.participantName,
              amount: participant.amount,
              percentage: participant.percentage,
              isSelf: participant.isSelf,
              settledAmount: participant.settledAmount,
              sortOrder: participant.sortOrder,
            ),
          )
          .toList(growable: false),
    );
  }

  ExpenseSplitDraft _buildSyntheticLentDraft(ExpenseRecord entry) {
    final participantName = entry.counterparty?.trim().isNotEmpty == true
        ? entry.counterparty!.trim()
        : entry.title;
    return ExpenseSplitDraft(
      lentEntryId: entry.id,
      totalAmount: entry.amount,
      participants: <ExpenseSplitParticipant>[
        ExpenseSplitParticipant(
          name: participantName,
          amount: entry.amount,
          percentage: 100,
          isSelf: false,
        ),
      ],
    );
  }

  Future<void> _upsertSplitExpense({
    required ExpenseDraft draft,
    int? existingExpenseEntryId,
    DbSplitRecord? existingSplitRecord,
  }) async {
    final splitDraft = draft.splitDraft!;
    final normalizedParticipants = splitDraft.participants
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(
            amount: _roundMoney(entry.value.amount),
            percentage: _roundPercentage(entry.value.percentage),
            sortOrder: entry.key,
          ),
        )
        .toList(growable: false);
    final normalizedSplitDraft = splitDraft.copyWith(
      totalAmount: _roundMoney(splitDraft.totalAmount),
      participants: normalizedParticipants,
    );
    final selfAmount = _roundMoney(normalizedSplitDraft.selfAmount);
    final pendingLentAmount = _roundMoney(normalizedSplitDraft.pendingLentAmount);
    final expenseEntryId = existingSplitRecord?.expenseEntryId ?? existingExpenseEntryId;

    int resolvedExpenseEntryId;
    if (expenseEntryId == null) {
      resolvedExpenseEntryId = await _insertFinanceEntry(
        draft: draft,
        amount: selfAmount,
        type: 'expense',
        counterparty: null,
      );
    } else {
      resolvedExpenseEntryId = expenseEntryId;
      await _updateFinanceEntry(
        entryId: expenseEntryId,
        draft: draft,
        amount: selfAmount,
        type: 'expense',
        counterparty: null,
      );
    }

    int? resolvedLentEntryId = existingSplitRecord?.lentEntryId;
    if (normalizedSplitDraft.hasLentParticipants) {
      if (resolvedLentEntryId == null) {
        resolvedLentEntryId = await _insertFinanceEntry(
          draft: draft,
          amount: pendingLentAmount,
          type: 'lent',
          counterparty: _buildParticipantSummary(normalizedParticipants),
        );
      } else {
        await _updateFinanceEntry(
          entryId: resolvedLentEntryId,
          draft: draft,
          amount: pendingLentAmount,
          type: 'lent',
          counterparty: _buildParticipantSummary(normalizedParticipants),
        );
      }
    } else if (resolvedLentEntryId != null) {
      await (_database.delete(
        _database.dbFinanceEntries,
      )..where((table) => table.id.equals(resolvedLentEntryId!))).go();
      resolvedLentEntryId = null;
    }

    int splitRecordId;
    if (existingSplitRecord == null) {
      splitRecordId = await _database.into(_database.dbSplitRecords).insert(
        DbSplitRecordsCompanion.insert(
          expenseEntryId: Value(resolvedExpenseEntryId),
          lentEntryId: Value(resolvedLentEntryId),
          totalAmount: normalizedSplitDraft.totalAmount,
        ),
      );
    } else {
      splitRecordId = existingSplitRecord.id;
      await (_database.update(_database.dbSplitRecords)
            ..where((table) => table.id.equals(existingSplitRecord.id)))
          .write(
            DbSplitRecordsCompanion(
              expenseEntryId: Value(resolvedExpenseEntryId),
              lentEntryId: Value(resolvedLentEntryId),
              totalAmount: Value(normalizedSplitDraft.totalAmount),
            ),
          );
    }

    await _syncSplitParticipants(
      splitRecordId: splitRecordId,
      participants: normalizedSplitDraft.participants,
    );
  }

  Future<void> _syncSplitParticipants({
    required int splitRecordId,
    required List<ExpenseSplitParticipant> participants,
  }) async {
    final existingParticipants = await (_database.select(_database.dbSplitParticipants)
          ..where((table) => table.splitRecordId.equals(splitRecordId))
          ..orderBy(<OrderingTerm Function($DbSplitParticipantsTable)>[
            (table) => OrderingTerm.asc(table.sortOrder),
            (table) => OrderingTerm.asc(table.id),
          ]))
        .get();
    final hasSettlements = existingParticipants.any(
      (participant) => !participant.isSelf && participant.settledAmount > 0.005,
    );

    if (!hasSettlements) {
      if (existingParticipants.isNotEmpty) {
        await (_database.delete(_database.dbSplitParticipants)
              ..where((table) => table.splitRecordId.equals(splitRecordId)))
            .go();
      }
      await _database.batch((batch) {
        batch.insertAll(
          _database.dbSplitParticipants,
          participants
              .map(
                (participant) => DbSplitParticipantsCompanion.insert(
                  splitRecordId: splitRecordId,
                  participantName: participant.name.trim(),
                  amount: participant.amount,
                  percentage: participant.percentage,
                  isSelf: Value(participant.isSelf),
                  settledAmount: Value(
                    math.min(participant.settledAmount, participant.amount),
                  ),
                  sortOrder: Value(participant.sortOrder),
                ),
              )
              .toList(growable: false),
        );
      });
      return;
    }

    final existingById = <int, DbSplitParticipant>{
      for (final participant in existingParticipants) participant.id: participant,
    };
    for (final participant in participants) {
      if (participant.id == null || !existingById.containsKey(participant.id)) {
        throw StateError(
          'Settled split participants cannot be added or removed.',
        );
      }
    }
    for (final participant in participants) {
      final existing = existingById[participant.id]!;
      final nextAmount = _roundMoney(
        math.max(participant.amount, existing.settledAmount),
      );
      await (_database.update(_database.dbSplitParticipants)
            ..where((table) => table.id.equals(existing.id)))
          .write(
            DbSplitParticipantsCompanion(
              participantName: Value(participant.name.trim()),
              amount: Value(nextAmount),
              percentage: Value(_roundPercentage(participant.percentage)),
              isSelf: Value(participant.isSelf),
              settledAmount: Value(
                math.min(existing.settledAmount, nextAmount),
              ),
              sortOrder: Value(participant.sortOrder),
            ),
          );
    }
  }

  Future<void> _applyLentResolution({
    required int incomeEntryId,
    required double incomeAmount,
    required LentResolutionDraft resolutionDraft,
  }) async {
    var splitDraft = await loadSplitDraftForEntry(resolutionDraft.lentEntryId);
    if (splitDraft == null) {
      final lentEntries = (await loadEntries())
          .where((entry) => entry.type == 'lent' && entry.id == resolutionDraft.lentEntryId)
          .toList(growable: false);
      if (lentEntries.isEmpty) {
        throw StateError('Selected lent entry was not found.');
      }
      splitDraft = await _createSplitRecordForLegacyLentEntry(lentEntries.first);
    }

    final selectedParticipants = splitDraft.participants.where(
      (participant) {
        if (participant.isSelf || participant.isSettled) {
          return false;
        }
        for (final selected in resolutionDraft.participants) {
          if (selected.id != null && selected.id == participant.id) {
            return true;
          }
          if (selected.id == null &&
              selected.sortOrder == participant.sortOrder &&
              selected.name == participant.name &&
              _amountEquals(selected.amount, participant.amount)) {
            return true;
          }
        }
        return false;
      },
    );
    final selectedTotal = _roundMoney(
      selectedParticipants.fold<double>(
        0,
        (sum, participant) => sum + participant.pendingAmount,
      ),
    );
    if (!_amountEquals(selectedTotal, incomeAmount)) {
      throw StateError(
        'Selected participant shares must exactly match the income amount.',
      );
    }

    for (final participant in selectedParticipants) {
      final pendingAmount = _roundMoney(participant.pendingAmount);
      await (_database.update(_database.dbSplitParticipants)
            ..where((table) => table.id.equals(participant.id!)))
          .write(
            DbSplitParticipantsCompanion(
              settledAmount: Value(participant.amount),
            ),
          );
      await _database.into(_database.dbLentSettlements).insert(
        DbLentSettlementsCompanion.insert(
          splitRecordId: splitDraft.recordId!,
          splitParticipantId: participant.id!,
          incomeEntryId: incomeEntryId,
          settledAmount: pendingAmount,
        ),
      );
    }
    await _refreshLinkedLentEntryAmount(splitDraft.recordId!);
  }

  Future<ExpenseSplitDraft> _createSplitRecordForLegacyLentEntry(
    ExpenseRecord lentEntry,
  ) async {
    final participantName = lentEntry.counterparty?.trim().isNotEmpty == true
        ? lentEntry.counterparty!.trim()
        : lentEntry.title;
    final recordId = await _database.into(_database.dbSplitRecords).insert(
      DbSplitRecordsCompanion.insert(
        lentEntryId: Value(lentEntry.id),
        totalAmount: lentEntry.amount,
      ),
    );
    await _database.into(_database.dbSplitParticipants).insert(
      DbSplitParticipantsCompanion.insert(
        splitRecordId: recordId,
        participantName: participantName,
        amount: lentEntry.amount,
        percentage: 100,
        sortOrder: const Value(0),
      ),
    );
    final record = await (_database.select(
      _database.dbSplitRecords,
    )..where((table) => table.id.equals(recordId))).getSingle();
    return _buildSplitDraft(record);
  }

  Future<List<DbLentSettlement>> _loadSettlementsByIncomeEntryId(int entryId) {
    return (_database.select(_database.dbLentSettlements)
          ..where((table) => table.incomeEntryId.equals(entryId)))
        .get();
  }

  Future<List<DbLentSettlement>> _loadSettlementsByIncomeEntryIds(
    List<int> entryIds,
  ) {
    if (entryIds.isEmpty) {
      return Future<List<DbLentSettlement>>.value(<DbLentSettlement>[]);
    }
    return (_database.select(_database.dbLentSettlements)
          ..where((table) => table.incomeEntryId.isIn(entryIds)))
        .get();
  }

  Future<void> _rollbackLentResolution(List<DbLentSettlement> settlements) async {
    final splitRecordIds = <int>{};
    for (final settlement in settlements) {
      splitRecordIds.add(settlement.splitRecordId);
      final participant = await (_database.select(_database.dbSplitParticipants)
            ..where((table) => table.id.equals(settlement.splitParticipantId)))
          .getSingle();
      final nextSettledAmount = _roundMoney(
        math.max(0, participant.settledAmount - settlement.settledAmount),
      );
      await (_database.update(_database.dbSplitParticipants)
            ..where((table) => table.id.equals(participant.id)))
          .write(
            DbSplitParticipantsCompanion(
              settledAmount: Value(nextSettledAmount),
            ),
          );
    }
    final incomeEntryIds = settlements
        .map((settlement) => settlement.incomeEntryId)
        .toSet()
        .toList(growable: false);
    await (_database.delete(_database.dbLentSettlements)
          ..where((table) => table.incomeEntryId.isIn(incomeEntryIds)))
        .go();
    for (final splitRecordId in splitRecordIds) {
      await _refreshLinkedLentEntryAmount(splitRecordId);
    }
  }

  Future<void> _refreshLinkedLentEntryAmount(int splitRecordId) async {
    final splitRecord = await (_database.select(_database.dbSplitRecords)
          ..where((table) => table.id.equals(splitRecordId)))
        .getSingle();
    if (splitRecord.lentEntryId == null) {
      return;
    }
    final participants = await (_database.select(_database.dbSplitParticipants)
          ..where((table) => table.splitRecordId.equals(splitRecordId)))
        .get();
    final pendingAmount = _roundMoney(
      participants
          .where((participant) => !participant.isSelf)
          .fold<double>(
            0,
            (sum, participant) =>
                sum + (participant.amount - participant.settledAmount),
          ),
    );
    await (_database.update(_database.dbFinanceEntries)
          ..where((table) => table.id.equals(splitRecord.lentEntryId!)))
        .write(DbFinanceEntriesCompanion(amount: Value(pendingAmount)));
  }

  Future<void> _deleteSplitRecord(
    DbSplitRecord splitRecord, {
    required bool deleteLinkedEntries,
  }) async {
    final settlements = await (_database.select(_database.dbLentSettlements)
          ..where((table) => table.splitRecordId.equals(splitRecord.id)))
        .get();
    if (settlements.isNotEmpty) {
      throw StateError('Split records with settlements cannot be deleted.');
    }
    await (_database.delete(_database.dbSplitParticipants)
          ..where((table) => table.splitRecordId.equals(splitRecord.id)))
        .go();
    await (_database.delete(_database.dbSplitRecords)
          ..where((table) => table.id.equals(splitRecord.id)))
        .go();
    if (!deleteLinkedEntries) {
      return;
    }
    final entryIds = <int>{
      if (splitRecord.expenseEntryId != null) splitRecord.expenseEntryId!,
      if (splitRecord.lentEntryId != null) splitRecord.lentEntryId!,
    };
    if (entryIds.isNotEmpty) {
      await (_database.delete(_database.dbFinanceEntries)
            ..where((table) => table.id.isIn(entryIds.toList(growable: false))))
          .go();
    }
  }

  Future<void> _removeSplitManagement(
    DbSplitRecord splitRecord, {
    required int preserveEntryId,
  }) async {
    await (_database.delete(_database.dbSplitParticipants)
          ..where((table) => table.splitRecordId.equals(splitRecord.id)))
        .go();
    await (_database.delete(_database.dbSplitRecords)
          ..where((table) => table.id.equals(splitRecord.id)))
        .go();
    final deletableIds = <int>[
      if (splitRecord.expenseEntryId != null &&
          splitRecord.expenseEntryId != preserveEntryId)
        splitRecord.expenseEntryId!,
      if (splitRecord.lentEntryId != null &&
          splitRecord.lentEntryId != preserveEntryId)
        splitRecord.lentEntryId!,
    ];
    if (deletableIds.isNotEmpty) {
      await (_database.delete(_database.dbFinanceEntries)
            ..where((table) => table.id.isIn(deletableIds)))
          .go();
    }
  }

  Future<int> _insertFinanceEntry({
    required ExpenseDraft draft,
    required double amount,
    required String type,
    String? counterparty,
  }) {
    return _database.insertEntry(
      DbFinanceEntriesCompanion.insert(
        title: draft.title.trim(),
        amount: _roundMoney(amount),
        type: type,
        categoryId: draft.categoryId,
        bankId: Value(draft.bankId),
        entryDate: draft.date,
        paymentMode: draft.paymentMode,
        notes: Value(draft.notes.trim()),
        counterparty: Value(
          counterparty ?? _normalizeCounterparty(draft.counterparty),
        ),
      ),
    );
  }

  Future<void> _updateFinanceEntry({
    required int entryId,
    required ExpenseDraft draft,
    required double amount,
    required String type,
    String? counterparty,
  }) async {
    await (_database.update(
      _database.dbFinanceEntries,
    )..where((table) => table.id.equals(entryId))).write(
      DbFinanceEntriesCompanion(
        title: Value(draft.title.trim()),
        amount: Value(_roundMoney(amount)),
        type: Value(type),
        categoryId: Value(draft.categoryId),
        bankId: Value(draft.bankId),
        entryDate: Value(draft.date),
        paymentMode: Value(draft.paymentMode),
        notes: Value(draft.notes.trim()),
        counterparty: Value(
          counterparty ?? _normalizeCounterparty(draft.counterparty),
        ),
      ),
    );
  }

  String? _normalizeCounterparty(String? counterparty) {
    if (counterparty == null || counterparty.trim().isEmpty) {
      return null;
    }
    return counterparty.trim();
  }

  String? _buildParticipantSummary(List<ExpenseSplitParticipant> participants) {
    final names = participants
        .where((participant) => !participant.isSelf)
        .map((participant) => participant.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (names.isEmpty) {
      return null;
    }
    if (names.length <= 2) {
      return names.join(', ');
    }
    return '${names.take(2).join(', ')} +${names.length - 2} more';
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
      var cursor = DateTime(range.start.year, range.start.month);
      final endBucket = DateTime(range.end.year, range.end.month);
      while (!cursor.isAfter(endBucket)) {
        buckets[cursor] = 0;
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
      for (final entry in entries) {
        final bucket = DateTime(entry.date.year, entry.date.month);
        buckets.update(bucket, (value) => value + entry.amount);
      }
      return buckets.entries
          .map(
            (entry) => ExpenseAnalyticsPoint(
              period: entry.key,
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
            period: entry.key,
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

  double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));

  double _roundPercentage(double value) =>
      double.parse(value.toStringAsFixed(2));

  bool _amountEquals(double left, double right) =>
      (left - right).abs() <= 0.01;
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
