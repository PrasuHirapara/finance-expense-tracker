import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/app_settings_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({
    required AppSettingsRepository settingsRepository,
    ThemeMode initialThemeMode = ThemeMode.dark,
  }) : _settingsRepository = settingsRepository,
       super(initialThemeMode);

  final AppSettingsRepository _settingsRepository;

  void setThemeMode(ThemeMode mode) {
    if (state == mode) {
      return;
    }

    emit(mode);
    unawaited(_settingsRepository.updateThemeMode(mode));
  }
}
