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

class DbFinanceEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  IntColumn get categoryId => integer().references(DbCategories, #id)();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get paymentMode => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get counterparty => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

@DriftDatabase(tables: <Type>[DbCategories, DbFinanceEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<int> countCategories() async =>
      (await select(dbCategories).get()).length;

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

  Future<void> insertCategories(List<DbCategoriesCompanion> companions) async {
    await batch(
      (batch) => batch.insertAll(
        dbCategories,
        companions,
        mode: InsertMode.insertOrIgnore,
      ),
    );
  }

  Future<int> insertCategory(DbCategoriesCompanion companion) {
    return into(dbCategories).insert(companion);
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
