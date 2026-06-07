import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/models/task_models.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/module_data_import_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../blocs/tasks/task_bloc.dart';

class TaskImportPreviewPage extends StatefulWidget {
  const TaskImportPreviewPage({super.key, required this.args});

  final TaskImportPreviewArgs args;

  @override
  State<TaskImportPreviewPage> createState() => _TaskImportPreviewPageState();
}

class _TaskImportPreviewPageState extends State<TaskImportPreviewPage> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewData = widget.args.previewData;
    final totalRows = previewData.rows.length;
    final validRowsCount = previewData.rows.where((r) => r.isValid).length;
    final invalidRowsCount = totalRows - validRowsCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Import Preview')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: totalRows,
              itemBuilder: (context, index) {
                final row = previewData.rows[index];
                final cardColor = row.isValid
                    ? theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      )
                    : theme.colorScheme.errorContainer.withValues(alpha: 0.15);
                final borderColor = row.isValid
                    ? Colors.transparent
                    : theme.colorScheme.error.withValues(alpha: 0.4);

                // Priority Color mapping (1-5)
                final priorityColor = switch (row.priority) {
                  5 => Colors.red.shade700,
                  4 => Colors.orange.shade700,
                  3 => Colors.blue.shade700,
                  2 => Colors.teal.shade700,
                  _ => Colors.grey.shade600,
                };

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
                                  decoration: row.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Priority ${row.priority}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: priorityColor,
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
                              row.categoryName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                if (row.isDaily) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Daily',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (row.isCompleted)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green.shade600,
                                    size: 18,
                                  ),
                              ],
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
                            if (row.checklist.isNotEmpty)
                              _buildInfoChip(
                                theme,
                                Icons.playlist_add_check_rounded,
                                '${row.checklist.length} items',
                              ),
                          ],
                        ),
                        if (row.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            row.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (row.checklist.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildChecklistPreview(theme, row.checklist),
                        ],
                        if (!row.isValid) ...[
                          const SizedBox(height: 10),
                          Row(
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
                            'Total Tasks: $totalRows',
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

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
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

  Widget _buildChecklistPreview(
    ThemeData theme,
    List<TaskChecklistItem> checklist,
  ) {
    final displayedItems = checklist.take(3).toList();
    final remainingCount = checklist.length - displayedItems.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    item.isCompleted
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank_rounded,
                    size: 14,
                    color: item.isCompleted
                        ? Colors.green.shade600
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isCompleted
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 20),
              child: Text(
                '+ $remainingCount more item${remainingCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
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
      final savedCount = await importService.saveTaskImport(validRows);

      if (!mounted) return;

      context.read<TaskBloc>().add(const TasksSubscriptionRequested());

      showAppSnackBar(
        context,
        message:
            '$savedCount task${savedCount == 1 ? '' : 's'} imported successfully.',
        type: AppSnackBarType.info,
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Failed to import tasks: ${e.toString()}',
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
