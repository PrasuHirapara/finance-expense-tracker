import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/services/firebase_runtime_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseIfSupported();
  runApp(const DailyUseApp());
}
