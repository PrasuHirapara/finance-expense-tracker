import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/app_preferences.dart';
import '../../../../core/models/cloud_sync_models.dart';
import '../../../../core/services/app_settings_repository.dart';
import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/services/firebase_cloud_sync_auth_service.dart';
import '../../../../core/services/firebase_runtime_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_settings_repository.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/cancellable_blocking_overlay.dart';
import '../../../credentials/data/services/credential_service.dart';
import '../../../credentials/presentation/widgets/credential_key_entry_dialog.dart';

class CloudSyncSettingsSection extends StatefulWidget {
  const CloudSyncSettingsSection({
    super.key,
    required this.preferences,
    this.embedded = false,
  });

  final AppPreferences preferences;
  final bool embedded;

  @override
  State<CloudSyncSettingsSection> createState() =>
      _CloudSyncSettingsSectionState();
}

class _CloudSyncSettingsSectionState extends State<CloudSyncSettingsSection> {
  bool _isSyncing = false;
  bool _isRestoring = false;
  bool _isToggling = false;
  bool _isUpdatingCredentialSync = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<FirebaseCloudSyncAuthService>();
    return StreamBuilder<FirebaseCloudSyncAccount?>(
      stream: authService.authStateChanges(),
      initialData: authService.currentAccount,
      builder: (context, snapshot) {
        final cloudSync = widget.preferences.cloudSync;
        final hasFirebaseAccount = snapshot.data != null;
        final canUseCloudSync =
            authService.isAvailable && hasFirebaseAccount && cloudSync.enabled;
        final canToggleCloudSync =
            authService.isAvailable &&
            (hasFirebaseAccount || cloudSync.enabled);

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Cloud Sync & Backup',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        !authService.isAvailable
                            ? 'Firebase cloud backup is available on builds configured with Firebase.'
                            : cloudSync.enabled
                            ? 'Firebase cloud backup is enabled for your app data.'
                            : 'Enable cloud sync to upload backups and restore from Firestore.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: cloudSync.enabled,
                  onChanged: _isToggling || !canToggleCloudSync
                      ? null
                      : (value) => _toggleCloudSync(context, value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!authService.isAvailable) ...<Widget>[
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
                  '$firebaseConfigMissingMessage Sync, restore, and cloud login are disabled.',
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
                  onPressed: !canUseCloudSync || _isSyncing || _isRestoring
                      ? null
                      : () => unawaited(_syncNow()),
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                ),
                FilledButton.tonalIcon(
                  onPressed: !canUseCloudSync || _isSyncing || _isRestoring
                      ? null
                      : () => unawaited(_restoreFromCloud()),
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: Text(
                    _isRestoring ? 'Restoring...' : 'Restore from Cloud',
                  ),
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
                    label: 'Account',
                    value:
                        cloudSync.lastSyncedAccountEmail?.trim().isNotEmpty ==
                            true
                        ? cloudSync.lastSyncedAccountEmail!
                        : hasFirebaseAccount
                        ? snapshot.data?.email ?? 'Connected'
                        : 'Not connected',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Backup Scope',
                    value: cloudSync.syncCredentials
                        ? 'All data'
                        : 'Expense and Task data only',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Last Sync',
                    value: _formatDateTime(cloudSync.lastSuccessfulSyncAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Last Restore',
                    value: _formatDateTime(cloudSync.lastRestoreAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Last Cloud Backup',
                    value: _formatDateTime(cloudSync.lastKnownCloudBackupAt),
                  ),
                ],
              ),
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
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Sync Credential Data',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !hasFirebaseAccount
                              ? 'Sign in to choose whether encrypted credential backups should be stored in Firestore.'
                              : !cloudSync.enabled
                              ? 'Turn on Cloud Sync first to choose whether credentials are included.'
                              : cloudSync.syncCredentials
                              ? 'Encrypted credential payloads and encrypted titles are included in your Firebase backup.'
                              : 'Credentials stay local only. Any previous Firebase credential backup for this account will be deleted.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: cloudSync.syncCredentials,
                    onChanged:
                        !cloudSync.enabled ||
                            _isUpdatingCredentialSync ||
                            !authService.isAvailable ||
                            !hasFirebaseAccount
                        ? null
                        : (value) => _toggleCredentialSync(context, value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<ReminderSettings>(
              stream: context
                  .read<ReminderSettingsRepository>()
                  .watchSettings(),
              builder: (context, reminderSnapshot) {
                final reminderSettings =
                    reminderSnapshot.data ?? const ReminderSettings();
                return Container(
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
                      Text(
                        'Manual Sync Reminder',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cloudSync.enabled
                            ? 'Get a daily reminder to open Daily Use and manually upload a fresh cloud backup.'
                            : 'Pick a reminder time now. The reminder will start once Cloud Sync is enabled.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isToggling || !authService.isAvailable
                            ? null
                            : () => _pickSyncReminderTime(
                                context,
                                initialTime: reminderSettings.syncReminder,
                              ),
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text(
                          _formatReminderTime(
                            context,
                            reminderSettings.syncReminder,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _statusSummary(cloudSync),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );

        return widget.embedded ? content : AppPanel(child: content);
      },
    );
  }

  Future<void> _toggleCloudSync(BuildContext context, bool enabled) async {
    setState(() {
      _isToggling = true;
    });
    try {
      await context.read<CloudSyncService>().setCloudSyncEnabled(enabled);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: enabled ? 'Cloud Sync enabled.' : 'Cloud Sync disabled.',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to update Cloud Sync: $error',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  Future<void> _syncNow() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSyncing = true;
    });
    await Future<void>.delayed(Duration.zero);
    try {
      await _performCloudUpload();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(context, message: 'Cloud backup completed.'),
      );
    } on CloudCredentialEncryptionKeyRequiredException {
      if (!mounted) {
        return;
      }
      final recovered = await _retrySyncWithCredentialKey(keyWasInvalid: false);
      if (!recovered || !mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(context, message: 'Cloud backup completed.'),
      );
    } on CloudCredentialEncryptionKeyInvalidException {
      if (!mounted) {
        return;
      }
      final recovered = await _retrySyncWithCredentialKey(keyWasInvalid: true);
      if (!recovered || !mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(context, message: 'Cloud backup completed.'),
      );
    } on AppTaskCancelledException {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Cloud backup canceled.',
          type: AppSnackBarType.warning,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Cloud sync failed: $error',
          type: AppSnackBarType.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    final service = context.read<CloudSyncService>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isRestoring = true;
    });
    await Future<void>.delayed(Duration.zero);
    try {
      final check = await _runBlockingOperation<CloudRestoreCheck>(
        statusText: 'Checking your cloud backup...',
        task: (token) => service.inspectRestoreState(cancellationToken: token),
      );
      var forceOverwrite = false;
      if (!mounted) {
        return;
      }
      if (check.isLocalNewer) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Local Data Is Newer'),
            content: const Text(
              'Your local data is newer. Sync first to avoid losing changes.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Restore Anyway'),
              ),
            ],
          ),
        );
        if (proceed != true) {
          return;
        }
        forceOverwrite = true;
      }

      if (!mounted) {
        return;
      }
      final restored = await _restoreWithCredentialKeyHandling(
        forceOverwrite: forceOverwrite,
      );
      if (!restored || !mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(context, message: 'Cloud restore completed.'),
      );
    } on AppTaskCancelledException {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Cloud restore canceled.',
          type: AppSnackBarType.warning,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Restore failed: $error',
          type: AppSnackBarType.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  String _formatReminderTime(BuildContext context, ReminderTime reminderTime) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      reminderTime.toTimeOfDay(),
      alwaysUse24HourFormat:
          MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Not available';
    }
    return DateFormat('dd-MM-yyyy HH:mm').format(value.toLocal());
  }

  String _statusSummary(CloudSyncPreferences preferences) {
    final parts = <String>[
      'Data: ${preferences.syncCredentials ? 'Full backup enabled' : 'App data backup without credentials'}',
      'Mode: manual sync only',
    ];
    return parts.join(' | ');
  }

  Future<void> _pickSyncReminderTime(
    BuildContext context, {
    required ReminderTime initialTime,
  }) async {
    final reminderSettingsRepository = context
        .read<ReminderSettingsRepository>();
    final notificationService = context.read<NotificationService>();
    final appSettingsRepository = context.read<AppSettingsRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final alwaysUse24HourFormat =
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime.toTimeOfDay(),
    );

    if (selectedTime == null) {
      return;
    }

    final reminderTime = ReminderTime.fromTimeOfDay(selectedTime);
    final formattedTime = materialLocalizations.formatTimeOfDay(
      selectedTime,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );

    await reminderSettingsRepository.updateSyncReminder(reminderTime);
    final appSettings = await appSettingsRepository.getSettings();
    if (appSettings.notificationsEnabled) {
      await notificationService.scheduleDailyReminders();
    } else {
      await notificationService.cancelDailyReminders();
    }

    if (!context.mounted) {
      return;
    }

    scaffoldMessenger.showSnackBar(
      buildAppSnackBar(
        context,
        message: 'Sync reminder set for $formattedTime.',
      ),
    );
  }

  Future<void> _toggleCredentialSync(BuildContext context, bool enabled) async {
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Keep Credentials Local Only?'),
          content: const Text(
            'This keeps credential records on this device only and deletes any existing credential backup from Firebase for the signed-in account.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Disable Sync'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) {
        return;
      }
    }

    setState(() {
      _isUpdatingCredentialSync = true;
    });
    try {
      await context.read<CloudSyncService>().setCredentialSyncEnabled(enabled);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: enabled
            ? 'Credential cloud backup enabled. Your next sync will include encrypted credential data.'
            : 'Credential cloud backup disabled. Existing Firebase credential backup deleted.',
        type: enabled ? AppSnackBarType.info : AppSnackBarType.warning,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to update credential cloud backup: $error',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingCredentialSync = false;
        });
      }
    }
  }

  Future<bool> _retrySyncWithCredentialKey({
    required bool keyWasInvalid,
  }) async {
    final credentialService = context.read<CredentialService>();
    final messenger = ScaffoldMessenger.of(context);
    final hasStoredKey = await credentialService.hasEncryptionKey();
    if (!mounted) {
      return false;
    }
    final enteredKey = await showCredentialKeyEntryDialog(
      context,
      title: 'Credential Key Required',
      reason: keyWasInvalid
          ? 'The saved credential key did not match the local encrypted credential records. Enter the correct key to continue syncing.'
          : hasStoredKey
          ? 'Enter the credential encryption key to verify and continue syncing credential titles to Firestore.'
          : 'Enter your credential encryption key so credential titles can be encrypted before upload and reused for future sync.',
      requireConfirmation: !hasStoredKey,
      submitLabel: hasStoredKey ? 'Verify & Sync' : 'Save & Sync',
    );

    if (enteredKey == null || !mounted) {
      return false;
    }

    final isValid = await credentialService
        .validateEncryptionKeyAgainstStoredCredentials(enteredKey);
    if (!isValid) {
      if (!mounted) {
        return false;
      }
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message:
              'That encryption key could not unlock the local credential records.',
          type: AppSnackBarType.error,
        ),
      );
      return false;
    }

    await credentialService.configureEncryptionKey(enteredKey);
    await _performCloudUpload(credentialEncryptionKey: enteredKey);
    return true;
  }

  Future<bool> _restoreWithCredentialKeyHandling({
    required bool forceOverwrite,
  }) async {
    final credentialService = context.read<CredentialService>();

    try {
      await _performCloudRestoreDownload(forceOverwrite: forceOverwrite);
      return true;
    } on CloudCredentialEncryptionKeyRequiredException {
      final requireConfirmation = !(await credentialService.hasEncryptionKey());
      if (!mounted) {
        return false;
      }
      return _promptForCredentialKeyAndRestore(
        forceOverwrite: forceOverwrite,
        requireConfirmation: requireConfirmation,
        reason:
            'Enter your credential encryption key to restore encrypted credential titles from Firestore.',
      );
    } on CloudCredentialEncryptionKeyInvalidException {
      if (!mounted) {
        return false;
      }
      return _promptForCredentialKeyAndRestore(
        forceOverwrite: forceOverwrite,
        requireConfirmation: false,
        reason:
            'The saved encryption key did not match the cloud credential backup. Enter the correct key to restore those records.',
      );
    }
  }

  Future<bool> _promptForCredentialKeyAndRestore({
    required bool forceOverwrite,
    required bool requireConfirmation,
    required String reason,
  }) async {
    final credentialService = context.read<CredentialService>();
    final enteredKey = await showCredentialKeyEntryDialog(
      context,
      title: 'Credential Key Required',
      reason: reason,
      requireConfirmation: requireConfirmation,
      submitLabel: requireConfirmation ? 'Save & Restore' : 'Restore',
    );

    if (enteredKey == null || !mounted) {
      return false;
    }

    await _performCloudRestoreDownload(
      forceOverwrite: forceOverwrite,
      credentialEncryptionKey: enteredKey,
    );
    await credentialService.configureEncryptionKey(enteredKey);
    return true;
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

  Future<void> _performCloudUpload({String? credentialEncryptionKey}) async {
    final cloudSyncService = context.read<CloudSyncService>();
    await _runBlockingOperation<void>(
      statusText: 'Syncing your data with Firebase...',
      task: (token) => cloudSyncService.uploadDataToCloud(
        credentialEncryptionKey: credentialEncryptionKey,
        cancellationToken: token,
      ),
    );
  }

  Future<void> _performCloudRestoreDownload({
    required bool forceOverwrite,
    String? credentialEncryptionKey,
  }) async {
    final cloudSyncService = context.read<CloudSyncService>();
    await _runBlockingOperation<void>(
      statusText: 'Restoring your cloud backup...',
      task: (token) => cloudSyncService.downloadDataFromCloud(
        forceOverwrite: forceOverwrite,
        credentialEncryptionKey: credentialEncryptionKey,
        cancellationToken: token,
      ),
    );
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
          width: 120,
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
