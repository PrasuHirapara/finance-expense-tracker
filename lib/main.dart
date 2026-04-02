import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/services/cloud_sync_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(cloudSyncCallbackDispatcher);
  runApp(const DailyUseApp());
}