import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/analytics_models.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.data});

  final List<CategorySpend> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, item) => sum + item.amount);
    if (data.isEmpty || total == 0) {
      return const SizedBox.shrink();
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 38,
        sections: data
            .map((item) {
              final percentage = (item.amount / total) * 100;
              return PieChartSectionData(
                value: item.amount,
                title: '${percentage.toStringAsFixed(0)}%',
                radius: 68,
                color: Color(item.colorValue),
                titleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
