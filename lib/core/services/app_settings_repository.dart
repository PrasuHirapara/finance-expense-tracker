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
      'exportDirectoryPath': settings.exportDirectoryPath,
      'cloudSync': _cloudSyncToJson(settings.cloudSync),
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
      exportDirectoryPath: _exportDirectoryPathFromJson(
        json['exportDirectoryPath'],
      ),
      cloudSync: _cloudSyncFromJson(json['cloudSync']),
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
