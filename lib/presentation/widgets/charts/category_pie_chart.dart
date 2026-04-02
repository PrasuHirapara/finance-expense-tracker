import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatters/indian_number_formatter.dart';
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
    if (widget.data.isEmpty || total == 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = _ChartBody(
          data: widget.data,
          total: total,
          selectedIndex: _selectedIndex,
          onSectionTap: _toggleSelection,
        );

        if (!widget.showLegend) {
          return chart;
        }

        final legend = _LegendList(
          data: widget.data,
          total: total,
          selectedIndex: _selectedIndex,
          onItemTap: _toggleSelection,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: constraints.maxWidth < 460 ? 3 : 4, child: chart),
            SizedBox(width: constraints.maxWidth < 460 ? 10 : 14),
            Expanded(flex: 7, child: legend),
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

class _ChartBody extends StatelessWidget {
  const _ChartBody({
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
    final selectedItem = selectedIndex == null ? null : data[selectedIndex!];

    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (selectedItem != null)
            Positioned(
              top: 0,
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      selectedItem.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
            ),
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 34,
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
                    final percentage = (item.amount / total) * 100;
                    final isSelected = selectedIndex == index;
                    final label = percentage >= 16 || isSelected
                        ? '${percentage.toStringAsFixed(0)}%'
                        : '';

                    return PieChartSectionData(
                      value: item.amount,
                      title: label,
                      radius: isSelected ? 60 : 54,
                      color: Color(item.colorValue),
                      titlePositionPercentageOffset: 0.72,
                      titleStyle: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendList extends StatelessWidget {
  const _LegendList({
    required this.data,
    required this.total,
    required this.selectedIndex,
    required this.onItemTap,
  });

  final List<CategorySpend> data;
  final double total;
  final int? selectedIndex;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    final children = data
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final item = entry.value;
          final percentage = (item.amount / total) * 100;
          final isSelected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onItemTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(item.colorValue).withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Color(item.colorValue)
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(item.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.categoryName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          IndianNumberFormatter.formatCompactCurrency(
                            item.amount,
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
