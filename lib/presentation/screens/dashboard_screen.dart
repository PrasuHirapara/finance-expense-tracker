import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/repositories/finance_repository.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/entry_list_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/summary_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const String routeName = 'dashboard';
  static const String routePath = '/dashboard';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (context) =>
          DashboardCubit(context.read<FinanceRepository>())..initialize(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.loading ||
              state.snapshot == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == DashboardStatus.failure) {
            return Center(child: Text(state.errorMessage ?? 'Unable to load.'));
          }

          final snapshot = state.snapshot!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              final tileCount = wide ? 5 : 2;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track today, review the week, and stay ahead of cash flow.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Today\'s Expense',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppConstants.currency(snapshot.todaysExpense),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Weekly overview: ${AppConstants.currency(snapshot.weeklyExpense)} spent and ${AppConstants.currency(snapshot.weeklyNet)} net.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: tileCount,
                      childAspectRatio: wide ? 1.35 : 1.25,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: <Widget>[
                        SummaryTile(
                          title: 'Weekly Expense',
                          value: AppConstants.currency(snapshot.weeklyExpense),
                          icon: Icons.arrow_circle_down_rounded,
                          color: const Color(0xFFC0392B),
                        ),
                        SummaryTile(
                          title: 'Weekly Credit',
                          value: AppConstants.currency(snapshot.weeklyCredit),
                          icon: Icons.arrow_circle_up_rounded,
                          color: const Color(0xFF1F8B4C),
                        ),
                        SummaryTile(
                          title: 'Weekly Debit',
                          value: AppConstants.currency(snapshot.weeklyDebit),
                          icon: Icons.payments_outlined,
                          color: const Color(0xFF8E44AD),
                        ),
                        SummaryTile(
                          title: 'Borrowed',
                          value: AppConstants.currency(snapshot.weeklyBorrowed),
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF2E86DE),
                        ),
                        SummaryTile(
                          title: 'Lent',
                          value: AppConstants.currency(snapshot.weeklyLent),
                          icon: Icons.savings_rounded,
                          color: const Color(0xFF16A085),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Recent Activity',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${snapshot.categoryCount} categories',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (snapshot.recentEntries.isEmpty)
                            const EmptyState(
                              title: 'No entries yet',
                              message:
                                  'Add your first transaction to populate the dashboard.',
                              icon: Icons.receipt_long_rounded,
                            )
                          else
                            ...snapshot.recentEntries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: EntryListTile(entry: entry),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
