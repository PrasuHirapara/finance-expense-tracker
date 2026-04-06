import 'package:flutter/material.dart';

class PrivacyPolicyConsentDialog extends StatelessWidget {
  const PrivacyPolicyConsentDialog({
    super.key,
    required this.lastUpdatedLabel,
    required this.onAccept,
    required this.onViewFullPolicy,
  });

  final String lastUpdatedLabel;
  final VoidCallback onAccept;
  final VoidCallback onViewFullPolicy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Privacy Policy'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Please review and accept the Privacy Policy before using the app.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: $lastUpdatedLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const _ConsentPoint(
                  title: 'Stored data',
                  body:
                      'The app can store credential, expense, task, reminder, and app-setting data on your device.',
                ),
                const _ConsentPoint(
                  title: 'Cloud backup',
                  body:
                      'If you enable Firebase cloud sync, backups may include expense, task, and settings data, and optionally credential data.',
                ),
                const _ConsentPoint(
                  title: 'Encryption',
                  body:
                      'Credential data uses its own encryption key. Expense, task, and settings cloud payloads use a separate encryption flow.',
                ),
                const _ConsentPoint(
                  title: 'Your control',
                  body:
                      'You can manage notifications, cloud sync, exports, local data, and account settings from inside the app.',
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: onViewFullPolicy,
            child: const Text('View Full Policy'),
          ),
          FilledButton(
            onPressed: onAccept,
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
