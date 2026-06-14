import 'package:flutter/foundation.dart';

class LogConsole {
  LogConsole._();

  static final List<String> logs = [];

  static void log(String message) {
    final timeStr = DateTime.now().toLocal().toString().split(' ').last;
    final timestamped =
        '[${timeStr.length > 8 ? timeStr.substring(0, 8) : timeStr}] $message';
    logs.add(timestamped);
    debugPrint(timestamped);
  }

  static void clear() {
    logs.clear();
  }
}
