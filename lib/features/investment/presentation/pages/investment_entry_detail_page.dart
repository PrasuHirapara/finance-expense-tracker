import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../core/formatters/indian_number_formatter.dart';
import '../../domain/models/investment_models.dart';
import '../../data/repositories/investment_repository.dart';

class InvestmentEntryDetailPage extends StatelessWidget {
  const InvestmentEntryDetailPage({super.key, required this.args});

  final InvestmentDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<InvestmentRepository>();

    final symbolStream = repo.watchBuyEntries().asyncCombine(
      repo.watchSellEntries(),
      (buys, sells) {
        final symbolBuys = buys.where((b) => b.symbol == args.symbol).toList();
        final symbolSells = sells.where((s) => s.symbol == args.symbol).toList();
        return SymbolGroup(
          symbol: args.symbol,
          buyEntries: symbolBuys,
          sellEntries: symbolSells,
        );
      },
    );

    return StreamBuilder<SymbolGroup>(
      stream: symbolStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final group = snapshot.data!;
        if (group.buyEntries.isEmpty) {
          // It was deleted
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
          return const Scaffold();
        }

        final firstBuy = group.buyEntries.first;
        final buyRates = {for (final b in group.buyEntries) b.id: b.buyRate};
        final buyDates = {for (final b in group.buyEntries) b.id: b.buyDate};
        final buyTaxProfiles = {for (final b in group.buyEntries) b.id: b.taxProfile};

        // Sell list
        final sells = List<SellEntry>.from(group.sellEntries)
          ..sort((a, b) => b.sellDate.compareTo(a.sellDate));

        var totalTax = 0.0;
        var totalPL = 0.0;

        for (final s in sells) {
          final buyRate = buyRates[s.buyEntryId] ?? 0.0;
          final pl = s.sellAmt - (buyRate * s.sellQty);
          totalPL += pl;

          final taxProfile = buyTaxProfiles[s.buyEntryId];
          if (taxProfile != null) {
            totalTax += repo.computeLiveTax(taxProfile, buyRate * s.sellQty, s.sellAmt);
          }
        }

        final totalPAT = totalPL - totalTax;
        final totalPLPct = group.totalInvested == 0 ? 0.0 : (totalPL / group.totalInvested) * 100;

        return Scaffold(
          appBar: AppBar(
            title: Text(group.symbol),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: <Widget>[
              // Section: Buy Information
              Text(
                'Buy Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              AppPanel(
                child: Column(
                  children: <Widget>[
                    _InfoRow(label: 'Symbol', value: group.symbol),
                    _InfoRow(label: 'Category', value: firstBuy.categoryName),
                    _InfoRow(label: 'Total Qty Bought', value: group.totalBoughtQty.toStringAsFixed(2)),
                    _InfoRow(
                      label: 'First Buy Date',
                      value: AppConstants.shortDateFormat.format(firstBuy.buyDate),
                    ),
                    _InfoRow(
                      label: 'Average Buy Rate',
                      value: IndianNumberFormatter.formatFull(group.averageBuyRate),
                    ),
                    _InfoRow(
                      label: 'Total Buy Amount',
                      value: IndianNumberFormatter.formatFull(group.totalInvested),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Sell History
              Text(
                'Sell History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (sells.isEmpty)
                const AppPanel(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No sell entries yet. Position is Open.'),
                    ),
                  ),
                )
              else
                ...sells.map((sell) {
                  final buyRate = buyRates[sell.buyEntryId] ?? 0.0;
                  final buyDate = buyDates[sell.buyEntryId] ?? DateTime.now();
                  final taxProfile = buyTaxProfiles[sell.buyEntryId];

                  final days = sell.sellDate.difference(buyDate).inDays;
                  final pl = sell.sellAmt - (buyRate * sell.sellQty);
                  final tax = taxProfile != null
                      ? repo.computeLiveTax(taxProfile, buyRate * sell.sellQty, sell.sellAmt)
                      : 0.0;
                  final pat = pl - tax;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                AppConstants.shortDateFormat.format(sell.sellDate),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _confirmDeleteSell(context, repo, sell.id),
                              ),
                            ],
                          ),
                          const Divider(),
                          _InfoRow(label: 'Qty Sold', value: sell.sellQty.toStringAsFixed(2)),
                          _InfoRow(label: 'Rate', value: IndianNumberFormatter.formatFull(sell.sellRate)),
                          _InfoRow(label: 'Amount', value: IndianNumberFormatter.formatFull(sell.sellAmt)),
                          _InfoRow(label: 'Days Held', value: '$days days'),
                          _InfoRow(
                            label: 'P/L',
                            value: '${pl >= 0 ? "+" : ""}${IndianNumberFormatter.formatFull(pl)}',
                            valueColor: pl >= 0 ? Colors.green : Colors.red,
                          ),
                          if (tax > 0) _InfoRow(label: 'Tax', value: IndianNumberFormatter.formatFull(tax)),
                          _InfoRow(
                            label: 'PAT',
                            value: '${pat >= 0 ? "+" : ""}${IndianNumberFormatter.formatFull(pat)}',
                            valueColor: pat >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Section: Summary
              if (sells.isNotEmpty) ...[
                Text(
                  'Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                AppPanel(
                  child: Column(
                    children: <Widget>[
                      _InfoRow(label: 'Total Sold Qty', value: group.totalSoldQty.toStringAsFixed(2)),
                      _InfoRow(label: 'Total Sell Value', value: IndianNumberFormatter.formatFull(group.totalSellValue)),
                      _InfoRow(
                        label: 'Total P/L',
                        value: '${totalPL >= 0 ? "+" : ""}${IndianNumberFormatter.formatFull(totalPL)}',
                        valueColor: totalPL >= 0 ? Colors.green : Colors.red,
                      ),
                      _InfoRow(
                        label: 'Total P/L %',
                        value: '${totalPLPct >= 0 ? "+" : ""}${totalPLPct.toStringAsFixed(2)}%',
                        valueColor: totalPLPct >= 0 ? Colors.green : Colors.red,
                      ),
                      _InfoRow(label: 'Total Tax', value: IndianNumberFormatter.formatFull(totalTax)),
                      _InfoRow(
                        label: 'Total PAT',
                        value: '${totalPAT >= 0 ? "+" : ""}${IndianNumberFormatter.formatFull(totalPAT)}',
                        valueColor: totalPAT >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // scroll/view
                      },
                      child: const Text('View'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.investmentAdd,
                          arguments: InvestmentEditorArgs(entry: firstBuy),
                        );
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _confirmDeleteBuy(context, repo, group),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add Sell Entry Button
              if (group.statusBadge != InvestmentStatusBadge.sold)
                FilledButton.icon(
                  onPressed: () {
                    final remaining = group.totalBoughtQty - group.totalSoldQty;
                    Navigator.of(context).pushNamed(
                      AppRoutes.investmentSellAdd,
                      arguments: SellEditorArgs(
                        buyEntryId: firstBuy.id,
                        symbol: group.symbol,
                        remainingUnsoldQty: remaining,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Sell Entry'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteBuy(BuildContext context, InvestmentRepository repo, SymbolGroup group) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Investment'),
          content: Text('This will delete all ${group.buyEntries.length} buy entries and ${group.sellEntries.length} linked sell records for ${group.symbol}. Are you sure?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      for (final buy in group.buyEntries) {
        await repo.deleteBuyEntry(buy.id);
      }
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Position deleted successfully.',
          type: AppSnackBarType.info,
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmDeleteSell(BuildContext context, InvestmentRepository repo, int sellId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Sell Entry'),
          content: const Text('Are you sure you want to delete this sell transaction?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await repo.deleteSellEntry(sellId);
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: 'Sell entry deleted successfully.',
          type: AppSnackBarType.info,
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

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
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

extension _AsyncStreamCombine<T> on Stream<T> {
  Stream<R> asyncCombine<S, R>(
    Stream<S> other,
    FutureOr<R> Function(T event, S otherEvent) combiner,
  ) {
    T? latestT;
    S? latestS;
    bool hasT = false;
    bool hasS = false;

    final controller = StreamController<R>.broadcast();
    StreamSubscription<T>? subT;
    StreamSubscription<S>? subS;

    void update() async {
      if (hasT && hasS) {
        try {
          final result = await combiner(latestT as T, latestS as S);
          if (!controller.isClosed) {
            controller.add(result);
          }
        } catch (e, s) {
          if (!controller.isClosed) {
            controller.addError(e, s);
          }
        }
      }
    }

    controller.onListen = () {
      subT = listen(
        (val) {
          latestT = val;
          hasT = true;
          update();
        },
        onError: controller.addError,
      );
      subS = other.listen(
        (val) {
          latestS = val;
          hasS = true;
          update();
        },
        onError: controller.addError,
      );
    };

    controller.onCancel = () {
      subT?.cancel();
      subS?.cancel();
    };

    return controller.stream;
  }
}
