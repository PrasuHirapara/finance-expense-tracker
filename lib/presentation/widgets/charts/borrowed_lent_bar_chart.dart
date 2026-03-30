import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BorrowedLentBarChart extends StatelessWidget {
  const BorrowedLentBarChart({
    super.key,
    required this.borrowed,
    required this.lent,
  });

  final double borrowed;
  final double lent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = borrowed > lent ? borrowed : lent;

    return BarChart(
      BarChartData(
        maxY: maxValue == 0 ? 100 : maxValue * 1.3,
        gridData: FlGridData(
          show: true,
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
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value == 0 ? 'Borrowed' : 'Lent',
                    style: theme.textTheme.bodySmall,
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
}
