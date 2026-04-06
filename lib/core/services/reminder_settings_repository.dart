import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ReminderTime {
  const ReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hour': hour,
    'minute': minute,
  };

  static ReminderTime fromTimeOfDay(TimeOfDay time) {
    return ReminderTime(hour: time.hour, minute: time.minute);
  }

  static ReminderTime fromJson(Object? json, {required ReminderTime fallback}) {
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

    return ReminderTime(hour: hour, minute: minute);
  }
}

class ReminderSettings {
  const ReminderSettings({
    this.expenseReminder = defaultExpenseReminder,
    this.taskReminder = defaultTaskReminder,
  });

  static const ReminderTime defaultExpenseReminder = ReminderTime(
    hour: 20,
    minute: 0,
  );
  static const ReminderTime defaultTaskReminder = ReminderTime(
    hour: 8,
    minute: 0,
  );

  final ReminderTime expenseReminder;
  final ReminderTime taskReminder;

  ReminderSettings copyWith({
    ReminderTime? expenseReminder,
    ReminderTime? taskReminder,
  }) {
    return ReminderSettings(
      expenseReminder: expenseReminder ?? this.expenseReminder,
      taskReminder: taskReminder ?? this.taskReminder,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'expenseReminder': expenseReminder.toJson(),
    'taskReminder': taskReminder.toJson(),
  };

  static ReminderSettings fromJson(Object? json) {
    if (json is! Map) {
      return const ReminderSettings();
    }

    return ReminderSettings(
      expenseReminder: ReminderTime.fromJson(
        json['expenseReminder'],
        fallback: ReminderSettings.defaultExpenseReminder,
      ),
      taskReminder: ReminderTime.fromJson(
        json['taskReminder'],
        fallback: ReminderSettings.defaultTaskReminder,
      ),
    );
  }
}

class ReminderSettingsRepository {
  final StreamController<ReminderSettings> _controller =
      StreamController<ReminderSettings>.broadcast();

  ReminderSettings? _cachedSettings;

  Stream<ReminderSettings> watchSettings() async* {
    yield await getSettings();
    yield* _controller.stream;
  }

  Future<ReminderSettings> getSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    final file = await _settingsFile();
    if (!await file.exists()) {
      _cachedSettings = const ReminderSettings();
      await _writeSettings(_cachedSettings!);
      return _cachedSettings!;
    }

    final content = await file.readAsString();
    _cachedSettings = ReminderSettings.fromJson(jsonDecode(content));
    return _cachedSettings!;
  }

  Future<void> updateExpenseReminder(ReminderTime time) async {
    final settings = await getSettings();
    await _commit(settings.copyWith(expenseReminder: time));
  }

  Future<void> updateTaskReminder(ReminderTime time) async {
    final settings = await getSettings();
    await _commit(settings.copyWith(taskReminder: time));
  }

  Future<void> resetExpenseReminder() async {
    final settings = await getSettings();
    await _commit(
      settings.copyWith(
        expenseReminder: ReminderSettings.defaultExpenseReminder,
      ),
    );
  }

  Future<void> resetTaskReminder() async {
    final settings = await getSettings();
    await _commit(
      settings.copyWith(taskReminder: ReminderSettings.defaultTaskReminder),
    );
  }

  Future<Map<String, dynamic>> exportForCloud() async {
    final settings = await getSettings();
    return settings.toJson();
  }

  Future<void> restoreFromCloud(Object? json) async {
    final current = await getSettings();
    final restored = json is Map ? ReminderSettings.fromJson(json) : current;
    await _commit(restored);
  }

  Future<DateTime?> lastModifiedAt() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return null;
    }
    return file.lastModified();
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  Future<void> _commit(ReminderSettings settings) async {
    _cachedSettings = settings;
    await _writeSettings(settings);
    _controller.add(settings);
  }

  Future<void> _writeSettings(ReminderSettings settings) async {
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(settings.toJson()));
  }

  Future<File> _settingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, 'reminder_settings.json'));
  }
}
