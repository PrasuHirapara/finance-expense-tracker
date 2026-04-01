import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models/task_models.dart';

class TaskConsistencyChart extends StatelessWidget {
  const TaskConsistencyChart({
    super.key,
    required this.points,
    this.xAxisTitle = 'Day',
    this.yAxisTitle = 'Completed Tasks',
  });

  final List<TaskConsistencyPoint> points;
  final String xAxisTitle;
  final String yAxisTitle;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = points
        .map((point) => point.completedCount)
        .fold<int>(0, (max, value) => value > max ? value : max);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxValue == 0 ? 1 : maxValue).toDouble() + 1,
        gridData: FlGridData(
          show: true,
          horizontalInterval:
              ((maxValue == 0 ? 1 : maxValue).toDouble() + 1) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(yAxisTitle),
            ),
            axisNameSize: 28,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(xAxisTitle),
            ),
            axisNameSize: 30,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(points[index].label),
                );
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            isCurved: true,
            color: const Color(0xFF2E86DE),
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2E86DE).withValues(alpha: 0.18),
            ),
            spots: points
                .asMap()
                .entries
                .map(
                  (entry) => FlSpot(
                    entry.key.toDouble(),
                    entry.value.completedCount.toDouble(),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
