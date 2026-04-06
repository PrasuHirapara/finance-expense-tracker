import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/app_preferences.dart';

class AppSettingsRepository {
  AppPreferences? _cachedPreferences;
  Future<void> _pendingWrite = Future<void>.value();
  final StreamController<AppPreferences> _controller =
      StreamController<AppPreferences>.broadcast();

  Stream<AppPreferences> watchSettings() async* {
    yield await getSettings();
    yield* _controller.stream;
  }

  Future<AppPreferences> getSettings() async {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    final file = await _settingsFile();
    if (!await file.exists()) {
      _cachedPreferences = const AppPreferences();
      await _writeSettings(_cachedPreferences!);
      return _cachedPreferences!;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      _cachedPreferences = _fromJson(json);
    } on FormatException {
      _cachedPreferences = const AppPreferences();
      await _writeSettings(_cachedPreferences!);
    }

    return _cachedPreferences!;
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final settings = await getSettings();
    await _commit(settings.copyWith(themeMode: themeMode));
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final settings = await getSettings();
    await _commit(settings.copyWith(notificationsEnabled: enabled));
  }

  Future<void> updateCredentialExpiryNotificationEnabled(bool enabled) async {
    final settings = await getSettings();
    await _commit(
      settings.copyWith(credentialExpiryNotificationEnabled: enabled),
    );
  }

  Future<void> updateExportDirectoryPath(String? pathValue) async {
    final settings = await getSettings();
    await _commit(settings.copyWith(exportDirectoryPath: pathValue));
  }

  Future<void> updateCloudSyncPreferences(
    CloudSyncPreferences preferences,
  ) async {
    final settings = await getSettings();
    await _commit(settings.copyWith(cloudSync: preferences));
  }

  Future<void> acceptPrivacyPolicy(String version) async {
    final settings = await getSettings();
    await _commit(
      settings.copyWith(acceptedPrivacyPolicyVersion: version.trim()),
    );
  }

  Future<Map<String, dynamic>> exportForCloud() async {
    final settings = await getSettings();
    return _toCloudJson(settings);
  }

  Future<void> restoreFromCloud(Object? json) async {
    final current = await getSettings();
    final restored = _fromCloudJson(json, fallback: current);
    await _commit(restored);
  }

  Future<DateTime?> lastModifiedAt() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return null;
    }
    return file.lastModified();
  }

  Future<void> flush() => _pendingWrite;

  Future<void> dispose() async {
    await _controller.close();
  }

  Future<void> _commit(AppPreferences settings) async {
    _cachedPreferences = settings;
    _pendingWrite = _pendingWrite.then((_) => _writeSettings(settings));
    await _pendingWrite;
    _controller.add(settings);
  }

  Future<void> _writeSettings(AppPreferences settings) async {
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(_toJson(settings)));
  }

  Future<File> _settingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, 'app_settings.json'));
  }

  Map<String, dynamic> _toJson(AppPreferences settings) {
    return <String, dynamic>{
      'themeMode': settings.themeMode.name,
      'notificationsEnabled': settings.notificationsEnabled,
      'credentialExpiryNotificationEnabled':
          settings.credentialExpiryNotificationEnabled,
      'exportDirectoryPath': settings.exportDirectoryPath,
      'acceptedPrivacyPolicyVersion': settings.acceptedPrivacyPolicyVersion,
      'cloudSync': _cloudSyncToJson(settings.cloudSync),
    };
  }

  Map<String, dynamic> _toCloudJson(AppPreferences settings) {
    return <String, dynamic>{
      'themeMode': settings.themeMode.name,
      'notificationsEnabled': settings.notificationsEnabled,
      'credentialExpiryNotificationEnabled':
          settings.credentialExpiryNotificationEnabled,
      'exportDirectoryPath': settings.exportDirectoryPath,
      'acceptedPrivacyPolicyVersion': settings.acceptedPrivacyPolicyVersion,
      'cloudSync': _cloudSyncToCloudJson(settings.cloudSync),
    };
  }

  AppPreferences _fromJson(Object? json) {
    if (json is! Map) {
      return const AppPreferences();
    }

    return AppPreferences(
      themeMode: _themeModeFromString(json['themeMode']),
      notificationsEnabled: _notificationsEnabledFromJson(
        json['notificationsEnabled'],
      ),
      credentialExpiryNotificationEnabled:
          json['credentialExpiryNotificationEnabled'] is bool
          ? json['credentialExpiryNotificationEnabled'] as bool
          : false,
      exportDirectoryPath: _exportDirectoryPathFromJson(
        json['exportDirectoryPath'],
      ),
      acceptedPrivacyPolicyVersion: _stringFromJson(
        json['acceptedPrivacyPolicyVersion'],
      ),
      cloudSync: _cloudSyncFromJson(json['cloudSync']),
    );
  }

  AppPreferences _fromCloudJson(
    Object? json, {
    required AppPreferences fallback,
  }) {
    if (json is! Map) {
      return fallback;
    }

    final restoredCloudSync = _cloudSyncFromCloudJson(
      json['cloudSync'],
      fallback: fallback.cloudSync,
    );

    return AppPreferences(
      themeMode: _themeModeFromString(json['themeMode']),
      notificationsEnabled: _notificationsEnabledFromJson(
        json['notificationsEnabled'],
      ),
      credentialExpiryNotificationEnabled:
          json['credentialExpiryNotificationEnabled'] is bool
          ? json['credentialExpiryNotificationEnabled'] as bool
          : fallback.credentialExpiryNotificationEnabled,
      exportDirectoryPath: json.containsKey('exportDirectoryPath')
          ? _exportDirectoryPathFromJson(json['exportDirectoryPath'])
          : fallback.exportDirectoryPath,
      acceptedPrivacyPolicyVersion: json.containsKey(
            'acceptedPrivacyPolicyVersion',
          )
          ? _stringFromJson(json['acceptedPrivacyPolicyVersion'])
          : fallback.acceptedPrivacyPolicyVersion,
      cloudSync: fallback.cloudSync.copyWith(
        enabled: restoredCloudSync.enabled,
        syncCredentials: restoredCloudSync.syncCredentials,
        autoBackupEnabled: restoredCloudSync.autoBackupEnabled,
        autoBackupHour: restoredCloudSync.autoBackupHour,
        autoBackupMinute: restoredCloudSync.autoBackupMinute,
      ),
    );
  }

  ThemeMode _themeModeFromString(Object? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  bool _notificationsEnabledFromJson(Object? value) {
    return value is bool ? value : true;
  }

  String? _exportDirectoryPathFromJson(Object? value) {
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  String? _stringFromJson(Object? value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  Map<String, dynamic> _cloudSyncToJson(CloudSyncPreferences preferences) {
    return <String, dynamic>{
      'enabled': preferences.enabled,
      'syncCredentials': preferences.syncCredentials,
      'autoBackupEnabled': preferences.autoBackupEnabled,
      'autoBackupHour': preferences.autoBackupHour,
      'autoBackupMinute': preferences.autoBackupMinute,
      'lastSuccessfulSyncAt': preferences.lastSuccessfulSyncAt
          ?.toIso8601String(),
      'lastAutoBackupAt': preferences.lastAutoBackupAt?.toIso8601String(),
      'lastRestoreAt': preferences.lastRestoreAt?.toIso8601String(),
      'lastSyncedAccountEmail': preferences.lastSyncedAccountEmail,
      'lastKnownCloudBackupAt': preferences.lastKnownCloudBackupAt
          ?.toIso8601String(),
    };
  }

  Map<String, dynamic> _cloudSyncToCloudJson(CloudSyncPreferences preferences) {
    return <String, dynamic>{
      'enabled': preferences.enabled,
      'syncCredentials': preferences.syncCredentials,
      'autoBackupEnabled': preferences.autoBackupEnabled,
      'autoBackupHour': preferences.autoBackupHour,
      'autoBackupMinute': preferences.autoBackupMinute,
    };
  }

  CloudSyncPreferences _cloudSyncFromJson(Object? value) {
    if (value is! Map) {
      return const CloudSyncPreferences();
    }

    return CloudSyncPreferences(
      enabled: value['enabled'] is bool ? value['enabled'] as bool : false,
      syncCredentials: value['syncCredentials'] is bool
          ? value['syncCredentials'] as bool
          : true,
      autoBackupEnabled: value['autoBackupEnabled'] is bool
          ? value['autoBackupEnabled'] as bool
          : false,
      autoBackupHour: _intFromJson(value['autoBackupHour'], fallback: 6),
      autoBackupMinute: _intFromJson(value['autoBackupMinute']),
      lastSuccessfulSyncAt: _dateTimeFromJson(value['lastSuccessfulSyncAt']),
      lastAutoBackupAt: _dateTimeFromJson(value['lastAutoBackupAt']),
      lastRestoreAt: _dateTimeFromJson(value['lastRestoreAt']),
      lastSyncedAccountEmail: value['lastSyncedAccountEmail'] is String
          ? (value['lastSyncedAccountEmail'] as String).trim().isEmpty
                ? null
                : value['lastSyncedAccountEmail'] as String
          : null,
      lastKnownCloudBackupAt: _dateTimeFromJson(
        value['lastKnownCloudBackupAt'],
      ),
    );
  }

  CloudSyncPreferences _cloudSyncFromCloudJson(
    Object? value, {
    required CloudSyncPreferences fallback,
  }) {
    if (value is! Map) {
      return fallback;
    }

    return fallback.copyWith(
      enabled: value['enabled'] is bool
          ? value['enabled'] as bool
          : fallback.enabled,
      syncCredentials: value['syncCredentials'] is bool
          ? value['syncCredentials'] as bool
          : fallback.syncCredentials,
      autoBackupEnabled: value['autoBackupEnabled'] is bool
          ? value['autoBackupEnabled'] as bool
          : fallback.autoBackupEnabled,
      autoBackupHour: _intFromJson(
        value['autoBackupHour'],
        fallback: fallback.autoBackupHour,
      ),
      autoBackupMinute: _intFromJson(
        value['autoBackupMinute'],
        fallback: fallback.autoBackupMinute,
      ),
    );
  }

  int _intFromJson(Object? value, {int fallback = 0}) {
    return value is int ? value : fallback;
  }

  DateTime? _dateTimeFromJson(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
