import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/formatters/indian_number_formatter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_models.dart';

class ExpenseEntriesPage extends StatefulWidget {
  const ExpenseEntriesPage({super.key});

  @override
  State<ExpenseEntriesPage> createState() => _ExpenseEntriesPageState();
}

class _ExpenseEntriesPageState extends State<ExpenseEntriesPage> {
  static const int _entriesPerPage = 10;

  ExpenseEntryFilter _filter = const ExpenseEntryFilter();
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ExpenseRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('All Entries')),
      body: FutureBuilder<_ExpenseFilterOptions>(
        future: _loadOptions(repository),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final options = snapshot.data!;
          return StreamBuilder<List<ExpenseRecord>>(
            stream: repository.watchEntries(filter: _filter),
            builder: (context, entrySnapshot) {
              final entries = entrySnapshot.data ?? const <ExpenseRecord>[];
              final entryById = <int, ExpenseRecord>{
                for (final entry in entries) entry.id: entry,
              };

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Filters',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _filter = const ExpenseEntryFilter();
                                  _currentPage = 1;
                                });
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            _DateFilterButton(
                              label: 'From',
                              value: _filter.fromDate,
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _filter.fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2022),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _filter = _filter.copyWith(
                                      fromDate: picked,
                                    );
                                    _currentPage = 1;
                                  });
                                }
                              },
                            ),
                            _DateFilterButton(
                              label: 'To',
                              value: _filter.toDate,
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _filter.toDate ?? DateTime.now(),
                                  firstDate: DateTime(2022),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _filter = _filter.copyWith(toDate: picked);
                                    _currentPage = 1;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppSelectField<int?>(
                          label: 'Bank',
                          value: _filter.bankId,
                          options: <AppSelectOption<int?>>[
                            const AppSelectOption<int?>(
                              value: null,
                              label: 'All Banks',
                            ),
                            ...options.banks.map(
                              (bank) => AppSelectOption<int?>(
                                value: bank.id,
                                label: bank.name,
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filter = _filter.copyWith(bankId: value);
                              _currentPage = 1;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        AppSelectField<int?>(
                          label: 'Category',
                          value: _filter.categoryId,
                          options: <AppSelectOption<int?>>[
                            const AppSelectOption<int?>(
                              value: null,
                              label: 'All Categories',
                            ),
                            ...options.categories.map(
                              (category) => AppSelectOption<int?>(
                                value: category.id,
                                label: category.name,
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filter = _filter.copyWith(categoryId: value);
                              _currentPage = 1;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        AppSelectField<ExpenseFlowFilter>(
                          label: 'Type',
                          value: _filter.flow,
                          options: const <AppSelectOption<ExpenseFlowFilter>>[
                            AppSelectOption(
                              value: ExpenseFlowFilter.all,
                              label: 'All',
                            ),
                            AppSelectOption(
                              value: ExpenseFlowFilter.credit,
                              label: 'Credit',
                            ),
                            AppSelectOption(
                              value: ExpenseFlowFilter.debit,
                              label: 'Debit',
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filter = _filter.copyWith(flow: value);
                              _currentPage = 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    const AppPanel(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: Text('No entries match your filters.'),
                        ),
                      ),
                    )
                  else
                    ..._buildPagedEntries(entries).map((entry) {
                      final actionEntry = _resolveActionEntry(entry, entryById);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppPanel(
                          child: Column(
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  CircleAvatar(
                                    backgroundColor: Color(
                                      entry.category.colorValue,
                                    ).withValues(alpha: 0.14),
                                    child: Icon(
                                      AppConstants.categoryIconFromCodePoint(
                                        entry.category.iconCodePoint,
                                      ),
                                      color: Color(entry.category.colorValue),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          entry.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            entry.category.name,
                                            if (entry.bank != null)
                                              entry.bank!.name,
                                            AppConstants.shortDateFormat.format(
                                              entry.date,
                                            ),
                                            entry.isCredit ? 'Credit' : 'Debit',
                                          ].join(' • '),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        if (entry.splitSummary !=
                                            null) ...<Widget>[
                                          const SizedBox(height: 8),
                                          _SplitEntrySummary(entry: entry),
                                        ],
                                        if (entry.borrowedSummary !=
                                            null) ...<Widget>[
                                          const SizedBox(height: 8),
                                          _BorrowedEntrySummary(entry: entry),
                                        ],
                                        if (entry
                                            .isBorrowedResolutionExpense) ...<
                                          Widget
                                        >[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Borrowed resolution expense',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${entry.isCredit ? '+' : '-'}${IndianNumberFormatter.formatCompactCurrency(entry.amount)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 4,
                                children: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.expenseDetail,
                                          arguments: ExpenseDetailArgs(
                                            entryId: entry.id,
                                          ),
                                        ),
                                    child: const Text('View'),
                                  ),
                                  if (actionEntry.canEdit)
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pushNamed(
                                            AppRoutes.expenseAdd,
                                            arguments: ExpenseEditorArgs(
                                              entry: actionEntry,
                                            ),
                                          ),
                                      child: const Text('Edit'),
                                    ),
                                  if (actionEntry.canDelete)
                                    TextButton(
                                      onPressed: () =>
                                          _deleteEntry(actionEntry),
                                      child: const Text('Delete'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (entries.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    _PaginationControls(
                      currentPage: _currentPage,
                      totalPages: _totalPages(entries.length),
                      onPageSelected: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<_ExpenseFilterOptions> _loadOptions(
    ExpenseRepository repository,
  ) async {
    final categories = await repository.watchCategories().first;
    final banks = await repository.watchBanks().first;
    return _ExpenseFilterOptions(categories: categories, banks: banks);
  }

  Future<void> _deleteEntry(ExpenseRecord entry) async {
    final repository = context.read<ExpenseRepository>();
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

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await repository.deleteExpense(entry.id);
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: '"${entry.title}" deleted.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: error.toString(),
        type: AppSnackBarType.error,
      );
    }
  }

  List<ExpenseRecord> _buildPagedEntries(List<ExpenseRecord> entries) {
    final totalPages = _totalPages(entries.length);
    final currentPage = _currentPage.clamp(1, totalPages);
    if (currentPage != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentPage = currentPage;
        });
      });
    }
    final startIndex = (currentPage - 1) * _entriesPerPage;
    final endIndex = (startIndex + _entriesPerPage).clamp(0, entries.length);
    return entries.sublist(startIndex, endIndex);
  }

  int _totalPages(int totalEntries) {
    return totalEntries == 0 ? 1 : ((totalEntries - 1) ~/ _entriesPerPage) + 1;
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_rounded),
      label: Text(
        value == null
            ? '$label date'
            : '$label: ${AppConstants.shortDateFormat.format(value!)}',
      ),
    );
  }
}

class _ExpenseFilterOptions {
  const _ExpenseFilterOptions({required this.categories, required this.banks});

  final List<ExpenseCategory> categories;
  final List<BankName> banks;
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

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        TextButton.icon(
          onPressed: currentPage > 1
              ? () => onPageSelected(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Prev'),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(totalPages, (index) {
                final page = index + 1;
                final isSelected = page == currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: TextButton(
                    onPressed: () => onPageSelected(page),
                    style: TextButton.styleFrom(
                      minimumSize: Size(_pageButtonWidth(page), 36),
                      padding: EdgeInsets.symmetric(
                        horizontal: _pageButtonHorizontalPadding(page),
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      foregroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      textStyle: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                    ),
                    child: Text('$page'),
                  ),
                );
              }),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: currentPage < totalPages
              ? () => onPageSelected(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Next'),
        ),
      ],
    );
  }

  double _pageButtonWidth(int page) {
    final digits = page.toString().length;
    return 18 + (digits * 10);
  }

  double _pageButtonHorizontalPadding(int page) {
    final digits = page.toString().length;
    final padding = 9 - (digits * 1.5);
    return padding < 3 ? 3 : padding;
  }
}
