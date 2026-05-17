import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../bootstrap/app_session.dart';
import '../models/cloud_sync_models.dart';
import 'auto_backup_scheduler_service.dart';
import 'cloud_sync_service.dart';
import 'firebase_runtime_service.dart';

Future<void> initializeAutoBackupWorkManager() async {
  if (!Platform.isAndroid) {
    return;
  }

  try {
    await Workmanager().initialize(autoBackupCallbackDispatcher);
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('WorkManager initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

@pragma('vm:entry-point')
void autoBackupCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != AutoBackupSchedulerService.taskName) {
      return true;
    }

    AppSession? session;
    try {
      DartPluginRegistrant.ensureInitialized();
      await initializeFirebaseIfSupported();

      session = AppSession.create();
      await session.cloudBackupService.runBackup(interactive: false);
      return true;
    } on CloudCredentialEncryptionKeyRequiredException catch (error) {
      _logPermanentAutoBackupFailure(error);
      return true;
    } on CloudCredentialEncryptionKeyInvalidException catch (error) {
      _logPermanentAutoBackupFailure(error);
      return true;
    } on CloudSyncDisabledException catch (error) {
      _logPermanentAutoBackupFailure(error);
      return true;
    } on StateError catch (error) {
      _logPermanentAutoBackupFailure(error);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Auto backup failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return false;
    } finally {
      await session?.dispose();
    }
  });
}

void _logPermanentAutoBackupFailure(Object error) {
  if (kDebugMode) {
    debugPrint('Auto backup skipped: $error');
  }
}
