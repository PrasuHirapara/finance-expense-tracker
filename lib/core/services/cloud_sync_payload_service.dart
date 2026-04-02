import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../features/credentials/domain/models/credential_models.dart';
import '../../features/tasks/data/repositories/task_category_repository.dart';
import '../models/cloud_sync_models.dart';
import 'cloud_sync_security_service.dart';
import 'credential_crypto_service.dart';

class CloudSyncPayloadService {
  CloudSyncPayloadService({
    required AppDatabase database,
    required TaskCategoryRepository taskCategoryRepository,
    required CredentialCryptoService credentialCryptoService,
    required CloudSyncSecurityService cloudSyncSecurityService,
  }) : _database = database,
       _taskCategoryRepository = taskCategoryRepository,
       _credentialCryptoService = credentialCryptoService,
       _cloudSyncSecurityService = cloudSyncSecurityService;

  final AppDatabase _database;
  final TaskCategoryRepository _taskCategoryRepository;
  final CredentialCryptoService _credentialCryptoService;
  final CloudSyncSecurityService _cloudSyncSecurityService;

  Future<CloudBackupBundle> buildBackupBundle({
    DateTime? exportedAt,
    String? accountEmail,
  }) async {
    final timestamp = exportedAt ?? DateTime.now();
    final categories = await (_database.select(
      _database.dbCategories,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
    final banks = await (_database.select(
      _database.dbBanks,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
    final entries = await (_database.select(
      _database.dbFinanceEntries,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
    final tasks = await (_database.select(
      _database.dbTasks,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
    final credentials = await (_database.select(
      _database.dbCredentials,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
    final taskCategories = await _taskCategoryRepository.getCategories();

    final credentialJson = jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'exportedAt': timestamp.toIso8601String(),
      'records': credentials
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'title': item.title,
              'encryptedPayload': item.encryptedPayload,
              'saltBase64': item.saltBase64,
              'nonceBase64': item.nonceBase64,
              'createdAt': item.createdAt.toIso8601String(),
              'updatedAt': item.updatedAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    });

    final expenseJson = jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'exportedAt': timestamp.toIso8601String(),
      'categories': categories
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'name': item.name,
              'iconCodePoint': item.iconCodePoint,
              'colorValue': item.colorValue,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'banks': banks
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'name': item.name,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'entries': entries
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'title': item.title,
              'amount': item.amount,
              'type': item.type,
              'categoryId': item.categoryId,
              'bankId': item.bankId,
              'entryDate': item.entryDate.toIso8601String(),
              'paymentMode': item.paymentMode,
              'notes': item.notes,
              'counterparty': item.counterparty,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    });

    final taskJson = jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'exportedAt': timestamp.toIso8601String(),
      'categories': taskCategories,
      'tasks': tasks
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'sourceTaskId': item.sourceTaskId,
              'title': item.title,
              'description': item.description,
              'category': item.category,
              'taskDate': item.taskDate.toIso8601String(),
              'priority': item.priority,
              'isDaily': item.isDaily,
              'isCompleted': item.isCompleted,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    });

    final credentialPayload = await encryptCredentialData(credentialJson);
    final localLatestAt = await computeLocalLatestChangeAt();

    return CloudBackupBundle(
      manifest: CloudSyncManifest(
        schemaVersion: 1,
        exportedAt: timestamp,
        localLatestAt: localLatestAt,
        accountEmail: accountEmail,
        domainCounts: <String, int>{
          CloudSyncDomain.credential.folderName: credentials.length,
          CloudSyncDomain.expense.folderName: entries.length,
          CloudSyncDomain.task.folderName: tasks.length,
        },
      ),
      credentialPayload: credentialPayload,
      expensePayload: expenseJson,
      taskPayload: taskJson,
    );
  }

  Future<DateTime> computeLocalLatestChangeAt() async {
    final categories = await (_database.select(_database.dbCategories)).get();
    final banks = await (_database.select(_database.dbBanks)).get();
    final entries = await (_database.select(_database.dbFinanceEntries)).get();
    final tasks = await (_database.select(_database.dbTasks)).get();
    final credentials = await (_database.select(_database.dbCredentials)).get();
    final taskCategoryUpdatedAt = await _taskCategoryRepository
        .lastModifiedAt();

    final candidates = <DateTime>[
      ...categories.map((item) => item.createdAt),
      ...banks.map((item) => item.createdAt),
      ...entries.map((item) => item.createdAt),
      ...entries.map((item) => item.entryDate),
      ...tasks.map((item) => item.createdAt),
      ...tasks.map((item) => item.taskDate),
      ...credentials.map((item) => item.updatedAt),
      ...credentials.map((item) => item.createdAt),
      ...?taskCategoryUpdatedAt == null
          ? null
          : <DateTime>[taskCategoryUpdatedAt],
    ];

    if (candidates.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    candidates.sort();
    return candidates.last;
  }

  Future<String> encryptCredentialData(String plainText) async {
    final backupKey = await _cloudSyncSecurityService.getOrCreateBackupKey();
    final encrypted = await _credentialCryptoService.encryptText(
      plainText: plainText,
      encryptionKey: backupKey,
    );

    return jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'encryptedPayload': encrypted.encryptedPayload,
      'saltBase64': encrypted.saltBase64,
      'nonceBase64': encrypted.nonceBase64,
    });
  }

  Future<String> decryptCredentialData(String encryptedContent) async {
    final decoded = jsonDecode(encryptedContent) as Map<String, dynamic>;
    final payload = EncryptedCredentialPayload(
      encryptedPayload: decoded['encryptedPayload'] as String? ?? '',
      saltBase64: decoded['saltBase64'] as String? ?? '',
      nonceBase64: decoded['nonceBase64'] as String? ?? '',
    );
    final backupKey = await _cloudSyncSecurityService.getOrCreateBackupKey();
    return _credentialCryptoService.decryptText(
      payload: payload,
      encryptionKey: backupKey,
    );
  }

  Future<void> restoreBundle({
    required String credentialPayload,
    required String expensePayload,
    required String taskPayload,
  }) async {
    final expense = jsonDecode(expensePayload) as Map<String, dynamic>;
    final task = jsonDecode(taskPayload) as Map<String, dynamic>;
    final credential =
        jsonDecode(await decryptCredentialData(credentialPayload))
            as Map<String, dynamic>;

    final categories =
        (expense['categories'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final banks = (expense['banks'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final entries = (expense['entries'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final taskCategories =
        (task['categories'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString())
            .toList(growable: false);
    final tasks = (task['tasks'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final credentials =
        (credential['records'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);

    await _database.transaction(() async {
      await _database.delete(_database.dbFinanceEntries).go();
      await _database.delete(_database.dbBanks).go();
      await _database.delete(_database.dbCategories).go();
      await _database.delete(_database.dbTasks).go();
      await _database.delete(_database.dbCredentials).go();

      if (categories.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbCategories,
            categories
                .map((item) {
                  return DbCategoriesCompanion(
                    id: Value(item['id'] as int),
                    name: Value(item['name'] as String? ?? ''),
                    iconCodePoint: Value(item['iconCodePoint'] as int? ?? 0),
                    colorValue: Value(item['colorValue'] as int? ?? 0),
                    createdAt: Value(
                      DateTime.tryParse(item['createdAt'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                  );
                })
                .toList(growable: false),
          );
        });
      }

      if (banks.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbBanks,
            banks
                .map((item) {
                  return DbBanksCompanion(
                    id: Value(item['id'] as int),
                    name: Value(item['name'] as String? ?? ''),
                    createdAt: Value(
                      DateTime.tryParse(item['createdAt'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                  );
                })
                .toList(growable: false),
          );
        });
      }

      if (entries.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbFinanceEntries,
            entries
                .map((item) {
                  return DbFinanceEntriesCompanion(
                    id: Value(item['id'] as int),
                    title: Value(item['title'] as String? ?? ''),
                    amount: Value((item['amount'] as num?)?.toDouble() ?? 0),
                    type: Value(item['type'] as String? ?? 'expense'),
                    categoryId: Value(item['categoryId'] as int? ?? 0),
                    bankId: Value(item['bankId'] as int?),
                    entryDate: Value(
                      DateTime.tryParse(item['entryDate'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                    paymentMode: Value(item['paymentMode'] as String? ?? ''),
                    notes: Value(item['notes'] as String? ?? ''),
                    counterparty: Value(item['counterparty'] as String?),
                    createdAt: Value(
                      DateTime.tryParse(item['createdAt'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                  );
                })
                .toList(growable: false),
          );
        });
      }

      if (tasks.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbTasks,
            tasks
                .map((item) {
                  return DbTasksCompanion(
                    id: Value(item['id'] as int),
                    sourceTaskId: Value(item['sourceTaskId'] as int?),
                    title: Value(item['title'] as String? ?? ''),
                    description: Value(item['description'] as String? ?? ''),
                    category: Value(item['category'] as String? ?? ''),
                    taskDate: Value(
                      DateTime.tryParse(item['taskDate'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                    priority: Value(item['priority'] as int? ?? 3),
                    isDaily: Value(item['isDaily'] as bool? ?? false),
                    isCompleted: Value(item['isCompleted'] as bool? ?? false),
                    createdAt: Value(
                      DateTime.tryParse(item['createdAt'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                  );
                })
                .toList(growable: false),
          );
        });
      }

      if (credentials.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbCredentials,
            credentials
                .map((item) {
                  return DbCredentialsCompanion(
                    id: Value(item['id'] as int),
                    title: Value(item['title'] as String? ?? ''),
                    encryptedPayload: Value(
                      item['encryptedPayload'] as String? ?? '',
                    ),
                    saltBase64: Value(item['saltBase64'] as String? ?? ''),
                    nonceBase64: Value(item['nonceBase64'] as String? ?? ''),
                    createdAt: Value(
                      DateTime.tryParse(item['createdAt'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                    updatedAt: Value(
                      DateTime.tryParse(item['updatedAt'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                  );
                })
                .toList(growable: false),
          );
        });
      }
    });

    await _taskCategoryRepository.replaceAll(taskCategories);
  }
}
