import 'package:drift/drift.dart';

import '../../../../data/database/app_database.dart';
import '../../domain/models/credential_models.dart';

class CredentialRepository {
  CredentialRepository(this._database);

  final AppDatabase _database;

  Stream<List<CredentialRecord>> watchCredentials({String query = ''}) {
    final normalizedQuery = query.trim();
    final selectQuery = _database.select(_database.dbCredentials)
      ..orderBy([
        (table) => OrderingTerm.desc(table.updatedAt),
        (table) => OrderingTerm.desc(table.id),
      ]);

    if (normalizedQuery.isNotEmpty) {
      selectQuery.where(
        (table) => table.title.like('%${_escapeLike(normalizedQuery)}%'),
      );
    }

    return selectQuery.watch().map(
      (rows) => rows.map(_mapRecord).toList(growable: false),
    );
  }

  Future<List<CredentialRecord>> loadCredentials({String query = ''}) async {
    return watchCredentials(query: query).first;
  }

  Future<CredentialRecord?> loadCredential(int id) async {
    final row =
        await (_database.select(_database.dbCredentials)
              ..where((table) => table.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _mapRecord(row);
  }

  Future<int> addCredential({
    required String title,
    required EncryptedCredentialPayload payload,
  }) {
    final now = DateTime.now();
    return _database.into(_database.dbCredentials).insert(
      DbCredentialsCompanion.insert(
        title: title.trim(),
        encryptedPayload: payload.encryptedPayload,
        saltBase64: payload.saltBase64,
        nonceBase64: payload.nonceBase64,
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateCredential({
    required int id,
    required String title,
    required EncryptedCredentialPayload payload,
  }) async {
    await (_database.update(
      _database.dbCredentials,
    )..where((table) => table.id.equals(id))).write(
      DbCredentialsCompanion(
        title: Value(title.trim()),
        encryptedPayload: Value(payload.encryptedPayload),
        saltBase64: Value(payload.saltBase64),
        nonceBase64: Value(payload.nonceBase64),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteCredential(int id) async {
    await (_database.delete(
      _database.dbCredentials,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> deleteAllCredentials() async {
    await _database.delete(_database.dbCredentials).go();
  }

  CredentialRecord _mapRecord(DbCredential row) {
    return CredentialRecord(
      id: row.id,
      title: row.title,
      encryptedPayload: row.encryptedPayload,
      saltBase64: row.saltBase64,
      nonceBase64: row.nonceBase64,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  String _escapeLike(String query) {
    return query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
