import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/finance_repository.dart';
import '../controllers/add_entry_form_controller.dart';

class AddEntryScreen extends StatelessWidget {
  const AddEntryScreen({super.key});

  static const String routeName = 'add-entry';
  static const String routePath = '/add-entry';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddEntryFormCubit>(
      create: (context) =>
          AddEntryFormCubit(context.read<FinanceRepository>())..initialize(),
      child: const _AddEntryView(),
    );
  }
}

class _AddEntryView extends StatelessWidget {
  const _AddEntryView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddEntryFormCubit, AddEntryFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AddEntryFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry added successfully.')),
          );
          Navigator.of(context).pop(true);
          return;
        }

        if (state.status == AddEntryFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, formState) {
        final controller = context.read<AddEntryFormCubit>();

        return Scaffold(
          appBar: AppBar(title: const Text('Add Entry')),
          body: formState.isLoading && formState.categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: <Widget>[
                    SegmentedButton<TransactionType>(
                      segments: const <ButtonSegment<TransactionType>>[
                        ButtonSegment(
                          value: TransactionType.expense(),
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_downward_rounded),
                        ),
                        ButtonSegment(
                          value: TransactionType.income(),
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_upward_rounded),
                        ),
                        ButtonSegment(
                          value: TransactionType.borrowed(),
                          label: Text('Borrowed'),
                          icon: Icon(Icons.account_balance_wallet_rounded),
                        ),
                        ButtonSegment(
                          value: TransactionType.lent(),
                          label: Text('Lent'),
                          icon: Icon(Icons.savings_rounded),
                        ),
                      ],
                      selected: <TransactionType>{formState.type},
                      onSelectionChanged: (selection) {
                        controller.setType(selection.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: formState.type.isLiability ||
                                formState.type.isReceivable
                            ? 'Title or purpose'
                            : 'Title',
                        errorText:
                            formState.showValidation && !formState.hasValidTitle
                            ? 'Enter a title'
                            : null,
                      ),
                      onChanged: controller.setTitle,
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
                            formState.showValidation &&
                                !formState.hasValidAmount
                            ? 'Enter a valid amount'
                            : null,
                      ),
                      onChanged: controller.setAmount,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: formState.selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        errorText: formState.showValidation &&
                                formState.selectedCategoryId == null
                            ? 'Select a category'
                            : null,
                      ),
                      items: formState.categories
                          .map(
                            (category) => DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: controller.setCategory,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: formState.paymentMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode',
                      ),
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
                          controller.setPaymentMode(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: formState.date,
                          firstDate: DateTime(2022),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (selectedDate != null) {
                          controller.setDate(selectedDate);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Text(
                          AppConstants.shortDateFormat.format(formState.date),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: formState.type.isLiability
                            ? 'Borrowed from'
                            : formState.type.isReceivable
                            ? 'Lent to'
                            : 'Counterparty (optional)',
                      ),
                      onChanged: controller.setCounterparty,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      onChanged: controller.setNotes,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: formState.isSaving
                          ? null
                          : () {
                              controller.submit();
                            },
                      icon: formState.isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Save Entry'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
