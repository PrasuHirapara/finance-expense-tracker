import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/export_payload.dart';
import '../controllers/app_providers.dart';
import '../controllers/export_controller.dart';
import '../widgets/charts/borrowed_lent_bar_chart.dart';
import '../widgets/charts/category_pie_chart.dart';
import '../widgets/charts/trend_line_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';
import '../widgets/summary_tile.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  static const String routeName = 'analytics';
  static const String routePath = '/analytics';

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final GlobalKey _pieChartKey = GlobalKey();
  final GlobalKey _lineChartKey = GlobalKey();
  final GlobalKey _barChartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final window = ref.watch(analyticsWindowProvider);
    final reportAsync = ref.watch(analyticsReportProvider(window));
    final exportState = ref.watch(exportControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Analytics', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Weekly, monthly, and yearly views with credit, debit, liability, and receivable signals.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<AnalyticsWindow>(
            segments: AnalyticsWindow.values
                .map(
                  (value) => ButtonSegment<AnalyticsWindow>(
                    value: value,
                    label: Text(value.label),
                  ),
                )
                .toList(growable: false),
            selected: <AnalyticsWindow>{window},
            onSelectionChanged: (selection) {
              ref.read(analyticsWindowProvider.notifier).state =
                  selection.first;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reportAsync.hasValue && !exportState.isLoading
                      ? () => _exportCsv(
                          context,
                          window,
                          reportAsync.requireValue,
                        )
                      : null,
                  icon: const Icon(Icons.table_chart_rounded),
                  label: const Text('Export CSV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: reportAsync.hasValue && !exportState.isLoading
                      ? () => _exportPdf(
                          context,
                          window,
                          reportAsync.requireValue,
                        )
                      : null,
                  icon: exportState.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Export PDF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          reportAsync.when(
            data: (report) => _AnalyticsBody(
              report: report,
              pieChartKey: _pieChartKey,
              lineChartKey: _lineChartKey,
              barChartKey: _barChartKey,
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Center(child: Text(error.toString())),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    AnalyticsWindow window,
    AnalyticsReport report,
  ) async {
    final path = await ref
        .read(exportControllerProvider.notifier)
        .exportCsv(window: window, report: report);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
  }

  Future<void> _exportPdf(
    BuildContext context,
    AnalyticsWindow window,
    AnalyticsReport report,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final snapshots = ExportChartSnapshots(
      pieChart: await _captureChart(_pieChartKey),
      lineChart: await _captureChart(_lineChartKey),
      barChart: await _captureChart(_barChartKey),
    );
    final path = await ref
        .read(exportControllerProvider.notifier)
        .exportPdf(window: window, report: report, snapshots: snapshots);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF exported to $path')));
  }

  Future<Uint8List?> _captureChart(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({
    required this.report,
    required this.pieChartKey,
    required this.lineChartKey,
    required this.barChartKey,
  });

  final AnalyticsReport report;
  final GlobalKey pieChartKey;
  final GlobalKey lineChartKey;
  final GlobalKey barChartKey;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final summaryColumns = width >= 1180 ? 4 : 2;

    if (report.entries.isEmpty) {
      return const EmptyState(
        title: 'No data in this range',
        message:
            'Try another period or add a few transactions to generate analytics.',
        icon: Icons.insights_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GridView.count(
          crossAxisCount: summaryColumns,
          childAspectRatio: width >= 1180 ? 1.5 : 1.25,
          shrinkWrap: true,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            SummaryTile(
              title: 'Total Credit',
              value: AppConstants.currency(report.totalCredit),
              icon: Icons.arrow_circle_up_rounded,
              color: const Color(0xFF1F8B4C),
            ),
            SummaryTile(
              title: 'Total Debit',
              value: AppConstants.currency(report.totalDebit),
              icon: Icons.arrow_circle_down_rounded,
              color: const Color(0xFFC0392B),
            ),
            SummaryTile(
              title: 'Liability',
              value: AppConstants.currency(report.outstandingLiability),
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF2E86DE),
            ),
            SummaryTile(
              title: 'Receivable',
              value: AppConstants.currency(report.outstandingReceivable),
              icon: Icons.savings_rounded,
              color: const Color(0xFF16A085),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (width >= 1100)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _ChartSection(
                  title: 'Category Distribution',
                  subtitle: 'Expense share by category',
                  chartKey: pieChartKey,
                  chart: CategoryPieChart(data: report.categoryDistribution),
                  footer: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: report.categoryDistribution
                        .map(
                          (item) => _LegendChip(
                            label:
                                '${item.categoryName} • ${AppConstants.currency(item.amount)}',
                            color: Color(item.colorValue),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ChartSection(
                  title: 'Expense Trendline',
                  subtitle: 'Expense movement over time',
                  chartKey: lineChartKey,
                  chart: TrendLineChart(points: report.trendPoints),
                ),
              ),
            ],
          )
        else ...<Widget>[
          _ChartSection(
            title: 'Category Distribution',
            subtitle: 'Expense share by category',
            chartKey: pieChartKey,
            chart: CategoryPieChart(data: report.categoryDistribution),
            footer: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: report.categoryDistribution
                  .map(
                    (item) => _LegendChip(
                      label:
                          '${item.categoryName} • ${AppConstants.currency(item.amount)}',
                      color: Color(item.colorValue),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 14),
          _ChartSection(
            title: 'Expense Trendline',
            subtitle: 'Expense movement over time',
            chartKey: lineChartKey,
            chart: TrendLineChart(points: report.trendPoints),
          ),
        ],
        const SizedBox(height: 14),
        _ChartSection(
          title: 'Borrowed vs Lent',
          subtitle: 'Asset and liability comparison',
          chartKey: barChartKey,
          chart: BorrowedLentBarChart(
            borrowed: report.totalBorrowed,
            lent: report.totalLent,
          ),
          footer: Text(
            'Net position: ${AppConstants.currency(report.borrowedVsLentBalance)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.chart,
    required this.chartKey,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget chart;
  final GlobalKey chartKey;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 250,
            child: RepaintBoundary(
              key: chartKey,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: chart,
              ),
            ),
          ),
          if (footer != null) ...<Widget>[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
      label: Text(label),
    );
  }
}
