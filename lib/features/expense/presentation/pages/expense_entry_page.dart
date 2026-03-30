import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../blocs/expense_form/expense_form_bloc.dart';

class ExpenseEntryPage extends StatelessWidget {
  const ExpenseEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseFormBloc, ExpenseFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ExpenseFormStatus.success) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Expense Entry')),
        body: BlocBuilder<ExpenseFormBloc, ExpenseFormState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment(
                      value: 'expense',
                      icon: Icon(Icons.arrow_circle_down_rounded),
                      label: Text('Expense'),
                    ),
                    ButtonSegment(
                      value: 'income',
                      icon: Icon(Icons.arrow_circle_up_rounded),
                      label: Text('Income'),
                    ),
                    ButtonSegment(
                      value: 'borrowed',
                      icon: Icon(Icons.account_balance_wallet_rounded),
                      label: Text('Borrowed'),
                    ),
                    ButtonSegment(
                      value: 'lent',
                      icon: Icon(Icons.savings_rounded),
                      label: Text('Lent'),
                    ),
                  ],
                  selected: <String>{state.type},
                  onSelectionChanged: (selection) {
                    context.read<ExpenseFormBloc>().add(
                      ExpenseTypeChanged(selection.first),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText:
                        state.type == 'borrowed' || state.type == 'lent'
                        ? 'Title or purpose'
                        : 'Title',
                    errorText:
                        state.showValidation && state.title.trim().isEmpty
                        ? 'Enter a title'
                        : null,
                  ),
                  onChanged: (value) => context.read<ExpenseFormBloc>().add(
                    ExpenseTitleChanged(value),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'Rs ',
                    errorText:
                        state.showValidation && (state.parsedAmount ?? 0) <= 0
                        ? 'Enter a valid amount'
                        : null,
                  ),
                  onChanged: (value) => context.read<ExpenseFormBloc>().add(
                    ExpenseAmountChanged(value),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: state.categoryId,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    errorText: state.showValidation && state.categoryId == null
                        ? 'Select a category'
                        : null,
                  ),
                  items: state.categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => context.read<ExpenseFormBloc>().add(
                    ExpenseCategoryChanged(value),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: state.bankId,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name (Optional)',
                  ),
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No bank selected'),
                    ),
                    ...state.banks.map(
                      (bank) => DropdownMenuItem<int?>(
                        value: bank.id,
                        child: Text(bank.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => context.read<ExpenseFormBloc>().add(
                    ExpenseBankChanged(value),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: state.paymentMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: AppConstants.paymentModes
                      .map(
                        (mode) => DropdownMenuItem<String>(
                          value: mode,
                          child: Text(mode),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ExpenseFormBloc>().add(
                        ExpensePaymentModeChanged(value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.date ?? DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && context.mounted) {
                      context.read<ExpenseFormBloc>().add(
                        ExpenseDateChanged(picked),
                      );
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(
                      AppConstants.shortDateFormat.format(
                        state.date ?? DateTime.now(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: switch (state.type) {
                      'borrowed' => 'Borrowed from',
                      'lent' => 'Lent to',
                      _ => 'Counterparty (optional)',
                    },
                  ),
                  onChanged: (value) => context.read<ExpenseFormBloc>().add(
                    ExpenseCounterpartyChanged(value),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  onChanged: (value) => context.read<ExpenseFormBloc>().add(
                    ExpenseNotesChanged(value),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.status == ExpenseFormStatus.submitting
                      ? null
                      : () {
                          context.read<ExpenseFormBloc>().add(
                            const ExpenseSubmitted(),
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      state.status == ExpenseFormStatus.submitting
                          ? 'Saving...'
                          : 'Save Entry',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
