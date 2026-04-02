import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/analytics_models.dart';

class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({
    super.key,
    required this.data,
    this.showLegend = false,
  });

  final List<CategorySpend> data;
  final bool showLegend;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold<double>(0, (sum, item) => sum + item.amount);
    if (widget.data.isEmpty || total <= 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = widget.showLegend && constraints.maxWidth >= 760;
        final chart = _PieBody(
          data: widget.data,
          total: total,
          selectedIndex: _selectedIndex,
          onSectionTap: _toggleSelection,
        );

        if (!widget.showLegend) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(constraints.maxWidth, 360),
              ),
              child: chart,
            ),
          );
        }

        final legend = _LegendList(
          data: widget.data,
          selectedIndex: _selectedIndex,
          onItemTap: _toggleSelection,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 6,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.min(constraints.maxWidth * 0.48, 380),
                    ),
                    child: chart,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: legend),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(constraints.maxWidth, 340),
                ),
                child: chart,
              ),
            ),
            const SizedBox(height: 20),
            legend,
          ],
        );
      },
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }
}

class _PieBody extends StatelessWidget {
  const _PieBody({
    required this.data,
    required this.total,
    required this.selectedIndex,
    required this.onSectionTap,
  });

  final List<CategorySpend> data;
  final double total;
  final int? selectedIndex;
  final ValueChanged<int> onSectionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = constraints.biggest.shortestSide;
          final baseRadius = diameter * 0.38;
          final activeRadius = diameter * 0.41;

          return Padding(
            padding: const EdgeInsets.all(10),
            child: PieChart(
              PieChartData(
                startDegreeOffset: -90,
                centerSpaceRadius: 0,
                sectionsSpace: 0,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event is! FlTapUpEvent) {
                      return;
                    }

                    final index = response?.touchedSection?.touchedSectionIndex;
                    if (index == null || index < 0 || index >= data.length) {
                      return;
                    }

                    onSectionTap(index);
                  },
                ),
                sections: data
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final percentage = item.amount / total * 100;
                      final isSelected = selectedIndex == index;

                      return PieChartSectionData(
                        value: item.amount,
                        color: Color(item.colorValue),
                        radius: isSelected ? activeRadius : baseRadius,
                        title: _formatPercentage(percentage),
                        titlePositionPercentageOffset: 1.18,
                        titleStyle: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPercentage(double value) {
    if (value >= 10) {
      return '${value.toStringAsFixed(1)}%';
    }
    return '${value.toStringAsFixed(2)}%';
  }
}

class _LegendList extends StatelessWidget {
  const _LegendList({
    required this.data,
    required this.selectedIndex,
    required this.onItemTap,
  });

  final List<CategorySpend> data;
  final int? selectedIndex;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = selectedIndex == index;
            final color = Color(item.colorValue);

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onItemTap(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.categoryName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: itemStyle?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : itemStyle.fontWeight,
                          color: isSelected
                              ? color
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
