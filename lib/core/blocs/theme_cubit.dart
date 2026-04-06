import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_preferences.dart';
import '../services/app_settings_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({
    required AppSettingsRepository settingsRepository,
    ThemeMode initialThemeMode = ThemeMode.dark,
  }) : _settingsRepository = settingsRepository,
       super(initialThemeMode) {
    _settingsSubscription = _settingsRepository.watchSettings().listen((
      settings,
    ) {
      if (state != settings.themeMode) {
        emit(settings.themeMode);
      }
    });
  }

  final AppSettingsRepository _settingsRepository;
  late final StreamSubscription<AppPreferences> _settingsSubscription;

  void setThemeMode(ThemeMode mode) {
    if (state == mode) {
      return;
    }

    emit(mode);
    unawaited(_settingsRepository.updateThemeMode(mode));
  }

  @override
  Future<void> close() async {
    await _settingsSubscription.cancel();
    await super.close();
  }
}
