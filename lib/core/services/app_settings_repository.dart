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

  Future<void> updateSelectedModule(AppModule module) async {
    final settings = await getSettings();
    await _commit(settings.copyWith(selectedModule: module));
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final settings = await getSettings();
    await _commit(settings.copyWith(notificationsEnabled: enabled));
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
      'selectedModule': settings.selectedModule.name,
      'notificationsEnabled': settings.notificationsEnabled,
    };
  }

  AppPreferences _fromJson(Object? json) {
    if (json is! Map) {
      return const AppPreferences();
    }

    return AppPreferences(
      themeMode: _themeModeFromString(json['themeMode']),
      selectedModule: _moduleFromString(json['selectedModule']),
      notificationsEnabled: _notificationsEnabledFromJson(
        json['notificationsEnabled'],
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

  AppModule _moduleFromString(Object? value) {
    return switch (value) {
      'tasks' => AppModule.tasks,
      'settings' => AppModule.settings,
      _ => AppModule.expense,
    };
  }

  bool _notificationsEnabledFromJson(Object? value) {
    return value is bool ? value : true;
  }
}
