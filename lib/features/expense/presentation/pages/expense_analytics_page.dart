import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/analytics_models.dart';
import '../../../../presentation/widgets/charts/borrowed_lent_bar_chart.dart';
import '../../../../presentation/widgets/charts/category_pie_chart.dart';
import '../../../../presentation/widgets/charts/trend_line_chart.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/metric_tile.dart';
import '../../domain/models/expense_models.dart';
import '../blocs/bank/bank_bloc.dart';
import '../blocs/expense_analytics/expense_analytics_bloc.dart';

class ExpenseAnalyticsPage extends StatelessWidget {
  const ExpenseAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Analytics')),
      body: BlocBuilder<ExpenseAnalyticsBloc, ExpenseAnalyticsState>(
        builder: (context, state) {
          return BlocBuilder<BankBloc, BankState>(
            builder: (context, bankState) {
              final analytics = state.analytics;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SegmentedButton<ExpenseAnalyticsWindow>(
                          segments: ExpenseAnalyticsWindow.values
                              .map(
                                (window) =>
                                    ButtonSegment<ExpenseAnalyticsWindow>(
                                      value: window,
                                      label: Text(window.name.toUpperCase()),
                                    ),
                              )
                              .toList(growable: false),
                          selected: <ExpenseAnalyticsWindow>{state.window},
                          onSelectionChanged: (selection) {
                            context.read<ExpenseAnalyticsBloc>().add(
                              ExpenseAnalyticsWindowChanged(selection.first),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: state.selectedBankId,
                    decoration: const InputDecoration(labelText: 'Bank filter'),
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
                      context.read<ExpenseAnalyticsBloc>().add(
                        ExpenseAnalyticsBankChanged(value),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (analytics != null) ...<Widget>[
                    GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width >= 1100
                          ? 4
                          : 2,
                      childAspectRatio: 1.35,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: <Widget>[
                        MetricTile(
                          label: 'Credit',
                          value: AppConstants.currency(analytics.totalCredit),
                          icon: Icons.arrow_circle_up_rounded,
                          color: const Color(0xFF1F8B4C),
                        ),
                        MetricTile(
                          label: 'Debit',
                          value: AppConstants.currency(analytics.totalDebit),
                          icon: Icons.arrow_circle_down_rounded,
                          color: const Color(0xFFC0392B),
                        ),
                        MetricTile(
                          label: 'Borrowed',
                          value: AppConstants.currency(analytics.totalBorrowed),
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF2E86DE),
                        ),
                        MetricTile(
                          label: 'Lent',
                          value: AppConstants.currency(analytics.totalLent),
                          icon: Icons.savings_rounded,
                          color: const Color(0xFF16A085),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Category-wise Spending',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: CategoryPieChart(
                              data: analytics.categoryBreakdown
                                  .map(
                                    (item) => CategorySpend(
                                      categoryName: item.name,
                                      amount: item.amount,
                                      colorValue: item.colorValue,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Expense Trend',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: TrendLineChart(
                              points: analytics.trend
                                  .map(
                                    (item) => TrendPoint(
                                      period: DateTime.now(),
                                      amount: item.amount,
                                      label: item.label,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Borrowed vs Lent',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: BorrowedLentBarChart(
                              borrowed: analytics.totalBorrowed,
                              lent: analytics.totalLent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
