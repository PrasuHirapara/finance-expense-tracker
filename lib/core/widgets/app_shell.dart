import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_preferences.dart';
import '../../features/expense/presentation/pages/expense_module_page.dart';
import '../../features/settings/presentation/pages/settings_module_page.dart';
import '../../features/tasks/presentation/pages/tasks_module_page.dart';
import '../blocs/module_navigation_bloc.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModuleNavigationBloc, ModuleNavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: IndexedStack(
            index: switch (state.module) {
              AppModule.expense => 0,
              AppModule.tasks => 1,
              AppModule.settings => 2,
            },
            children: const <Widget>[
              ExpenseModulePage(),
              TasksModulePage(),
              SettingsModulePage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: switch (state.module) {
              AppModule.expense => 0,
              AppModule.tasks => 1,
              AppModule.settings => 2,
            },
            onDestinationSelected: (index) {
              context.read<ModuleNavigationBloc>().add(
                ModuleSelected(switch (index) {
                  0 => AppModule.expense,
                  1 => AppModule.tasks,
                  _ => AppModule.settings,
                }),
              );
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Expense',
              ),
              NavigationDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt_rounded),
                label: 'Tasks',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
