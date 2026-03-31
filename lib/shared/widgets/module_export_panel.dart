import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/module_export_models.dart';
import 'app_panel.dart';
import 'app_select_field.dart';

class ModuleExportPanel extends StatefulWidget {
  const ModuleExportPanel({
    super.key,
    required this.title,
    required this.onExport,
    this.description,
  });

  final String title;
  final String? description;
  final Future<String> Function(
    DateTimeRange range,
    ModuleExportFormat format,
  )
  onExport;

  @override
  State<ModuleExportPanel> createState() => _ModuleExportPanelState();
}

class _ModuleExportPanelState extends State<ModuleExportPanel> {
  ModuleExportRange _selectedRange = ModuleExportRange.month;
  ModuleExportFormat _selectedFormat = ModuleExportFormat.pdf;
  bool _isExporting = false;
  DateTimeRange _customRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.title, style: theme.textTheme.titleLarge),
          if (widget.description != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              widget.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final children = <Widget>[
                SizedBox(
                  width: isWide ? 180 : double.infinity,
                  child: AppSelectField<ModuleExportRange>(
                    label: 'Time range',
                    value: _selectedRange,
                    options: ModuleExportRange.values
                        .map(
                          (value) => AppSelectOption<ModuleExportRange>(
                            value: value,
                            label: value.label,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) async {
                      setState(() {
                        _selectedRange = value;
                      });
                      if (value == ModuleExportRange.custom) {
                        await _pickCustomRange();
                      }
                    },
                  ),
                ),
                if (_selectedRange == ModuleExportRange.custom)
                  SizedBox(
                    width: isWide ? 260 : double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickCustomRange,
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(_customRangeLabel),
                    ),
                  ),
                SizedBox(
                  width: isWide ? 160 : double.infinity,
                  child: AppSelectField<ModuleExportFormat>(
                    label: 'Format',
                    value: _selectedFormat,
                    options: ModuleExportFormat.values
                        .map(
                          (value) => AppSelectOption<ModuleExportFormat>(
                            value: value,
                            label: value.label,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: isWide ? 170 : double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _isExporting
                          ? 'Downloading...'
                          : 'Download ${_selectedFormat.label}',
                    ),
                  ),
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children
                      .expand((child) => <Widget>[child, const SizedBox(width: 12)])
                      .toList()
                    ..removeLast(),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children
                    .expand((child) => <Widget>[child, const SizedBox(height: 12)])
                    .toList()
                  ..removeLast(),
              );
            },
          ),
        ],
      ),
    );
  }

  String get _customRangeLabel {
    return '${AppConstants.shortDateFormat.format(_customRange.start)} - ${AppConstants.shortDateFormat.format(_customRange.end)}';
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customRange,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _customRange = picked;
    });
  }

  Future<void> _handleExport() async {
    final messenger = ScaffoldMessenger.of(context);
    final range = _selectedRange == ModuleExportRange.custom
        ? _customRange
        : _selectedRange.resolveRange(DateTime.now());

    setState(() {
      _isExporting = true;
    });

    try {
      final path = await widget.onExport(range, _selectedFormat);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('${_selectedFormat.label} exported to $path')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
