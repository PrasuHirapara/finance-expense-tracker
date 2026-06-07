import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/module_data_import_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class CredentialImportPreviewPage extends StatefulWidget {
  const CredentialImportPreviewPage({super.key, required this.args});

  final CredentialImportPreviewArgs args;

  @override
  State<CredentialImportPreviewPage> createState() =>
      _CredentialImportPreviewPageState();
}

class _CredentialImportPreviewPageState
    extends State<CredentialImportPreviewPage> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewData = widget.args.previewData;
    final totalRows = previewData.rows.length;
    final validRowsCount = previewData.rows.where((r) => r.isValid).length;
    final invalidRowsCount = totalRows - validRowsCount;

    // Group rows by Title for presentation
    final groupedRows = <String, List<CredentialImportRow>>{};
    for (final row in previewData.rows) {
      groupedRows.putIfAbsent(row.title, () => []).add(row);
    }

    final groupKeys = groupedRows.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Import Preview')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: groupKeys.length,
              itemBuilder: (context, index) {
                final title = groupKeys[index];
                final rows = groupedRows[title]!;
                final isGroupValid = rows.every((r) => r.isValid);

                final cardColor = isGroupValid
                    ? theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      )
                    : theme.colorScheme.errorContainer.withValues(alpha: 0.15);
                final borderColor = isGroupValid
                    ? Colors.transparent
                    : theme.colorScheme.error.withValues(alpha: 0.4);

                // Expiry Date (taken from first row with an expiry date)
                final firstExpiryRow = rows.where((r) => r.expiryDate != null);
                final expiryDate = firstExpiryRow.isNotEmpty
                    ? firstExpiryRow.first.expiryDate
                    : null;

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
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (expiryDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_rounded,
                                      size: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(expiryDate),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        ...rows.map((row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    row.field,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    row.value,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Validation errors for this credential group
                        ...rows.where((r) => !r.isValid).map((row) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: theme.colorScheme.error,
                                  size: 16,
                                ),
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
                          );
                        }),
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
                        child: Text(
                          _isSaving ? 'Importing...' : 'Confirm Import',
                        ),
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
      final validRows = widget.args.previewData.rows
          .where((r) => r.isValid)
          .toList();
      final result = await importService.saveCredentialImport(
        validRows,
        encryptionKey: widget.args.encryptionKey,
      );

      if (!mounted) return;

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
