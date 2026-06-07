import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/module_data_import_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/download_result_snackbar.dart';

class TaskImportSection extends StatefulWidget {
  const TaskImportSection({super.key});

  @override
  State<TaskImportSection> createState() => _TaskImportSectionState();
}

class _TaskImportSectionState extends State<TaskImportSection> {
  bool _isDownloadingSample = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Task Import', style: theme.textTheme.titleLarge),
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
          .downloadTaskSampleExcel();
      if (!mounted) {
        return;
      }
      showDownloadResultSnackBar(
        context,
        message: 'Task sample Excel saved to $path',
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
      dialogTitle: 'Select task Excel file',
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
      final previewData = await context
          .read<ModuleDataImportService>()
          .previewTaskExcel(result.files.single.path!);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        AppRoutes.taskImportPreview,
        arguments: TaskImportPreviewArgs(previewData: previewData),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Import failed: ${error.toString()}',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}
