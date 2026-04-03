import 'package:flutter/material.dart';

enum AppModule { credential, expense, tasks, settings }

class CloudSyncPreferences {
  const CloudSyncPreferences({
    this.enabled = false,
    this.syncCredentials = true,
    this.autoBackupEnabled = false,
    this.autoBackupHour = 6,
    this.autoBackupMinute = 0,
    this.lastSuccessfulSyncAt,
    this.lastAutoBackupAt,
    this.lastRestoreAt,
    this.lastSyncedAccountEmail,
    this.lastKnownCloudBackupAt,
  });

  final bool enabled;
  final bool syncCredentials;
  final bool autoBackupEnabled;
  final int autoBackupHour;
  final int autoBackupMinute;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastAutoBackupAt;
  final DateTime? lastRestoreAt;
  final String? lastSyncedAccountEmail;
  final DateTime? lastKnownCloudBackupAt;

  CloudSyncPreferences copyWith({
    bool? enabled,
    bool? syncCredentials,
    bool? autoBackupEnabled,
    int? autoBackupHour,
    int? autoBackupMinute,
    Object? lastSuccessfulSyncAt = _appPreferenceUnset,
    Object? lastAutoBackupAt = _appPreferenceUnset,
    Object? lastRestoreAt = _appPreferenceUnset,
    Object? lastSyncedAccountEmail = _appPreferenceUnset,
    Object? lastKnownCloudBackupAt = _appPreferenceUnset,
  }) {
    return CloudSyncPreferences(
      enabled: enabled ?? this.enabled,
      syncCredentials: syncCredentials ?? this.syncCredentials,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupHour: autoBackupHour ?? this.autoBackupHour,
      autoBackupMinute: autoBackupMinute ?? this.autoBackupMinute,
      lastSuccessfulSyncAt: identical(lastSuccessfulSyncAt, _appPreferenceUnset)
          ? this.lastSuccessfulSyncAt
          : lastSuccessfulSyncAt as DateTime?,
      lastAutoBackupAt: identical(lastAutoBackupAt, _appPreferenceUnset)
          ? this.lastAutoBackupAt
          : lastAutoBackupAt as DateTime?,
      lastRestoreAt: identical(lastRestoreAt, _appPreferenceUnset)
          ? this.lastRestoreAt
          : lastRestoreAt as DateTime?,
      lastSyncedAccountEmail:
          identical(lastSyncedAccountEmail, _appPreferenceUnset)
          ? this.lastSyncedAccountEmail
          : lastSyncedAccountEmail as String?,
      lastKnownCloudBackupAt:
          identical(lastKnownCloudBackupAt, _appPreferenceUnset)
          ? this.lastKnownCloudBackupAt
          : lastKnownCloudBackupAt as DateTime?,
    );
  }
}

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.dark,
    this.notificationsEnabled = true,
    this.exportDirectoryPath,
    this.cloudSync = const CloudSyncPreferences(),
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String? exportDirectoryPath;
  final CloudSyncPreferences cloudSync;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    Object? exportDirectoryPath = _appPreferenceUnset,
    CloudSyncPreferences? cloudSync,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      exportDirectoryPath: identical(exportDirectoryPath, _appPreferenceUnset)
          ? this.exportDirectoryPath
          : exportDirectoryPath as String?,
      cloudSync: cloudSync ?? this.cloudSync,
    );
  }
}

const Object _appPreferenceUnset = Object();
