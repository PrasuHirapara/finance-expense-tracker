import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/module_export_models.dart';
import '../../../../core/services/module_data_export_service.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/download_result_snackbar.dart';
import '../../data/services/credential_service.dart';
import '../../domain/models/credential_models.dart';
import 'credential_auth_dialog.dart';

class CredentialExportPanel extends StatefulWidget {
  const CredentialExportPanel({super.key});

  @override
  State<CredentialExportPanel> createState() => _CredentialExportPanelState();
}

class _CredentialExportPanelState extends State<CredentialExportPanel> {
  _CredentialExportScope _selectedScope = _CredentialExportScope.all;
  ModuleExportFormat _selectedFormat = ModuleExportFormat.pdf;
  Set<int> _selectedCredentialIds = <int>{};
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Credential Export', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Export all credentials or choose a custom set. Authentication is required before export.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final children = <Widget>[
                SizedBox(
                  width: isWide ? 190 : double.infinity,
                  child: AppSelectField<_CredentialExportScope>(
                    label: 'Export scope',
                    value: _selectedScope,
                    options: _CredentialExportScope.values
                        .map(
                          (value) => AppSelectOption<_CredentialExportScope>(
                            value: value,
                            label: value.label,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) async {
                      setState(() {
                        _selectedScope = value;
                      });
                      if (value == _CredentialExportScope.custom) {
                        await _pickCustomCredentials();
                      }
                    },
                  ),
                ),
                if (_selectedScope == _CredentialExportScope.custom)
                  SizedBox(
                    width: isWide ? 220 : double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickCustomCredentials,
                      icon: const Icon(Icons.checklist_rounded),
                      label: Text(_customSelectionLabel),
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
                  width: isWide ? 150 : double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isExporting ? null : _exportCredentials,
                    icon: _isExporting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _isExporting
                          ? 'Exporting...'
                          : 'Export ${_selectedFormat.label}',
                    ),
                  ),
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      children
                          .expand(
                            (child) => <Widget>[
                              child,
                              const SizedBox(width: 12),
                            ],
                          )
                          .toList()
                        ..removeLast(),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    children
                        .expand(
                          (child) => <Widget>[
                            child,
                            const SizedBox(height: 12),
                          ],
                        )
                        .toList()
                      ..removeLast(),
              );
            },
          ),
        ],
      ),
    );
  }

  String get _customSelectionLabel {
    final count = _selectedCredentialIds.length;
    if (count == 0) {
      return 'Choose Credentials';
    }
    if (count == 1) {
      return '1 selected';
    }
    return '$count selected';
  }

  Future<void> _pickCustomCredentials() async {
    final service = context.read<CredentialService>();
    final credentials = await service.loadCredentials();

    if (!mounted) {
      return;
    }

    if (credentials.isEmpty) {
      showAppSnackBar(
        context,
        message: 'No credentials available to export.',
        type: AppSnackBarType.warning,
      );
      return;
    }

    final selectedIds = await showDialog<Set<int>>(
      context: context,
      builder: (dialogContext) {
        final workingSelection = _selectedCredentialIds.toSet();

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Choose Credentials'),
            content: SizedBox(
              width: 420,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: credentials
                        .map(
                          (credential) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: workingSelection.contains(credential.id),
                            title: Text(credential.title),
                            subtitle: Text(
                              'Updated ${AppConstants.shortDateFormat.format(credential.updatedAt)}',
                            ),
                            onChanged: (selected) {
                              setDialogState(() {
                                if (selected == true) {
                                  workingSelection.add(credential.id);
                                } else {
                                  workingSelection.remove(credential.id);
                                }
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(workingSelection),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedIds == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCredentialIds = selectedIds;
    });
  }

  Future<void> _exportCredentials() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<CredentialService>();
    final exportService = context.read<ModuleDataExportService>();

    setState(() {
      _isExporting = true;
    });

    try {
      final allCredentials = await service.loadCredentials();
      if (!mounted) {
        return;
      }
      if (allCredentials.isEmpty) {
        showAppSnackBar(
          context,
          message: 'No credentials available to export.',
          type: AppSnackBarType.warning,
        );
        return;
      }

      final recordsToExport = _selectedScope == _CredentialExportScope.all
          ? allCredentials
          : allCredentials
                .where(
                  (credential) =>
                      _selectedCredentialIds.contains(credential.id),
                )
                .toList(growable: false);

      if (recordsToExport.isEmpty) {
        showAppSnackBar(
          context,
          message: 'Choose at least one credential to export.',
          type: AppSnackBarType.warning,
        );
        return;
      }

      if (!mounted) {
        return;
      }

      final encryptionKey = await showCredentialAuthenticationDialog(
        context,
        title: 'Authenticate',
        reason: 'Authenticate before exporting credential data.',
      );

      if (encryptionKey == null || !mounted) {
        return;
      }

      final decryptedCredentials = <DecryptedCredential>[];
      for (final record in recordsToExport) {
        decryptedCredentials.add(
          await service.decryptCredential(
            record: record,
            encryptionKey: encryptionKey,
          ),
        );
      }

      final path = await exportService.exportCredentialData(
        format: _selectedFormat,
        credentials: decryptedCredentials,
      );

      if (!mounted) {
        return;
      }

      showDownloadResultSnackBar(
        context,
        message: '${_selectedFormat.label} exported to $path',
        path: path,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Export failed: $error',
          type: AppSnackBarType.error,
        ),
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

enum _CredentialExportScope {
  all('All Credentials'),
  custom('Custom');

  const _CredentialExportScope(this.label);

  final String label;
}
