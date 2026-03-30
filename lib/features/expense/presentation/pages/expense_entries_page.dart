import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_models.dart';

class ExpenseEntriesPage extends StatefulWidget {
  const ExpenseEntriesPage({super.key});

  @override
  State<ExpenseEntriesPage> createState() => _ExpenseEntriesPageState();
}

class _ExpenseEntriesPageState extends State<ExpenseEntriesPage> {
  ExpenseEntryFilter _filter = const ExpenseEntryFilter();

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
                                  initialDate: _filter.fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2022),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _filter = _filter.copyWith(fromDate: picked);
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
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          key: ValueKey<int?>(_filter.bankId),
                          initialValue: _filter.bankId,
                          decoration: const InputDecoration(labelText: 'Bank'),
                          items: <DropdownMenuItem<int?>>[
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All Banks'),
                            ),
                            ...options.banks.map(
                              (bank) => DropdownMenuItem<int?>(
                                value: bank.id,
                                child: Text(bank.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filter = _filter.copyWith(bankId: value);
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          key: ValueKey<int?>(_filter.categoryId),
                          initialValue: _filter.categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: <DropdownMenuItem<int?>>[
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...options.categories.map(
                              (category) => DropdownMenuItem<int?>(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filter = _filter.copyWith(categoryId: value);
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ExpenseFlowFilter>(
                          key: ValueKey<ExpenseFlowFilter>(_filter.flow),
                          initialValue: _filter.flow,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const <DropdownMenuItem<ExpenseFlowFilter>>[
                            DropdownMenuItem(
                              value: ExpenseFlowFilter.all,
                              child: Text('All'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseFlowFilter.credit,
                              child: Text('Credit'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseFlowFilter.debit,
                              child: Text('Debit'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _filter = _filter.copyWith(flow: value);
                              });
                            }
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
                        child: Center(child: Text('No entries match your filters.')),
                      ),
                    )
                  else
                    ...entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppPanel(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
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
                            title: Text(entry.title),
                            subtitle: Text(
                              [
                                entry.category.name,
                                if (entry.bank != null) entry.bank!.name,
                                AppConstants.shortDateFormat.format(entry.date),
                                entry.isCredit ? 'Credit' : 'Debit',
                              ].join(' - '),
                            ),
                            trailing: Text(
                              '${entry.isCredit ? '+' : '-'}${AppConstants.currency(entry.amount)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<_ExpenseFilterOptions> _loadOptions(ExpenseRepository repository) async {
    final categories = await repository.watchCategories().first;
    final banks = await repository.watchBanks().first;
    return _ExpenseFilterOptions(categories: categories, banks: banks);
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
  const _ExpenseFilterOptions({
    required this.categories,
    required this.banks,
  });

  final List<ExpenseCategory> categories;
  final List<BankName> banks;
}
