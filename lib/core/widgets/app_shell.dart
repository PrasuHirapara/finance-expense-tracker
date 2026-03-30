import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/expense/presentation/pages/expense_module_page.dart';
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
            index: state.module == AppModule.expense ? 0 : 1,
            children: const <Widget>[ExpenseModulePage(), TasksModulePage()],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.module == AppModule.expense ? 0 : 1,
            onDestinationSelected: (index) {
              context.read<ModuleNavigationBloc>().add(
                ModuleSelected(
                  index == 0 ? AppModule.expense : AppModule.tasks,
                ),
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
            ],
          ),
        );
      },
    );
  }
}
