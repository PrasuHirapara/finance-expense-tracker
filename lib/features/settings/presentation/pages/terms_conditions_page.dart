import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          Text('Terms & Conditions', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Last updated: April 3, 2026',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          const _TermsSection(
            title: 'Use of the app',
            body:
                'You are responsible for the data you enter into the app and for how you use exports, backups, and connected services such as Firebase.',
          ),
          const _TermsSection(
            title: 'Encryption key responsibility',
            body:
                'You are responsible for remembering and protecting your credential encryption key. If the key is lost, encrypted credential records may become unrecoverable.',
          ),
          const _TermsSection(
            title: 'Cloud backup responsibility',
            body:
                'Cloud sync is optional and depends on your Firebase configuration, connectivity, and account access. If you enable credential backup, the app rewrites the Firebase credential backup on future syncs, including after an encryption-key change.',
          ),
          const _TermsSection(
            title: 'Local-only credentials',
            body:
                'If you disable credential cloud backup, credential records remain on the device only. Existing credential backup data stored for your account in Firebase is intended to be deleted when that option is turned off.',
          ),
          const _TermsSection(
            title: 'No warranty',
            body:
                'The app is provided on an as-is basis. You should maintain your own secure practices and verify important data before relying on backups or restores.',
          ),
          const _TermsSection(
            title: 'Changes',
            body:
                'These terms may be updated as the app changes. The in-app terms page should be reviewed after significant updates.',
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
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
