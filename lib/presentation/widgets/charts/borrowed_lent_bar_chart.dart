import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/formatters/indian_number_formatter.dart';

class BorrowedLentBarChart extends StatelessWidget {
  const BorrowedLentBarChart({
    super.key,
    required this.borrowed,
    required this.lent,
    this.xAxisTitle = 'Flow Type',
    this.yAxisTitle = 'Amount',
  });

  final double borrowed;
  final double lent;
  final String xAxisTitle;
  final String yAxisTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final axisLabelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final axisTitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final maxValue = borrowed > lent ? borrowed : lent;
    final yInterval = _niceAxisInterval(maxValue);
    final maxY = maxValue == 0
        ? yInterval * 4
        : (maxValue / yInterval).ceil() * yInterval;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
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
              getTitlesWidget: (value, meta) => Text(
                _formatAxisLabel(value, maxValue),
                style: axisLabelStyle,
              ),
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
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value == 0 ? 'Borrowed' : 'Lent',
                    style: axisLabelStyle,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          BarChartGroupData(
            x: 0,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: borrowed,
                width: 28,
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFC0392B),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: lent,
                width: 28,
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF1F8B4C),
              ),
            ],
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
