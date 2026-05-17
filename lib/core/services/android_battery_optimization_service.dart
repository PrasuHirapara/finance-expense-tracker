import 'dart:io';

import 'package:flutter/services.dart';

class AndroidBatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel(
    'daily_use/battery_optimization',
  );

  bool get isSupported => Platform.isAndroid;

  Future<bool> isBatteryOptimizationEnabled() async {
    if (!isSupported) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>(
            'isBatteryOptimizationEnabled',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isIgnoringBatteryOptimization() async {
    if (!isSupported) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimization',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (!isSupported) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
    } catch (_) {}
  }

  Future<void> openAppBatterySettings() async {
    if (!isSupported) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('openAppBatterySettings');
    } catch (_) {}
  }
}
