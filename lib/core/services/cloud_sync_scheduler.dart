import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

class CloudSyncScheduler {
  static const String autoBackupUniqueName = 'daily_use.auto_backup.periodic';
  static const String autoBackupTaskName = 'daily_use_auto_backup';

  Future<void> schedule(TimeOfDay time) async {
    await Workmanager().cancelByUniqueName(autoBackupUniqueName);
    await Workmanager().registerPeriodicTask(
      autoBackupUniqueName,
      autoBackupTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: _initialDelay(time),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
    );
  }

  Future<void> cancel() {
    return Workmanager().cancelByUniqueName(autoBackupUniqueName);
  }

  Duration _initialDelay(TimeOfDay time) {
    final now = DateTime.now();
    var nextRun = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!nextRun.isAfter(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }
    return nextRun.difference(now);
  }
}
