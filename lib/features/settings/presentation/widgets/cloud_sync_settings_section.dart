import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/app_preferences.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../shared/widgets/app_panel.dart';

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
    final cloudSync = widget.preferences.cloudSync;

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
                      cloudSync.enabled
                          ? 'Google Drive backup is enabled for Credential, Expense, and Task data.'
                          : 'Enable Drive sync to upload backups and restore from cloud.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: cloudSync.enabled,
                onChanged: _isToggling
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
                onPressed: !cloudSync.enabled || _isSyncing || _isRestoring
                    ? null
                    : () => unawaited(_syncNow(context)),
                icon: const Icon(Icons.cloud_upload_rounded),
                label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
              ),
              FilledButton.tonalIcon(
                onPressed: !cloudSync.enabled || _isSyncing || _isRestoring
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
                            cloudSync.enabled
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
                      value: cloudSync.enabled && cloudSync.autoBackupEnabled,
                      onChanged: !cloudSync.enabled || _isToggling
                          ? null
                          : (value) => _toggleAutoBackup(context, value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      !cloudSync.enabled ||
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
            'Credential backups are encrypted before upload. Expense and Task backups are uploaded as plain JSON. Google OAuth platform configuration is still required for the sign-in flow.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
      await context.read<CloudSyncService>().uploadDataToDrive();
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

      await service.downloadDataFromDrive(forceOverwrite: forceOverwrite);
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
}
