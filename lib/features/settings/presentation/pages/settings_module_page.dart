import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/blocs/module_navigation_bloc.dart';
import '../../../../core/blocs/theme_cubit.dart';
import '../../../../core/models/app_preferences.dart';
import '../../../../core/services/app_settings_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';

class SettingsModulePage extends StatefulWidget {
  const SettingsModulePage({super.key});

  @override
  State<SettingsModulePage> createState() => _SettingsModulePageState();
}

class _SettingsModulePageState extends State<SettingsModulePage> {
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
                'Global settings now only includes app-wide preferences. Expense and task settings live inside their own modules.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
                    const SizedBox(height: 12),
                    AppSelectField<AppModule>(
                      label: 'Startup module',
                      value: context
                          .watch<ModuleNavigationBloc>()
                          .state
                          .module,
                      options: const <AppSelectOption<AppModule>>[
                        AppSelectOption(
                          value: AppModule.expense,
                          label: 'Expense',
                        ),
                        AppSelectOption(
                          value: AppModule.tasks,
                          label: 'Tasks',
                        ),
                        AppSelectOption(
                          value: AppModule.settings,
                          label: 'Settings',
                        ),
                      ],
                      onChanged: (value) {
                        context.read<ModuleNavigationBloc>().add(
                          ModuleSelected(value),
                        );
                      },
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
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Reminder timing stays inside Expense Settings and Task Settings. This switch only turns all reminders on or off.',
                        style: theme.textTheme.bodyMedium,
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
                                snapshot.data ?? 'Loading...',
                                style: theme.textTheme.bodyMedium,
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
      SnackBar(
        content: Text(
          enabled
              ? 'App notifications enabled.'
              : 'App notifications disabled.',
        ),
      ),
    );
  }

  Future<String> _resolveExportDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, 'exports');
  }
}
