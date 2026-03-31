import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/credential_service.dart';

Future<bool?> showCredentialKeySetupDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _CredentialKeySetupDialog(),
  );
}

class _CredentialKeySetupDialog extends StatefulWidget {
  const _CredentialKeySetupDialog();

  @override
  State<_CredentialKeySetupDialog> createState() =>
      _CredentialKeySetupDialogState();
}

class _CredentialKeySetupDialogState extends State<_CredentialKeySetupDialog> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _keyController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Set Encryption Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Credential data is protected with an encryption key. You must set it before using this tab.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Encryption Key'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Encryption Key',
                errorText: _errorText,
              ),
              onSubmitted: (_) => _saveKey(),
            ),
          ],
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: _isSaving ? null : _saveKey,
            child: Text(_isSaving ? 'Saving...' : 'Save Key'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    final confirm = _confirmController.text.trim();

    if (key.isEmpty || confirm.isEmpty) {
      setState(() {
        _errorText = 'Encryption key is required';
      });
      return;
    }

    if (key != confirm) {
      setState(() {
        _errorText = 'Keys do not match';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    await context.read<CredentialService>().configureEncryptionKey(key);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }
}
