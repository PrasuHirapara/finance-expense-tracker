import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/services/cloud_sync_background.dart';
import 'core/services/firebase_runtime_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseIfSupported();
  if (Platform.isAndroid || Platform.isIOS) {
    await Workmanager().initialize(cloudSyncCallbackDispatcher);
  }
  runApp(const DailyUseApp());
}
