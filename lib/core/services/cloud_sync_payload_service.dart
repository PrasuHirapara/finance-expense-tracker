import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../features/tasks/data/repositories/task_category_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../models/cloud_sync_models.dart';
import '../../features/credentials/domain/models/credential_models.dart';
import 'cancellable_task.dart';
import 'credential_crypto_service.dart';

class CloudSyncPayloadService {
  CloudSyncPayloadService({
    required AppDatabase database,
    required TaskRepository taskRepository,
    required TaskCategoryRepository taskCategoryRepository,
    required CredentialCryptoService credentialCryptoService,
  }) : _database = database,
       _taskRepository = taskRepository,
       _taskCategoryRepository = taskCategoryRepository,
       _credentialCryptoService = credentialCryptoService;

  final AppDatabase _database;
  final TaskRepository _taskRepository;
  final TaskCategoryRepository _taskCategoryRepository;
  final CredentialCryptoService _credentialCryptoService;
  final HashAlgorithm _hashAlgorithm = Sha256();

  Future<CloudBackupBundle> buildBackupBundle({
    DateTime? exportedAt,
    String? accountEmail,
    String? credentialEncryptionKey,
    bool encryptCredentialTitlesForCloud = true,
    bool includeCredentialsInBundle = true,
    AppCancellationToken? cancellationToken,
  }) async {
    final timestamp = exportedAt ?? DateTime.now();
    cancellationToken?.throwIfCancelled();
    await _taskRepository.ensureDailyTasksThroughDate(timestamp);
    cancellationToken?.throwIfCancelled();
    final loadedData = await Future.wait<Object?>(<Future<Object?>>[
      (_database.select(
        _database.dbCategories,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbBanks,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbFinanceEntries,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbTasks,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbCredentials,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      _taskCategoryRepository.getCategories(),
      _taskCategoryRepository.lastModifiedAt(),
    ]);
    cancellationToken?.throwIfCancelled();
    final categories = loadedData[0] as List<DbCategory>;
    final banks = loadedData[1] as List<DbBank>;
    final entries = loadedData[2] as List<DbFinanceEntry>;
    final tasks = loadedData[3] as List<DbTask>;
    final credentials = loadedData[4] as List<DbCredential>;
    final taskCategories = loadedData[5] as List<String>;
    final taskCategoryUpdatedAt = loadedData[6] as DateTime?;
    final credentialHashSource = <String, dynamic>{
      'syncEnabled': includeCredentialsInBundle,
      'records': includeCredentialsInBundle
          ? credentials
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
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
    };
    final expenseHashSource = <String, dynamic>{
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
    };
    final taskHashSource = <String, dynamic>{
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
    };
    final domainHashes = <String, String>{
      CloudSyncDomain.credential.folderName: await _hashJsonContent(
        credentialHashSource,
      ),
      CloudSyncDomain.expense.folderName: await _hashJsonContent(
        expenseHashSource,
      ),
      CloudSyncDomain.task.folderName: await _hashJsonContent(taskHashSource),
    };

    if (includeCredentialsInBundle &&
        encryptCredentialTitlesForCloud &&
        credentials.isNotEmpty &&
        (credentialEncryptionKey == null ||
            credentialEncryptionKey.trim().isEmpty)) {
      throw const CloudCredentialEncryptionKeyRequiredException(
        'A credential encryption key is required before credential titles can be synced to Firestore.',
      );
    }

    if (includeCredentialsInBundle &&
        encryptCredentialTitlesForCloud &&
        credentials.isNotEmpty) {
      cancellationToken?.throwIfCancelled();
      final firstCredential = credentials.first;
      try {
        await _credentialCryptoService.decryptFields(
          record: CredentialRecord(
            id: firstCredential.id,
            title: firstCredential.title,
            encryptedPayload: firstCredential.encryptedPayload,
            saltBase64: firstCredential.saltBase64,
            nonceBase64: firstCredential.nonceBase64,
            createdAt: firstCredential.createdAt,
            updatedAt: firstCredential.updatedAt,
          ),
          encryptionKey: credentialEncryptionKey!.trim(),
        );
      } catch (_) {
        throw const CloudCredentialEncryptionKeyInvalidException(
          'The saved credential encryption key could not decrypt local credential records.',
        );
      }
    }

    final credentialRecords = <Map<String, dynamic>>[];
    if (includeCredentialsInBundle) {
      for (var index = 0; index < credentials.length; index++) {
        if (index % 8 == 0) {
          await cancellableUiYield(cancellationToken);
        } else {
          cancellationToken?.throwIfCancelled();
        }

        final item = credentials[index];
        final expiryDate = await _extractCredentialExpiryDate(
          item,
          credentialEncryptionKey: credentialEncryptionKey,
        );
        final map = <String, dynamic>{
          'id': item.id,
          'encryptedPayload': item.encryptedPayload,
          'saltBase64': item.saltBase64,
          'nonceBase64': item.nonceBase64,
          'createdAt': item.createdAt.toIso8601String(),
          'updatedAt': item.updatedAt.toIso8601String(),
        };

        if (expiryDate != null) {
          if (encryptCredentialTitlesForCloud &&
              credentialEncryptionKey != null &&
              credentialEncryptionKey.trim().isNotEmpty) {
            final expiryPayload = await _credentialCryptoService.encryptText(
              plainText: expiryDate.toIso8601String(),
              encryptionKey: credentialEncryptionKey.trim(),
            );
            map['expiryEncryptedPayload'] = expiryPayload.encryptedPayload;
            map['expirySaltBase64'] = expiryPayload.saltBase64;
            map['expiryNonceBase64'] = expiryPayload.nonceBase64;
          } else {
            map['expiryDate'] = expiryDate.toIso8601String();
          }
        }

        if (encryptCredentialTitlesForCloud) {
          final titlePayload = await _credentialCryptoService.encryptText(
            plainText: item.title,
            encryptionKey: credentialEncryptionKey!.trim(),
          );
          map['titleEncryptedPayload'] = titlePayload.encryptedPayload;
          map['titleSaltBase64'] = titlePayload.saltBase64;
          map['titleNonceBase64'] = titlePayload.nonceBase64;
        } else {
          map['title'] = item.title;
        }

        credentialRecords.add(map);
      }
    }

    final credentialJson = jsonEncode(<String, dynamic>{
      'schemaVersion': includeCredentialsInBundle
          ? encryptCredentialTitlesForCloud
                ? 3
                : 1
          : 0,
      'exportedAt': timestamp.toIso8601String(),
      'records': credentialRecords,
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
    final localLatestAt = _computeLocalLatestChangeAtFromData(
      categories: categories,
      banks: banks,
      entries: entries,
      tasks: tasks,
      credentials: credentials,
      taskCategoryUpdatedAt: taskCategoryUpdatedAt,
    );

    return CloudBackupBundle(
      manifest: CloudSyncManifest(
        schemaVersion: 1,
        exportedAt: timestamp,
        localLatestAt: localLatestAt,
        accountEmail: accountEmail,
        domainCounts: <String, int>{
          CloudSyncDomain.credential.folderName: includeCredentialsInBundle
              ? credentials.length
              : 0,
          CloudSyncDomain.expense.folderName: entries.length,
          CloudSyncDomain.task.folderName: tasks.length,
        },
        domainHashes: domainHashes,
      ),
      credentialPayload: credentialJson,
      containsCredentialPayload: includeCredentialsInBundle,
      expensePayload: expenseJson,
      taskPayload: taskJson,
    );
  }

  Future<DateTime> computeLocalLatestChangeAt() async {
    return computeLocalLatestChangeAtWithCancellation();
  }

  Future<DateTime> computeLocalLatestChangeAtWithCancellation({
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    await _taskRepository.ensureDailyTasksThroughDate(DateTime.now());
    cancellationToken?.throwIfCancelled();
    final loadedData = await Future.wait<Object?>(<Future<Object?>>[
      (_database.select(_database.dbCategories)).get(),
      (_database.select(_database.dbBanks)).get(),
      (_database.select(_database.dbFinanceEntries)).get(),
      (_database.select(_database.dbTasks)).get(),
      (_database.select(_database.dbCredentials)).get(),
      _taskCategoryRepository.lastModifiedAt(),
    ]);
    cancellationToken?.throwIfCancelled();

    return _computeLocalLatestChangeAtFromData(
      categories: loadedData[0] as List<DbCategory>,
      banks: loadedData[1] as List<DbBank>,
      entries: loadedData[2] as List<DbFinanceEntry>,
      tasks: loadedData[3] as List<DbTask>,
      credentials: loadedData[4] as List<DbCredential>,
      taskCategoryUpdatedAt: loadedData[5] as DateTime?,
    );
  }

  DateTime _computeLocalLatestChangeAtFromData({
    required List<DbCategory> categories,
    required List<DbBank> banks,
    required List<DbFinanceEntry> entries,
    required List<DbTask> tasks,
    required List<DbCredential> credentials,
    required DateTime? taskCategoryUpdatedAt,
  }) {
    final candidates = <DateTime>[
      ...categories.map((item) => item.createdAt),
      ...banks.map((item) => item.createdAt),
      ...entries.map((item) => item.createdAt),
      ...entries.map((item) => item.entryDate),
      ...tasks.map((item) => item.createdAt),
      ...tasks.map((item) => item.taskDate),
      ...credentials.map((item) => item.updatedAt),
      ...credentials.map((item) => item.createdAt),
      ...<DateTime?>[taskCategoryUpdatedAt].whereType<DateTime>(),
    ];

    if (candidates.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    candidates.sort();
    return candidates.last;
  }

  Future<void> restoreBundle({
    required String credentialPayload,
    required String expensePayload,
    required String taskPayload,
    String? credentialEncryptionKey,
    bool restoreCredentials = true,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final expense = jsonDecode(expensePayload) as Map<String, dynamic>;
    final task = jsonDecode(taskPayload) as Map<String, dynamic>;
    final credential = restoreCredentials
        ? jsonDecode(credentialPayload) as Map<String, dynamic>
        : const <String, dynamic>{};

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
    final credentials = restoreCredentials
        ? (credential['records'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final credentialCompanions = <DbCredentialsCompanion>[];
    if (restoreCredentials) {
      for (var index = 0; index < credentials.length; index++) {
        if (index % 8 == 0) {
          await cancellableUiYield(cancellationToken);
        } else {
          cancellationToken?.throwIfCancelled();
        }

        final item = credentials[index];
        final title = await _restoreCredentialTitle(
          item,
          credentialEncryptionKey: credentialEncryptionKey,
        );
        final payload = await _restoreCredentialPayload(
          item,
          title: title,
          credentialEncryptionKey: credentialEncryptionKey,
        );
        credentialCompanions.add(
          DbCredentialsCompanion(
            id: Value(item['id'] as int),
            title: Value(title),
            encryptedPayload: Value(payload.encryptedPayload),
            saltBase64: Value(payload.saltBase64),
            nonceBase64: Value(payload.nonceBase64),
            createdAt: Value(
              DateTime.tryParse(item['createdAt'] as String? ?? '') ??
                  DateTime.now(),
            ),
            updatedAt: Value(
              DateTime.tryParse(item['updatedAt'] as String? ?? '') ??
                  DateTime.now(),
            ),
          ),
        );
      }
    }

    await _database.transaction(() async {
      cancellationToken?.throwIfCancelled();
      await _database.delete(_database.dbFinanceEntries).go();
      await _database.delete(_database.dbBanks).go();
      await _database.delete(_database.dbCategories).go();
      await _database.delete(_database.dbTasks).go();
      if (restoreCredentials) {
        await _database.delete(_database.dbCredentials).go();
      }

      if (categories.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
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
        cancellationToken?.throwIfCancelled();
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
        cancellationToken?.throwIfCancelled();
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
        cancellationToken?.throwIfCancelled();
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

      if (restoreCredentials && credentials.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(_database.dbCredentials, credentialCompanions);
        });
      }
    });

    cancellationToken?.throwIfCancelled();
    await _taskCategoryRepository.replaceAll(taskCategories);
  }

  Future<String> _restoreCredentialTitle(
    Map<String, dynamic> item, {
    String? credentialEncryptionKey,
  }) async {
    final encryptedTitle = item['titleEncryptedPayload'] as String?;
    if (encryptedTitle == null || encryptedTitle.isEmpty) {
      return item['title'] as String? ?? '';
    }

    if (credentialEncryptionKey == null ||
        credentialEncryptionKey.trim().isEmpty) {
      throw const CloudCredentialEncryptionKeyRequiredException(
        'Enter your credential encryption key to restore encrypted credential titles from Firestore.',
      );
    }

    try {
      return await _credentialCryptoService.decryptText(
        payload: EncryptedCredentialPayload(
          encryptedPayload: encryptedTitle,
          saltBase64: item['titleSaltBase64'] as String? ?? '',
          nonceBase64: item['titleNonceBase64'] as String? ?? '',
        ),
        encryptionKey: credentialEncryptionKey.trim(),
      );
    } catch (_) {
      throw const CloudCredentialEncryptionKeyInvalidException(
        'The provided credential encryption key could not decrypt the Firestore credential backup.',
      );
    }
  }

  Future<DateTime?> _extractCredentialExpiryDate(
    DbCredential credential, {
    String? credentialEncryptionKey,
  }) async {
    if (credentialEncryptionKey == null ||
        credentialEncryptionKey.trim().isEmpty) {
      return null;
    }

    try {
      final fields = await _credentialCryptoService.decryptFields(
        record: CredentialRecord(
          id: credential.id,
          title: credential.title,
          encryptedPayload: credential.encryptedPayload,
          saltBase64: credential.saltBase64,
          nonceBase64: credential.nonceBase64,
          createdAt: credential.createdAt,
          updatedAt: credential.updatedAt,
        ),
        encryptionKey: credentialEncryptionKey.trim(),
      );
      return extractCredentialExpiryDate(fields);
    } catch (_) {
      return null;
    }
  }

  Future<EncryptedCredentialPayload> _restoreCredentialPayload(
    Map<String, dynamic> item, {
    required String title,
    String? credentialEncryptionKey,
  }) async {
    final originalPayload = EncryptedCredentialPayload(
      encryptedPayload: item['encryptedPayload'] as String? ?? '',
      saltBase64: item['saltBase64'] as String? ?? '',
      nonceBase64: item['nonceBase64'] as String? ?? '',
    );
    final expiryDate = await _restoreCredentialExpiryDate(
      item,
      credentialEncryptionKey: credentialEncryptionKey,
    );
    if (expiryDate == null ||
        credentialEncryptionKey == null ||
        credentialEncryptionKey.trim().isEmpty) {
      return originalPayload;
    }

    try {
      final decryptedFields = await _credentialCryptoService.decryptFields(
        record: CredentialRecord(
          id: item['id'] as int? ?? 0,
          title: title,
          encryptedPayload: originalPayload.encryptedPayload,
          saltBase64: originalPayload.saltBase64,
          nonceBase64: originalPayload.nonceBase64,
          createdAt:
              DateTime.tryParse(item['createdAt'] as String? ?? '') ??
              DateTime.now(),
          updatedAt:
              DateTime.tryParse(item['updatedAt'] as String? ?? '') ??
              DateTime.now(),
        ),
        encryptionKey: credentialEncryptionKey.trim(),
      );
      return _credentialCryptoService.encryptFields(
        fields: withCredentialExpiryMetadataFields(
          fields: decryptedFields,
          expiryDate: expiryDate,
        ),
        encryptionKey: credentialEncryptionKey.trim(),
      );
    } catch (_) {
      return originalPayload;
    }
  }

  Future<DateTime?> _restoreCredentialExpiryDate(
    Map<String, dynamic> item, {
    String? credentialEncryptionKey,
  }) async {
    final encryptedExpiry = item['expiryEncryptedPayload'] as String?;
    if (encryptedExpiry != null && encryptedExpiry.isNotEmpty) {
      if (credentialEncryptionKey == null ||
          credentialEncryptionKey.trim().isEmpty) {
        throw const CloudCredentialEncryptionKeyRequiredException(
          'Enter your credential encryption key to restore encrypted credential expiry dates from Firestore.',
        );
      }

      try {
        final decryptedValue = await _credentialCryptoService.decryptText(
          payload: EncryptedCredentialPayload(
            encryptedPayload: encryptedExpiry,
            saltBase64: item['expirySaltBase64'] as String? ?? '',
            nonceBase64: item['expiryNonceBase64'] as String? ?? '',
          ),
          encryptionKey: credentialEncryptionKey.trim(),
        );
        return DateTime.tryParse(decryptedValue);
      } catch (_) {
        throw const CloudCredentialEncryptionKeyInvalidException(
          'The provided credential encryption key could not decrypt the Firestore credential expiry dates.',
        );
      }
    }

    final plainExpiry = item['expiryDate'] as String?;
    if (plainExpiry == null || plainExpiry.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(plainExpiry);
  }

  Future<String> _hashJsonContent(Map<String, dynamic> content) async {
    final digest = await _hashAlgorithm.hash(utf8.encode(jsonEncode(content)));
    return base64UrlEncode(digest.bytes);
  }
}
