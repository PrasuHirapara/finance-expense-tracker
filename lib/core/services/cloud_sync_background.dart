import 'dart:async';

import 'package:workmanager/workmanager.dart';

import '../../data/database/app_database.dart';
import '../../features/tasks/data/repositories/task_category_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import 'app_settings_repository.dart';
import 'cloud_sync_payload_service.dart';
import 'cloud_sync_scheduler.dart';
import 'cloud_sync_security_service.dart';
import 'cloud_sync_service.dart';
import 'credential_crypto_service.dart';
import 'google_drive_api_service.dart';
import 'google_drive_auth_service.dart';

@pragma('vm:entry-point')
void cloudSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != CloudSyncScheduler.autoBackupTaskName &&
        task != Workmanager.iOSBackgroundTask) {
      return Future<bool>.value(true);
    }

    final database = AppDatabase();
    final appSettingsRepository = AppSettingsRepository();
    final taskRepository = TaskRepository(database);
    final taskCategoryRepository = TaskCategoryRepository(taskRepository);
    final cloudSyncService = CloudSyncService(
      appSettingsRepository: appSettingsRepository,
      authService: GoogleDriveAuthService(),
      driveApiService: GoogleDriveApiService(),
      payloadService: CloudSyncPayloadService(
        database: database,
        taskCategoryRepository: taskCategoryRepository,
        credentialCryptoService: CredentialCryptoService(),
        cloudSyncSecurityService: CloudSyncSecurityService(),
      ),
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
