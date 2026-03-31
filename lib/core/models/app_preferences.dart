import 'package:flutter/material.dart';

enum AppModule { expense, tasks, settings }

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.dark,
    this.selectedModule = AppModule.expense,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;
  final AppModule selectedModule;
  final bool notificationsEnabled;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    AppModule? selectedModule,
    bool? notificationsEnabled,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      selectedModule: selectedModule ?? this.selectedModule,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
