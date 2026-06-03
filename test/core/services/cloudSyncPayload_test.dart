// ignore_for_file: file_names

import 'dart:io';

import 'package:finance_analytics_app/core/models/cloud_sync_models.dart';
import 'package:finance_analytics_app/core/services/app_settings_repository.dart';
import 'package:finance_analytics_app/data/database/app_database.dart';
import 'package:finance_analytics_app/features/credentials/data/repositories/credential_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/testHelpers.dart';

void main() {
  initializeProductionTestEnvironment();

  group('Cloud sync production scenarios', () {
    late Directory testRoot;
    late AppDatabase database;
    late AppSettingsRepository appSettingsRepository;

    setUp(() async {
      testRoot = await createTestRoot();
      installPathProviderMock(testRoot);
      database = createTestDatabase();
      appSettingsRepository = settingsRepository(testRoot);
    });

    tearDown(() async {
      clearPathProviderMock();
      await appSettingsRepository.dispose();
      await database.close();
      await deleteTestRoot(testRoot);
    });

    test('builds and restores a complete backup bundle', () async {
      await seedSyncData(database);
      final sourcePayloadService = cloudPayloadService(
        database,
        appSettingsRepository,
      );

      final bundle = await sourcePayloadService.buildBackupBundle(
        exportedAt: DateTime(2026, 5, 23, 10),
        accountEmail: 'user@example.com',
        credentialEncryptionKey: testCredentialKey,
        nonCredentialEncryptionKey: testCloudKey,
        encryptNonCredentialPayloadsForCloud: false,
      );

      expect(
        bundle.manifest.domainCounts[CloudSyncDomain.credential.folderName],
        1,
      );
      expect(
        bundle.manifest.domainCounts[CloudSyncDomain.expense.folderName],
        1,
      );
      expect(bundle.manifest.domainCounts[CloudSyncDomain.task.folderName], 1);

      final restoredDatabase = createTestDatabase();
      final restoredSettingsRepository = settingsRepository(
        Directory('${testRoot.path}${Platform.pathSeparator}restore'),
      );
      addTearDown(() async {
        await restoredSettingsRepository.dispose();
        await restoredDatabase.close();
      });

      await cloudPayloadService(
        restoredDatabase,
        restoredSettingsRepository,
      ).restoreBundle(
        credentialPayload: bundle.credentialPayload,
        expensePayload: bundle.expensePayload,
        taskPayload: bundle.taskPayload,
        settingsPayload: bundle.settingsPayload,
        investmentPayload: bundle.investmentPayload,
        credentialEncryptionKey: testCredentialKey,
        restoreSettings: false,
      );

      expect(await restoredDatabase.countEntries(), 1);
      expect(
        await (restoredDatabase.select(restoredDatabase.dbTasks)).get(),
        hasLength(1),
      );
      final restoredCredential = await CredentialRepository(
        restoredDatabase,
      ).loadCredential(1);
      expect(restoredCredential?.title, 'Sync Credential');
    });

    test('requires a credential key before syncing encrypted titles', () async {
      await seedCredential(database);
      final payloadService = cloudPayloadService(
        database,
        appSettingsRepository,
      );

      await expectLater(
        payloadService.buildBackupBundle(
          nonCredentialEncryptionKey: testCloudKey,
        ),
        throwsA(isA<CloudCredentialEncryptionKeyRequiredException>()),
      );
    });
  });
}
