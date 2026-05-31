import 'package:flutter/material.dart';

class AnalyticsWindowOption<T> {
  const AnalyticsWindowOption({required this.value, required this.label});

  final T value;
  final String label;
}

class AnalyticsWindowSelector<T> extends StatelessWidget {
  const AnalyticsWindowSelector({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<AnalyticsWindowOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.36,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: options
            .asMap()
            .entries
            .map((entry) {
              final option = entry.value;
              final isSelected = option.value == selectedValue;
              final isLast = entry.key == options.length - 1;

              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(option.value),
                  borderRadius: BorderRadius.horizontal(
                    left: entry.key == 0
                        ? const Radius.circular(16)
                        : Radius.zero,
                    right: isLast ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.75,
                            )
                          : Colors.transparent,
                      border: Border(
                        right: isLast
                            ? BorderSide.none
                            : BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.35),
                              ),
                      ),
                    ),
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
