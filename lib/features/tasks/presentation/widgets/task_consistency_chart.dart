import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models/task_models.dart';

class TaskConsistencyChart extends StatelessWidget {
  const TaskConsistencyChart({super.key, required this.points});

  final List<TaskConsistencyPoint> points;

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
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
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
