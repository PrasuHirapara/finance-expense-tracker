import 'package:flutter/material.dart';

import '../../../../core/constants/legal_constants.dart';

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
            'Last updated: ${LegalConstants.privacyPolicyLastUpdatedLabel}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This Privacy Policy explains how Daily Use stores, processes, protects, and restores the information you place inside the app. It is written to help you understand the app behavior implemented in this project, especially around local storage, reminders, encryption, and optional Firebase cloud backup.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          _PolicySection(
            title: '1. Information Stored by the App',
            children: const <Widget>[
              _PolicyParagraph(
                'Daily Use can store several kinds of information so the app keeps working between sessions and so your records remain available on the same device.',
              ),
              _PolicyBulletList(
                items: <String>[
                  'Credential records, including encrypted credential payloads and related metadata.',
                  'Expense records, banks, categories, split information, and transaction history.',
                  'Task records, task categories, completion state, and task dates.',
                  'Reminder preferences, app theme, export folder path, notification settings, and cloud sync preferences.',
                  'Privacy-policy acceptance version so the app can know whether you have accepted the current policy text.',
                ],
              ),
              _PolicyParagraph(
                'Some information is stored in the app database, while some settings are stored in local settings files on the device. These values are used only to provide the app features described in the project.',
              ),
            ],
          ),
          _PolicySection(
            title: '2. Local Device Storage',
            children: const <Widget>[
              _PolicyParagraph(
                'Most app data is intended to live primarily on your own device. This includes expense data, task data, settings, and locally stored credential records.',
              ),
              _PolicyParagraph(
                'Credential records are treated differently from ordinary app data. The credential content is encrypted before local storage, while some visible metadata, such as titles, may remain readable in the app so you can identify entries more easily.',
              ),
              _PolicyParagraph(
                'If you delete the app, clear storage, reset the device, or remove local data from the app settings, some or all of this locally stored information may be removed unless you have separately backed it up.',
              ),
            ],
          ),
          _PolicySection(
            title: '3. Cloud Backup and Firebase',
            children: const <Widget>[
              _PolicyParagraph(
                'Cloud sync is optional. If you enable it, Daily Use can store backup documents in your Firebase project under your signed-in account. This backup is designed to help you restore app data on the same or another device using the same signed-in Firebase account.',
              ),
              _PolicyBulletList(
                items: <String>[
                  'Expense data can be backed up to Firebase.',
                  'Task data can be backed up to Firebase.',
                  'Saved app settings and reminder settings can be backed up to Firebase.',
                  'Credential backup is optional and can be turned on or off separately.',
                ],
              ),
              _PolicyParagraph(
                'If credential cloud backup is disabled, credential records are intended to remain local only, and any previous Firebase credential backup for that signed-in account is intended to be deleted when the option is turned off.',
              ),
            ],
          ),
          _PolicySection(
            title: '4. Encryption and Data Protection',
            children: const <Widget>[
              _PolicyParagraph(
                'The app uses separate protection paths for different kinds of data. This distinction is important.',
              ),
              _PolicyBulletList(
                items: <String>[
                  'Credential data uses a dedicated credential encryption key flow.',
                  'Expense, task, and settings cloud payloads use a separate encryption flow and do not use the credential encryption key.',
                  'Credential titles and selected credential metadata may be additionally protected during cloud sync when credential backup is enabled.',
                  'Secure-storage mechanisms supported by the device platform are used where applicable for sensitive local key material.',
                ],
              ),
              _PolicyParagraph(
                'Although the app uses encryption and storage safeguards, no software system can promise absolute security. You remain responsible for protecting access to your device, Firebase account, and any keys or credentials that you create.',
              ),
            ],
          ),
          _PolicySection(
            title: '5. Account and Sign-In Information',
            children: const <Widget>[
              _PolicyParagraph(
                'If you choose to sign in with Firebase, the app may process basic account-related data so the cloud sync feature can identify your account and attach backups to it.',
              ),
              _PolicyBulletList(
                items: <String>[
                  'Firebase user ID',
                  'Email address',
                  'Display name',
                  'Provider information, such as Google or email/password',
                  'Basic sign-in timestamps used by Firebase-related account features',
                ],
              ),
              _PolicyParagraph(
                'This account information is used for app account linkage and cloud backup behavior. The project expects Firebase security rules to limit access so users only read and write their own cloud data.',
              ),
            ],
          ),
          _PolicySection(
            title: '6. Notifications and Reminders',
            children: const <Widget>[
              _PolicyParagraph(
                'The app can schedule reminders for expenses, tasks, and credential expiry. Those reminders depend on your local settings and platform notification permissions.',
              ),
              _PolicyParagraph(
                'If reminders are enabled, the app may use stored reminder times and task or credential metadata to schedule local notifications on your device. These notifications are meant to improve usability and do not require cloud sync to work.',
              ),
            ],
          ),
          _PolicySection(
            title: '7. Your Choices and Controls',
            children: const <Widget>[
              _PolicyParagraph(
                'You remain in control of several important privacy-related choices inside the app.',
              ),
              _PolicyBulletList(
                items: <String>[
                  'Use the app without signing in to Firebase.',
                  'Enable or disable cloud sync.',
                  'Enable or disable credential cloud backup separately.',
                  'Turn notifications and reminders on or off.',
                  'Delete local app data from the app settings area.',
                  'Delete cloud backup data linked to your Firebase account.',
                ],
              ),
            ],
          ),
          _PolicySection(
            title: '8. First-Run Acceptance',
            children: const <Widget>[
              _PolicyParagraph(
                'On first launch, the app asks you to review and accept this Privacy Policy before continuing to use the main experience. The accepted version may be stored in app settings and may also be restored if your settings are restored from backup.',
              ),
              _PolicyParagraph(
                'If the policy is updated in a future version, the app may ask you to review and accept the updated version again.',
              ),
            ],
          ),
          _PolicySection(
            title: '9. Policy Changes',
            children: const <Widget>[
              _PolicyParagraph(
                'This Privacy Policy may change as app features change. If storage, backup, encryption, or account behavior changes materially, the in-app policy text and related HTML copies should be updated to reflect those changes.',
              ),
            ],
          ),
          _PolicySection(
            title: '10. Important Notice',
            children: const <Widget>[
              _PolicyParagraph(
                'This Privacy Policy is provided for transparency regarding the behavior implemented in this project. It is not legal advice, and it does not replace advice from a qualified lawyer or compliance professional.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.children});

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

class _PolicyParagraph extends StatelessWidget {
  const _PolicyParagraph(this.text);

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

class _PolicyBulletList extends StatelessWidget {
  const _PolicyBulletList({required this.items});

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
