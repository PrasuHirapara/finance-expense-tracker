import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/credential_service.dart';

Future<String?> showCredentialAuthenticationDialog(
  BuildContext context, {
  required String title,
  required String reason,
  bool allowBiometric = true,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _CredentialAuthenticationDialog(
      title: title,
      reason: reason,
      allowBiometric: allowBiometric,
    ),
  );
}

class _CredentialAuthenticationDialog extends StatefulWidget {
  const _CredentialAuthenticationDialog({
    required this.title,
    required this.reason,
    required this.allowBiometric,
  });

  final String title;
  final String reason;
  final bool allowBiometric;

  @override
  State<_CredentialAuthenticationDialog> createState() =>
      _CredentialAuthenticationDialogState();
}

class _CredentialAuthenticationDialogState
    extends State<_CredentialAuthenticationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _biometricAvailable = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadBiometricAvailability();
  }

  @override
  void dispose() {
    _controller.dispose();
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
            controller: _controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Encryption Key',
              errorText: _errorText,
            ),
            onSubmitted: (_) => _authenticateWithKey(),
          ),
          if (_biometricAvailable) ...<Widget>[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _isSubmitting ? null : _authenticateWithBiometrics,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Biometric'),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _authenticateWithKey,
          child: Text(_isSubmitting ? 'Checking...' : 'Unlock'),
        ),
      ],
    );
  }

  Future<void> _loadBiometricAvailability() async {
    if (!widget.allowBiometric) {
      return;
    }

    final service = context.read<CredentialService>();
    final enabled = await service.isBiometricUnlockEnabled();
    final available = await service.canUseBiometrics();
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricAvailable = enabled && available;
    });
  }

  Future<void> _authenticateWithKey() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final service = context.read<CredentialService>();
    final enteredKey = _controller.text.trim();
    final isValid = await service.verifyEncryptionKey(enteredKey);

    if (!mounted) {
      return;
    }

    if (isValid) {
      Navigator.of(context).pop(enteredKey);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorText = 'Incorrect encryption key';
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final service = context.read<CredentialService>();
    final authenticated = await service.authenticateWithBiometrics(
      reason: widget.reason,
    );
    final storedKey = authenticated
        ? await service.readStoredEncryptionKey()
        : null;

    if (!mounted) {
      return;
    }

    if (authenticated && storedKey != null && storedKey.isNotEmpty) {
      Navigator.of(context).pop(storedKey);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorText = 'Biometric authentication failed';
    });
  }
}
