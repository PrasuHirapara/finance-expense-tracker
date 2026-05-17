import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/formatters/indian_number_formatter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_models.dart';
import '../blocs/bank/bank_bloc.dart';
import '../blocs/expense/expense_bloc.dart';
import '../utils/expense_search_utils.dart';

class ExpenseModulePage extends StatefulWidget {
  const ExpenseModulePage({super.key});

  @override
  State<ExpenseModulePage> createState() => _ExpenseModulePageState();
}

class _ExpenseModulePageState extends State<ExpenseModulePage> {
  static const int _initialVisibleDateGroups = 10;
  static const int _cashFilterValue = -1;

  _ExpenseSummaryFilter _activeSummaryFilter = _ExpenseSummaryFilter.net;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _expandedDate;
  int _visibleDateGroupCount = _initialVisibleDateGroups;
  bool _showCashEntries = false;

  @override
  void initState() {
    super.initState();
    context.read<BankBloc>().add(const BanksSubscriptionRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

            final activeEntries = _showCashEntries
                ? dashboard.entries
                      .where((entry) => entry.bank == null)
                      .toList(growable: false)
                : dashboard.entries;
            final summary = _buildSummary(activeEntries);
            final filteredEntries = activeEntries
                .where(
                  (entry) => _matchesSummaryFilter(entry, _activeSummaryFilter),
                )
                .where(
                  (entry) => _matchesSearchQuery(entry, _searchController.text),
                )
                .toList(growable: false);
            final entryById = <int, ExpenseRecord>{
              for (final entry in activeEntries) entry.id: entry,
            };
            final groupedEntries = _groupEntries(filteredEntries);
            final visibleGroupedEntries =
                Map<DateTime, List<ExpenseRecord>>.fromEntries(
                  groupedEntries.entries.take(_visibleDateGroupCount),
                );
            final expandedDate =
                visibleGroupedEntries.keys.any((date) => date == _expandedDate)
                ? _expandedDate
                : null;
            final summaryCards = <_SummaryCardData>[
              _SummaryCardData(
                label: 'Total Credit',
                value: IndianNumberFormatter.formatCompactCurrency(
                  summary.totalCredit,
                ),
                color: const Color(0xFF1F8B4C),
                filter: _ExpenseSummaryFilter.credit,
              ),
              _SummaryCardData(
                label: 'Total Debit',
                value: IndianNumberFormatter.formatCompactCurrency(
                  summary.totalDebit,
                ),
                color: const Color(0xFFC0392B),
                filter: _ExpenseSummaryFilter.debit,
              ),
              _SummaryCardData(
                label: 'Total Lent',
                value: IndianNumberFormatter.formatCompactCurrency(
                  summary.totalLent,
                ),
                color: const Color(0xFF8E44AD),
                filter: _ExpenseSummaryFilter.lent,
              ),
              _SummaryCardData(
                label: 'Total Borrowed',
                value: IndianNumberFormatter.formatCompactCurrency(
                  summary.totalBorrowed,
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
                      bankId: _showCashEntries
                          ? null
                          : expenseState.selectedBankId,
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
                            value: _showCashEntries
                                ? _cashFilterValue
                                : expenseState.selectedBankId,
                            options: <AppSelectOption<int?>>[
                              const AppSelectOption<int?>(
                                value: null,
                                label: 'All Banks',
                              ),
                              const AppSelectOption<int?>(
                                value: _cashFilterValue,
                                label: 'Cash',
                              ),
                              ...bankState.banks.map(
                                (bank) => AppSelectOption<int?>(
                                  value: bank.id,
                                  label: bank.name,
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == _cashFilterValue) {
                                setState(() {
                                  _showCashEntries = true;
                                  _visibleDateGroupCount =
                                      _initialVisibleDateGroups;
                                });
                                context.read<ExpenseBloc>().add(
                                  const ExpenseBankFilterChanged(null),
                                );
                                return;
                              }
                              setState(() {
                                _showCashEntries = false;
                                _visibleDateGroupCount =
                                    _initialVisibleDateGroups;
                              });
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
                              summary.totalNet,
                            ),
                            selected:
                                _activeSummaryFilter ==
                                _ExpenseSummaryFilter.net,
                            onTap: () {
                              setState(() {
                                _activeSummaryFilter =
                                    _ExpenseSummaryFilter.net;
                                _visibleDateGroupCount =
                                    _initialVisibleDateGroups;
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
                                        _visibleDateGroupCount =
                                            _initialVisibleDateGroups;
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
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search expenses',
                        hintText:
                            'Search by date, title, description, or amount',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (_) => setState(() {
                        _visibleDateGroupCount = _initialVisibleDateGroups;
                      }),
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
                                child: const Text('All Entries'),
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
                            ...visibleGroupedEntries.entries.map(
                              (group) => Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _DateTransactionGroup(
                                  date: group.key,
                                  entries: group.value,
                                  entryById: entryById,
                                  expanded: expandedDate == group.key,
                                  onTap: () {
                                    setState(() {
                                      _expandedDate = expandedDate == group.key
                                          ? null
                                          : group.key;
                                    });
                                  },
                                  onView: (entry) {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.expenseDetail,
                                      arguments: ExpenseDetailArgs(
                                        entryId: entry.id,
                                      ),
                                    );
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
                          if (groupedEntries.length >
                              visibleGroupedEntries.length)
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleDateGroupCount += 10;
                                  });
                                },
                                child: const Text('Show more'),
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
        return !entry.isManagedLentEntry &&
            (entry.type == 'lent' || entry.hasTrackedSplitLent);
      case _ExpenseSummaryFilter.borrowed:
        return entry.type == 'borrowed' || entry.isBorrowedResolutionExpense;
    }
  }

  bool _matchesSearchQuery(ExpenseRecord entry, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchDateFormat = DateFormat('dd-MM-yyyy');
    if (matchesEquivalentDateQuery(entry.date, normalizedQuery)) {
      return true;
    }
    final searchableValues = <String>[
      entry.title,
      entry.notes,
      entry.category.name,
      entry.paymentMode,
      entry.type,
      if (entry.counterparty != null) entry.counterparty!,
      if (entry.bank != null) entry.bank!.name,
      entry.amount.toStringAsFixed(2),
      entry.amount.toString(),
      AppConstants.shortDateFormat.format(entry.date),
      searchDateFormat.format(entry.date),
      ...equivalentDateSearchTerms(entry.date),
    ].map((value) => value.toLowerCase());

    return searchableValues.any((value) => value.contains(normalizedQuery));
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

  ExpenseDashboardData _buildSummary(List<ExpenseRecord> entries) {
    return ExpenseDashboardData(
      totalCredit: entries
          .where((entry) => entry.isCredit)
          .fold<double>(0, (sum, entry) => sum + entry.amount),
      totalDebit: entries.fold<double>(
        0,
        (sum, entry) => sum + entry.effectiveDebitAmount,
      ),
      totalLent: entries.fold<double>(
        0,
        (sum, entry) => sum + entry.effectiveLentAmount,
      ),
      totalBorrowed: entries
          .where((entry) => entry.type == 'borrowed')
          .fold<double>(
            0,
            (sum, entry) =>
                sum + (entry.borrowedSummary?.pendingAmount ?? entry.amount),
          ),
      entries: entries,
    );
  }

  Future<void> _deleteEntry(BuildContext context, ExpenseRecord entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction'),
        content: Text(
          entry.isResolutionIncome
              ? 'Delete "${entry.title}"? This will add the amount back to pending lent.'
              : entry.isBorrowedResolutionExpense
              ? 'Delete "${entry.title}"? This will add the amount back to pending borrowed.'
              : entry.borrowedSummary?.resolutionCount != null &&
                    entry.borrowedSummary!.resolutionCount > 0
              ? 'Delete "${entry.title}" and all linked borrowed resolution entries?'
              : entry.splitSummary?.hasSettlements == true
              ? 'Delete "${entry.title}" and all linked resolution entries?'
              : 'Delete "${entry.title}"?',
        ),
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

    try {
      await context.read<ExpenseRepository>().deleteExpense(entry.id);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: '"${entry.title}" deleted.');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: error.toString(),
        type: AppSnackBarType.error,
      );
    }
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
    required this.entryById,
    required this.expanded,
    required this.onTap,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime date;
  final List<ExpenseRecord> entries;
  final Map<int, ExpenseRecord> entryById;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<ExpenseRecord> onView;
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
                    .map((entry) {
                      final actionEntry = _resolveActionEntry(entry, entryById);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ExpenseEntryCard(
                          entry: entry,
                          actionEntry: actionEntry,
                          onView: () => onView(entry),
                          onEdit: () => onEdit(actionEntry),
                          onDelete: () => onDelete(actionEntry),
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
    required this.actionEntry,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseRecord entry;
  final ExpenseRecord actionEntry;
  final VoidCallback onView;
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
                    if (entry.splitSummary != null) ...<Widget>[
                      const SizedBox(height: 6),
                      _SplitEntrySummary(entry: entry),
                    ],
                    if (entry.borrowedSummary != null) ...<Widget>[
                      const SizedBox(height: 6),
                      _BorrowedEntrySummary(entry: entry),
                    ],
                    if (entry.isResolutionIncome) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        'Lent resolution income',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (entry.isBorrowedResolutionExpense) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        'Borrowed resolution expense',
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
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: <Widget>[
              TextButton(onPressed: onView, child: const Text('View')),
              if (actionEntry.canEdit)
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              if (actionEntry.canDelete)
                TextButton(onPressed: onDelete, child: const Text('Delete')),
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

class _BorrowedEntrySummary extends StatelessWidget {
  const _BorrowedEntrySummary({required this.entry});

  final ExpenseRecord entry;

  @override
  Widget build(BuildContext context) {
    final summary = entry.borrowedSummary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SplitSummaryLine(
          label: 'Resolved',
          value: AppConstants.currency(summary.settledAmount),
        ),
        const SizedBox(height: 4),
        _SplitSummaryLine(
          label: 'Pending',
          value: AppConstants.currency(summary.pendingAmount),
        ),
        const SizedBox(height: 4),
        _SplitSummaryLine(
          label: 'Repayments',
          value: '${summary.resolutionCount}',
        ),
      ],
    );
  }
}

ExpenseRecord _resolveActionEntry(
  ExpenseRecord entry,
  Map<int, ExpenseRecord> entryById,
) {
  if (entry.isManagedLentEntry && entry.splitSummary?.expenseEntryId != null) {
    return entryById[entry.splitSummary!.expenseEntryId!] ?? entry;
  }
  return entry;
}

class _SplitEntrySummary extends StatelessWidget {
  const _SplitEntrySummary({required this.entry});

  final ExpenseRecord entry;

  @override
  Widget build(BuildContext context) {
    final summary = entry.splitSummary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!entry.isManagedLentEntry) ...<Widget>[
          _SplitSummaryLine(
            label: 'My share',
            value: AppConstants.currency(summary.selfAmount),
          ),
          const SizedBox(height: 4),
        ],
        _SplitSummaryLine(
          label: 'Lent amount',
          value: entry.isManagedLentEntry
              ? AppConstants.currency(entry.amount)
              : AppConstants.currency(summary.pendingLentAmount),
        ),
        const SizedBox(height: 4),
        _SplitSummaryLine(
          label: entry.isManagedLentEntry ? 'Status' : 'Participants',
          value: entry.isManagedLentEntry
              ? (summary.isFullySettled ? 'Settled' : 'Pending')
              : '${summary.participantCount}',
        ),
      ],
    );
  }
}

class _SplitSummaryLine extends StatelessWidget {
  const _SplitSummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
