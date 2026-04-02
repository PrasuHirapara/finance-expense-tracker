import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/services/cloud_sync_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp();
  }
  await Workmanager().initialize(cloudSyncCallbackDispatcher);
  runApp(const DailyUseApp());
}
