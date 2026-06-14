import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../core/formatters/indian_number_formatter.dart';
import '../../domain/models/investment_models.dart';
import '../../data/repositories/investment_repository.dart';
import '../blocs/investment_form/investment_form_bloc.dart';

class SellEntryFormPage extends StatefulWidget {
  const SellEntryFormPage({super.key});

  @override
  State<SellEntryFormPage> createState() => _SellEntryFormPageState();
}

class _SellEntryFormPageState extends State<SellEntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  InvestmentEntry? _buyEntry;
  bool _loadingBuyEntry = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_buyEntry == null) {
      _loadBuyEntry();
    }
  }

  Future<void> _loadBuyEntry() async {
    final args = ModalRoute.of(context)!.settings.arguments as SellEditorArgs;
    final repo = context.read<InvestmentRepository>();
    try {
      final buys = await repo.getBuyEntries();
      final buy = buys.firstWhere((b) => b.id == args.buyEntryId);
      setState(() {
        _buyEntry = buy;
        _loadingBuyEntry = false;
      });
    } catch (e) {
      setState(() {
        _loadingBuyEntry = false;
      });
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Error loading buy entry: ${e.toString()}',
          type: AppSnackBarType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)!.settings.arguments as SellEditorArgs;

    return BlocListener<InvestmentFormBloc, InvestmentFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == InvestmentFormStatus.success) {
          Navigator.of(context).pop();
        } else if (state.status == InvestmentFormStatus.failure &&
            state.errorMessage != null) {
          showAppSnackBar(
            context,
            message: state.errorMessage!,
            type: AppSnackBarType.warning,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Sell Entry')),
        body: _loadingBuyEntry
            ? const Center(child: CircularProgressIndicator())
            : BlocBuilder<InvestmentFormBloc, InvestmentFormState>(
                builder: (context, state) {
                  if (state.status == InvestmentFormStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Live Preview calculations
                  double estPL = 0.0;
                  double estPLPct = 0.0;
                  double estTax = 0.0;
                  double estPAT = 0.0;

                  if (_buyEntry != null &&
                      state.sellQty != null &&
                      state.sellRate != null) {
                    final qty = state.sellQty!;
                    final rate = state.sellRate!;
                    final sellAmt = state.sellAmt ?? (qty * rate);
                    final buyRate = _buyEntry!.buyRate;

                    estPL = sellAmt - (buyRate * qty);
                    estPLPct = (buyRate * qty) == 0.0
                        ? 0.0
                        : (estPL / (buyRate * qty)) * 100;

                    if (_buyEntry!.taxProfile != null) {
                      estTax = context
                          .read<InvestmentRepository>()
                          .computeLiveTax(
                            _buyEntry!.taxProfile!,
                            buyRate * qty,
                            sellAmt,
                          );
                    }
                    estPAT = estPL - estTax;
                  }

                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: <Widget>[
                        // Sell Date
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: state.sellDate ?? DateTime.now(),
                              firstDate: _buyEntry?.buyDate ?? DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null && context.mounted) {
                              context.read<InvestmentFormBloc>().add(
                                InvestmentFormSellDateChanged(picked),
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Sell Date',
                            ),
                            child: Text(
                              AppConstants.shortDateFormat.format(
                                state.sellDate ?? DateTime.now(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sell Quantity
                        TextFormField(
                          initialValue: state.sellQty?.toString() ?? '',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Sell Quantity',
                            errorText: state.showValidation
                                ? (state.sellQty == null || state.sellQty! <= 0
                                      ? 'Enter valid quantity'
                                      : (state.sellQty! >
                                                args.remainingUnsoldQty
                                            ? 'Cannot sell more than remaining quantity (${args.remainingUnsoldQty.toStringAsFixed(2)})'
                                            : null))
                                : null,
                          ),
                          onChanged: (value) {
                            final val = double.tryParse(value);
                            context.read<InvestmentFormBloc>().add(
                              InvestmentFormSellQtyChanged(val),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Sell Rate
                        TextFormField(
                          initialValue: state.sellRate?.toString() ?? '',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Sell Rate',
                            errorText:
                                state.showValidation &&
                                    (state.sellRate == null ||
                                        state.sellRate! < 0)
                                ? 'Enter sell rate'
                                : null,
                          ),
                          onChanged: (value) {
                            final val = double.tryParse(value);
                            context.read<InvestmentFormBloc>().add(
                              InvestmentFormSellRateChanged(val),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Sell Amount (Auto calculated or Overridden)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                key: ValueKey<String>(
                                  '${state.isSellAmtOverridden}_${state.sellAmt ?? state.computedSellAmt}',
                                ),
                                initialValue:
                                    state.sellAmt?.toStringAsFixed(2) ??
                                    state.computedSellAmt.toStringAsFixed(2),
                                enabled: state.isSellAmtOverridden,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'Sell Amount',
                                  helperText: state.isSellAmtOverridden
                                      ? 'Manual override active'
                                      : 'Auto-calculated',
                                ),
                                onChanged: (value) {
                                  final val = double.tryParse(value);
                                  context.read<InvestmentFormBloc>().add(
                                    InvestmentFormSellAmtChanged(val),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                state.isSellAmtOverridden
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () {
                                context.read<InvestmentFormBloc>().add(
                                  const InvestmentFormSellAmtOverrideToggled(),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Live Preview Card
                        Text(
                          'Estimated Preview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppPanel(
                          child: Column(
                            children: <Widget>[
                              _PreviewRow(
                                label: 'Estimated P/L',
                                value:
                                    '${estPL >= 0 ? "+" : ""}${IndianNumberFormatter.formatFull(estPL)}',
                                color: estPL >= 0 ? Colors.green : Colors.red,
                              ),
                              _PreviewRow(
                                label: 'Estimated P/L %',
                                value:
                                    '${estPLPct >= 0 ? "+" : ""}${estPLPct.toStringAsFixed(2)}%',
                                color: estPLPct >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              _PreviewRow(
                                label: 'Estimated Tax',
                                value: IndianNumberFormatter.formatFull(estTax),
                                color: Colors.amber[800],
                              ),
                              _PreviewRow(
                                label: 'Estimated PAT',
                                value:
                                    '${estPAT >= 0 ? "+" : ""}${IndianNumberFormatter.formatFull(estPAT)}',
                                color: estPAT >= 0 ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        FilledButton(
                          onPressed:
                              state.status == InvestmentFormStatus.submitting
                              ? null
                              : () {
                                  if (state.sellQty != null &&
                                      state.sellQty! >
                                          args.remainingUnsoldQty) {
                                    showAppSnackBar(
                                      context,
                                      message:
                                          'Cannot sell more than remaining quantity (${args.remainingUnsoldQty.toStringAsFixed(2)})',
                                      type: AppSnackBarType.warning,
                                    );
                                    return;
                                  }
                                  context.read<InvestmentFormBloc>().add(
                                    InvestmentFormSellSubmitted(
                                      buyEntryId: args.buyEntryId,
                                      symbol: args.symbol,
                                    ),
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              state.status == InvestmentFormStatus.submitting
                                  ? 'Saving...'
                                  : 'Save Sell Entry',
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

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
