import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          Text('Privacy Policy', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Last updated: April 3, 2026',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          const _PolicySection(
            title: 'What the app stores',
            body:
                'Credential, expense, task, and preference data are primarily stored on your device. Credential fields are encrypted before local storage. Local credential titles remain visible in the app so you can identify entries quickly.',
          ),
          const _PolicySection(
            title: 'Cloud sync',
            body:
                'Cloud sync is optional. If enabled, the app can store backups in your Firebase project under your signed-in account. You can choose whether credential data is included in that backup. When credential backup is enabled, credential titles are encrypted before upload and the encrypted credential payload is uploaded. If credential backup is disabled, credential records stay local and any previous Firebase credential backup is deleted.',
          ),
          const _PolicySection(
            title: 'Account information',
            body:
                'If you sign in with Firebase, the app stores basic account profile details such as your user ID, email address, display name, provider list, and sign-in timestamps so cloud sync can be tied to your account.',
          ),
          const _PolicySection(
            title: 'Security controls',
            body:
                'Credential encryption keys are stored using the device secure-storage facilities supported by the platform. Biometric authentication can be used as an access gate where supported. Firestore access is expected to be restricted so users can only read and write their own documents.',
          ),
          const _PolicySection(
            title: 'Your choices',
            body:
                'You can use the app without signing in, disable cloud sync, disable credential cloud backup separately, delete cloud data for your account, or remove all app data locally from the settings screens.',
          ),
          const _PolicySection(
            title: 'Important note',
            body:
                'This page describes the app behavior implemented in this project and is provided for transparency inside the app. It is not legal advice.',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
