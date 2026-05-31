import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/formatters/indian_number_formatter.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../domain/entities/analytics_models.dart';
import '../../../../presentation/widgets/charts/borrowed_lent_bar_chart.dart';
import '../../../../presentation/widgets/charts/category_pie_chart.dart';
import '../../../../presentation/widgets/charts/trend_line_chart.dart';
import '../../../../shared/widgets/analytics_window_selector.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/custom_date_range_selector.dart';
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

              if (state.status == ExpenseAnalyticsStatus.failure &&
                  analytics == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.errorMessage ?? 'Unable to load analytics.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  AnalyticsWindowSelector<ExpenseAnalyticsWindow>(
                    selectedValue: state.window,
                    options:
                        const <AnalyticsWindowOption<ExpenseAnalyticsWindow>>[
                          AnalyticsWindowOption<ExpenseAnalyticsWindow>(
                            value: ExpenseAnalyticsWindow.weekly,
                            label: 'Week',
                          ),
                          AnalyticsWindowOption<ExpenseAnalyticsWindow>(
                            value: ExpenseAnalyticsWindow.monthly,
                            label: 'Month',
                          ),
                          AnalyticsWindowOption<ExpenseAnalyticsWindow>(
                            value: ExpenseAnalyticsWindow.yearly,
                            label: 'Year',
                          ),
                          AnalyticsWindowOption<ExpenseAnalyticsWindow>(
                            value: ExpenseAnalyticsWindow.custom,
                            label: 'Custom',
                          ),
                        ],
                    onChanged: (window) {
                      context.read<ExpenseAnalyticsBloc>().add(
                        ExpenseAnalyticsWindowChanged(window),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (state.window ==
                      ExpenseAnalyticsWindow.custom) ...<Widget>[
                    CustomDateRangeSelector(
                      startDate: _customStartDate(state),
                      endDate: _customEndDate(state),
                      onChanged: (startDate, endDate) {
                        context.read<ExpenseAnalyticsBloc>().add(
                          ExpenseAnalyticsCustomRangeChanged(
                            startDate: startDate,
                            endDate: endDate,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppSelectField<int?>(
                    label: 'Bank filter',
                    value: state.selectedBankId,
                    options: <AppSelectOption<int?>>[
                      const AppSelectOption<int?>(
                        value: null,
                        label: 'All Banks',
                      ),
                      ...bankState.banks.map(
                        (bank) => AppSelectOption<int?>(
                          value: bank.id,
                          label: bank.name,
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
                      childAspectRatio: 1.55,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: <Widget>[
                        _ExpenseAnalyticsCard(
                          label: 'Credit',
                          value: IndianNumberFormatter.formatCompact(
                            analytics.totalCredit,
                          ),
                          color: const Color(0xFF1F8B4C),
                        ),
                        _ExpenseAnalyticsCard(
                          label: 'Debit',
                          value: IndianNumberFormatter.formatCompact(
                            analytics.totalDebit,
                          ),
                          color: const Color(0xFFC0392B),
                        ),
                        _ExpenseAnalyticsCard(
                          label: 'Borrowed',
                          value: IndianNumberFormatter.formatCompact(
                            analytics.totalBorrowed,
                          ),
                          color: const Color(0xFF2E86DE),
                        ),
                        _ExpenseAnalyticsCard(
                          label: 'Lent',
                          value: IndianNumberFormatter.formatCompact(
                            analytics.totalLent,
                          ),
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
                          const SizedBox(height: 10),
                          Text(
                            'Category list is shown beside the pie chart with color, name, percentage, and amount in a compact layout.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 18),
                          if (analytics.categoryBreakdown.isEmpty)
                            Text(
                              'No expense categories found for the selected range.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          else
                            CategoryPieChart(
                              data: analytics.categoryBreakdown
                                  .map(
                                    (item) => CategorySpend(
                                      categoryName: item.name,
                                      amount: item.amount,
                                      colorValue: item.colorValue,
                                    ),
                                  )
                                  .toList(growable: false),
                              showLegend: true,
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
                          const SizedBox(height: 10),
                          Text(
                            _trendDescription(analytics),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 18),
                          if (analytics.trend.isEmpty)
                            Text(
                              'No expense trend available for this range.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final chartHeight = _trendChartHeight(
                                  constraints.maxWidth,
                                );

                                return SizedBox(
                                  height: chartHeight,
                                  child: TrendLineChart(
                                    points: analytics.trend
                                        .map(
                                          (item) => TrendPoint(
                                            period: item.period,
                                            amount: item.amount,
                                            label: item.label,
                                          ),
                                        )
                                        .toList(growable: false),
                                    xAxisTitle: _trendXAxisTitle(analytics),
                                    yAxisTitle: 'Expense Amount',
                                    bottomTitlesReservedSize:
                                        _trendBottomReservedSize(
                                          analytics,
                                          constraints.maxWidth,
                                        ),
                                    bottomTitleBuilder:
                                        (context, point, index) {
                                          return _buildTrendBottomLabel(
                                            context,
                                            analytics,
                                            point,
                                            index,
                                          );
                                        },
                                  ),
                                );
                              },
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
                          const SizedBox(height: 8),
                          Text(
                            'X-axis shows flow type. Y-axis shows amount.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 240,
                            child: BorrowedLentBarChart(
                              borrowed: analytics.totalBorrowed,
                              lent: analytics.totalLent,
                              xAxisTitle: 'Flow Type',
                              yAxisTitle: 'Amount',
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

  String _trendDescription(ExpenseAnalyticsData analytics) {
    if (analytics.window == ExpenseAnalyticsWindow.custom) {
      return 'Bottom labels follow the selected custom date range.';
    }

    if (_usesYearlyTrendLabels(analytics)) {
      return 'Bottom labels show month buckets across the selected year.';
    }

    if (_usesWeeklyTrendLabels(analytics)) {
      return 'Bottom labels show each weekday once across the selected week.';
    }

    return 'Bottom labels show the day number and day name so the expense trend reads like the task consistency graph.';
  }

  String _trendXAxisTitle(ExpenseAnalyticsData analytics) {
    return _usesYearlyTrendLabels(analytics) ? 'Month' : 'Day';
  }

  double _trendBottomReservedSize(
    ExpenseAnalyticsData analytics,
    double availableWidth,
  ) {
    if (_usesYearlyTrendLabels(analytics)) {
      return 44;
    }
    if (_usesWeeklyTrendLabels(analytics)) {
      return availableWidth < 420 ? 36 : 40;
    }
    return availableWidth < 420 ? 52 : 58;
  }

  double _trendChartHeight(double availableWidth) {
    return availableWidth < 420 ? 300 : 340;
  }

  bool _usesYearlyTrendLabels(ExpenseAnalyticsData analytics) {
    return analytics.window == ExpenseAnalyticsWindow.yearly;
  }

  bool _usesWeeklyTrendLabels(ExpenseAnalyticsData analytics) {
    return analytics.window == ExpenseAnalyticsWindow.weekly;
  }

  DateTime _customStartDate(ExpenseAnalyticsState state) {
    return state.customStartDate ?? DateTime.now().startOfWeek;
  }

  DateTime _customEndDate(ExpenseAnalyticsState state) {
    return state.customEndDate ?? DateTime.now().endOfWeek;
  }

  Widget _buildTrendBottomLabel(
    BuildContext context,
    ExpenseAnalyticsData analytics,
    TrendPoint point,
    int index,
  ) {
    final totalPoints = analytics.trend.length;
    if (!_shouldShowTrendLabel(
      index: index,
      totalPoints: totalPoints,
      useMonthlyLabels: _usesYearlyTrendLabels(analytics),
    )) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    if (_usesYearlyTrendLabels(analytics) ||
        _usesWeeklyTrendLabels(analytics)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            point.label,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          point.label,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        Text(
          _dayName(point.period),
          textAlign: TextAlign.center,
          style: textTheme.labelSmall,
        ),
      ],
    );
  }

  bool _shouldShowTrendLabel({
    required int index,
    required int totalPoints,
    required bool useMonthlyLabels,
  }) {
    if (index == 0 || index == totalPoints - 1) {
      return true;
    }

    if (useMonthlyLabels) {
      if (totalPoints <= 6) {
        return true;
      }
      return index.isEven;
    }

    if (totalPoints <= 7) {
      return true;
    }
    if (totalPoints <= 14) {
      return index.isEven;
    }
    if (totalPoints <= 31) {
      return index % 5 == 0;
    }
    if (totalPoints <= 62) {
      return index % 7 == 0;
    }
    return index % 14 == 0;
  }

  String _dayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
    }
    return '';
  }
}

class _ExpenseAnalyticsCard extends StatelessWidget {
  const _ExpenseAnalyticsCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
