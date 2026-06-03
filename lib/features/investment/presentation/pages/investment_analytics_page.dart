import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/formatters/indian_number_formatter.dart';
import '../../../../domain/entities/analytics_models.dart';
import '../../../../presentation/widgets/charts/category_pie_chart.dart';
import '../../../../presentation/widgets/charts/trend_line_chart.dart';
import '../../../../shared/widgets/analytics_window_selector.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/custom_date_range_selector.dart';
import '../../domain/models/investment_models.dart';
import '../blocs/investment_analytics/investment_analytics_bloc.dart';

class InvestmentAnalyticsPage extends StatefulWidget {
  const InvestmentAnalyticsPage({super.key});

  @override
  State<InvestmentAnalyticsPage> createState() => _InvestmentAnalyticsPageState();
}

class _InvestmentAnalyticsPageState extends State<InvestmentAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    context.read<InvestmentAnalyticsBloc>().add(const InvestmentAnalyticsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Investment Analytics')),
      body: BlocBuilder<InvestmentAnalyticsBloc, InvestmentAnalyticsState>(
        builder: (context, state) {
          final analytics = state.analytics;

          if (state.status == InvestmentAnalyticsStatus.failure && analytics == null) {
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
              AnalyticsWindowSelector<InvestmentAnalyticsWindow>(
                selectedValue: state.window,
                options: const <AnalyticsWindowOption<InvestmentAnalyticsWindow>>[
                  AnalyticsWindowOption<InvestmentAnalyticsWindow>(
                    value: InvestmentAnalyticsWindow.year,
                    label: 'Year',
                  ),
                  AnalyticsWindowOption<InvestmentAnalyticsWindow>(
                    value: InvestmentAnalyticsWindow.threeYears,
                    label: '3 Years',
                  ),
                  AnalyticsWindowOption<InvestmentAnalyticsWindow>(
                    value: InvestmentAnalyticsWindow.all,
                    label: 'All Time',
                  ),
                  AnalyticsWindowOption<InvestmentAnalyticsWindow>(
                    value: InvestmentAnalyticsWindow.custom,
                    label: 'Custom',
                  ),
                ],
                onChanged: (window) {
                  context.read<InvestmentAnalyticsBloc>().add(
                        InvestmentAnalyticsWindowChanged(window),
                      );
                },
              ),
              const SizedBox(height: 16),
              if (state.window == InvestmentAnalyticsWindow.custom) ...<Widget>[
                CustomDateRangeSelector(
                  startDate: state.customStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
                  endDate: state.customEndDate ?? DateTime.now(),
                  onChanged: (startDate, endDate) {
                    context.read<InvestmentAnalyticsBloc>().add(
                          InvestmentAnalyticsCustomRangeChanged(
                            startDate: startDate,
                            endDate: endDate,
                          ),
                        );
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (analytics != null) ...<Widget>[
                // Summary Metric Cards
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.55,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: <Widget>[
                    _AnalyticsCard(
                      label: 'Total Invested',
                      value: IndianNumberFormatter.formatFull(analytics.totalInvested),
                      color: Colors.blue,
                    ),
                    _AnalyticsCard(
                      label: 'Total Sell Value',
                      value: IndianNumberFormatter.formatFull(analytics.totalSellValue),
                      color: Colors.orange,
                    ),
                    _AnalyticsCard(
                      label: 'Total P/L',
                      value: '${analytics.totalPL >= 0 ? "+" : ""}${IndianNumberFormatter.formatFull(analytics.totalPL)}',
                      color: analytics.totalPL >= 0 ? Colors.green : Colors.red,
                    ),
                    _AnalyticsCard(
                      label: 'Total P/L %',
                      value: '${analytics.totalPLPct >= 0 ? "+" : ""}${analytics.totalPLPct.toStringAsFixed(2)}%',
                      color: analytics.totalPLPct >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Chart 1: P/L Over Time
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('P/L Trend Over Time', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 18),
                      if (analytics.trend.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No sell transactions for P/L trend.'),
                        )
                      else
                        SizedBox(
                          height: 250,
                          child: TrendLineChart(
                            points: analytics.trend
                                .map((t) => TrendPoint(period: t.period, amount: t.amount, label: t.label))
                                .toList(),
                            xAxisTitle: 'Date',
                            yAxisTitle: 'P/L Amount',
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chart 2: Category Distribution
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Allocation by Category', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 18),
                      if (analytics.categoryBreakdown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No investment categories allocation.'),
                        )
                      else
                        CategoryPieChart(
                          data: analytics.categoryBreakdown
                              .map((c) => CategorySpend(
                                    categoryName: c.name,
                                    amount: c.amount,
                                    colorValue: c.colorValue,
                                  ))
                              .toList(),
                          showLegend: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chart 3: P/L % by Symbol (Horizontal bar list)
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('P/L % by Symbol', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 18),
                      if (analytics.symbolPLBreakdown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No P/L data per symbol.'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: analytics.symbolPLBreakdown.length,
                          itemBuilder: (context, index) {
                            final item = analytics.symbolPLBreakdown[index];
                            final isPos = item.plPct >= 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(item.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        '${isPos ? "+" : ""}${item.plPct.toStringAsFixed(2)}% (${isPos ? "+" : ""}${IndianNumberFormatter.formatFull(item.pl)})',
                                        style: TextStyle(color: isPos ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: (item.plPct.abs() / 100.0).clamp(0.0, 1.0),
                                    color: isPos ? Colors.green : Colors.red,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chart 4: Category Summary Table
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Category P/L Summary', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 18),
                      if (analytics.categoryPLSummary.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No category breakdown summary.'),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Invested')),
                              DataColumn(label: Text('Sell Value')),
                              DataColumn(label: Text('P/L')),
                              DataColumn(label: Text('P/L %')),
                            ],
                            rows: analytics.categoryPLSummary.map((s) {
                              final isPos = s.pl >= 0;
                              return DataRow(
                                cells: [
                                  DataCell(Text(s.categoryName)),
                                  DataCell(Text(IndianNumberFormatter.formatFull(s.totalInvested))),
                                  DataCell(Text(IndianNumberFormatter.formatFull(s.totalSellValue))),
                                  DataCell(Text(
                                    '${isPos ? "+" : ""}${IndianNumberFormatter.formatFull(s.pl)}',
                                    style: TextStyle(color: isPos ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                  )),
                                  DataCell(Text(
                                    '${isPos ? "+" : ""}${s.plPct.toStringAsFixed(2)}%',
                                    style: TextStyle(color: isPos ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                  )),
                                ],
                              );
                            }).toList(),
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
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
