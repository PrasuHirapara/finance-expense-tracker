import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/blocs/module_navigation_bloc.dart';
import 'core/blocs/theme_cubit.dart';
import 'core/models/app_preferences.dart';
import 'core/router/app_router.dart';
import 'core/services/app_data_reset_service.dart';
import 'core/services/app_settings_repository.dart';
import 'core/services/cloud_sync_payload_service.dart';
import 'core/services/cloud_sync_scheduler.dart';
import 'core/services/cloud_sync_security_service.dart';
import 'core/services/cloud_sync_service.dart';
import 'core/services/credential_crypto_service.dart';
import 'core/services/credential_security_service.dart';
import 'core/services/file_launcher_service.dart';
import 'core/services/google_drive_api_service.dart';
import 'core/services/google_drive_auth_service.dart';
import 'core/services/module_data_import_service.dart';
import 'core/services/module_data_export_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/reminder_settings_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'data/database/app_database.dart';
import 'data/repositories/export_repository_impl.dart';
import 'data/repositories/finance_repository_impl.dart';
import 'data/services/export/csv_export_service.dart';
import 'data/services/export/pdf_export_service.dart';
import 'data/services/seed_service.dart';
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
  late final AppDatabase _database;
  late final AppSettingsRepository _appSettingsRepository;
  late final ExpenseRepository _expenseRepository;
  late final CredentialRepository _credentialRepository;
  late final CredentialCryptoService _credentialCryptoService;
  late final CredentialSecurityService _credentialSecurityService;
  late final CloudSyncSecurityService _cloudSyncSecurityService;
  late final CredentialService _credentialService;
  late final FinanceRepository _financeRepository;
  late final ExportRepository _exportRepository;
  late final TaskRepository _taskRepository;
  late final NotificationService _notificationService;
  late final FileLauncherService _fileLauncherService;
  late final ModuleDataExportService _moduleDataExportService;
  late final ModuleDataImportService _moduleDataImportService;
  late final TaskCategoryRepository _taskCategoryRepository;
  late final ReminderSettingsRepository _reminderSettingsRepository;
  late final CloudSyncScheduler _cloudSyncScheduler;
  late final GoogleDriveAuthService _googleDriveAuthService;
  late final CloudSyncService _cloudSyncService;
  late final AppDataResetService _appDataResetService;
  late final Future<void> _bootstrap;
  AppPreferences _appPreferences = const AppPreferences();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _database = AppDatabase();
    _appSettingsRepository = AppSettingsRepository();
    _expenseRepository = ExpenseRepository(_database);
    _credentialRepository = CredentialRepository(_database);
    _credentialCryptoService = CredentialCryptoService();
    _credentialSecurityService = CredentialSecurityService();
    _cloudSyncSecurityService = CloudSyncSecurityService();
    _credentialService = CredentialService(
      repository: _credentialRepository,
      cryptoService: _credentialCryptoService,
      securityService: _credentialSecurityService,
    );
    _financeRepository = FinanceRepositoryImpl(
      database: _database,
      seedService: SeedService(_database),
    );
    _exportRepository = ExportRepositoryImpl(
      csvExportService: CsvExportService(),
      pdfExportService: PdfExportService(),
    );
    _taskRepository = TaskRepository(_database);
    _taskCategoryRepository = TaskCategoryRepository(_taskRepository);
    _reminderSettingsRepository = ReminderSettingsRepository();
    _notificationService = NotificationService(_reminderSettingsRepository);
    _cloudSyncScheduler = CloudSyncScheduler();
    _googleDriveAuthService = GoogleDriveAuthService();
    _fileLauncherService = FileLauncherService();
    _moduleDataExportService = ModuleDataExportService(_appSettingsRepository);
    _moduleDataImportService = ModuleDataImportService(
      database: _database,
      appSettingsRepository: _appSettingsRepository,
      credentialCryptoService: _credentialCryptoService,
    );
    _cloudSyncService = CloudSyncService(
      appSettingsRepository: _appSettingsRepository,
      authService: _googleDriveAuthService,
      driveApiService: GoogleDriveApiService(),
      payloadService: CloudSyncPayloadService(
        database: _database,
        taskCategoryRepository: _taskCategoryRepository,
        credentialCryptoService: _credentialCryptoService,
        cloudSyncSecurityService: _cloudSyncSecurityService,
      ),
      scheduler: _cloudSyncScheduler,
    );
    _appDataResetService = AppDataResetService(
      credentialService: _credentialService,
      expenseRepository: _expenseRepository,
      taskRepository: _taskRepository,
      taskCategoryRepository: _taskCategoryRepository,
      reminderSettingsRepository: _reminderSettingsRepository,
      appSettingsRepository: _appSettingsRepository,
      notificationService: _notificationService,
      cloudSyncService: _cloudSyncService,
    );
    _bootstrap = _bootstrapApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reminderSettingsRepository.dispose();
    unawaited(_appSettingsRepository.dispose());
    unawaited(_appSettingsRepository.flush());
    _database.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_appSettingsRepository.flush());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<AppDatabase>.value(value: _database),
        RepositoryProvider<CredentialRepository>.value(
          value: _credentialRepository,
        ),
        RepositoryProvider<CredentialService>.value(value: _credentialService),
        RepositoryProvider<ExpenseRepository>.value(value: _expenseRepository),
        RepositoryProvider<FinanceRepository>.value(value: _financeRepository),
        RepositoryProvider<ExportRepository>.value(value: _exportRepository),
        RepositoryProvider<TaskRepository>.value(value: _taskRepository),
        RepositoryProvider<TaskCategoryRepository>.value(
          value: _taskCategoryRepository,
        ),
        RepositoryProvider<AppSettingsRepository>.value(
          value: _appSettingsRepository,
        ),
        RepositoryProvider<ReminderSettingsRepository>.value(
          value: _reminderSettingsRepository,
        ),
        RepositoryProvider<NotificationService>.value(
          value: _notificationService,
        ),
        RepositoryProvider<GoogleDriveAuthService>.value(
          value: _googleDriveAuthService,
        ),
        RepositoryProvider<CloudSyncService>.value(value: _cloudSyncService),
        RepositoryProvider<AppDataResetService>.value(
          value: _appDataResetService,
        ),
        RepositoryProvider<FileLauncherService>.value(
          value: _fileLauncherService,
        ),
        RepositoryProvider<ModuleDataExportService>.value(
          value: _moduleDataExportService,
        ),
        RepositoryProvider<ModuleDataImportService>.value(
          value: _moduleDataImportService,
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
                  settingsRepository: _appSettingsRepository,
                  initialThemeMode: _appPreferences.themeMode,
                ),
              ),
              BlocProvider<ModuleNavigationBloc>(
                create: (_) => ModuleNavigationBloc(),
              ),
              BlocProvider<ExpenseBloc>(
                create: (context) =>
                    ExpenseBloc(context.read<ExpenseRepository>())
                      ..add(const ExpenseSubscriptionRequested()),
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
    final appPreferences = await _appSettingsRepository.getSettings();
    if (mounted) {
      setState(() {
        _appPreferences = appPreferences;
      });
    } else {
      _appPreferences = appPreferences;
    }

    await _expenseRepository.seedDefaults();
    await _taskCategoryRepository.ensureSeeded();
    await _notificationService.initialize();
    if (_appPreferences.notificationsEnabled) {
      await _notificationService.scheduleDailyReminders();
    } else {
      await _notificationService.cancelDailyReminders();
    }
    if (_appPreferences.cloudSync.enabled &&
        _appPreferences.cloudSync.autoBackupEnabled) {
      await _cloudSyncService.scheduleAutoBackup(
        TimeOfDay(
          hour: _appPreferences.cloudSync.autoBackupHour,
          minute: _appPreferences.cloudSync.autoBackupMinute,
        ),
      );
    } else {
      await _cloudSyncScheduler.cancel();
    }
  }
}
