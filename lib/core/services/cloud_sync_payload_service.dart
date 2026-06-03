import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

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

  static const int _expensePayloadSchemaVersion = 5;

  Future<CloudBackupBundle> buildBackupBundle({
    DateTime? exportedAt,
    String? accountEmail,
    String? credentialEncryptionKey,
    String? nonCredentialEncryptionKey,
    bool encryptCredentialTitlesForCloud = true,
    bool encryptNonCredentialPayloadsForCloud = true,
    bool includeCredentialsInBundle = true,
    bool includeExpenseInBundle = true,
    bool includeTasksInBundle = true,
    bool includeInvestmentInBundle = true,
    bool includeSettingsInBundle = true,
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
        _database.dbBorrowedSettlements,
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
      (_database.select(
        _database.dbInvestmentCategories,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbInvestmentTaxProfiles,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbInvestmentEntries,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
      (_database.select(
        _database.dbSellEntries,
      )..orderBy([(table) => OrderingTerm.asc(table.id)])).get(),
    ]);
    cancellationToken?.throwIfCancelled();
    final categories = loadedData[0] as List<DbCategory>;
    final banks = loadedData[1] as List<DbBank>;
    final entries = loadedData[2] as List<DbFinanceEntry>;
    final splitRecords = loadedData[3] as List<DbSplitRecord>;
    final splitParticipants = loadedData[4] as List<DbSplitParticipant>;
    final lentSettlements = loadedData[5] as List<DbLentSettlement>;
    final borrowedSettlements = loadedData[6] as List<DbBorrowedSettlement>;
    final tasks = loadedData[7] as List<DbTask>;
    final credentials = loadedData[8] as List<DbCredential>;
    final taskCategories = loadedData[9] as List<String>;
    final taskCategoryUpdatedAt = loadedData[10] as DateTime?;
    final appSettings = loadedData[11] as Map<String, dynamic>;
    final reminderSettings = loadedData[12] as Map<String, dynamic>;
    final appSettingsUpdatedAt = loadedData[13] as DateTime?;
    final reminderSettingsUpdatedAt = loadedData[14] as DateTime?;
    final investmentCategories = loadedData[15] as List<DbInvestmentCategory>;
    final investmentTaxProfiles = loadedData[16] as List<DbInvestmentTaxProfile>;
    final investmentEntries = loadedData[17] as List<DbInvestmentEntry>;
    final sellEntries = loadedData[18] as List<DbSellEntry>;
    final normalizedExpensePayload = _buildNormalizedExpensePayloadMaps(
      entries: entries,
      splitRecords: splitRecords,
      splitParticipants: splitParticipants,
      lentSettlements: lentSettlements,
      borrowedSettlements: borrowedSettlements,
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
      'categories': includeExpenseInBundle
          ? categories
                .map(
                  (item) => <String, dynamic>{
                    'id': item.id,
                    'name': item.name,
                    'iconCodePoint': item.iconCodePoint,
                    'colorValue': item.colorValue,
                    'createdAt': item.createdAt.toIso8601String(),
                  },
                )
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
      'banks': includeExpenseInBundle
          ? banks
                .map(
                  (item) => <String, dynamic>{
                    'id': item.id,
                    'name': item.name,
                    'createdAt': item.createdAt.toIso8601String(),
                  },
                )
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
      'entries': includeExpenseInBundle ? normalizedExpensePayload.entries : const <Map<String, dynamic>>[],
      'splitRecords': includeExpenseInBundle ? normalizedExpensePayload.splitRecords : const <Map<String, dynamic>>[],
      'splitParticipants': includeExpenseInBundle ? normalizedExpensePayload.splitParticipants : const <Map<String, dynamic>>[],
      'lentSettlements': includeExpenseInBundle ? normalizedExpensePayload.lentSettlements : const <Map<String, dynamic>>[],
      'borrowedSettlements': includeExpenseInBundle ? normalizedExpensePayload.borrowedSettlements : const <Map<String, dynamic>>[],
    };
    final taskHashSource = <String, dynamic>{
      'categories': includeTasksInBundle ? taskCategories : const <String>[],
      'tasks': includeTasksInBundle
          ? tasks
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
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
    };
    final settingsHashSource = <String, dynamic>{
      'appSettings': includeSettingsInBundle ? appSettings : const <String, dynamic>{},
      'reminderSettings': includeSettingsInBundle ? reminderSettings : const <String, dynamic>{},
    };
    final investmentHashSource = <String, dynamic>{
      'categories': includeInvestmentInBundle
          ? investmentCategories
                .map(
                  (item) => <String, dynamic>{
                    'id': item.id,
                    'name': item.name,
                    'iconCodePoint': item.iconCodePoint,
                    'colorValue': item.colorValue,
                    'createdAt': item.createdAt.toIso8601String(),
                    'updatedAt': item.updatedAt.toIso8601String(),
                  },
                )
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
      'taxProfiles': includeInvestmentInBundle
          ? investmentTaxProfiles
                .map(
                  (item) => <String, dynamic>{
                    'id': item.id,
                    'brokerName': item.brokerName,
                    'sttBuyPct': item.sttBuyPct,
                    'sttSellPct': item.sttSellPct,
                    'exchangeChargePct': item.exchangeChargePct,
                    'sebiChargePct': item.sebiChargePct,
                    'stampDutyPct': item.stampDutyPct,
                    'gstPct': item.gstPct,
                    'brokeragePct': item.brokeragePct,
                    'brokerageFlat': item.brokerageFlat,
                    'brokerageMinOfBoth': item.brokerageMinOfBoth,
                    'dpChargePerScrip': item.dpChargePerScrip,
                    'createdAt': item.createdAt.toIso8601String(),
                    'updatedAt': item.updatedAt.toIso8601String(),
                  },
                )
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
      'entries': includeInvestmentInBundle
          ? investmentEntries
                .map(
                  (item) => <String, dynamic>{
                    'id': item.id,
                    'categoryId': item.categoryId,
                    'symbol': item.symbol,
                    'qty': item.qty,
                    'buyDate': item.buyDate.toIso8601String(),
                    'buyRate': item.buyRate,
                    'buyAmt': item.buyAmt,
                    'taxProfileId': item.taxProfileId,
                    'notes': item.notes,
                    'createdAt': item.createdAt.toIso8601String(),
                    'updatedAt': item.updatedAt.toIso8601String(),
                  },
                )
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
      'sellEntries': includeInvestmentInBundle
          ? sellEntries
                .map(
                  (item) => <String, dynamic>{
                    'id': item.id,
                    'buyEntryId': item.buyEntryId,
                    'symbol': item.symbol,
                    'sellQty': item.sellQty,
                    'sellDate': item.sellDate.toIso8601String(),
                    'sellRate': item.sellRate,
                    'sellAmt': item.sellAmt,
                    'createdAt': item.createdAt.toIso8601String(),
                  },
                )
                .toList(growable: false)
          : const <Map<String, dynamic>>[],
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
      CloudSyncDomain.investment.folderName: await _hashJsonContent(
        investmentHashSource,
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
      'borrowedSettlements': normalizedExpensePayload.borrowedSettlements,
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
      'appSettings': includeSettingsInBundle ? appSettings : const <String, dynamic>{},
      'reminderSettings': includeSettingsInBundle ? reminderSettings : const <String, dynamic>{},
    });
    final investmentJson = jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'exportedAt': timestamp.toIso8601String(),
      ...investmentHashSource,
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
    final protectedInvestmentPayload = encryptNonCredentialPayloadsForCloud
        ? await _encryptCloudPayload(
            payload: investmentJson,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.investment.folderName,
          )
        : investmentJson;
    final localLatestAt = _computeLocalLatestChangeAtFromData(
      categories: categories,
      banks: banks,
      entries: entries,
      splitRecords: splitRecords,
      splitParticipants: splitParticipants,
      lentSettlements: lentSettlements,
      borrowedSettlements: borrowedSettlements,
      tasks: tasks,
      credentials: credentials,
      taskCategoryUpdatedAt: taskCategoryUpdatedAt,
      appSettingsUpdatedAt: appSettingsUpdatedAt,
      reminderSettingsUpdatedAt: reminderSettingsUpdatedAt,
      investmentCategories: investmentCategories,
      investmentTaxProfiles: investmentTaxProfiles,
      investmentEntries: investmentEntries,
      sellEntries: sellEntries,
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
          CloudSyncDomain.expense.folderName: includeExpenseInBundle
              ? (normalizedExpensePayload.entries.length +
                 normalizedExpensePayload.splitRecords.length +
                 normalizedExpensePayload.splitParticipants.length +
                 normalizedExpensePayload.lentSettlements.length +
                 normalizedExpensePayload.borrowedSettlements.length)
              : 0,
          CloudSyncDomain.task.folderName: includeTasksInBundle ? tasks.length : 0,
          CloudSyncDomain.settings.folderName: includeSettingsInBundle ? 2 : 0,
          CloudSyncDomain.investment.folderName: includeInvestmentInBundle
              ? (investmentCategories.length +
                 investmentTaxProfiles.length +
                 investmentEntries.length +
                 sellEntries.length)
              : 0,
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
      containsSettingsPayload: includeSettingsInBundle,
      investmentPayload: protectedInvestmentPayload,
      containsInvestmentPayload: includeInvestmentInBundle,
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
      (_database.select(_database.dbBorrowedSettlements)).get(),
      (_database.select(_database.dbTasks)).get(),
      (_database.select(_database.dbCredentials)).get(),
      _taskCategoryRepository.lastModifiedAt(),
      _appSettingsRepository.lastModifiedAt(),
      _reminderSettingsRepository.lastModifiedAt(),
      (_database.select(_database.dbInvestmentCategories)).get(),
      (_database.select(_database.dbInvestmentTaxProfiles)).get(),
      (_database.select(_database.dbInvestmentEntries)).get(),
      (_database.select(_database.dbSellEntries)).get(),
    ]);
    cancellationToken?.throwIfCancelled();

    return _computeLocalLatestChangeAtFromData(
      categories: loadedData[0] as List<DbCategory>,
      banks: loadedData[1] as List<DbBank>,
      entries: loadedData[2] as List<DbFinanceEntry>,
      splitRecords: loadedData[3] as List<DbSplitRecord>,
      splitParticipants: loadedData[4] as List<DbSplitParticipant>,
      lentSettlements: loadedData[5] as List<DbLentSettlement>,
      borrowedSettlements: loadedData[6] as List<DbBorrowedSettlement>,
      tasks: loadedData[7] as List<DbTask>,
      credentials: loadedData[8] as List<DbCredential>,
      taskCategoryUpdatedAt: loadedData[9] as DateTime?,
      appSettingsUpdatedAt: loadedData[10] as DateTime?,
      reminderSettingsUpdatedAt: loadedData[11] as DateTime?,
      investmentCategories: loadedData[12] as List<DbInvestmentCategory>,
      investmentTaxProfiles: loadedData[13] as List<DbInvestmentTaxProfile>,
      investmentEntries: loadedData[14] as List<DbInvestmentEntry>,
      sellEntries: loadedData[15] as List<DbSellEntry>,
    );
  }

  DateTime _computeLocalLatestChangeAtFromData({
    required List<DbCategory> categories,
    required List<DbBank> banks,
    required List<DbFinanceEntry> entries,
    required List<DbSplitRecord> splitRecords,
    required List<DbSplitParticipant> splitParticipants,
    required List<DbLentSettlement> lentSettlements,
    required List<DbBorrowedSettlement> borrowedSettlements,
    required List<DbTask> tasks,
    required List<DbCredential> credentials,
    required DateTime? taskCategoryUpdatedAt,
    required DateTime? appSettingsUpdatedAt,
    required DateTime? reminderSettingsUpdatedAt,
    required List<DbInvestmentCategory> investmentCategories,
    required List<DbInvestmentTaxProfile> investmentTaxProfiles,
    required List<DbInvestmentEntry> investmentEntries,
    required List<DbSellEntry> sellEntries,
  }) {
    final candidates = <DateTime>[
      ...categories.map((item) => item.createdAt),
      ...banks.map((item) => item.createdAt),
      ...entries.map((item) => item.createdAt),
      ...entries.map((item) => item.entryDate),
      ...splitRecords.map((item) => item.createdAt),
      ...splitParticipants.map((item) => item.createdAt),
      ...lentSettlements.map((item) => item.createdAt),
      ...borrowedSettlements.map((item) => item.createdAt),
      ...tasks.map((item) => item.createdAt),
      ...tasks.map((item) => item.taskDate),
      ...credentials.map((item) => item.updatedAt),
      ...credentials.map((item) => item.createdAt),
      ...investmentCategories.map((item) => item.createdAt),
      ...investmentTaxProfiles.map((item) => item.createdAt),
      ...investmentTaxProfiles.map((item) => item.updatedAt),
      ...investmentEntries.map((item) => item.createdAt),
      ...investmentEntries.map((item) => item.buyDate),
      ...sellEntries.map((item) => item.createdAt),
      ...sellEntries.map((item) => item.sellDate),
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
    required String investmentPayload,
    String? credentialEncryptionKey,
    String? nonCredentialEncryptionKey,
    bool restoreCredentials = true,
    bool restoreSettings = true,
    bool restoreInvestment = true,
    bool restoreExpense = true,
    bool restoreTasks = true,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final decodedExpensePayload = restoreExpense
        ? await _decryptCloudPayloadIfNeeded(
            payload: expensePayload,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.expense.folderName,
          )
        : '{}';
    final decodedTaskPayload = restoreTasks
        ? await _decryptCloudPayloadIfNeeded(
            payload: taskPayload,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.task.folderName,
          )
        : '{}';
    final decodedSettingsPayload = restoreSettings
        ? await _decryptCloudPayloadIfNeeded(
            payload: settingsPayload,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.settings.folderName,
          )
        : '{}';
    final decodedInvestmentPayload = restoreInvestment
        ? await _decryptCloudPayloadIfNeeded(
            payload: investmentPayload,
            encryptionKey: nonCredentialEncryptionKey,
            domainLabel: CloudSyncDomain.investment.folderName,
          )
        : '{}';
    final expense = restoreExpense
        ? jsonDecode(decodedExpensePayload) as Map<String, dynamic>
        : const <String, dynamic>{};
    final task = restoreTasks
        ? jsonDecode(decodedTaskPayload) as Map<String, dynamic>
        : const <String, dynamic>{};
    final settings = restoreSettings
        ? jsonDecode(decodedSettingsPayload) as Map<String, dynamic>
        : const <String, dynamic>{};
    final credential = restoreCredentials
        ? jsonDecode(credentialPayload) as Map<String, dynamic>
        : const <String, dynamic>{};
    final investment = restoreInvestment
        ? jsonDecode(decodedInvestmentPayload) as Map<String, dynamic>
        : const <String, dynamic>{};
    final normalizedExpensePayload = _normalizeExpenseRestorePayload(expense);
    final categories = restoreExpense
        ? (expense['categories'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final banks = restoreExpense
        ? (expense['banks'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final entries = restoreExpense ? normalizedExpensePayload.entries : const <Map<String, dynamic>>[];
    final splitRecords = restoreExpense ? normalizedExpensePayload.splitRecords : const <Map<String, dynamic>>[];
    final splitParticipants = restoreExpense ? normalizedExpensePayload.splitParticipants : const <Map<String, dynamic>>[];
    final lentSettlements = restoreExpense ? normalizedExpensePayload.lentSettlements : const <Map<String, dynamic>>[];
    final borrowedSettlements = restoreExpense ? normalizedExpensePayload.borrowedSettlements : const <Map<String, dynamic>>[];
    final taskCategories = restoreTasks
        ? (task['categories'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false)
        : const <String>[];
    final tasks = restoreTasks
        ? (task['tasks'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final investmentCategories = restoreInvestment
        ? (investment['categories'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final investmentTaxProfiles = restoreInvestment
        ? (investment['taxProfiles'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final investmentEntries = restoreInvestment
        ? (investment['entries'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final sellEntries = restoreInvestment
        ? (investment['sellEntries'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
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
      await _database.delete(_database.dbBorrowedSettlements).go();
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
      if (restoreInvestment) {
        await _database.delete(_database.dbSellEntries).go();
        await _database.delete(_database.dbInvestmentEntries).go();
        await _database.delete(_database.dbInvestmentTaxProfiles).go();
        await _database.delete(_database.dbInvestmentCategories).go();
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
                    entryDay: Value(
                      (item['entryDay'] is String &&
                              (item['entryDay'] as String).trim().isNotEmpty)
                          ? item['entryDay'] as String
                          : _dayLabelForDate(
                              DateTime.tryParse(
                                    item['entryDate'] as String? ?? '',
                                  ) ??
                                  DateTime.now(),
                            ),
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

      if (borrowedSettlements.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbBorrowedSettlements,
            borrowedSettlements
                .map((item) {
                  return DbBorrowedSettlementsCompanion(
                    id: Value(item['id'] as int),
                    borrowedEntryId: Value(
                      item['borrowedEntryId'] as int? ?? 0,
                    ),
                    expenseEntryId: Value(item['expenseEntryId'] as int? ?? 0),
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

      if (restoreInvestment && investmentCategories.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbInvestmentCategories,
            investmentCategories
                .map((item) {
                  return DbInvestmentCategoriesCompanion(
                    id: Value(item['id'] as int),
                    name: Value(item['name'] as String? ?? ''),
                    iconCodePoint: Value(item['iconCodePoint'] as int? ?? 0),
                    colorValue: Value(item['colorValue'] as int? ?? 0),
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

      if (restoreInvestment && investmentTaxProfiles.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbInvestmentTaxProfiles,
            investmentTaxProfiles
                .map((item) {
                  return DbInvestmentTaxProfilesCompanion(
                    id: Value(item['id'] as int),
                    brokerName: Value(item['brokerName'] as String? ?? ''),
                    sttBuyPct: Value((item['sttBuyPct'] as num?)?.toDouble() ?? 0.0),
                    sttSellPct: Value((item['sttSellPct'] as num?)?.toDouble() ?? 0.0),
                    exchangeChargePct: Value((item['exchangeChargePct'] as num?)?.toDouble() ?? 0.0),
                    sebiChargePct: Value((item['sebiChargePct'] as num?)?.toDouble() ?? 0.0),
                    stampDutyPct: Value((item['stampDutyPct'] as num?)?.toDouble() ?? 0.0),
                    gstPct: Value((item['gstPct'] as num?)?.toDouble() ?? 0.0),
                    brokeragePct: Value((item['brokeragePct'] as num?)?.toDouble() ?? 0.0),
                    brokerageFlat: Value((item['brokerageFlat'] as num?)?.toDouble() ?? 0.0),
                    brokerageMinOfBoth: Value(item['brokerageMinOfBoth'] as bool? ?? false),
                    dpChargePerScrip: Value((item['dpChargePerScrip'] as num?)?.toDouble() ?? 0.0),
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

      if (restoreInvestment && investmentEntries.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbInvestmentEntries,
            investmentEntries
                .map((item) {
                  return DbInvestmentEntriesCompanion(
                    id: Value(item['id'] as int),
                    categoryId: Value(item['categoryId'] as int? ?? 0),
                    symbol: Value(item['symbol'] as String? ?? ''),
                    qty: Value((item['qty'] as num?)?.toDouble() ?? 0.0),
                    buyDate: Value(
                      DateTime.tryParse(item['buyDate'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                    buyRate: Value((item['buyRate'] as num?)?.toDouble() ?? 0.0),
                    buyAmt: Value((item['buyAmt'] as num?)?.toDouble() ?? 0.0),
                    taxProfileId: Value(item['taxProfileId'] as int?),
                    notes: Value(item['notes'] as String?),
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

      if (restoreInvestment && sellEntries.isNotEmpty) {
        cancellationToken?.throwIfCancelled();
        await _database.batch((batch) {
          batch.insertAll(
            _database.dbSellEntries,
            sellEntries
                .map((item) {
                  return DbSellEntriesCompanion(
                    id: Value(item['id'] as int),
                    buyEntryId: Value(item['buyEntryId'] as int? ?? 0),
                    symbol: Value(item['symbol'] as String? ?? ''),
                    sellQty: Value((item['sellQty'] as num?)?.toDouble() ?? 0.0),
                    sellDate: Value(
                      DateTime.tryParse(item['sellDate'] as String? ?? '') ??
                          DateTime.now(),
                    ),
                    sellRate: Value((item['sellRate'] as num?)?.toDouble() ?? 0.0),
                    sellAmt: Value((item['sellAmt'] as num?)?.toDouble() ?? 0.0),
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
    final algorithm =
        decoded['algorithm'] as String? ??
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

  String _dayLabelForDate(DateTime date) {
    return DateFormat('EEEE').format(date);
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
    required List<DbBorrowedSettlement> borrowedSettlements,
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
              'entryDay': item.entryDay.isEmpty
                  ? _dayLabelForDate(item.entryDate)
                  : item.entryDay,
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
      borrowedSettlements: borrowedSettlements
          .map(
            (item) => <String, dynamic>{
              'id': item.id,
              'borrowedEntryId': item.borrowedEntryId,
              'expenseEntryId': item.expenseEntryId,
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
    final rawBorrowedSettlements =
        (expense['borrowedSettlements'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);

    Map<String, dynamic> normalizeEntry(Map<String, dynamic> item) {
      final normalized = Map<String, dynamic>.from(item);
      final parsedDate =
          DateTime.tryParse(normalized['entryDate'] as String? ?? '') ??
          DateTime.now();
      final entryDay = normalized['entryDay'] is String
          ? normalized['entryDay'] as String
          : null;
      normalized['entryDay'] = entryDay != null && entryDay.trim().isNotEmpty
          ? entryDay
          : _dayLabelForDate(parsedDate);
      return normalized;
    }

    if (rawSplitRecords.isEmpty) {
      return _NormalizedExpenseSyncPayload(
        entries: rawEntries.map(normalizeEntry).toList(growable: false),
        splitRecords: const <Map<String, dynamic>>[],
        splitParticipants: rawSplitParticipants
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
        lentSettlements: rawLentSettlements
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
        borrowedSettlements: rawBorrowedSettlements
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
          .map(normalizeEntry)
          .map((normalized) {
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
      borrowedSettlements: rawBorrowedSettlements
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
    required this.borrowedSettlements,
  });

  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> splitRecords;
  final List<Map<String, dynamic>> splitParticipants;
  final List<Map<String, dynamic>> lentSettlements;
  final List<Map<String, dynamic>> borrowedSettlements;
}
