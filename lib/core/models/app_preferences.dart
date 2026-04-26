import 'package:flutter/material.dart';

enum AppModule { credential, expense, tasks, settings }

class CloudSyncPreferences {
  const CloudSyncPreferences({
    this.enabled = false,
    this.syncCredentials = true,
    this.lastSuccessfulSyncAt,
    this.lastRestoreAt,
    this.lastSyncedAccountEmail,
    this.lastKnownCloudBackupAt,
  });

  final bool enabled;
  final bool syncCredentials;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastRestoreAt;
  final String? lastSyncedAccountEmail;
  final DateTime? lastKnownCloudBackupAt;

  CloudSyncPreferences copyWith({
    bool? enabled,
    bool? syncCredentials,
    Object? lastSuccessfulSyncAt = _appPreferenceUnset,
    Object? lastRestoreAt = _appPreferenceUnset,
    Object? lastSyncedAccountEmail = _appPreferenceUnset,
    Object? lastKnownCloudBackupAt = _appPreferenceUnset,
  }) {
    return CloudSyncPreferences(
      enabled: enabled ?? this.enabled,
      syncCredentials: syncCredentials ?? this.syncCredentials,
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
