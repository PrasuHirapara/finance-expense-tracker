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
import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/firebase_cloud_sync_auth_service.dart';
import '../../../../core/services/firebase_runtime_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/cancellable_blocking_overlay.dart';
import '../../../auth/presentation/pages/auth_page.dart';
import '../widgets/cloud_sync_settings_section.dart';

class UserSettingsInfoPage extends StatefulWidget {
  const UserSettingsInfoPage({super.key});

  @override
  State<UserSettingsInfoPage> createState() => _UserSettingsInfoPageState();
}

class _UserSettingsInfoPageState extends State<UserSettingsInfoPage> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<FirebaseCloudSyncAuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('User Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildFirebaseAccountContent(context, theme, authService),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _deleteAllData(context),
                    style: FilledButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('Delete All Data'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseAccountContent(
    BuildContext context,
    ThemeData theme,
    FirebaseCloudSyncAuthService authService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Firebase Account', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.42,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: StreamBuilder<FirebaseCloudSyncAccount?>(
            stream: authService.authStateChanges(),
            initialData: authService.currentAccount,
            builder: (context, snapshot) {
              final account = snapshot.data;
              final providerLabel = _providerSummary(account);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    account?.displayName?.trim().isNotEmpty == true
                        ? account!.displayName!.trim()
                        : account?.email ?? 'Not connected',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account?.email ?? 'No active Firebase session.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    providerLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!authService.isAvailable) ...<Widget>[
                    Text(
                      '$firebaseConfigMissingMessage Login and cloud backup are disabled on this build.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (authService.isAvailable && account == null)
                    FilledButton.icon(
                      onPressed: () => _openFirebaseAuthPage(context),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Login or Sign Up'),
                    ),
                  if (authService.isAvailable && account != null)
                    FilledButton.tonalIcon(
                      onPressed: _isSigningOut
                          ? null
                          : () => _signOutFirebaseAccount(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        _isSigningOut ? 'Signing Out...' : 'Sign Out',
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _providerSummary(FirebaseCloudSyncAccount? account) {
    if (account == null || account.providerIds.isEmpty) {
      return 'Provider: Firebase Authentication';
    }

    final labels = account.providerIds
        .map((providerId) {
          return switch (providerId) {
            'google.com' => 'Google',
            'password' => 'Email and Password',
            _ => providerId,
          };
        })
        .join(' | ');

    return 'Provider: $labels';
  }

  Future<void> _signOutFirebaseAccount(BuildContext context) async {
    setState(() {
      _isSigningOut = true;
    });
    try {
      await runWithCancellableBlockingOverlay<void>(
        context: context,
        title: 'Signing out',
        statusText: 'Signing out of your Firebase account...',
        task: (token) => context.read<FirebaseCloudSyncAuthService>().signOut(
          cancellationToken: token,
        ),
      );
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Firebase account signed out.',
      );
    } on AppTaskCancelledException {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Sign out canceled.',
        type: AppSnackBarType.warning,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to sign out: $error',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
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
      showAppSnackBar(
        context,
        message: 'All app data deleted.',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to delete all data: $error',
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _openFirebaseAuthPage(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const AuthPage(closeOnSuccess: true),
      ),
    );
  }
}

class AppSettingsInfoPage extends StatefulWidget {
  const AppSettingsInfoPage({super.key});

  @override
  State<AppSettingsInfoPage> createState() => _AppSettingsInfoPageState();
}

class _AppSettingsInfoPageState extends State<AppSettingsInfoPage> {
  late final Future<String> _exportDirectoryPath;

  @override
  void initState() {
    super.initState();
    _exportDirectoryPath = _resolveExportDirectoryPath();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsRepository = context.read<AppSettingsRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: StreamBuilder<AppPreferences>(
        stream: settingsRepository.watchSettings(),
        builder: (context, snapshot) {
          final preferences = snapshot.data ?? const AppPreferences();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: <Widget>[
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                                  'Notifications',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
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
                                'Storage',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Exports are stored locally in the app documents folder.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Export folder',
                                style: theme.textTheme.titleSmall,
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
      buildAppSnackBar(
        context,
        message: enabled
            ? 'App notifications enabled.'
            : 'App notifications disabled.',
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

  Future<String> _resolveExportDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'exports');
  }
}

class BackupSettingsInfoPage extends StatelessWidget {
  const BackupSettingsInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepository = context.read<AppSettingsRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Backup Settings')),
      body: StreamBuilder<AppPreferences>(
        stream: settingsRepository.watchSettings(),
        builder: (context, snapshot) {
          final preferences = snapshot.data ?? const AppPreferences();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: <Widget>[
              CloudSyncSettingsSection(preferences: preferences),
            ],
          );
        },
      ),
    );
  }
}
