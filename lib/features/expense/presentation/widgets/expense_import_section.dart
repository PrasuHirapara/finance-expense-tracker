import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/module_data_import_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/download_result_snackbar.dart';

class ExpenseImportSection extends StatefulWidget {
  const ExpenseImportSection({super.key});

  @override
  State<ExpenseImportSection> createState() => _ExpenseImportSectionState();
}

class _ExpenseImportSectionState extends State<ExpenseImportSection> {
  bool _isDownloadingSample = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Expense Import', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Download a sample Excel file, fill it row by row, then import it. Nothing is saved unless every filled row is valid.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _isDownloadingSample || _isImporting
                    ? null
                    : _downloadSampleExcel,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  _isDownloadingSample
                      ? 'Preparing...'
                      : 'Download Sample Excel',
                ),
              ),
              FilledButton.icon(
                onPressed: _isDownloadingSample || _isImporting
                    ? null
                    : _importExcel,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(_isImporting ? 'Importing...' : 'Import Excel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadSampleExcel() async {
    setState(() {
      _isDownloadingSample = true;
    });

    try {
      final path = await context
          .read<ModuleDataImportService>()
          .downloadExpenseSampleExcel();
      if (!mounted) {
        return;
      }
      showDownloadResultSnackBar(
        context,
        message: 'Expense sample Excel saved to $path',
        path: path,
      );
    } on ModuleImportException catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: error.message,
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingSample = false;
        });
      }
    }
  }

  Future<void> _importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select expense Excel file',
      type: FileType.custom,
      allowedExtensions: const <String>['xlsx'],
    );

    if (result == null || result.files.single.path == null || !mounted) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final importResult = await context
          .read<ModuleDataImportService>()
          .importExpenseExcel(result.files.single.path!);
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: importResult.message);
    } on ModuleImportException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.errors.isEmpty) {
        showAppSnackBar(
          context,
          message: error.message,
          type: AppSnackBarType.error,
        );
      } else {
        await _showImportErrors(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _showImportErrors(ModuleImportException error) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Errors'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(error.message),
                const SizedBox(height: 12),
                ...error.errors.map(
                  (rowError) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(rowError),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
