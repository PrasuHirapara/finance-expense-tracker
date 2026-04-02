import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../services/firebase_cloud_sync_auth_service.dart';
import 'app_shell.dart';

class FirebaseAuthGate extends StatelessWidget {
  const FirebaseAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<FirebaseCloudSyncAuthService>();
    if (!authService.isAvailable) {
      return const AppShell();
    }

    return StreamBuilder<FirebaseCloudSyncAccount?>(
      stream: authService.authStateChanges(),
      initialData: authService.currentAccount,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const AuthPage();
        }

        return const AppShell();
      },
    );
  }
}
