import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/blocs/module_navigation_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';
import 'data/database/app_database.dart';
import 'features/expense/data/repositories/expense_repository.dart';
import 'features/expense/presentation/blocs/bank/bank_bloc.dart';
import 'features/expense/presentation/blocs/expense/expense_bloc.dart';
import 'features/tasks/data/repositories/task_repository.dart';
import 'features/tasks/presentation/blocs/tasks/task_bloc.dart';

class FinanceAnalyticsApp extends StatefulWidget {
  const FinanceAnalyticsApp({super.key});

  @override
  State<FinanceAnalyticsApp> createState() => _FinanceAnalyticsAppState();
}

class _FinanceAnalyticsAppState extends State<FinanceAnalyticsApp> {
  late final AppDatabase _database;
  late final ExpenseRepository _expenseRepository;
  late final TaskRepository _taskRepository;
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _expenseRepository = ExpenseRepository(_database);
    _taskRepository = TaskRepository(_database);
    _bootstrap = _expenseRepository.seedDefaults();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<Object>>[
        RepositoryProvider<AppDatabase>.value(value: _database),
        RepositoryProvider<ExpenseRepository>.value(value: _expenseRepository),
        RepositoryProvider<TaskRepository>.value(value: _taskRepository),
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
            child: MaterialApp(
              title: 'Ledger Lens',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              onGenerateRoute: AppRouter.onGenerateRoute,
              home: const AppShell(),
            ),
          );
        },
      ),
    );
  }
}
