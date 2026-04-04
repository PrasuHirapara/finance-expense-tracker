import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../data/services/credential_service.dart';
import '../../domain/models/credential_models.dart';

class CredentialEditorArgs {
  const CredentialEditorArgs({this.credential});

  final DecryptedCredential? credential;
}

class CredentialEditorPage extends StatefulWidget {
  const CredentialEditorPage({super.key, this.args = const CredentialEditorArgs()});

  final CredentialEditorArgs args;

  @override
  State<CredentialEditorPage> createState() => _CredentialEditorPageState();
}

class _CredentialEditorPageState extends State<CredentialEditorPage> {
  late final TextEditingController _titleController;
  late final List<_FieldRowController> _fieldControllers;
  DateTime? _expiryDate;
  bool _isSaving = false;
  bool _showValidation = false;

  bool get _isEditing => widget.args.credential != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.args.credential?.title ?? '',
    );
    _expiryDate = widget.args.credential?.expiryDate;
    final existingFields = widget.args.credential?.fields ?? const <CredentialField>[];
    _fieldControllers = existingFields.isEmpty
        ? <_FieldRowController>[_FieldRowController.empty()]
        : existingFields
              .map(
                (field) => _FieldRowController(
                  keyController: TextEditingController(text: field.keyLabel),
                  valueController: TextEditingController(text: field.value),
                ),
              )
              .toList(growable: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _fieldControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Credential' : 'Add Credential'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              errorText: _showValidation && _titleController.text.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            onChanged: (_) {
              if (_showValidation) {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Credential Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickExpiryDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                    ),
                    child: Text(
                      _expiryDate == null
                          ? 'No expiry date'
                          : AppConstants.shortDateFormat.format(_expiryDate!),
                    ),
                  ),
                ),
                if (_expiryDate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _expiryDate = null;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Clear expiry'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Secure Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Every key and value below is encrypted before it is saved.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildFieldRows(),
                FilledButton.tonalIcon(
                  onPressed: _addFieldRow,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Data'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _saveCredential,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(_isSaving ? 'Saving...' : 'Save Credential'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFieldRows() {
    return List<Widget>.generate(_fieldControllers.length, (index) {
      final row = _fieldControllers[index];
      final hasValidationError =
          _showValidation &&
          (row.keyController.text.trim().isEmpty ||
              row.valueController.text.trim().isEmpty) &&
          (row.keyController.text.trim().isNotEmpty ||
              row.valueController.text.trim().isNotEmpty);

      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: row.keyController,
              decoration: InputDecoration(
                labelText: 'Key',
                errorText:
                    hasValidationError ? 'Both key and value are required' : null,
              ),
              onChanged: (_) {
                if (_showValidation) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: row.valueController,
              decoration: InputDecoration(
                labelText: 'Value',
                errorText: hasValidationError ? '' : null,
              ),
              onChanged: (_) {
                if (_showValidation) {
                  setState(() {});
                }
              },
            ),
            if (_fieldControllers.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _removeFieldRow(index),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remove'),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _addFieldRow() {
    setState(() {
      _fieldControllers.add(_FieldRowController.empty());
    });
  }

  void _removeFieldRow(int index) {
    setState(() {
      final controller = _fieldControllers.removeAt(index);
      controller.dispose();
    });
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _expiryDate = picked;
    });
  }

  Future<void> _saveCredential() async {
    setState(() {
      _showValidation = true;
    });

    final title = _titleController.text.trim();
    final fields = _normalizedFields();
    if (title.isEmpty || fields.isEmpty || !_hasValidRows()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final service = context.read<CredentialService>();
    final draft = CredentialDraft(
      title: title,
      fields: fields,
      expiryDate: _expiryDate,
    );

    try {
      if (_isEditing) {
        await service.updateCredential(
          id: widget.args.credential!.id,
          draft: draft,
        );
      } else {
        await service.createCredential(draft);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save credential: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  List<CredentialField> _normalizedFields() {
    return _fieldControllers
        .map(
          (row) => CredentialField(
            keyLabel: row.keyController.text.trim(),
            value: row.valueController.text.trim(),
          ),
        )
        .where((field) => field.keyLabel.isNotEmpty || field.value.isNotEmpty)
        .toList(growable: false);
  }

  bool _hasValidRows() {
    final fields = _normalizedFields();
    if (fields.isEmpty) {
      return false;
    }
    return fields.every(
      (field) => field.keyLabel.isNotEmpty && field.value.isNotEmpty,
    );
  }
}

class _FieldRowController {
  _FieldRowController({
    required this.keyController,
    required this.valueController,
  });

  factory _FieldRowController.empty() {
    return _FieldRowController(
      keyController: TextEditingController(),
      valueController: TextEditingController(),
    );
  }

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
