import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/bootstrap/app_session.dart';
import 'core/blocs/module_navigation_bloc.dart';
import 'core/blocs/theme_cubit.dart';
import 'core/models/app_preferences.dart';
import 'core/router/app_router.dart';
import 'core/services/app_data_reset_service.dart';
import 'core/services/app_settings_repository.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/firebase_cloud_sync_auth_service.dart';
import 'core/services/file_launcher_service.dart';
import 'core/services/module_data_import_service.dart';
import 'core/services/module_data_export_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/reminder_settings_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'data/database/app_database.dart';
import 'domain/repositories/export_repository.dart';
import 'domain/repositories/finance_repository.dart';
import 'features/credentials/data/repositories/credential_repository.dart';
import 'features/credentials/data/services/credential_service.dart';
import 'features/expense/data/repositories/expense_repository.dart';
import 'features/expense/presentation/blocs/bank/bank_bloc.dart';
import 'features/expense/presentation/blocs/expense/expense_bloc.dart';
import 'features/tasks/data/repositories/task_repository.dart';
import 'features/tasks/data/repositories/task_category_repository.dart';
import 'features/tasks/presentation/blocs/tasks/task_bloc.dart';

class DailyUseApp extends StatefulWidget {
  const DailyUseApp({super.key});

  @override
  State<DailyUseApp> createState() => _DailyUseAppState();
}

class _DailyUseAppState extends State<DailyUseApp> with WidgetsBindingObserver {
  late final AppSession _session;
  late final Future<void> _bootstrap;
  AppPreferences _appPreferences = const AppPreferences();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = AppSession.create();
    _bootstrap = _bootstrapApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_session.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_session.appSettingsRepository.flush());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<AppDatabase>.value(value: _session.database),
        RepositoryProvider<CredentialRepository>.value(
          value: _session.credentialRepository,
        ),
        RepositoryProvider<CredentialService>.value(
          value: _session.credentialService,
        ),
        RepositoryProvider<ExpenseRepository>.value(
          value: _session.expenseRepository,
        ),
        RepositoryProvider<FinanceRepository>.value(
          value: _session.financeRepository,
        ),
        RepositoryProvider<ExportRepository>.value(
          value: _session.exportRepository,
        ),
        RepositoryProvider<TaskRepository>.value(
          value: _session.taskRepository,
        ),
        RepositoryProvider<TaskCategoryRepository>.value(
          value: _session.taskCategoryRepository,
        ),
        RepositoryProvider<AppSettingsRepository>.value(
          value: _session.appSettingsRepository,
        ),
        RepositoryProvider<ReminderSettingsRepository>.value(
          value: _session.reminderSettingsRepository,
        ),
        RepositoryProvider<NotificationService>.value(
          value: _session.notificationService,
        ),
        RepositoryProvider<FirebaseCloudSyncAuthService>.value(
          value: _session.firebaseCloudSyncAuthService,
        ),
        RepositoryProvider<CloudSyncService>.value(
          value: _session.cloudSyncService,
        ),
        RepositoryProvider<AppDataResetService>.value(
          value: _session.appDataResetService,
        ),
        RepositoryProvider<FileLauncherService>.value(
          value: _session.fileLauncherService,
        ),
        RepositoryProvider<ModuleDataExportService>.value(
          value: _session.moduleDataExportService,
        ),
        RepositoryProvider<ModuleDataImportService>.value(
          value: _session.moduleDataImportService,
        ),
      ],
      child: FutureBuilder<void>(
        future: _bootstrap,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _appPreferences.themeMode,
              restorationScopeId: 'daily_use_app',
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: _appPreferences.themeMode,
              restorationScopeId: 'daily_use_app',
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to initialise the app.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          return MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<ThemeCubit>(
                create: (_) => ThemeCubit(
                  settingsRepository: _session.appSettingsRepository,
                  initialThemeMode: _appPreferences.themeMode,
                ),
              ),
              BlocProvider<ModuleNavigationBloc>(
                create: (_) => ModuleNavigationBloc(),
              ),
              BlocProvider<ExpenseBloc>(
                create: (context) => ExpenseBloc(
                  context.read<ExpenseRepository>(),
                  context.read<AppSettingsRepository>(),
                )..add(const ExpenseRestoreRequested()),
              ),
              BlocProvider<BankBloc>(
                create: (context) =>
                    BankBloc(context.read<ExpenseRepository>())
                      ..add(const BanksSubscriptionRequested()),
              ),
              BlocProvider<TaskBloc>(
                create: (context) =>
                    TaskBloc(context.read<TaskRepository>())
                      ..add(const TasksSubscriptionRequested()),
              ),
            ],
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return MaterialApp(
                  title: 'Daily Use',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: themeMode,
                  restorationScopeId: 'daily_use_app',
                  onGenerateRoute: AppRouter.onGenerateRoute,
                  home: const AppShell(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _bootstrapApp() async {
    final appPreferences = await _session.bootstrap();
    if (mounted) {
      setState(() {
        _appPreferences = appPreferences;
      });
    } else {
      _appPreferences = appPreferences;
    }
  }
}
