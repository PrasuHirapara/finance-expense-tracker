import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class TaskDateSelector extends StatelessWidget {
  const TaskDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final dates = List<DateTime>.generate(
      15,
      (index) =>
          today.subtract(const Duration(days: 7)).add(Duration(days: index)),
    );

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = dates[index];
          final selected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return InkWell(
            onTap: () => onDateSelected(date),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 78,
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
}
