import 'package:flutter/material.dart';

enum AppModule { expense, tasks, settings }

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.dark,
    this.notificationsEnabled = true,
    this.exportDirectoryPath,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String? exportDirectoryPath;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    Object? exportDirectoryPath = _appPreferenceUnset,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      exportDirectoryPath: identical(exportDirectoryPath, _appPreferenceUnset)
          ? this.exportDirectoryPath
          : exportDirectoryPath as String?,
    );
  }
}

const Object _appPreferenceUnset = Object();
