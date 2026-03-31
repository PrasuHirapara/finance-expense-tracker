import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/formatters/indian_number_formatter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_models.dart';
import '../blocs/bank/bank_bloc.dart';
import '../blocs/expense/expense_bloc.dart';

class ExpenseModulePage extends StatefulWidget {
  const ExpenseModulePage({super.key});

  @override
  State<ExpenseModulePage> createState() => _ExpenseModulePageState();
}

class _ExpenseModulePageState extends State<ExpenseModulePage> {
  _ExpenseSummaryFilter _activeSummaryFilter = _ExpenseSummaryFilter.net;
  DateTime? _expandedDate;

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const ExpenseSubscriptionRequested());
    context.read<BankBloc>().add(const BanksSubscriptionRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, expenseState) {
        return BlocBuilder<BankBloc, BankState>(
          builder: (context, bankState) {
            final dashboard = expenseState.dashboard;

            if (dashboard == null) {
              return const SafeArea(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final filteredEntries = dashboard.entries
                .where(
                  (entry) => _matchesSummaryFilter(entry, _activeSummaryFilter),
                )
                .toList(growable: false);
            final groupedEntries = _groupEntries(filteredEntries);
            final expandedDate =
                groupedEntries.keys.any((date) => date == _expandedDate)
                ? _expandedDate
                : null;
            final summaryCards = <_SummaryCardData>[
              _SummaryCardData(
                label: 'Total Credit',
                value: IndianNumberFormatter.formatCompactCurrency(
                  dashboard.totalCredit,
                ),
                color: const Color(0xFF1F8B4C),
                filter: _ExpenseSummaryFilter.credit,
              ),
              _SummaryCardData(
                label: 'Total Debit',
                value: IndianNumberFormatter.formatCompactCurrency(
                  dashboard.totalDebit,
                ),
                color: const Color(0xFFC0392B),
                filter: _ExpenseSummaryFilter.debit,
              ),
              _SummaryCardData(
                label: 'Total Lent',
                value: IndianNumberFormatter.formatCompactCurrency(
                  dashboard.totalLent,
                ),
                color: const Color(0xFF8E44AD),
                filter: _ExpenseSummaryFilter.lent,
              ),
              _SummaryCardData(
                label: 'Total Borrowed',
                value: IndianNumberFormatter.formatCompactCurrency(
                  dashboard.totalBorrowed,
                ),
                color: const Color(0xFF16A085),
                filter: _ExpenseSummaryFilter.borrowed,
              ),
            ];

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<ExpenseBloc>().add(
                    ExpenseSubscriptionRequested(
                      bankId: expenseState.selectedBankId,
                    ),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Expense',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.expenseAnalytics),
                          icon: const Icon(Icons.insights_rounded),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.expenseSettings),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppSelectField<int?>(
                            label: 'Filter by bank',
                            value: expenseState.selectedBankId,
                            options: <AppSelectOption<int?>>[
                              const AppSelectOption<int?>(
                                value: null,
                                label: 'All Banks',
                              ),
                              ...bankState.banks.map(
                                (bank) => AppSelectOption<int?>(
                                  value: bank.id,
                                  label: bank.name,
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              context.read<ExpenseBloc>().add(
                                ExpenseBankFilterChanged(value),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.expenseAdd),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Expense'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Summary',
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                _activeSummaryFilter.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _NetSummaryRow(
                            value: IndianNumberFormatter.formatCompactCurrency(
                              dashboard.totalNet,
                            ),
                            selected:
                                _activeSummaryFilter ==
                                _ExpenseSummaryFilter.net,
                            onTap: () {
                              setState(() {
                                _activeSummaryFilter =
                                    _ExpenseSummaryFilter.net;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1.45,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: summaryCards
                                .map(
                                  (item) => _SummaryMetricCard(
                                    data: item,
                                    selected:
                                        item.filter == _activeSummaryFilter,
                                    onTap: () {
                                      setState(() {
                                        _activeSummaryFilter = item.filter;
                                      });
                                    },
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'History',
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.expenseEntries),
                                child: const Text('Show More'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (filteredEntries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No transactions match the current filter.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            ...groupedEntries.entries.map(
                              (group) => Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _DateTransactionGroup(
                                  date: group.key,
                                  entries: group.value,
                                  expanded: expandedDate == group.key,
                                  onTap: () {
                                    setState(() {
                                      _expandedDate = expandedDate == group.key
                                          ? null
                                          : group.key;
                                    });
                                  },
                                  onEdit: (entry) {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.expenseAdd,
                                      arguments: ExpenseEditorArgs(
                                        entry: entry,
                                      ),
                                    );
                                  },
                                  onDelete: (entry) {
                                    _deleteEntry(context, entry);
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _matchesSummaryFilter(
    ExpenseRecord entry,
    _ExpenseSummaryFilter filter,
  ) {
    switch (filter) {
      case _ExpenseSummaryFilter.net:
        return true;
      case _ExpenseSummaryFilter.credit:
        return entry.isCredit;
      case _ExpenseSummaryFilter.debit:
        return entry.isDebit;
      case _ExpenseSummaryFilter.lent:
        return entry.type == 'lent';
      case _ExpenseSummaryFilter.borrowed:
        return entry.type == 'borrowed';
    }
  }

  Map<DateTime, List<ExpenseRecord>> _groupEntries(
    List<ExpenseRecord> entries,
  ) {
    final grouped = <DateTime, List<ExpenseRecord>>{};
    for (final entry in entries) {
      grouped
          .putIfAbsent(entry.date.startOfDay, () => <ExpenseRecord>[])
          .add(entry);
    }
    return grouped;
  }

  Future<void> _deleteEntry(BuildContext context, ExpenseRecord entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction'),
        content: Text('Delete "${entry.title}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    await context.read<ExpenseRepository>().deleteExpense(entry.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('"${entry.title}" deleted.')));
  }
}

enum _ExpenseSummaryFilter {
  net('All transactions'),
  credit('Showing credit'),
  debit('Showing debit'),
  lent('Showing lent'),
  borrowed('Showing borrowed');

  const _ExpenseSummaryFilter(this.label);

  final String label;
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.color,
    required this.filter,
  });

  final String label;
  final String value;
  final Color color;
  final _ExpenseSummaryFilter filter;
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _SummaryCardData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: selected
              ? data.color.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.42,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? data.color : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              data.value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NetSummaryRow extends StatelessWidget {
  const _NetSummaryRow({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2E86DE).withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.42,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E86DE)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Total Net',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTransactionGroup extends StatelessWidget {
  const _DateTransactionGroup({
    required this.date,
    required this.entries,
    required this.expanded,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime date;
  final List<ExpenseRecord> entries;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<ExpenseRecord> onEdit;
  final ValueChanged<ExpenseRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = entries.fold<double>(0, (sum, entry) {
      return sum + (entry.isCredit ? entry.amount : -entry.amount);
    });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.32,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _labelForDate(date),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entries.length} transaction${entries.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    IndianNumberFormatter.formatCompactCurrency(total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: total >= 0
                          ? const Color(0xFF1F8B4C)
                          : const Color(0xFFC0392B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ExpenseEntryCard(
                          entry: entry,
                          onEdit: () => onEdit(entry),
                          onDelete: () => onDelete(entry),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  String _labelForDate(DateTime date) {
    final today = DateTime.now().startOfDay;
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) {
      return 'Today';
    }
    if (date == yesterday) {
      return 'Yesterday';
    }
    return AppConstants.shortDateFormat.format(date);
  }
}

class _ExpenseEntryCard extends StatelessWidget {
  const _ExpenseEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseRecord entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = entry.isCredit
        ? const Color(0xFF1F8B4C)
        : const Color(0xFFC0392B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(entry.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      [
                        entry.category.name,
                        if (entry.bank != null) entry.bank!.name,
                        _typeLabel(entry.type),
                        entry.paymentMode,
                        AppConstants.shortDateFormat.format(entry.date),
                      ].join(' | '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (entry.counterparty != null &&
                        entry.counterparty!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        entry.counterparty!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.isCredit ? '+' : '-'}${IndianNumberFormatter.formatCompactCurrency(entry.amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'lent':
        return 'Lent';
      case 'borrowed':
        return 'Borrowed';
      default:
        return 'Expense';
    }
  }
}
