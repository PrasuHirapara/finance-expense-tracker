import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const String firebaseConfigMissingMessage =
    'No Firebase config found for this platform.';

bool get supportsFirebaseRuntime =>
    Platform.isAndroid || Platform.isIOS || Platform.isWindows;

Future<void> initializeFirebaseIfSupported() async {
  if (!supportsFirebaseRuntime || Firebase.apps.isNotEmpty) {
    return;
  }

  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
