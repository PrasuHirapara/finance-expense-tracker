import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/metric_tile.dart';
import '../blocs/bank/bank_bloc.dart';
import '../blocs/expense/expense_bloc.dart';

class ExpenseModulePage extends StatefulWidget {
  const ExpenseModulePage({super.key});

  @override
  State<ExpenseModulePage> createState() => _ExpenseModulePageState();
}

class _ExpenseModulePageState extends State<ExpenseModulePage> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const ExpenseSubscriptionRequested());
    context.read<BankBloc>().add(const BanksSubscriptionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, expenseState) {
        return BlocBuilder<BankBloc, BankState>(
          builder: (context, bankState) {
            final dashboard = expenseState.dashboard;
            final width = MediaQuery.of(context).size.width;
            final crossAxisCount = width >= 1150 ? 4 : 2;

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<ExpenseBloc>().add(
                    ExpenseSubscriptionRequested(
                      bankId: expenseState.selectedBankId,
                    ),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Expense Module',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Track expenses, borrowed/lent entries, and bank-linked spending.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.expenseAnalytics),
                          icon: const Icon(Icons.insights_rounded),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.expenseSettings),
                          icon: const Icon(Icons.settings_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: expenseState.selectedBankId,
                            decoration: const InputDecoration(
                              labelText: 'Filter by bank',
                            ),
                            items: <DropdownMenuItem<int?>>[
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('All Banks'),
                              ),
                              ...bankState.banks.map(
                                (bank) => DropdownMenuItem<int?>(
                                  value: bank.id,
                                  child: Text(bank.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              context.read<ExpenseBloc>().add(
                                ExpenseBankFilterChanged(value),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.expenseAdd),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Expense'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (dashboard != null) ...<Widget>[
                      AppPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Today\'s Expense',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppConstants.currency(dashboard.todaysExpense),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Weekly net: ${AppConstants.currency(dashboard.weeklyNet)}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: width >= 1150 ? 1.45 : 1.2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          MetricTile(
                            label: 'Weekly Expense',
                            value: AppConstants.currency(
                              dashboard.weeklyExpense,
                            ),
                            icon: Icons.arrow_circle_down_rounded,
                            color: const Color(0xFFC0392B),
                          ),
                          MetricTile(
                            label: 'Weekly Credit',
                            value: AppConstants.currency(
                              dashboard.weeklyCredit,
                            ),
                            icon: Icons.arrow_circle_up_rounded,
                            color: const Color(0xFF1F8B4C),
                          ),
                          MetricTile(
                            label: 'Weekly Debit',
                            value: AppConstants.currency(dashboard.weeklyDebit),
                            icon: Icons.payments_rounded,
                            color: const Color(0xFF8E44AD),
                          ),
                          MetricTile(
                            label: 'Recent Entries',
                            value: dashboard.recentEntries.length.toString(),
                            icon: Icons.receipt_long_rounded,
                            color: const Color(0xFF2E86DE),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AppPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Recent Entries',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            ...dashboard.recentEntries.map(
                              (entry) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: Color(
                                    entry.category.colorValue,
                                  ).withValues(alpha: 0.14),
                                  child: Icon(
                                    IconData(
                                      entry.category.iconCodePoint,
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    color: Color(entry.category.colorValue),
                                  ),
                                ),
                                title: Text(entry.title),
                                subtitle: Text(
                                  [
                                    entry.category.name,
                                    if (entry.bank != null) entry.bank!.name,
                                    entry.type.toUpperCase(),
                                  ].join(' • '),
                                ),
                                trailing: Text(
                                  '${entry.isCredit ? '+' : '-'}${AppConstants.currency(entry.amount)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
