import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/formatters/indian_number_formatter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/module_data_import_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../blocs/expense/expense_bloc.dart';

class ExpenseImportPreviewPage extends StatefulWidget {
  const ExpenseImportPreviewPage({super.key, required this.args});

  final ExpenseImportPreviewArgs args;

  @override
  State<ExpenseImportPreviewPage> createState() => _ExpenseImportPreviewPageState();
}

class _ExpenseImportPreviewPageState extends State<ExpenseImportPreviewPage> {
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

                final typeColor = row.type.toLowerCase() == 'income'
                    ? const Color(0xFF1F8B4C)
                    : row.type.toLowerCase() == 'lent'
                        ? const Color(0xFF2980B9)
                        : row.type.toLowerCase() == 'borrowed'
                            ? const Color(0xFFD35400)
                            : theme.colorScheme.error;

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
                            Expanded(
                              child: Text(
                                row.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                row.type.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              IndianNumberFormatter.formatFull(row.amount),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                            Text(
                              row.categoryName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              theme,
                              Icons.calendar_today_rounded,
                              DateFormat('yyyy-MM-dd').format(row.date),
                            ),
                            if (row.bankName != null)
                              _buildInfoChip(
                                theme,
                                Icons.account_balance_wallet_rounded,
                                row.bankName!,
                              ),
                            _buildInfoChip(
                              theme,
                              Icons.payment_rounded,
                              row.paymentMode,
                            ),
                            if (row.counterparty != null)
                              _buildInfoChip(
                                theme,
                                Icons.person_rounded,
                                row.counterparty!,
                              ),
                          ],
                        ),
                        if (row.notes.isNotEmpty) ...[
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

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _handleConfirmImport() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final importService = context.read<ModuleDataImportService>();
      final validRows = widget.args.previewData.rows.where((r) => r.isValid).toList();
      final result = await importService.saveExpenseImport(validRows, widget.args.previewData.splitBundle);

      if (!mounted) return;

      context.read<ExpenseBloc>().add(const ExpenseSubscriptionRequested());

      showAppSnackBar(
        context,
        message: result.message,
        type: AppSnackBarType.info,
      );

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
