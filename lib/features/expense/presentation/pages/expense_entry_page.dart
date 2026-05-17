import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/expense_repository.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/models/expense_models.dart';
import '../blocs/expense_form/expense_form_bloc.dart';
import '../widgets/expense_split_flow.dart';

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
        appBar: AppBar(
          title: BlocBuilder<ExpenseFormBloc, ExpenseFormState>(
            buildWhen: (previous, current) =>
                previous.expenseId != current.expenseId,
            builder: (context, state) =>
                Text(state.isEditing ? 'Edit Transaction' : 'Add Transaction'),
          ),
        ),
        body: BlocBuilder<ExpenseFormBloc, ExpenseFormState>(
          builder: (context, state) {
            final categoryOptions = state.categories
                .map(
                  (category) => AppSelectOption<int>(
                    value: category.id,
                    label: category.name,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(
                        category.colorValue,
                      ).withValues(alpha: 0.16),
                      child: Icon(
                        AppConstants.categoryIconFromCodePoint(
                          category.iconCodePoint,
                        ),
                        size: 14,
                        color: Color(category.colorValue),
                      ),
                    ),
                  ),
                )
                .toList(growable: false);

            final bankOptions = <AppSelectOption<int?>>[
              const AppSelectOption<int?>(
                value: null,
                label: 'No bank selected',
              ),
              ...state.banks.map(
                (bank) =>
                    AppSelectOption<int?>(value: bank.id, label: bank.name),
              ),
            ];

            final paymentModes = state.isEditing
                ? AppConstants.paymentModes
                      .where((mode) => mode != 'Self Transfer')
                      .toList(growable: false)
                : AppConstants.paymentModes;
            final paymentOptions = paymentModes
                .map(
                  (mode) => AppSelectOption<String>(value: mode, label: mode),
                )
                .toList(growable: false);

            return ListView(
              key: ValueKey<int?>(state.expenseId),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                AppPanel(
                  padding: const EdgeInsets.all(14),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.4,
                    children: <Widget>[
                      _TypeRadioCard(
                        label: 'Expense',
                        selected: state.type == 'expense',
                        onTap: () => context.read<ExpenseFormBloc>().add(
                          const ExpenseTypeChanged('expense'),
                        ),
                      ),
                      _TypeRadioCard(
                        label: 'Income',
                        selected: state.type == 'income',
                        onTap: () => context.read<ExpenseFormBloc>().add(
                          const ExpenseTypeChanged('income'),
                        ),
                      ),
                      _TypeRadioCard(
                        label: 'Lent',
                        selected: state.type == 'lent',
                        onTap: () => context.read<ExpenseFormBloc>().add(
                          const ExpenseTypeChanged('lent'),
                        ),
                      ),
                      _TypeRadioCard(
                        label: 'Borrowed',
                        selected: state.type == 'borrowed',
                        onTap: () => context.read<ExpenseFormBloc>().add(
                          const ExpenseTypeChanged('borrowed'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.title,
                  decoration: InputDecoration(
                    labelText: state.type == 'borrowed' || state.type == 'lent'
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
                TextFormField(
                  initialValue: state.amount,
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
                AppSelectField<int>(
                  label: 'Category',
                  value: state.categoryId,
                  options: categoryOptions,
                  errorText: state.showValidation && state.categoryId == null
                      ? 'Select a category'
                      : null,
                  onChanged: (value) => context.read<ExpenseFormBloc>().add(
                    ExpenseCategoryChanged(value),
                  ),
                ),
                if (state.type == 'expense' && !state.isSelfTransfer) ...<Widget>[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      TextButton(
                        onPressed: () async {
                          if ((state.parsedAmount ?? 0) <= 0) {
                            showAppSnackBar(
                              context,
                              message: 'Enter the expense amount first.',
                              type: AppSnackBarType.warning,
                            );
                            return;
                          }
                          final result = await showExpenseSplitEditor(
                            context,
                            totalAmount: state.parsedAmount ?? 0,
                            initialDraft: state.splitDraft,
                          );
                          if (result != null && context.mounted) {
                            context.read<ExpenseFormBloc>().add(
                              ExpenseSplitDraftChanged(result),
                            );
                          }
                        },
                        child: Text(
                          state.splitDraft == null
                              ? 'Split Expense'
                              : 'Edit Split Expense',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          if ((state.parsedAmount ?? 0) <= 0) {
                            showAppSnackBar(
                              context,
                              message: 'Enter the expense amount first.',
                              type: AppSnackBarType.warning,
                            );
                            return;
                          }
                          if (!state.isBorrowedExpense) {
                            showAppSnackBar(
                              context,
                              message:
                                  'Select the Borrowed category to resolve borrowed amount.',
                              type: AppSnackBarType.warning,
                            );
                            return;
                          }
                          final result = await showBorrowedResolutionEditor(
                            context,
                            repository: context.read<ExpenseRepository>(),
                            expenseAmount: state.parsedAmount ?? 0,
                            initialDraft: state.borrowedResolutionDraft,
                          );
                          if (result != null && context.mounted) {
                            context.read<ExpenseFormBloc>().add(
                              ExpenseBorrowedResolutionChanged(result),
                            );
                          }
                        },
                        child: Text(
                          state.borrowedResolutionDraft == null
                              ? 'Resolve Borrowed'
                              : 'Edit Resolve Borrowed',
                        ),
                      ),
                    ],
                  ),
                  if (state.splitDraft != null)
                    AppPanel(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SplitSummaryRow(
                            label: 'My share',
                            value: AppConstants.currency(
                              state.splitDraft!.selfAmount,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SplitSummaryRow(
                            label: 'Lent amount',
                            value: AppConstants.currency(
                              state.splitDraft!.pendingLentAmount,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SplitSummaryRow(
                            label: 'Participants',
                            value: state.splitDraft!.participants
                                .map((participant) => participant.name)
                                .join(', '),
                          ),
                        ],
                      ),
                    ),
                  if (state.borrowedResolutionDraft != null) ...<Widget>[
                    const SizedBox(height: 12),
                    AppPanel(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SplitSummaryRow(
                            label: 'Borrowed entry',
                            value: state
                                .borrowedResolutionDraft!
                                .borrowedEntryTitle,
                          ),
                          const SizedBox(height: 8),
                          _SplitSummaryRow(
                            label: 'Resolve amount',
                            value: AppConstants.currency(
                              state.borrowedResolutionDraft!.settledAmount,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                if (state.type == 'income') ...<Widget>[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        if ((state.parsedAmount ?? 0) <= 0) {
                          showAppSnackBar(
                            context,
                            message: 'Enter the income amount first.',
                            type: AppSnackBarType.warning,
                          );
                          return;
                        }
                        if (!state.isLentIncome) {
                          showAppSnackBar(
                            context,
                            message:
                                'Select the Lent category to resolve lent shares.',
                            type: AppSnackBarType.warning,
                          );
                          return;
                        }
                        final result = await showLentResolutionEditor(
                          context,
                          repository: context.read<ExpenseRepository>(),
                          incomeAmount: state.parsedAmount ?? 0,
                          initialDraft: state.lentResolutionDraft,
                        );
                        if (result != null && context.mounted) {
                          context.read<ExpenseFormBloc>().add(
                            ExpenseLentResolutionChanged(result),
                          );
                        }
                      },
                      child: Text(
                        state.lentResolutionDraft == null
                            ? 'Resolve Lent'
                            : 'Edit Lent Resolution',
                      ),
                    ),
                  ),
                  if (state.lentResolutionDraft != null)
                    AppPanel(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SplitSummaryRow(
                            label: 'Selected shares',
                            value:
                                '${state.lentResolutionDraft!.participants.length}',
                          ),
                          const SizedBox(height: 8),
                          _SplitSummaryRow(
                            label: 'Settlement amount',
                            value: AppConstants.currency(
                              state.lentResolutionDraft!.participants
                                  .fold<double>(
                                    0,
                                    (sum, participant) =>
                                        sum + participant.pendingAmount,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                AppSelectField<String>(
                  label: 'Payment Mode',
                  value: state.paymentMode,
                  options: paymentOptions,
                  errorText:
                      state.showValidation &&
                          state.isSelfTransfer &&
                          state.selfTransferDraft == null
                      ? 'Configure self transfer'
                      : null,
                  onChanged: (value) async {
                    if (value != 'Self Transfer') {
                      context.read<ExpenseFormBloc>().add(
                        ExpensePaymentModeChanged(value),
                      );
                      return;
                    }

                    final result = await Navigator.of(context).push<SelfTransferDraft>(
                      MaterialPageRoute<SelfTransferDraft>(
                        builder: (_) => SelfTransferPage(
                          banks: state.banks,
                          initialDraft: state.selfTransferDraft,
                        ),
                      ),
                    );
                    if (result != null && context.mounted) {
                      context.read<ExpenseFormBloc>().add(
                        ExpenseSelfTransferDraftChanged(result),
                      );
                    }
                  },
                ),
                if (state.selfTransferDraft != null) ...<Widget>[
                  const SizedBox(height: 12),
                  AppPanel(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SplitSummaryRow(
                          label: 'Category',
                          value: state.selfTransferDraft!.sourcePaymentMode,
                        ),
                        const SizedBox(height: 8),
                        _SplitSummaryRow(
                          label: 'Recipient',
                          value: state.selfTransferDraft!.recipientName,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppSelectField<int?>(
                  label: state.isSelfTransfer
                      ? 'Source Bank Name (Optional)'
                      : 'Bank Name (Optional)',
                  value: state.bankId,
                  options: bankOptions,
                  onChanged: (value) => context.read<ExpenseFormBloc>().add(
                    ExpenseBankChanged(value),
                  ),
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
                TextFormField(
                  initialValue: state.counterparty,
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
                TextFormField(
                  initialValue: state.notes,
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
                          : state.isEditing
                          ? 'Update Transaction'
                          : 'Save Transaction',
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

class SelfTransferPage extends StatefulWidget {
  const SelfTransferPage({
    super.key,
    required this.banks,
    this.initialDraft,
  });

  final List<BankName> banks;
  final SelfTransferDraft? initialDraft;

  @override
  State<SelfTransferPage> createState() => _SelfTransferPageState();
}

class _SelfTransferPageState extends State<SelfTransferPage> {
  late String _sourcePaymentMode;
  late int? _recipientBankId;

  @override
  void initState() {
    super.initState();
    final sourceOptions = _sourcePaymentModes;
    _sourcePaymentMode =
        widget.initialDraft?.sourcePaymentMode ?? sourceOptions.first;
    _recipientBankId = widget.initialDraft?.recipientBankId;
  }

  @override
  Widget build(BuildContext context) {
    final sourceOptions = _sourcePaymentModes
        .map((mode) => AppSelectOption<String>(value: mode, label: mode))
        .toList(growable: false);
    final recipientOptions = <AppSelectOption<int?>>[
      const AppSelectOption<int?>(value: null, label: 'Cash'),
      ...widget.banks.map(
        (bank) => AppSelectOption<int?>(value: bank.id, label: bank.name),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Self Transfer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          AppSelectField<String>(
            label: 'Category',
            value: _sourcePaymentMode,
            options: sourceOptions,
            onChanged: (value) {
              setState(() {
                _sourcePaymentMode = value;
              });
            },
          ),
          const SizedBox(height: 16),
          AppSelectField<int?>(
            label: 'Recipient',
            value: _recipientBankId,
            options: recipientOptions,
            onChanged: (value) {
              setState(() {
                _recipientBankId = value;
              });
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                SelfTransferDraft(
                  sourcePaymentMode: _sourcePaymentMode,
                  recipientBankId: _recipientBankId,
                  recipientName: _recipientName,
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Save Transfer'),
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _sourcePaymentModes => AppConstants.paymentModes
      .where((mode) => mode != 'Self Transfer')
      .toList(growable: false);

  String get _recipientName {
    if (_recipientBankId == null) {
      return 'Cash';
    }
    for (final bank in widget.banks) {
      if (bank.id == _recipientBankId) {
        return bank.name;
      }
    }
    return 'Cash';
  }
}

class _SplitSummaryRow extends StatelessWidget {
  const _SplitSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _TypeRadioCard extends StatelessWidget {
  const _TypeRadioCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
