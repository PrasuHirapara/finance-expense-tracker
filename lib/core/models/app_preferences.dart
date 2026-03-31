import 'package:flutter/material.dart';

enum AppModule { expense, tasks, settings }

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.dark,
    this.selectedModule = AppModule.expense,
  });

  final ThemeMode themeMode;
  final AppModule selectedModule;

  AppPreferences copyWith({ThemeMode? themeMode, AppModule? selectedModule}) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      selectedModule: selectedModule ?? this.selectedModule,
    );
  }
}
