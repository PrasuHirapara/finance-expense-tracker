import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../features/credentials/domain/models/credential_models.dart';
import '../../features/tasks/data/repositories/task_category_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../models/cloud_sync_models.dart';
import 'app_settings_repository.dart';
import 'cancellable_task.dart';
import 'cloud_backup_crypto_service.dart';
import 'credential_crypto_service.dart';
import 'reminder_settings_repository.dart';

class CloudSyncPayloadService {
  CloudSyncPayloadService({
    required AppDatabase database,
    required TaskRepository taskRepository,
    required TaskCategoryRepository taskCategoryRepository,
    required AppSettingsRepository appSettingsRepository,
    required ReminderSettingsRepository reminderSettingsRepository,
    required CredentialCryptoService credentialCryptoService,
    required CloudBackupCryptoService cloudBackupCryptoService,
  }) : _database = database,
       _taskRepository = taskRepository,
       _taskCategoryRepository = taskCategoryRepository,
       _appSettingsRepository = appSettingsRepository,
       _reminderSettingsRepository = reminderSettingsRepository,
       _credentialCryptoService = credentialCryptoService,
       _cloudBackupCryptoService = cloudBackupCryptoService;

  final AppDatabase _database;
  final TaskRepository _taskRepository;
  final TaskCategoryRepository _taskCategoryRepository;
  final AppSettingsRepository _appSettingsRepository;
  final ReminderSettingsRepository _reminderSettingsRepository;
  final CredentialCryptoService _credentialCryptoService;
  final CloudBackupCryptoService _cloudBackupCryptoService;
  final HashAlgorithm _hashAlgorithm = Sha256();

  static const int _expensePayloadSchemaVersion = 3;

  Future<CloudBackupBundle> buildBackupBundle({
    DateTime? exportedAt,
    String? accountEmail,
    String? credentialEncryptionKey,
    String? nonCredentialEncryptionKey,
    bool encryptCredentialTitlesForCloud = true,
    bool encryptNonCredentialPayloadsForCloud = true,
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
        _database.dbSplitRecords,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbSplitParticipants,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbLentSettlements,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbTasks,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbCredentials,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      _taskCategoryRepository.getCategories(),
      _taskCategoryRepository.lastModifiedAt(),
      _appSettingsRepository.exportForCloud(),
      _reminderSettingsRepository.exportForCloud(),
      _appSettingsRepository.lastModifiedAt(),
      _reminderSettingsRepository.lastModifiedAt(),
    ]);
    cancellationToken?.throwIfCancelled();
    final categories = loadedData[0] as List<DbCategory>;
    final banks = loadedData[1] as List<DbBank>;
    final entries = loadedData[2] as List<DbFinanceEntry>;
    final splitRecords = loadedData[3] as List<DbSplitRecord>;
    final splitParticipants = loadedData[4] as List<DbSplitParticipant>;
    final lentSettlements = loadedData[5] as List<DbLentSettlement>;
    final tasks = loadedData[6] as List<DbTask>;
    final credentials = loadedData[7] as List<DbCredential>;
    final taskCategories = loadedData[8] as List<String>;
    final taskCategoryUpdatedAt = loadedData[9] as DateTime?;
    final appSettings = loadedData[10] as Map<String, dynamic>;
    final reminderSettings = loadedData[11] as Map<String, dynamic>;
    final appSettingsUpdatedAt = loadedData[12] as DateTime?;
    final reminderSettingsUpdatedAt = loadedData[13] as DateTime?;
    final normalizedExpensePayload = _buildNormalizedExpensePayloadMaps(
      entries: entries,
      splitRecords: splitRecords,
      splitParticipants: splitParticipants,
      lentSettlements: lentSettlements,
    );
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
      'entries': normalizedExpensePayload.entries,
      'splitRecords': normalizedExpensePayload.splitRecords,
      'splitParticipants': normalizedExpensePayload.splitParticipants,
      'lentSettlements': normalizedExpensePayload.lentSettlements,
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
    final settingsHashSource = <String, dynamic>{
      'appSettings': appSettings,
      'reminderSettings': reminderSettings,
    };
    final domainHashes = <String, String>{
      CloudSyncDomain.credential.folderName: await _hashJsonContent(
        credentialHashSource,
      ),
      CloudSyncDomain.expense.folderName: await _hashJsonContent(
        expenseHashSource,
      ),
      CloudSyncDomain.task.folderName: await _hashJsonContent(taskHashSource),
      CloudSyncDomain.settings.folderName: await _hashJsonContent(
        settingsHashSource,
      ),
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
      'schemaVersion': _expensePayloadSchemaVersion,
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
      'entries': normalizedExpensePayload.entries,
      'splitRecords': normalizedExpensePayload.splitRecords,
      'splitParticipants': normalizedExpensePayload.splitParticipants,
      'lentSettlements': normalizedExpensePayload.lentSettlements,
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
    final settingsJson = jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'exportedAt': timestamp.toIso8601String(),
      'appSettings': appSettings,
      'reminderSettings': reminderSettings,
    });
    final protectedExpensePayload = encryptNonCredentialPayloadsForCloud
        ? await _encryptCloudPayload(
            payload: expenseJson,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.expense.folderName,
          )
        : expenseJson;
    final protectedTaskPayload = encryptNonCredentialPayloadsForCloud
        ? await _encryptCloudPayload(
            payload: taskJson,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.task.folderName,
          )
        : taskJson;
    final protectedSettingsPayload = encryptNonCredentialPayloadsForCloud
        ? await _encryptCloudPayload(
            payload: settingsJson,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.settings.folderName,
          )
        : settingsJson;
    final localLatestAt = _computeLocalLatestChangeAtFromData(
      categories: categories,
      banks: banks,
      entries: entries,
      splitRecords: splitRecords,
      splitParticipants: splitParticipants,
      lentSettlements: lentSettlements,
      tasks: tasks,
      credentials: credentials,
      taskCategoryUpdatedAt: taskCategoryUpdatedAt,
      appSettingsUpdatedAt: appSettingsUpdatedAt,
      reminderSettingsUpdatedAt: reminderSettingsUpdatedAt,
    );

    return CloudBackupBundle(
      manifest: CloudSyncManifest(
        schemaVersion: CloudSyncProtocol.manifestSchemaVersion,
        exportedAt: timestamp,
        localLatestAt: localLatestAt,
        accountEmail: accountEmail,
        domainCounts: <String, int>{
          CloudSyncDomain.credential.folderName: includeCredentialsInBundle
              ? credentials.length
              : 0,
          CloudSyncDomain.expense.folderName:
              normalizedExpensePayload.entries.length +
              normalizedExpensePayload.splitRecords.length +
              normalizedExpensePayload.splitParticipants.length +
              normalizedExpensePayload.lentSettlements.length,
          CloudSyncDomain.task.folderName: tasks.length,
          CloudSyncDomain.settings.folderName: 2,
        },
        domainHashes: domainHashes,
        payloadEncryptionSchemaVersion:
            CloudSyncProtocol.encryptedEnvelopeSchemaVersion,
        cloudKeyFormatVersion: CloudSyncProtocol.cloudKeyFormatVersion,
      ),
      credentialPayload: credentialJson,
      containsCredentialPayload: includeCredentialsInBundle,
      expensePayload: protectedExpensePayload,
      taskPayload: protectedTaskPayload,
      settingsPayload: protectedSettingsPayload,
      containsSettingsPayload: true,
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
      (_database.select(_database.dbSplitRecords)).get(),
      (_database.select(_database.dbSplitParticipants)).get(),
      (_database.select(_database.dbLentSettlements)).get(),
      (_database.select(_database.dbTasks)).get(),
      (_database.select(_database.dbCredentials)).get(),
      _taskCategoryRepository.lastModifiedAt(),
      _appSettingsRepository.lastModifiedAt(),
      _reminderSettingsRepository.lastModifiedAt(),
    ]);
    cancellationToken?.throwIfCancelled();

    return _computeLocalLatestChangeAtFromData(
      categories: loadedData[0] as List<DbCategory>,
      banks: loadedData[1] as List<DbBank>,
      entries: loadedData[2] as List<DbFinanceEntry>,
      splitRecords: loadedData[3] as List<DbSplitRecord>,
      splitParticipants: loadedData[4] as List<DbSplitParticipant>,
      lentSettlements: loadedData[5] as List<DbLentSettlement>,
      tasks: loadedData[6] as List<DbTask>,
      credentials: loadedData[7] as List<DbCredential>,
      taskCategoryUpdatedAt: loadedData[8] as DateTime?,
      appSettingsUpdatedAt: loadedData[9] as DateTime?,
      reminderSettingsUpdatedAt: loadedData[10] as DateTime?,
    );
  }

  DateTime _computeLocalLatestChangeAtFromData({
    required List<DbCategory> categories,
    required List<DbBank> banks,
    required List<DbFinanceEntry> entries,
    required List<DbSplitRecord> splitRecords,
    required List<DbSplitParticipant> splitParticipants,
    required List<DbLentSettlement> lentSettlements,
    required List<DbTask> tasks,
    required List<DbCredential> credentials,
    required DateTime? taskCategoryUpdatedAt,
    required DateTime? appSettingsUpdatedAt,
    required DateTime? reminderSettingsUpdatedAt,
  }) {
    final candidates = <DateTime>[
      ...categories.map((item) => item.createdAt),
      ...banks.map((item) => item.createdAt),
      ...entries.map((item) => item.createdAt),
      ...entries.map((item) => item.entryDate),
      ...splitRecords.map((item) => item.createdAt),
      ...splitParticipants.map((item) => item.createdAt),
      ...lentSettlements.map((item) => item.createdAt),
      ...tasks.map((item) => item.createdAt),
      ...tasks.map((item) => item.taskDate),
      ...credentials.map((item) => item.updatedAt),
      ...credentials.map((item) => item.createdAt),
      ...<DateTime?>[taskCategoryUpdatedAt].whereType<DateTime>(),
      ...<DateTime?>[appSettingsUpdatedAt].whereType<DateTime>(),
      ...<DateTime?>[reminderSettingsUpdatedAt].whereType<DateTime>(),
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
    required String settingsPayload,
    String? credentialEncryptionKey,
    String? nonCredentialEncryptionKey,
    bool restoreCredentials = true,
    bool restoreSettings = true,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final decodedExpensePayload = await _decryptCloudPayloadIfNeeded(
      payload: expensePayload,
      encryptionKey: nonCredentialEncryptionKey,
      domainLabel: CloudSyncDomain.expense.folderName,
    );
    final decodedTaskPayload = await _decryptCloudPayloadIfNeeded(
      payload: taskPayload,
      encryptionKey: nonCredentialEncryptionKey,
      domainLabel: CloudSyncDomain.task.folderName,
    );
    final decodedSettingsPayload = restoreSettings
        ? await _decryptCloudPayloadIfNeeded(
            payload: settingsPayload,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.settings.folderName,
          )
        : '{}';
    final expense = jsonDecode(decodedExpensePayload) as Map<String, dynamic>;
    final task = jsonDecode(decodedTaskPayload) as Map<String, dynamic>;
    final settings = restoreSettings
        ? jsonDecode(decodedSettingsPayload) as Map<String, dynamic>
        : const <String, dynamic>{};
    final credential = restoreCredentials
        ? jsonDecode(credentialPayload) as Map<String, dynamic>
        : const <String, dynamic>{};
    final normalizedExpensePayload = _normalizeExpenseRestorePayload(expense);
    final categories =
        (expense['categories'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final banks = (expense['banks'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final entries = normalizedExpensePayload.entries;
    final splitRecords = normalizedExpensePayload.splitRecords;
    final splitParticipants = normalizedExpensePayload.splitParticipants;
    final lentSettlements = normalizedExpensePayload.lentSettlements;
    final taskCategories =
        (task['categories'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item.toString())
            .toList(growable: false);
    final tasks = (task['tasks'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final appSettings = settings['appSettings'];
    final reminderSettings = settings['reminderSettings'];
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
      await _database.delete(_database.dbLentSettlements).go();
      await _database.delete(_database.dbSplitParticipants).go();
      await _database.delete(_database.dbSplitRecords).go();
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

      if (splitRecords.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbSplitRecords,
            splitRecords
                .map((item) {
                  return DbSplitRecordsCompanion(
                    id: Value(item['id'] as int),
                    expenseEntryId: Value(item['expenseEntryId'] as int?),
                    lentEntryId: Value(item['lentEntryId'] as int?),
                    totalAmount: Value(
                      (item['totalAmount'] as num?)?.toDouble() ?? 0,
                    ),
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

      if (splitParticipants.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbSplitParticipants,
            splitParticipants
                .map((item) {
                  return DbSplitParticipantsCompanion(
                    id: Value(item['id'] as int),
                    splitRecordId: Value(item['splitRecordId'] as int? ?? 0),
                    participantName: Value(
                      item['participantName'] as String? ?? '',
                    ),
                    amount: Value((item['amount'] as num?)?.toDouble() ?? 0),
                    percentage: Value(
                      (item['percentage'] as num?)?.toDouble() ?? 0,
                    ),
                    isSelf: Value(item['isSelf'] as bool? ?? false),
                    settledAmount: Value(
                      (item['settledAmount'] as num?)?.toDouble() ?? 0,
                    ),
                    sortOrder: Value(item['sortOrder'] as int? ?? 0),
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

      if (lentSettlements.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbLentSettlements,
            lentSettlements
                .map((item) {
                  return DbLentSettlementsCompanion(
                    id: Value(item['id'] as int),
                    splitRecordId: Value(item['splitRecordId'] as int? ?? 0),
                    splitParticipantId: Value(
                      item['splitParticipantId'] as int? ?? 0,
                    ),
                    incomeEntryId: Value(item['incomeEntryId'] as int? ?? 0),
                    settledAmount: Value(
                      (item['settledAmount'] as num?)?.toDouble() ?? 0,
                    ),
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
    if (restoreSettings) {
      await _appSettingsRepository.restoreFromCloud(appSettings);
      await _reminderSettingsRepository.restoreFromCloud(reminderSettings);
    }
  }

  Future<String> _encryptCloudPayload({
    required String payload,
    required String? encryptionKey,
    required String domainLabel,
  }) async {
    final trimmedKey = encryptionKey?.trim();
    if (trimmedKey == null || trimmedKey.isEmpty) {
      throw CloudPayloadDecryptionException(
        'A non-credential encryption key is required for the $domainLabel cloud payload.',
      );
    }

    final encryptedPayload = await _cloudBackupCryptoService.encryptText(
      plainText: payload,
      encryptionKey: trimmedKey,
    );
    return jsonEncode(<String, dynamic>{
      'encrypted': true,
      ...encryptedPayload.toJson(),
    });
  }

  Future<String> _decryptCloudPayloadIfNeeded({
    required String payload,
    required String? encryptionKey,
    required String domainLabel,
  }) async {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic> || decoded['encrypted'] != true) {
      return payload;
    }

    final schemaVersion = decoded['schemaVersion'] is int
        ? decoded['schemaVersion'] as int
        : 1;
    final keyFormatVersion = decoded['keyFormatVersion'] is int
        ? decoded['keyFormatVersion'] as int
        : 1;
    final algorithm = decoded['algorithm'] as String? ??
        CloudSyncProtocol.encryptedPayloadAlgorithm;

    if (schemaVersion > CloudSyncProtocol.encryptedEnvelopeSchemaVersion) {
      throw CloudPayloadDecryptionException(
        'The $domainLabel cloud payload uses a newer encryption format.',
      );
    }
    if (keyFormatVersion != CloudSyncProtocol.cloudKeyFormatVersion) {
      throw CloudPayloadDecryptionException(
        'The $domainLabel cloud payload uses an unsupported cloud key format.',
      );
    }
    if (algorithm != CloudSyncProtocol.encryptedPayloadAlgorithm) {
      throw CloudPayloadDecryptionException(
        'The $domainLabel cloud payload uses an unsupported encryption algorithm.',
      );
    }

    final trimmedKey = encryptionKey?.trim();
    if (trimmedKey == null || trimmedKey.isEmpty) {
      throw CloudPayloadDecryptionException(
        'A non-credential encryption key is required to restore the $domainLabel cloud payload.',
      );
    }

    try {
      return await _cloudBackupCryptoService.decryptText(
        payload: EncryptedCloudPayload.fromJson(decoded),
        encryptionKey: trimmedKey,
      );
    } catch (_) {
      throw CloudPayloadDecryptionException(
        'Unable to decrypt the $domainLabel cloud payload.',
      );
    }
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

  _NormalizedExpenseSyncPayload _buildNormalizedExpensePayloadMaps({
    required List<DbFinanceEntry> entries,
    required List<DbSplitRecord> splitRecords,
    required List<DbSplitParticipant> splitParticipants,
    required List<DbLentSettlement> lentSettlements,
  }) {
    final legacyManagedLentEntryIds = splitRecords
        .where(
          (item) => item.expenseEntryId != null && item.lentEntryId != null,
        )
        .map((item) => item.lentEntryId)
        .whereType<int>()
        .toSet();
    final totalAmountByExpenseEntryId = <int, double>{
      for (final item in splitRecords)
        if (item.expenseEntryId != null) item.expenseEntryId!: item.totalAmount,
    };

    return _NormalizedExpenseSyncPayload(
      entries: entries
          .where((item) => !legacyManagedLentEntryIds.contains(item.id))
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'title': item.title,
              'amount': totalAmountByExpenseEntryId[item.id] ?? item.amount,
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
      splitRecords: splitRecords
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'expenseEntryId': item.expenseEntryId,
              'lentEntryId': item.expenseEntryId != null
                  ? null
                  : item.lentEntryId,
              'totalAmount': item.totalAmount,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      splitParticipants: splitParticipants
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'splitRecordId': item.splitRecordId,
              'participantName': item.participantName,
              'amount': item.amount,
              'percentage': item.percentage,
              'isSelf': item.isSelf,
              'settledAmount': item.settledAmount,
              'sortOrder': item.sortOrder,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      lentSettlements: lentSettlements
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'splitRecordId': item.splitRecordId,
              'splitParticipantId': item.splitParticipantId,
              'incomeEntryId': item.incomeEntryId,
              'settledAmount': item.settledAmount,
              'createdAt': item.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    );
  }

  _NormalizedExpenseSyncPayload _normalizeExpenseRestorePayload(
    Map<String, dynamic> expense,
  ) {
    final rawEntries =
        (expense['entries'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final rawSplitRecords =
        (expense['splitRecords'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final rawSplitParticipants =
        (expense['splitParticipants'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final rawLentSettlements =
        (expense['lentSettlements'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);

    if (rawSplitRecords.isEmpty) {
      return _NormalizedExpenseSyncPayload(
        entries: rawEntries
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
        splitRecords: const <Map<String, dynamic>>[],
        splitParticipants: rawSplitParticipants
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
        lentSettlements: rawLentSettlements
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
      );
    }

    final legacyManagedLentEntryIds = rawSplitRecords
        .where(
          (item) =>
              item['expenseEntryId'] != null && item['lentEntryId'] != null,
        )
        .map((item) => item['lentEntryId'])
        .whereType<int>()
        .toSet();
    final totalAmountByExpenseEntryId = <int, double>{
      for (final item in rawSplitRecords)
        if (item['expenseEntryId'] is int)
          item['expenseEntryId'] as int:
              (item['totalAmount'] as num?)?.toDouble() ?? 0,
    };

    return _NormalizedExpenseSyncPayload(
      entries: rawEntries
          .where((item) => !legacyManagedLentEntryIds.contains(item['id']))
          .map((item) {
            final normalized = Map<String, dynamic>.from(item);
            final entryId = normalized['id'];
            if (entryId is int &&
                totalAmountByExpenseEntryId.containsKey(entryId)) {
              normalized['amount'] = totalAmountByExpenseEntryId[entryId];
            }
            return normalized;
          })
          .toList(growable: false),
      splitRecords: rawSplitRecords
          .map((item) {
            final normalized = Map<String, dynamic>.from(item);
            if (normalized['expenseEntryId'] != null) {
              normalized['lentEntryId'] = null;
            }
            return normalized;
          })
          .toList(growable: false),
      splitParticipants: rawSplitParticipants
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
      lentSettlements: rawLentSettlements
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
    );
  }

  Future<String> _hashJsonContent(Map<String, dynamic> content) async {
    final digest = await _hashAlgorithm.hash(utf8.encode(jsonEncode(content)));
    return base64UrlEncode(digest.bytes);
  }
}

class _NormalizedExpenseSyncPayload {
  const _NormalizedExpenseSyncPayload({
    required this.entries,
    required this.splitRecords,
    required this.splitParticipants,
    required this.lentSettlements,
  });

  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> splitRecords;
  final List<Map<String, dynamic>> splitParticipants;
  final List<Map<String, dynamic>> lentSettlements;
}
