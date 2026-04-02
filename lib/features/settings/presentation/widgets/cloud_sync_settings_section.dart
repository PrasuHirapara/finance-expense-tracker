import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/app_preferences.dart';
import '../../../../core/models/cloud_sync_models.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/services/firebase_cloud_sync_auth_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../credentials/data/services/credential_service.dart';
import '../../../credentials/presentation/widgets/credential_key_entry_dialog.dart';

class CloudSyncSettingsSection extends StatefulWidget {
  const CloudSyncSettingsSection({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<CloudSyncSettingsSection> createState() =>
      _CloudSyncSettingsSectionState();
}

class _CloudSyncSettingsSectionState extends State<CloudSyncSettingsSection> {
  bool _isSyncing = false;
  bool _isRestoring = false;
  bool _isToggling = false;

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

        return AppPanel(
          child: Column(
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
                              ? 'Firebase cloud backup is available on mobile builds configured with Firebase.'
                              : cloudSync.enabled
                              ? 'Firebase cloud backup is enabled for Credential, Expense, and Task data.'
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: !canUseCloudSync || _isSyncing || _isRestoring
                        ? null
                        : () => unawaited(_syncNow(context)),
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: !canUseCloudSync || _isSyncing || _isRestoring
                        ? null
                        : () => unawaited(_restoreFromCloud(context)),
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Enable Auto Backup',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                !hasFirebaseAccount
                                    ? 'Sign in from the Firebase Account section to enable scheduled Firestore backups.'
                                    : cloudSync.enabled
                                    ? 'Runs a daily background upload near the selected time when the device allows background work.'
                                    : 'Turn on Cloud Sync first to use scheduled backups.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value:
                              cloudSync.enabled && cloudSync.autoBackupEnabled,
                          onChanged:
                              !cloudSync.enabled ||
                                  _isToggling ||
                                  !authService.isAvailable ||
                                  !hasFirebaseAccount
                              ? null
                              : (value) => _toggleAutoBackup(context, value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed:
                          !canUseCloudSync ||
                              !cloudSync.autoBackupEnabled ||
                              _isToggling
                          ? null
                          : () => _pickTime(context),
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(
                        _formatBackupTime(
                          context,
                          TimeOfDay(
                            hour: cloudSync.autoBackupHour,
                            minute: cloudSync.autoBackupMinute,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusSummary(cloudSync),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasFirebaseAccount
                    ? 'Credential titles, keys, and values stay encrypted before upload. Expense and Task backups are stored in your Firebase cloud space for the signed-in account.'
                    : 'You can keep using local storage without login. Sign in only when you want Firestore sync.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Cloud Sync enabled.'
                : 'Cloud Sync disabled and background backup stopped.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update Cloud Sync: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  Future<void> _toggleAutoBackup(BuildContext context, bool enabled) async {
    setState(() {
      _isToggling = true;
    });
    try {
      await context.read<CloudSyncService>().setAutoBackupEnabled(enabled);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'Auto Backup enabled.' : 'Auto Backup disabled.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update Auto Backup: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final current = TimeOfDay(
      hour: widget.preferences.cloudSync.autoBackupHour,
      minute: widget.preferences.cloudSync.autoBackupMinute,
    );
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !context.mounted) {
      return;
    }

    setState(() {
      _isToggling = true;
    });
    try {
      await context.read<CloudSyncService>().scheduleAutoBackup(picked);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auto Backup scheduled for ${_formatBackupTime(context, picked)}.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to schedule Auto Backup: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  Future<void> _syncNow(BuildContext context) async {
    setState(() {
      _isSyncing = true;
    });
    try {
      await context.read<CloudSyncService>().uploadDataToCloud();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cloud backup completed.')));
    } on CloudCredentialEncryptionKeyRequiredException {
      final recovered = await _retrySyncWithCredentialKey(
        context,
        keyWasInvalid: false,
      );
      if (!recovered || !context.mounted) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cloud backup completed.')));
    } on CloudCredentialEncryptionKeyInvalidException {
      final recovered = await _retrySyncWithCredentialKey(
        context,
        keyWasInvalid: true,
      );
      if (!recovered || !context.mounted) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cloud backup completed.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud sync failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    setState(() {
      _isRestoring = true;
    });
    try {
      final service = context.read<CloudSyncService>();
      final check = await service.inspectRestoreState();
      var forceOverwrite = false;
      if (check.isLocalNewer && context.mounted) {
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

      final restored = await _restoreWithCredentialKeyHandling(
        context,
        forceOverwrite: forceOverwrite,
      );
      if (!restored || !context.mounted) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cloud restore completed.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  String _formatBackupTime(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time);
  }

  String _statusSummary(CloudSyncPreferences preferences) {
    final sync = preferences.lastSuccessfulSyncAt;
    final restore = preferences.lastRestoreAt;
    final account = preferences.lastSyncedAccountEmail;
    final parts = <String>[
      if (sync != null) 'Last sync: ${sync.toLocal()}',
      if (restore != null) 'Last restore: ${restore.toLocal()}',
      if (account != null && account.isNotEmpty) 'Account: $account',
    ];
    return parts.isEmpty ? 'No cloud activity yet.' : parts.join(' | ');
  }

  Future<bool> _retrySyncWithCredentialKey(
    BuildContext context, {
    required bool keyWasInvalid,
  }) async {
    final credentialService = context.read<CredentialService>();
    final hasStoredKey = await credentialService.hasEncryptionKey();
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

    if (enteredKey == null || !context.mounted) {
      return false;
    }

    final isValid = await credentialService
        .validateEncryptionKeyAgainstStoredCredentials(enteredKey);
    if (!isValid) {
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That encryption key could not unlock the local credential records.',
          ),
        ),
      );
      return false;
    }

    await credentialService.configureEncryptionKey(enteredKey);
    await context.read<CloudSyncService>().uploadDataToCloud(
      credentialEncryptionKey: enteredKey,
    );
    return true;
  }

  Future<bool> _restoreWithCredentialKeyHandling(
    BuildContext context, {
    required bool forceOverwrite,
  }) async {
    final cloudSyncService = context.read<CloudSyncService>();
    final credentialService = context.read<CredentialService>();

    try {
      await cloudSyncService.downloadDataFromCloud(
        forceOverwrite: forceOverwrite,
      );
      return true;
    } on CloudCredentialEncryptionKeyRequiredException {
      return _promptForCredentialKeyAndRestore(
        context,
        forceOverwrite: forceOverwrite,
        requireConfirmation: !(await credentialService.hasEncryptionKey()),
        reason:
            'Enter your credential encryption key to restore encrypted credential titles from Firestore.',
      );
    } on CloudCredentialEncryptionKeyInvalidException {
      return _promptForCredentialKeyAndRestore(
        context,
        forceOverwrite: forceOverwrite,
        requireConfirmation: false,
        reason:
            'The saved encryption key did not match the cloud credential backup. Enter the correct key to restore those records.',
      );
    }
  }

  Future<bool> _promptForCredentialKeyAndRestore(
    BuildContext context, {
    required bool forceOverwrite,
    required bool requireConfirmation,
    required String reason,
  }) async {
    final enteredKey = await showCredentialKeyEntryDialog(
      context,
      title: 'Credential Key Required',
      reason: reason,
      requireConfirmation: requireConfirmation,
      submitLabel: requireConfirmation ? 'Save & Restore' : 'Restore',
    );

    if (enteredKey == null || !context.mounted) {
      return false;
    }

    await context.read<CloudSyncService>().downloadDataFromCloud(
      forceOverwrite: forceOverwrite,
      credentialEncryptionKey: enteredKey,
    );
    await context.read<CredentialService>().configureEncryptionKey(enteredKey);
    return true;
  }
}
