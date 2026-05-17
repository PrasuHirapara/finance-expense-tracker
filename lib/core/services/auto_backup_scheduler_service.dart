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
    final nextCloudSync = settings.cloudSync.copyWith(
      autoBackupEnabled: enabled,
    );
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);

    if (enabled && nextCloudSync.enabled) {
      await _register(nextCloudSync.autoBackupTime);
    } else {
      await cancelScheduledBackup();
    }
  }

  Future<void> updateAutoBackupTime(AppBackupTime time) async {
    final settings = await _appSettingsRepository.getSettings();
    final nextCloudSync = settings.cloudSync.copyWith(autoBackupTime: time);
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);

    if (nextCloudSync.autoBackupEnabled && nextCloudSync.enabled) {
      await _register(time);
    }
  }

  Future<void> reconcileScheduledBackup() async {
    try {
      final settings = await _appSettingsRepository.getSettings();
      final cloudSync = settings.cloudSync;
      if (cloudSync.enabled && cloudSync.autoBackupEnabled) {
        await _register(cloudSync.autoBackupTime);
        return;
      }

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

  Future<void> _register(AppBackupTime time) async {
    if (!Platform.isAndroid) {
      return;
    }

    await cancelScheduledBackup();
    await _workmanager.registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: const Duration(days: 1),
      initialDelay: _initialDelayFor(time),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(networkType: NetworkType.connected),
      inputData: <String, dynamic>{'hour': time.hour, 'minute': time.minute},
      tag: tag,
    );
  }

  Duration _initialDelayFor(AppBackupTime time) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled.difference(now);
  }
}
