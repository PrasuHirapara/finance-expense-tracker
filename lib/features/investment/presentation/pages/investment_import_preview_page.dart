import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/module_data_import_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../blocs/investment/investment_bloc.dart';

class InvestmentImportPreviewPage extends StatefulWidget {
  const InvestmentImportPreviewPage({super.key, required this.args});

  final InvestmentImportPreviewArgs args;

  @override
  State<InvestmentImportPreviewPage> createState() => _InvestmentImportPreviewPageState();
}

class _InvestmentImportPreviewPageState extends State<InvestmentImportPreviewPage> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewData = widget.args.previewData;
    final totalRows = previewData.rows.length;
    final validRowsCount = previewData.rows.where((r) => r.isValid).length;
    final invalidRowsCount = totalRows - validRowsCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Preview'),
      ),
      body: Column(
        children: [
          if (previewData.unrecognizedSections.isNotEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFFC88719).withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFC88719)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unrecognized category sections will fall back to "Equity / Stocks":\n'
                      '${previewData.unrecognizedSections.join(", ")}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFC88719),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: totalRows,
              itemBuilder: (context, index) {
                final row = previewData.rows[index];
                final cardColor = row.isValid
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                    : theme.colorScheme.errorContainer.withValues(alpha: 0.15);
                final borderColor = row.isValid
                    ? Colors.transparent
                    : theme.colorScheme.error.withValues(alpha: 0.4);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              row.symbol.toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                row.categoryName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BUY DETAILS',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${row.qty.toStringAsFixed(row.qty == row.qty.toInt() ? 0 : 2)}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Rate: ${row.buyRate.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Date: ${DateFormat('yyyy-MM-dd').format(row.buyDate)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (row.sellDate != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SELL DETAILS',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${row.qty.toStringAsFixed(row.qty == row.qty.toInt() ? 0 : 2)}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'Rate: ${row.sellRate?.toStringAsFixed(2) ?? "0.00"}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'Date: ${DateFormat('yyyy-MM-dd').format(row.sellDate!)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (row.notes != null && row.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Notes: ${row.notes}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (!row.isValid) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: theme.colorScheme.error, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  row.validationError ?? 'Invalid row data',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: AppPanel(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Rows: $totalRows',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Valid: $validRowsCount | Invalid: $invalidRowsCount',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: invalidRowsCount > 0
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      FilledButton(
                        onPressed: _isSaving || validRowsCount == 0
                            ? null
                            : _handleConfirmImport,
                        child: Text(_isSaving ? 'Importing...' : 'Confirm Import'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmImport() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final importService = context.read<ModuleDataImportService>();
      final validRows = widget.args.previewData.rows.where((r) => r.isValid).toList();
      final count = await importService.saveInvestmentImport(validRows);

      if (!mounted) return;
      
      // Refresh the investment bloc
      context.read<InvestmentBloc>().add(const InvestmentSubscriptionRequested());

      showAppSnackBar(
        context,
        message: 'Successfully imported $count investment entries.',
        type: AppSnackBarType.info,
      );

      // Return back to settings
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Failed to import data: ${e.toString()}',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
