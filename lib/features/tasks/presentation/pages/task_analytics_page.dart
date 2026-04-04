import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/analytics_models.dart';
import '../../../../presentation/widgets/charts/trend_line_chart.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/metric_tile.dart';
import '../../domain/models/task_models.dart';
import '../blocs/task_analytics/task_analytics_bloc.dart';

class TaskAnalyticsPage extends StatelessWidget {
  const TaskAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Analytics')),
      body: BlocBuilder<TaskAnalyticsBloc, TaskAnalyticsState>(
        builder: (context, state) {
          final analytics = state.analytics;
          if (state.status == TaskAnalyticsStatus.failure && analytics == null) {
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<TaskAnalyticsWindow>(
                  segments: TaskAnalyticsWindow.values
                      .map(
                        (window) => ButtonSegment<TaskAnalyticsWindow>(
                          value: window,
                          label: Text(window.label),
                        ),
                      )
                      .toList(growable: false),
                  selected: <TaskAnalyticsWindow>{state.window},
                  onSelectionChanged: (selection) {
                    context.read<TaskAnalyticsBloc>().add(
                      TaskAnalyticsWindowChanged(selection.first),
                    );
                  },
                ),
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
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: <Widget>[
                    MetricTile(
                      label: 'Completed',
                      value: analytics.completedCount.toString(),
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF1F8B4C),
                    ),
                    MetricTile(
                      label: 'Pending',
                      value: analytics.pendingCount.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFC0392B),
                    ),
                    MetricTile(
                      label: 'Daily Streak',
                      value: analytics.dailyTaskStreak.toString(),
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF2E86DE),
                    ),
                    MetricTile(
                      label: 'Categories',
                      value: analytics.categoryBreakdown.length.toString(),
                      icon: Icons.category_rounded,
                      color: const Color(0xFF8E44AD),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Priority Distribution',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(_prioritySummary(analytics)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Daily Consistency',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _trendDescription(analytics),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (analytics.consistencyTrend.isEmpty)
                        Text(
                          'No completed task trend available for this range.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final chartWidth = _trendChartWidth(
                              constraints.maxWidth,
                              analytics,
                            );
                            final chartHeight = _trendChartHeight(
                              constraints.maxWidth,
                            );

                            return SizedBox(
                              height: chartHeight,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: chartWidth,
                                  height: chartHeight,
                                  child: TrendLineChart(
                                    points: analytics.consistencyTrend
                                        .map(
                                          (item) => TrendPoint(
                                            period: item.date,
                                            amount:
                                                item.completedCount.toDouble(),
                                            label: item.label,
                                          ),
                                        )
                                        .toList(growable: false),
                                    xAxisTitle: _trendXAxisTitle(analytics),
                                    yAxisTitle: 'Completed Tasks',
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
                                ),
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
                        'Category-wise Analysis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (analytics.categoryBreakdown.isEmpty)
                        Text(
                          'No task categories found for the selected range.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...analytics.categoryBreakdown.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(item.count.toString()),
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

  String _prioritySummary(TaskAnalyticsData analytics) {
    final total = analytics.priorityDistribution.fold<int>(
      0,
      (sum, item) => sum + item.count,
    );
    if (total == 0) {
      return '1: 0%  2: 0%  3: 0%  4: 0%  5: 0%';
    }

    final values = analytics.priorityDistribution
        .map(
          (item) =>
              '${item.priority}: ${((item.count / total) * 100).round()}%',
        )
        .join('   ');
    return values;
  }

  String _trendDescription(TaskAnalyticsData analytics) {
    if (_usesMonthlyTrendLabels(analytics)) {
      return 'Bottom labels show month buckets across the selected year.';
    }

    return 'Bottom labels show the day number and day name so the task trend reads like the expense graph.';
  }

  String _trendXAxisTitle(TaskAnalyticsData analytics) {
    return _usesMonthlyTrendLabels(analytics) ? 'Month' : 'Day';
  }

  double _trendBottomReservedSize(
    TaskAnalyticsData analytics,
    double availableWidth,
  ) {
    if (_usesMonthlyTrendLabels(analytics)) {
      return 44;
    }
    return availableWidth < 420 ? 52 : 58;
  }

  double _trendChartWidth(
    double availableWidth,
    TaskAnalyticsData analytics,
  ) {
    final pointWidth = _usesMonthlyTrendLabels(analytics) ? 56.0 : 30.0;
    return math.max(
      availableWidth,
      analytics.consistencyTrend.length * pointWidth,
    );
  }

  double _trendChartHeight(double availableWidth) {
    return availableWidth < 420 ? 300 : 340;
  }

  bool _usesMonthlyTrendLabels(TaskAnalyticsData analytics) {
    return analytics.window == TaskAnalyticsWindow.yearly;
  }

  Widget _buildTrendBottomLabel(
    BuildContext context,
    TaskAnalyticsData analytics,
    TrendPoint point,
    int index,
  ) {
    final totalPoints = analytics.consistencyTrend.length;
    if (!_shouldShowTrendLabel(
      index: index,
      totalPoints: totalPoints,
      useMonthlyLabels: _usesMonthlyTrendLabels(analytics),
    )) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    if (_usesMonthlyTrendLabels(analytics)) {
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
