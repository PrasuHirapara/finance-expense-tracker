import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/blocs/theme_cubit.dart';
import '../../../../core/models/app_preferences.dart';
import '../../../../core/services/app_data_reset_service.dart';
import '../../../../core/services/app_settings_repository.dart';
import '../../../../core/services/google_drive_auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../widgets/cloud_sync_settings_section.dart';

class SettingsModulePage extends StatefulWidget {
  const SettingsModulePage({super.key});

  @override
  State<SettingsModulePage> createState() => _SettingsModulePageState();
}

class _SettingsModulePageState extends State<SettingsModulePage> {
  late final Future<String> _exportDirectoryPath;
  bool _isGoogleAuthLoading = false;
  String? _googleAccountEmail;

  @override
  void initState() {
    super.initState();
    _exportDirectoryPath = _resolveExportDirectoryPath();
    unawaited(_restoreGoogleSession());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsRepository = context.read<AppSettingsRepository>();

    return SafeArea(
      child: StreamBuilder<AppPreferences>(
        stream: settingsRepository.watchSettings(),
        builder: (context, snapshot) {
          final preferences = snapshot.data ?? const AppPreferences();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: <Widget>[
              Text('Settings', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Global settings only includes app-wide preferences. Expense, credential, and task settings live inside their own tabs.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Google Drive Account',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _googleAccountEmail == null
                          ? 'Sign in with Google first so Drive sync can upload and restore your backup data.'
                          : 'Connected Google account used for Drive sync.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _googleAccountEmail ?? 'Not connected',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              FilledButton.icon(
                                onPressed: _isGoogleAuthLoading
                                    ? null
                                    : () => _signInWithGoogle(context),
                                icon: Icon(
                                  _googleAccountEmail == null
                                      ? Icons.login_rounded
                                      : Icons.refresh_rounded,
                                ),
                                label: Text(
                                  _isGoogleAuthLoading
                                      ? 'Please wait...'
                                      : _googleAccountEmail == null
                                      ? 'Continue with Google'
                                      : 'Switch Google Account',
                                ),
                              ),
                              if (_googleAccountEmail != null)
                                TextButton(
                                  onPressed: _isGoogleAuthLoading
                                      ? null
                                      : () => _signOutGoogle(context),
                                  child: const Text('Sign Out'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Appearance', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Theme and startup preferences for the full app.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Theme',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.watch<ThemeCubit>().state ==
                                          ThemeMode.dark
                                      ? 'Dark theme is active'
                                      : 'Light theme is active',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value:
                                context.watch<ThemeCubit>().state ==
                                ThemeMode.dark,
                            onChanged: (value) {
                              context.read<ThemeCubit>().setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppPanel(
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
                                'Notifications',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                preferences.notificationsEnabled
                                    ? 'Module reminders are enabled app-wide.'
                                    : 'All daily reminders are paused for the app.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: preferences.notificationsEnabled,
                          onChanged: (value) {
                            _updateNotifications(context, value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Storage', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Exports are stored locally in the app documents folder.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<String>(
                      future: _exportDirectoryPath,
                      builder: (context, snapshot) {
                        final defaultPath = snapshot.data ?? 'Loading...';
                        final activePath =
                            preferences.exportDirectoryPath ?? defaultPath;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Export folder',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                activePath,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: <Widget>[
                                  FilledButton.tonalIcon(
                                    onPressed: snapshot.hasData
                                        ? () => _chooseExportFolder(context)
                                        : null,
                                    icon: const Icon(Icons.folder_open_rounded),
                                    label: const Text('Choose Folder'),
                                  ),
                                  if (preferences.exportDirectoryPath != null)
                                    TextButton(
                                      onPressed: () =>
                                          _resetExportFolder(context),
                                      child: const Text('Use Default'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              CloudSyncSettingsSection(preferences: preferences),
              const SizedBox(height: 18),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Danger Zone', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Delete all Credential, Expense, and Task data. If Cloud Sync is enabled, the full Daily Use folder is also removed from Google Drive.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _deleteAllData(context),
                      style: FilledButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Delete All Data'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateNotifications(BuildContext context, bool enabled) async {
    final settingsRepository = context.read<AppSettingsRepository>();
    final notificationService = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);

    await settingsRepository.updateNotificationsEnabled(enabled);
    if (enabled) {
      await notificationService.scheduleDailyReminders();
    } else {
      await notificationService.cancelDailyReminders();
    }

    if (!context.mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'App notifications enabled.'
              : 'App notifications disabled.',
        ),
      ),
    );
  }

  Future<void> _chooseExportFolder(BuildContext context) async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose export folder',
    );

    if (selectedPath == null || !context.mounted) {
      return;
    }

    await context.read<AppSettingsRepository>().updateExportDirectoryPath(
      selectedPath,
    );
  }

  Future<void> _resetExportFolder(BuildContext context) async {
    await context.read<AppSettingsRepository>().updateExportDirectoryPath(null);
  }

  Future<void> _restoreGoogleSession() async {
    try {
      final email = await context
          .read<GoogleDriveAuthService>()
          .restoreCurrentUserEmail();
      if (!mounted) {
        return;
      }
      setState(() {
        _googleAccountEmail = email;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _googleAccountEmail = null;
      });
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() {
      _isGoogleAuthLoading = true;
    });
    try {
      final account = await context
          .read<GoogleDriveAuthService>()
          .authenticateInteractively();
      if (!context.mounted) {
        return;
      }
      setState(() {
        _googleAccountEmail = account.email;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signed in as ${account.email}.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleAuthLoading = false;
        });
      }
    }
  }

  Future<void> _signOutGoogle(BuildContext context) async {
    setState(() {
      _isGoogleAuthLoading = true;
    });
    try {
      await context.read<GoogleDriveAuthService>().signOut();
      if (!context.mounted) {
        return;
      }
      setState(() {
        _googleAccountEmail = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google account signed out.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to sign out: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleAuthLoading = false;
        });
      }
    }
  }

  Future<String> _resolveExportDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'exports');
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This deletes all Credential, Expense, and Task data. Continue?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await context.read<AppDataResetService>().deleteAllData();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All app data deleted.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete all data: $error')),
      );
    }
  }
}
