import 'dart:io';

import 'package:workmanager/workmanager.dart';

import '../models/app_preferences.dart';
import 'app_settings_repository.dart';

class AutoBackupSchedulerService {
  AutoBackupSchedulerService({
    required AppSettingsRepository appSettingsRepository,
    Workmanager? workmanager,
  }) : _appSettingsRepository = appSettingsRepository,
       _workmanager = workmanager ?? Workmanager();

  static const String uniqueName = 'daily_use_auto_cloud_backup';
  static const String taskName = 'daily_use.auto_cloud_backup';
  static const String tag = 'daily_use_auto_backup';

  final AppSettingsRepository _appSettingsRepository;
  final Workmanager _workmanager;

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final settings = await _appSettingsRepository.getSettings();
    final nextCloudSync = settings.cloudSync.copyWith(autoBackupEnabled: false);
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);
    await cancelScheduledBackup();
  }

  Future<void> updateAutoBackupTime(AppBackupTime time) async {
    final settings = await _appSettingsRepository.getSettings();
    final nextCloudSync = settings.cloudSync.copyWith(autoBackupTime: time);
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);
    await cancelScheduledBackup();
  }

  Future<void> reconcileScheduledBackup() async {
    try {
      await cancelScheduledBackup();
    } catch (_) {
      // Startup reconciliation should never make app launch fail.
    }
  }

  Future<void> cancelScheduledBackup() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _workmanager.cancelByUniqueName(uniqueName);
    await _workmanager.cancelByTag(tag);
  }
}
