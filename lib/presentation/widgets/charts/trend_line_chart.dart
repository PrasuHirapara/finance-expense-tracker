import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/formatters/indian_number_formatter.dart';
import '../../../domain/entities/analytics_models.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.points,
    this.xAxisTitle = 'Period',
    this.yAxisTitle = 'Amount',
  });

  final List<TrendPoint> points;
  final String xAxisTitle;
  final String yAxisTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = points.fold<double>(
      0,
      (max, point) => point.amount > max ? point.amount : max,
    );
    final yInterval = _niceAxisInterval(maxValue);
    final maxY = maxValue == 0
        ? yInterval * 4
        : (maxValue / yInterval).ceil() * yInterval;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(yAxisTitle, style: theme.textTheme.bodySmall),
            ),
            axisNameSize: 28,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 68,
              interval: yInterval,
              getTitlesWidget: (value, meta) => Text(
                _formatAxisLabel(value, maxValue),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(xAxisTitle, style: theme.textTheme.bodySmall),
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
                  child: Text(
                    points[index].label,
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            isCurved: true,
            barWidth: 3,
            color: theme.colorScheme.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
            spots: points
                .asMap()
                .entries
                .map(
                  (entry) => FlSpot(entry.key.toDouble(), entry.value.amount),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  double _niceAxisInterval(double maxValue) {
    if (maxValue <= 0) {
      return 10;
    }

    final rawStep = maxValue / 4;
    final magnitude = math
        .pow(10, (math.log(rawStep) / math.ln10).floor())
        .toDouble();
    final normalized = rawStep / magnitude;

    if (normalized <= 1) {
      return magnitude;
    }
    if (normalized <= 2) {
      return 2 * magnitude;
    }
    if (normalized <= 5) {
      return 5 * magnitude;
    }
    return 10 * magnitude;
  }

  String _formatAxisLabel(double value, double maxValue) {
    if (maxValue >= 100000) {
      return IndianNumberFormatter.formatCompact(value);
    }
    return IndianNumberFormatter.formatFull(value);
  }
}
