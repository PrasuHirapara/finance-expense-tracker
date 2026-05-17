import 'package:flutter/material.dart';

enum AppModule { credential, expense, tasks, settings }

class AppBackupTime {
  const AppBackupTime({required this.hour, required this.minute});

  static const AppBackupTime defaultAutoBackup = AppBackupTime(
    hour: 7,
    minute: 0,
  );

  final int hour;
  final int minute;

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hour': hour,
    'minute': minute,
  };

  static AppBackupTime fromTimeOfDay(TimeOfDay time) {
    return AppBackupTime(hour: time.hour, minute: time.minute);
  }

  static AppBackupTime fromJson(
    Object? json, {
    required AppBackupTime fallback,
  }) {
    if (json is! Map) {
      return fallback;
    }

    final hour = json['hour'];
    final minute = json['minute'];
    if (hour is! int || minute is! int) {
      return fallback;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return fallback;
    }

    return AppBackupTime(hour: hour, minute: minute);
  }
}

class CloudSyncPreferences {
  const CloudSyncPreferences({
    this.enabled = false,
    this.syncCredentials = true,
    this.autoBackupEnabled = false,
    this.autoBackupTime = AppBackupTime.defaultAutoBackup,
    this.lastSuccessfulSyncAt,
    this.lastRestoreAt,
    this.lastSyncedAccountEmail,
    this.lastKnownCloudBackupAt,
  });

  final bool enabled;
  final bool syncCredentials;
  final bool autoBackupEnabled;
  final AppBackupTime autoBackupTime;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastRestoreAt;
  final String? lastSyncedAccountEmail;
  final DateTime? lastKnownCloudBackupAt;

  CloudSyncPreferences copyWith({
    bool? enabled,
    bool? syncCredentials,
    bool? autoBackupEnabled,
    AppBackupTime? autoBackupTime,
    Object? lastSuccessfulSyncAt = _appPreferenceUnset,
    Object? lastRestoreAt = _appPreferenceUnset,
    Object? lastSyncedAccountEmail = _appPreferenceUnset,
    Object? lastKnownCloudBackupAt = _appPreferenceUnset,
  }) {
    return CloudSyncPreferences(
      enabled: enabled ?? this.enabled,
      syncCredentials: syncCredentials ?? this.syncCredentials,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupTime: autoBackupTime ?? this.autoBackupTime,
      lastSuccessfulSyncAt: identical(lastSuccessfulSyncAt, _appPreferenceUnset)
          ? this.lastSuccessfulSyncAt
          : lastSuccessfulSyncAt as DateTime?,
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
    this.credentialExpiryNotificationEnabled = false,
    this.exportDirectoryPath,
    this.acceptedPrivacyPolicyVersion,
    this.selectedExpenseBankId,
    this.cloudSync = const CloudSyncPreferences(),
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool credentialExpiryNotificationEnabled;
  final String? exportDirectoryPath;
  final String? acceptedPrivacyPolicyVersion;
  final int? selectedExpenseBankId;
  final CloudSyncPreferences cloudSync;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? credentialExpiryNotificationEnabled,
    Object? exportDirectoryPath = _appPreferenceUnset,
    Object? acceptedPrivacyPolicyVersion = _appPreferenceUnset,
    Object? selectedExpenseBankId = _appPreferenceUnset,
    CloudSyncPreferences? cloudSync,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      credentialExpiryNotificationEnabled:
          credentialExpiryNotificationEnabled ??
          this.credentialExpiryNotificationEnabled,
      exportDirectoryPath: identical(exportDirectoryPath, _appPreferenceUnset)
          ? this.exportDirectoryPath
          : exportDirectoryPath as String?,
      acceptedPrivacyPolicyVersion:
          identical(acceptedPrivacyPolicyVersion, _appPreferenceUnset)
          ? this.acceptedPrivacyPolicyVersion
          : acceptedPrivacyPolicyVersion as String?,
      selectedExpenseBankId:
          identical(selectedExpenseBankId, _appPreferenceUnset)
          ? this.selectedExpenseBankId
          : selectedExpenseBankId as int?,
      cloudSync: cloudSync ?? this.cloudSync,
    );
  }
}

const Object _appPreferenceUnset = Object();
