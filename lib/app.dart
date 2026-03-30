import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/blocs/module_navigation_bloc.dart';
import 'core/blocs/theme_cubit.dart';
import 'core/router/app_router.dart';
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

class _DailyUseAppState extends State<DailyUseApp> {
  late final AppDatabase _database;
  late final ExpenseRepository _expenseRepository;
  late final FinanceRepository _financeRepository;
  late final ExportRepository _exportRepository;
  late final TaskRepository _taskRepository;
  late final NotificationService _notificationService;
  late final TaskCategoryRepository _taskCategoryRepository;
  late final ReminderSettingsRepository _reminderSettingsRepository;
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _expenseRepository = ExpenseRepository(_database);
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
    _bootstrap = _bootstrapApp();
  }

  @override
  void dispose() {
    _reminderSettingsRepository.dispose();
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<AppDatabase>.value(value: _database),
        RepositoryProvider<ExpenseRepository>.value(value: _expenseRepository),
        RepositoryProvider<FinanceRepository>.value(value: _financeRepository),
        RepositoryProvider<ExportRepository>.value(value: _exportRepository),
        RepositoryProvider<TaskRepository>.value(value: _taskRepository),
        RepositoryProvider<TaskCategoryRepository>.value(
          value: _taskCategoryRepository,
        ),
        RepositoryProvider<ReminderSettingsRepository>.value(
          value: _reminderSettingsRepository,
        ),
        RepositoryProvider<NotificationService>.value(
          value: _notificationService,
        ),
      ],
      child: FutureBuilder<void>(
        future: _bootstrap,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
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
              BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
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
    await _expenseRepository.seedDefaults();
    await _taskCategoryRepository.ensureSeeded();
    await _notificationService.initialize();
    await _notificationService.scheduleDailyReminders();
  }
}
