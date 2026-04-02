import 'package:flutter/material.dart';

Future<String?> showCredentialKeyEntryDialog(
  BuildContext context, {
  required String title,
  required String reason,
  bool requireConfirmation = false,
  String submitLabel = 'Continue',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _CredentialKeyEntryDialog(
      title: title,
      reason: reason,
      requireConfirmation: requireConfirmation,
      submitLabel: submitLabel,
    ),
  );
}

class _CredentialKeyEntryDialog extends StatefulWidget {
  const _CredentialKeyEntryDialog({
    required this.title,
    required this.reason,
    required this.requireConfirmation,
    required this.submitLabel,
  });

  final String title;
  final String reason;
  final bool requireConfirmation;
  final String submitLabel;

  @override
  State<_CredentialKeyEntryDialog> createState() =>
      _CredentialKeyEntryDialogState();
}

class _CredentialKeyEntryDialogState extends State<_CredentialKeyEntryDialog> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _keyController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.reason),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Encryption Key',
              errorText: _errorText,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.requireConfirmation) ...<Widget>[
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Encryption Key',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }

  void _submit() {
    final key = _keyController.text.trim();
    final confirm = _confirmController.text.trim();

    if (key.isEmpty) {
      setState(() {
        _errorText = 'Encryption key is required';
      });
      return;
    }

    if (widget.requireConfirmation && key != confirm) {
      setState(() {
        _errorText = 'Keys do not match';
      });
      return;
    }

    Navigator.of(context).pop(key);
  }
}
