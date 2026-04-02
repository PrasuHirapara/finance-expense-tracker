import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/database/app_database.dart';
import '../../features/tasks/data/repositories/task_category_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import 'app_settings_repository.dart';
import 'cloud_sync_payload_service.dart';
import 'cloud_sync_scheduler.dart';
import 'cloud_sync_service.dart';
import 'credential_crypto_service.dart';
import 'credential_security_service.dart';
import 'firebase_cloud_sync_auth_service.dart';
import 'firestore_cloud_sync_store_service.dart';

@pragma('vm:entry-point')
void cloudSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != CloudSyncScheduler.autoBackupTaskName &&
        task != Workmanager.iOSBackgroundTask) {
      return Future<bool>.value(true);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      await Firebase.initializeApp();
    }

    final database = AppDatabase();
    final appSettingsRepository = AppSettingsRepository();
    final taskRepository = TaskRepository(database);
    final taskCategoryRepository = TaskCategoryRepository(taskRepository);
    final cloudSyncService = CloudSyncService(
      appSettingsRepository: appSettingsRepository,
      authService: FirebaseCloudSyncAuthService(),
      remoteStoreService: FirestoreCloudSyncStoreService(),
      payloadService: CloudSyncPayloadService(
        database: database,
        taskCategoryRepository: taskCategoryRepository,
        credentialCryptoService: CredentialCryptoService(),
      ),
      credentialSecurityService: CredentialSecurityService(),
      scheduler: CloudSyncScheduler(),
    );

    try {
      await cloudSyncService.runAutomaticBackupIfDue();
      return true;
    } catch (_) {
      return false;
    } finally {
      await database.close();
      await appSettingsRepository.flush();
      unawaited(appSettingsRepository.dispose());
    }
  });
}
