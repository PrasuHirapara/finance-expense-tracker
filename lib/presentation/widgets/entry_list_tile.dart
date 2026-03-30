import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/finance_entry.dart';

class EntryListTile extends StatelessWidget {
  const EntryListTile({super.key, required this.entry});

  final FinanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = Color(entry.category.colorValue);
    final amountPrefix = entry.type.isCredit ? '+' : '-';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(
          AppConstants.categoryIconFromCodePoint(entry.category.iconCodePoint),
          color: color,
        ),
      ),
      title: Text(entry.title),
      subtitle: Text(
        '${entry.category.name} - ${AppConstants.shortDateFormat.format(entry.date)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            '$amountPrefix${AppConstants.currency(entry.amount)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: entry.type.isCredit
                  ? const Color(0xFF1F8B4C)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(entry.type.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
