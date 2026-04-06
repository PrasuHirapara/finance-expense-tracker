import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/database/app_database.dart';
import '../../features/credentials/data/repositories/credential_repository.dart';
import '../../features/tasks/data/repositories/task_category_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import 'app_settings_repository.dart';
import 'cloud_backup_crypto_service.dart';
import 'cloud_sync_payload_service.dart';
import 'cloud_sync_scheduler.dart';
import 'cloud_sync_security_service.dart';
import 'cloud_sync_service.dart';
import 'credential_crypto_service.dart';
import 'credential_security_service.dart';
import 'firebase_runtime_service.dart';
import 'firebase_cloud_sync_auth_service.dart';
import 'firestore_cloud_sync_store_service.dart';
import 'notification_service.dart';
import 'reminder_settings_repository.dart';

@pragma('vm:entry-point')
void cloudSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    ui.DartPluginRegistrant.ensureInitialized();

    if (task != CloudSyncScheduler.autoBackupTaskName &&
        task != Workmanager.iOSBackgroundTask) {
      return Future<bool>.value(true);
    }
    await initializeFirebaseIfSupported();

    final database = AppDatabase();
    final appSettingsRepository = AppSettingsRepository();
    final reminderSettingsRepository = ReminderSettingsRepository();
    final credentialRepository = CredentialRepository(database);
    final credentialCryptoService = CredentialCryptoService();
    final credentialSecurityService = CredentialSecurityService();
    final taskRepository = TaskRepository(database);
    final taskCategoryRepository = TaskCategoryRepository(taskRepository);
    final cloudBackupCryptoService = CloudBackupCryptoService();
    final cloudSyncSecurityService = CloudSyncSecurityService();
    final notificationService = NotificationService(
      reminderSettingsRepository: reminderSettingsRepository,
      appSettingsRepository: appSettingsRepository,
      credentialRepository: credentialRepository,
      credentialCryptoService: credentialCryptoService,
      credentialSecurityService: credentialSecurityService,
    );
    final cloudSyncService = CloudSyncService(
      appSettingsRepository: appSettingsRepository,
      authService: FirebaseCloudSyncAuthService(),
      remoteStoreService: FirestoreCloudSyncStoreService(),
      payloadService: CloudSyncPayloadService(
        database: database,
        taskRepository: taskRepository,
        taskCategoryRepository: taskCategoryRepository,
        appSettingsRepository: appSettingsRepository,
        reminderSettingsRepository: reminderSettingsRepository,
        credentialCryptoService: credentialCryptoService,
        cloudBackupCryptoService: cloudBackupCryptoService,
      ),
      cloudSyncSecurityService: cloudSyncSecurityService,
      credentialSecurityService: credentialSecurityService,
      scheduler: CloudSyncScheduler(),
      notificationService: notificationService,
    );

    try {
      await cloudSyncService.runAutomaticBackupIfDue();
      return true;
    } catch (_) {
      return false;
    } finally {
      await database.close();
      await appSettingsRepository.flush();
      reminderSettingsRepository.dispose();
      unawaited(appSettingsRepository.dispose());
    }
  });
}
