import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_preferences.dart';
import '../../features/credentials/presentation/pages/credential_module_page.dart';
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
              AppModule.credential => 0,
              AppModule.expense => 1,
              AppModule.tasks => 2,
              AppModule.settings => 3,
            },
            children: const <Widget>[
              CredentialModulePage(),
              ExpenseModulePage(),
              TasksModulePage(),
              SettingsModulePage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: switch (state.module) {
              AppModule.credential => 0,
              AppModule.expense => 1,
              AppModule.tasks => 2,
              AppModule.settings => 3,
            },
            onDestinationSelected: (index) {
              context.read<ModuleNavigationBloc>().add(
                ModuleSelected(switch (index) {
                  0 => AppModule.credential,
                  1 => AppModule.expense,
                  2 => AppModule.tasks,
                  _ => AppModule.settings,
                }),
              );
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.vpn_key_outlined),
                selectedIcon: Icon(Icons.vpn_key_rounded),
                label: 'Credential',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Expense',
              ),
              NavigationDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt_rounded),
                label: 'Task',
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
