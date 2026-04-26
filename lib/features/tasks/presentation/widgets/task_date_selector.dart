import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class TaskDateSelector extends StatefulWidget {
  const TaskDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<TaskDateSelector> createState() => _TaskDateSelectorState();
}

class _TaskDateSelectorState extends State<TaskDateSelector> {
  static const double _itemWidth = 78;
  static const double _itemSpacing = 10;

  late final ScrollController _scrollController;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _dates = _buildDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerDate(widget.selectedDate);
    });
  }

  @override
  void didUpdateWidget(covariant TaskDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDate(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerDate(widget.selectedDate);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 82,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final selected = _isSameDate(date, widget.selectedDate);

          return InkWell(
            onTap: () {
              widget.onDateSelected(date);
              _centerDate(date);
            },
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _itemWidth,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    AppConstants.dayLabelFormat.format(date).split(' ').first,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.monthLabelFormat.format(date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<DateTime> _buildDates() {
    final today = DateTime.now();
    return List<DateTime>.generate(
      15,
      (index) =>
          today.subtract(const Duration(days: 7)).add(Duration(days: index)),
    );
  }

  void _centerDate(DateTime targetDate) {
    if (!_scrollController.hasClients) {
      return;
    }

    final targetIndex = _dates.indexWhere(
      (date) => _isSameDate(date, targetDate),
    );
    if (targetIndex == -1) {
      return;
    }

    final viewportWidth = _scrollController.position.viewportDimension;
    final itemExtent = _itemWidth + _itemSpacing;
    final targetOffset =
        (targetIndex * itemExtent) - ((viewportWidth - _itemWidth) / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
