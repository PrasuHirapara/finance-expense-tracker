import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/app_preferences.dart';
import '../../../../core/services/app_settings_repository.dart';
import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/firebase_cloud_sync_auth_service.dart';
import '../../../../core/services/google_drive_backup_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/cancellable_blocking_overlay.dart';
import '../../../../core/router/app_router.dart';
import '../../../credentials/data/services/credential_service.dart';
import '../../../credentials/presentation/widgets/credential_key_entry_dialog.dart';

class GoogleDriveBackupSettingsSection extends StatefulWidget {
  const GoogleDriveBackupSettingsSection({
    super.key,
    required this.preferences,
    this.embedded = false,
  });

  final AppPreferences preferences;
  final bool embedded;

  @override
  State<GoogleDriveBackupSettingsSection> createState() =>
      _GoogleDriveBackupSettingsSectionState();
}

class _GoogleDriveBackupSettingsSectionState
    extends State<GoogleDriveBackupSettingsSection> {
  bool _isBackingUp = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<FirebaseCloudSyncAuthService>();

    return StreamBuilder<FirebaseCloudSyncAccount?>(
      stream: authService.authStateChanges(),
      initialData: authService.currentAccount,
      builder: (context, snapshot) {
        final account = snapshot.data;
        final isGoogleUser =
            account != null && account.providerIds.contains('google.com');
        final googleEmail = isGoogleUser ? account.email : 'Not connected';

        final backupDetails = widget.preferences.googleDriveBackup;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Google Drive Backup', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  !isGoogleUser
                      ? 'Google Drive backup is only available for accounts signed in with a Google account.'
                      : 'Back up your app data to Google Drive as a ZIP archive.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!isGoogleUser) ...<Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.42,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Please log in using Google Authentication to enable Google Drive backups. Username/Password logins are not eligible.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: !isGoogleUser || _isBackingUp
                      ? null
                      : () => unawaited(_backupNow()),
                  icon: const Icon(Icons.backup_rounded),
                  label: Text(_isBackingUp ? 'Backing up...' : 'Backup Now'),
                ),
                FilledButton.tonalIcon(
                  onPressed: !isGoogleUser || _isBackingUp
                      ? null
                      : () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.googleDriveBackups);
                        },
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('View Backups'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.42,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Backup Details', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Last Backup',
                    value: _formatDateTime(backupDetails.lastBackupAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Backup Status',
                    value: backupDetails.backupStatus,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Last File Uploaded',
                    value: backupDetails.lastUploadedFileName,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Google Account',
                    value: isGoogleUser
                        ? googleEmail
                        : backupDetails.backupGoogleAccount,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Included Modules',
                    value: backupDetails.backupIncludedModules,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Total Backup Size',
                    value: backupDetails.backupTotalSize,
                  ),
                  const SizedBox(height: 8),
                  const _InfoRow(
                    label: 'Backup Location',
                    value: 'Google Drive',
                  ),
                ],
              ),
            ),
          ],
        );

        return widget.embedded ? content : AppPanel(child: content);
      },
    );
  }

  Future<void> _backupNow() async {
    final backupService = context.read<GoogleDriveBackupService>();
    final credentialService = context.read<CredentialService>();
    final settingsRepo = context.read<AppSettingsRepository>();
    final messenger = ScaffoldMessenger.of(context);

    if (!await backupService.isEligible()) {
      if (!mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Google login is required to back up to Google Drive.',
          type: AppSnackBarType.warning,
        ),
      );
      return;
    }

    if (!mounted) return;
    final settings = await settingsRepo.getSettings();
    String? enteredKey;

    if (settings.cloudSync.syncCredentials) {
      final records = await credentialService.loadCredentials();
      if (records.isNotEmpty) {
        enteredKey = await credentialService.readStoredEncryptionKey();
        if (enteredKey == null || enteredKey.isEmpty) {
          if (!mounted) return;
          enteredKey = await showCredentialKeyEntryDialog(
            context,
            title: 'Credential Key Required',
            reason:
                'Enter your credential master key to include credentials in the backup.',
            requireConfirmation: false,
            submitLabel: 'Authenticate & Backup',
          );
          if (enteredKey == null || !mounted) {
            return; // Cancelled
          }
        }
      }
    }

    setState(() {
      _isBackingUp = true;
    });

    try {
      await _runBlockingOperation<void>(
        statusText: 'Creating backup ZIP and uploading to Google Drive...',
        task: (token) => backupService.runBackup(
          credentialEncryptionKey: enteredKey,
          cancellationToken: token,
        ),
      );

      if (!mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Google Drive backup completed successfully.',
        ),
      );
    } on AppTaskCancelledException {
      if (!mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Google Drive backup canceled.',
          type: AppSnackBarType.warning,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Failed to take backup: $e',
          type: AppSnackBarType.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<T> _runBlockingOperation<T>({
    required String statusText,
    required Future<T> Function(AppCancellationToken token) task,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final token = AppCancellationToken();
    final route = createCancellableBlockingOverlayRoute<void>(
      statusText: statusText,
      onCancel: token.cancel,
    );
    unawaited(navigator.push<void>(route));
    await Future<void>.delayed(Duration.zero);

    try {
      return await task(token);
    } finally {
      if (route.isActive) {
        navigator.removeRoute(route);
      }
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Not available';
    }
    return DateFormat('dd-MM-yyyy HH:mm').format(value.toLocal());
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
