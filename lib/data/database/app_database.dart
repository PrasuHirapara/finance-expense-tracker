import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/finance_category_model.dart';
import '../models/finance_entry_model.dart';

part 'app_database.g.dart';

class DbCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorValue => integer()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

class DbBanks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

class DbFinanceEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  IntColumn get categoryId => integer().references(DbCategories, #id)();
  IntColumn get bankId => integer().nullable().references(DbBanks, #id)();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get paymentMode => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get counterparty => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

class DbSplitRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('expenseSplitRecords')
  IntColumn get expenseEntryId =>
      integer().nullable().references(DbFinanceEntries, #id)();
  @ReferenceName('lentSplitRecords')
  IntColumn get lentEntryId =>
      integer().nullable().references(DbFinanceEntries, #id)();
  RealColumn get totalAmount => real()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

class DbSplitParticipants extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get splitRecordId => integer().references(DbSplitRecords, #id)();
  TextColumn get participantName => text()();
  RealColumn get amount => real()();
  RealColumn get percentage => real()();
  BoolColumn get isSelf => boolean().withDefault(const Constant(false))();
  RealColumn get settledAmount => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

class DbLentSettlements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get splitRecordId => integer().references(DbSplitRecords, #id)();
  IntColumn get splitParticipantId =>
      integer().references(DbSplitParticipants, #id)();
  IntColumn get incomeEntryId => integer().references(DbFinanceEntries, #id)();
  RealColumn get settledAmount => real()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

class DbBorrowedSettlements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get borrowedEntryId =>
      integer().references(DbFinanceEntries, #id)();
  IntColumn get expenseEntryId => integer().references(DbFinanceEntries, #id)();
  RealColumn get settledAmount => real()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

class DbTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceTaskId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text()();
  DateTimeColumn get taskDate => dateTime()();
  IntColumn get priority => integer().withDefault(const Constant(3))();
  BoolColumn get isDaily => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

class DbCredentials extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get encryptedPayload => text()();
  TextColumn get saltBase64 => text()();
  TextColumn get nonceBase64 => text()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

@DriftDatabase(
  tables: <Type>[
    DbCategories,
    DbBanks,
    DbFinanceEntries,
    DbSplitRecords,
    DbSplitParticipants,
    DbLentSettlements,
    DbBorrowedSettlements,
    DbTasks,
    DbCredentials,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(dbBanks);
        await m.addColumn(dbFinanceEntries, dbFinanceEntries.bankId);
        await m.createTable(dbTasks);
      }
      if (from < 3) {
        await m.createTable(dbCredentials);
      }
      if (from < 4) {
        await m.createTable(dbSplitRecords);
        await m.createTable(dbSplitParticipants);
        await m.createTable(dbLentSettlements);
      }
      if (from < 5) {
        await m.createTable(dbBorrowedSettlements);
      }
    },
  );

  Future<int> countCategories() async =>
      (await select(dbCategories).get()).length;

  Future<int> countBanks() async => (await select(dbBanks).get()).length;

  Future<int> countEntries() async =>
      (await select(dbFinanceEntries).get()).length;

  Future<List<FinanceCategoryModel>> getCategories() async {
    final rows =
        await (select(dbCategories)
              ..orderBy(<OrderingTerm Function($DbCategoriesTable)>[
                (table) => OrderingTerm.asc(table.name),
              ]))
            .get();

    return rows
        .map(
          (row) => FinanceCategoryModel(
            id: row.id,
            name: row.name,
            iconCodePoint: row.iconCodePoint,
            colorValue: row.colorValue,
          ),
        )
        .toList(growable: false);
  }

  Stream<List<FinanceCategoryModel>> watchCategories() {
    return (select(dbCategories)
          ..orderBy(<OrderingTerm Function($DbCategoriesTable)>[
            (table) => OrderingTerm.asc(table.name),
          ]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => FinanceCategoryModel(
                  id: row.id,
                  name: row.name,
                  iconCodePoint: row.iconCodePoint,
                  colorValue: row.colorValue,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<List<DbBank>> getBanks() async {
    return (select(dbBanks)..orderBy(<OrderingTerm Function($DbBanksTable)>[
          (table) => OrderingTerm.asc(table.name),
        ]))
        .get();
  }

  Stream<List<DbBank>> watchBanks() {
    return (select(dbBanks)..orderBy(<OrderingTerm Function($DbBanksTable)>[
          (table) => OrderingTerm.asc(table.name),
        ]))
        .watch();
  }

  Future<void> insertCategories(List<DbCategoriesCompanion> companions) async {
    await batch(
      (batch) => batch.insertAll(
        dbCategories,
        companions,
        mode: InsertMode.insertOrIgnore,
      ),
    );
  }

  Future<void> insertBanks(List<DbBanksCompanion> companions) async {
    await batch(
      (batch) =>
          batch.insertAll(dbBanks, companions, mode: InsertMode.insertOrIgnore),
    );
  }

  Future<int> insertCategory(DbCategoriesCompanion companion) {
    return into(dbCategories).insert(companion);
  }

  Future<int> insertBank(DbBanksCompanion companion) {
    return into(dbBanks).insert(companion);
  }

  Future<int> updateBankName({required int bankId, required String name}) {
    return (update(dbBanks)..where((table) => table.id.equals(bankId))).write(
      DbBanksCompanion(name: Value(name)),
    );
  }

  Future<int> deleteBankById(int bankId) {
    return (delete(dbBanks)..where((table) => table.id.equals(bankId))).go();
  }

  Future<void> insertEntries(List<DbFinanceEntriesCompanion> companions) async {
    await batch(
      (batch) => batch.insertAll(
        dbFinanceEntries,
        companions,
        mode: InsertMode.insertOrReplace,
      ),
    );
  }

  Future<int> insertEntry(DbFinanceEntriesCompanion companion) {
    return into(dbFinanceEntries).insert(companion);
  }

  Future<List<FinanceEntryModel>> getAllEntries() async {
    final query = _joinedEntriesQuery();
    return _mapJoinedEntries(await query.get());
  }

  Stream<List<FinanceEntryModel>> watchAllEntries() {
    final query = _joinedEntriesQuery();
    return query.watch().map(_mapJoinedEntries);
  }

  Future<List<FinanceEntryModel>> getEntriesBetween(
    DateTime start,
    DateTime end,
  ) async {
    final query = _joinedEntriesQuery()
      ..where(
        dbFinanceEntries.entryDate.isBiggerOrEqualValue(start) &
            dbFinanceEntries.entryDate.isSmallerOrEqualValue(end),
      );

    return _mapJoinedEntries(await query.get());
  }

  JoinedSelectStatement<HasResultSet, dynamic> _joinedEntriesQuery() {
    return (select(dbFinanceEntries)
          ..orderBy(<OrderingTerm Function($DbFinanceEntriesTable)>[
            (table) => OrderingTerm.desc(table.entryDate),
            (table) => OrderingTerm.desc(table.id),
          ]))
        .join(<Join>[
          innerJoin(
            dbCategories,
            dbCategories.id.equalsExp(dbFinanceEntries.categoryId),
          ),
        ]);
  }

  List<FinanceEntryModel> _mapJoinedEntries(List<TypedResult> rows) {
    return rows
        .map((row) {
          final entry = row.readTable(dbFinanceEntries);
          final category = row.readTable(dbCategories);
          return FinanceEntryModel(
            id: entry.id,
            title: entry.title,
            amount: entry.amount,
            typeKey: entry.type,
            categoryId: category.id,
            categoryName: category.name,
            categoryIconCodePoint: category.iconCodePoint,
            categoryColorValue: category.colorValue,
            entryDate: entry.entryDate,
            paymentMode: entry.paymentMode,
            notes: entry.notes,
            counterparty: entry.counterparty,
          );
        })
        .toList(growable: false);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'ledger_lens.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
