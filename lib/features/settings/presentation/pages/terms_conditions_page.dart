import 'package:flutter/material.dart';

import '../../../../core/constants/legal_constants.dart';

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
            'Last updated: ${LegalConstants.termsLastUpdatedLabel}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'These Terms & Conditions describe the basic rules for using Daily Use. They cover your responsibilities, the project limitations, how backup-related features behave, and what expectations apply when you choose to store data in the app or connect Firebase services.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          _TermsSection(
            title: '1. Using the App',
            children: const <Widget>[
              _TermsParagraph(
                'Daily Use is a productivity and personal-record app. You are responsible for what you enter into the app, how you organize it, and how you choose to use exports, reminders, backup features, and connected services.',
              ),
              _TermsParagraph(
                'You should only use the app in ways that are lawful and appropriate for your own data. You should not rely on the app as a substitute for professional legal, security, accounting, or compliance advice.',
              ),
            ],
          ),
          _TermsSection(
            title: '2. Your Data Responsibilities',
            children: const <Widget>[
              _TermsParagraph(
                'You are responsible for the accuracy, legality, and sensitivity of the information that you enter into the app.',
              ),
              _TermsBulletList(
                items: <String>[
                  'Check important entries before relying on them.',
                  'Keep your own records if the information is critical.',
                  'Use backups carefully and verify restored data.',
                  'Avoid storing information in the app if you are not comfortable managing the related risk.',
                ],
              ),
            ],
          ),
          _TermsSection(
            title: '3. Credential Encryption Key Responsibility',
            children: const <Widget>[
              _TermsParagraph(
                'Credential data uses a dedicated encryption-key flow. You are responsible for creating, remembering, and protecting that credential encryption key.',
              ),
              _TermsParagraph(
                'If you lose the credential encryption key, encrypted credential records may become unrecoverable. The app cannot guarantee recovery of credential data when the required key is no longer available.',
              ),
            ],
          ),
          _TermsSection(
            title: '4. Cloud Backup and Restore',
            children: const <Widget>[
              _TermsParagraph(
                'Cloud sync depends on Firebase configuration, internet connectivity, account access, and correct app behavior. The availability of cloud backup is not guaranteed at all times.',
              ),
              _TermsBulletList(
                items: <String>[
                  'Expense data, task data, and settings may be included in cloud backup when sync is enabled.',
                  'Credential backup is optional and can be turned on or off separately.',
                  'Restore behavior may replace local data with cloud data depending on the restore action you choose.',
                  'You should confirm important information after a restore before relying on it.',
                ],
              ),
            ],
          ),
          _TermsSection(
            title: '5. Credential Backup Choice',
            children: const <Widget>[
              _TermsParagraph(
                'If you choose to disable credential cloud backup, credential records are intended to remain local to the device. Existing credential backup data for your account in Firebase is intended to be deleted when that setting is turned off.',
              ),
              _TermsParagraph(
                'Because cloud and local systems can be affected by connectivity, configuration, or implementation issues, you should still verify the result of any backup-related change that matters to you.',
              ),
            ],
          ),
          _TermsSection(
            title: '6. Notifications, Reminders, and Scheduling',
            children: const <Widget>[
              _TermsParagraph(
                'Reminder and notification features depend on device permissions, operating-system behavior, notification scheduling support, and your own app settings.',
              ),
              _TermsParagraph(
                'The app may try to schedule expense reminders, task reminders, or credential expiry reminders, but it cannot guarantee delivery on every platform or under every device condition.',
              ),
            ],
          ),
          _TermsSection(
            title: '7. Account Access',
            children: const <Widget>[
              _TermsParagraph(
                'If you sign in with Firebase, you are responsible for maintaining access to that account and keeping it secure. If you lose account access, backup and restore behavior tied to that account may be affected.',
              ),
            ],
          ),
          _TermsSection(
            title: '8. Privacy Policy Acceptance and Updates',
            children: const <Widget>[
              _TermsParagraph(
                'The app may require you to review and accept the current Privacy Policy before using the app fully. If the privacy terms change in a meaningful way, the project may prompt you to review and accept the updated policy again.',
              ),
              _TermsParagraph(
                'You should review the in-app legal pages after significant updates instead of assuming that earlier wording still applies unchanged.',
              ),
            ],
          ),
          _TermsSection(
            title: '9. No Warranty',
            children: const <Widget>[
              _TermsParagraph(
                'Daily Use is provided on an "as is" and "as available" basis. No guarantee is made that the app will be error-free, uninterrupted, fully secure, or appropriate for every use case.',
              ),
              _TermsParagraph(
                'You should maintain your own secure practices and verify important data before relying on backups, restores, reminders, exports, or encryption-related workflows.',
              ),
            ],
          ),
          _TermsSection(
            title: '10. Changes to These Terms',
            children: const <Widget>[
              _TermsParagraph(
                'These Terms & Conditions may be updated as the app changes. When the project updates legal text, the in-app pages and matching HTML copies should be reviewed so you can understand the current terms of use.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _TermsParagraph extends StatelessWidget {
  const _TermsParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
      ),
    );
  }
}

class _TermsBulletList extends StatelessWidget {
  const _TermsBulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('• ', style: textStyle),
                    Expanded(child: Text(item, style: textStyle)),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
