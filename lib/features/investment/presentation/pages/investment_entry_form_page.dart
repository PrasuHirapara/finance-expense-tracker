import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../blocs/investment_form/investment_form_bloc.dart';

class InvestmentEntryFormPage extends StatefulWidget {
  const InvestmentEntryFormPage({super.key});

  @override
  State<InvestmentEntryFormPage> createState() => _InvestmentEntryFormPageState();
}

class _InvestmentEntryFormPageState extends State<InvestmentEntryFormPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvestmentFormBloc, InvestmentFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == InvestmentFormStatus.success) {
          showAppSnackBar(
            context,
            message: 'Investment saved successfully.',
            type: AppSnackBarType.info,
          );
          Navigator.of(context).pop();
        } else if (state.status == InvestmentFormStatus.failure && state.errorMessage != null) {
          showAppSnackBar(
            context,
            message: state.errorMessage!,
            type: AppSnackBarType.warning,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<InvestmentFormBloc, InvestmentFormState>(
            buildWhen: (previous, current) => previous.isBuyAmtOverridden != current.isBuyAmtOverridden,
            builder: (context, state) {
              final isEdit = state.qty != null; // check if initialized or edit
              return Text(state.isBuyAmtOverridden || isEdit ? 'Edit Investment' : 'Add Investment');
            },
          ),
        ),
        body: BlocBuilder<InvestmentFormBloc, InvestmentFormState>(
          builder: (context, state) {
            if (state.status == InvestmentFormStatus.loading || state.status == InvestmentFormStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            final categoryOptions = state.categories
                .map(
                  (category) => AppSelectOption<int>(
                    value: category.id,
                    label: category.name,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(category.colorValue).withValues(alpha: 0.16),
                      child: Icon(
                        AppConstants.categoryIconFromCodePoint(category.iconCodePoint),
                        size: 14,
                        color: Color(category.colorValue),
                      ),
                    ),
                  ),
                )
                .toList();

            final brokerOptions = <AppSelectOption<int?>>[
              const AppSelectOption<int?>(
                value: null,
                label: 'No broker / tax profile',
              ),
              ...state.profiles.map(
                (profile) => AppSelectOption<int?>(
                  value: profile.id,
                  label: profile.brokerName,
                ),
              ),
            ];

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  // Category Dropdown
                  AppSelectField<int>(
                    label: 'Category',
                    value: state.categoryId,
                    options: categoryOptions,
                    errorText: state.showValidation && state.categoryId == null ? 'Select a category' : null,
                    onChanged: (value) {
                      context.read<InvestmentFormBloc>().add(InvestmentFormCategoryChanged(value));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Symbol
                  TextFormField(
                    initialValue: state.symbol,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Symbol / Name',
                      errorText: state.showValidation && state.symbol.trim().isEmpty ? 'Enter symbol name' : null,
                    ),
                    onChanged: (value) {
                      context.read<InvestmentFormBloc>().add(InvestmentFormSymbolChanged(value));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextFormField(
                    initialValue: state.qty?.toString() ?? '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      errorText: state.showValidation && (state.qty == null || state.qty! <= 0)
                          ? 'Enter valid quantity'
                          : null,
                    ),
                    onChanged: (value) {
                      final val = double.tryParse(value);
                      context.read<InvestmentFormBloc>().add(InvestmentFormQtyChanged(val));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Buy Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.buyDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && context.mounted) {
                        context.read<InvestmentFormBloc>().add(InvestmentFormBuyDateChanged(picked));
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Buy Date'),
                      child: Text(
                        AppConstants.shortDateFormat.format(state.buyDate ?? DateTime.now()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buy Rate
                  TextFormField(
                    initialValue: state.buyRate?.toString() ?? '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Buy Rate',
                      errorText: state.showValidation && (state.buyRate == null || state.buyRate! < 0)
                          ? 'Enter buy rate'
                          : null,
                    ),
                    onChanged: (value) {
                      final val = double.tryParse(value);
                      context.read<InvestmentFormBloc>().add(InvestmentFormBuyRateChanged(val));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Buy Amount (Always auto-calculated from qty × rate)
                  TextFormField(
                    key: ValueKey<double>(state.computedBuyAmt),
                    initialValue: state.computedBuyAmt.toStringAsFixed(2),
                    enabled: false,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Buy Amount',
                      helperText: 'Auto-calculated (Qty × Rate)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Broker/Tax Profile Dropdown
                  AppSelectField<int?>(
                    label: 'Broker (Optional)',
                    value: state.taxProfileId,
                    options: brokerOptions,
                    onChanged: (value) {
                      context.read<InvestmentFormBloc>().add(InvestmentFormBrokerChanged(value));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    initialValue: state.notes ?? '',
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                    onChanged: (value) {
                      context.read<InvestmentFormBloc>().add(InvestmentFormNotesChanged(value));
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  FilledButton(
                    onPressed: state.status == InvestmentFormStatus.submitting
                        ? null
                        : () {
                            context.read<InvestmentFormBloc>().add(
                                  InvestmentFormBuySubmitted(
                                    existingId: state.isBuyAmtOverridden ? null : null, // Handled inside router
                                  ),
                                );
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        state.status == InvestmentFormStatus.submitting ? 'Saving...' : 'Save Investment',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
