import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatters/indian_number_formatter.dart';
import '../../../domain/entities/analytics_models.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.points,
    this.xAxisTitle = 'Period',
    this.yAxisTitle = 'Amount',
    this.bottomTitleBuilder,
    this.bottomTitlesReservedSize = 38,
  });

  final List<TrendPoint> points;
  final String xAxisTitle;
  final String yAxisTitle;
  final Widget Function(BuildContext context, TrendPoint point, int index)?
  bottomTitleBuilder;
  final double bottomTitlesReservedSize;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final axisLabelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final axisTitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final maxValue = points.fold<double>(
      points.first.amount,
      (max, point) => point.amount > max ? point.amount : max,
    );
    final minValue = points.fold<double>(
      points.first.amount,
      (min, point) => point.amount < min ? point.amount : min,
    );
    final range = maxValue - minValue;
    final padding = range == 0
        ? math.max(1, maxValue.abs() * 0.25)
        : math.max(range * 0.18, maxValue.abs() * 0.04);
    final minCandidate = math.max(0, minValue - padding);
    final maxCandidate = maxValue + padding;
    final yInterval = _niceAxisInterval(
      math.max(maxCandidate - minCandidate, 1),
    );
    final maxY = maxValue == 0
        ? yInterval * 4
        : (maxCandidate / yInterval).ceil() * yInterval;
    final minY = minCandidate <= 0
        ? 0.0
        : (minCandidate / yInterval).floor() * yInterval;
    final dotRadius = points.length > 24 ? 2.6 : 3.4;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: points.length == 1 ? 1 : (points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
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
              child: Text(yAxisTitle, style: axisTitleStyle),
            ),
            axisNameSize: 28,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 68,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value < minY || value > maxY) {
                  return const SizedBox.shrink();
                }

                return Text(
                  _formatAxisLabel(value, maxY),
                  style: axisLabelStyle,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(xAxisTitle, style: axisTitleStyle),
            ),
            axisNameSize: 30,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: bottomTitlesReservedSize,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }

                final customLabel = bottomTitleBuilder?.call(
                  context,
                  points[index],
                  index,
                );
                if (customLabel != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: customLabel,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    points[index].label,
                    textAlign: TextAlign.center,
                    style: axisLabelStyle,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            isCurved: points.length > 2,
            preventCurveOverShooting: true,
            curveSmoothness: 0.18,
            barWidth: 3,
            color: theme.colorScheme.primary,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) =>
                  _shouldShowDot(spot.x.toInt(), maxValue),
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: dotRadius,
                color: theme.colorScheme.primary,
                strokeWidth: 1.5,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
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
      return 1;
    }

    final rawStep = maxValue / 4;
    final magnitude = math
        .pow(10, (math.log(rawStep) / math.ln10).floor())
        .toDouble();
    final normalized = rawStep / magnitude;

    if (normalized <= 1) {
      return magnitude;
    }
    if (normalized <= 2.5) {
      return 2 * magnitude;
    }
    if (normalized <= 5) {
      return 5 * magnitude;
    }
    return 10 * magnitude;
  }

  bool _shouldShowDot(int index, double maxValue) {
    if (index < 0 || index >= points.length) {
      return false;
    }

    if (points.length <= 12) {
      return true;
    }

    final amount = points[index].amount;
    if (index == 0 || index == points.length - 1 || amount == maxValue) {
      return true;
    }

    final interval = points.length <= 24 ? 3 : 5;
    return index % interval == 0;
  }

  String _formatAxisLabel(double value, double maxValue) {
    if (value == 0) {
      return '0';
    }

    if (maxValue >= 100000) {
      return IndianNumberFormatter.formatCompact(value);
    }
    return IndianNumberFormatter.formatFull(value);
  }
}
