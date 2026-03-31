import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_panel.dart';
import '../../../credentials/data/services/credential_service.dart';
import '../../../credentials/presentation/widgets/credential_auth_dialog.dart';
import '../../../credentials/presentation/widgets/credential_export_panel.dart';
import '../../../credentials/presentation/widgets/credential_key_setup_dialog.dart';

class CredentialSettingsSection extends StatefulWidget {
  const CredentialSettingsSection({super.key});

  @override
  State<CredentialSettingsSection> createState() =>
      _CredentialSettingsSectionState();
}

class _CredentialSettingsSectionState extends State<CredentialSettingsSection> {
  bool _hasEncryptionKey = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppPanel(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Credential Settings', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Credential encryption is managed only for the Credential module.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_hasEncryptionKey)
                  FilledButton.icon(
                    onPressed: _setEncryptionKey,
                    icon: const Icon(Icons.key_rounded),
                    label: const Text('Set Encryption Key'),
                  )
                else ...<Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _changeEncryptionKey,
                    icon: const Icon(Icons.key_rounded),
                    label: const Text('Change Encryption Key'),
                  ),
                  const SizedBox(height: 16),
                  const CredentialExportPanel(),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Biometric Unlock',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _biometricAvailable
                                    ? 'Use fingerprint or face unlock to decrypt credentials after authentication.'
                                    : 'Biometric authentication is not available on this device.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _biometricEnabled,
                          onChanged: !_biometricAvailable
                              ? null
                              : (value) => _toggleBiometric(value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'If you forget your encryption key, your credential data cannot be recovered. You may only delete all stored credential data.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _deleteAllCredentials,
                    style: FilledButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('Delete All Credentials'),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _refresh() async {
    final service = context.read<CredentialService>();
    final hasEncryptionKey = await service.hasEncryptionKey();
    final biometricEnabled = await service.isBiometricUnlockEnabled();
    final biometricAvailable = await service.canUseBiometrics();

    if (!mounted) {
      return;
    }

    setState(() {
      _hasEncryptionKey = hasEncryptionKey;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _isLoading = false;
    });
  }

  Future<void> _setEncryptionKey() async {
    await showCredentialKeySetupDialog(context);
    if (!mounted) {
      return;
    }
    await _refresh();
  }

  Future<void> _changeEncryptionKey() async {
    final oldKey = await showCredentialAuthenticationDialog(
      context,
      title: 'Authenticate',
      reason:
          'Authenticate with your current encryption key or biometrics to change it.',
    );

    if (oldKey == null || !mounted) {
      return;
    }

    final newKey = await _showNewKeyDialog();
    if (newKey == null || !mounted) {
      return;
    }

    try {
      await context.read<CredentialService>().rotateEncryptionKey(
        oldEncryptionKey: oldKey,
        newEncryptionKey: newKey,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update encryption key: $error')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Encryption key updated.')));
    await _refresh();
  }

  Future<void> _toggleBiometric(bool enabled) async {
    await context.read<CredentialService>().setBiometricUnlockEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  Future<void> _deleteAllCredentials() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Credentials'),
        content: const Text(
          'This permanently deletes every stored credential. Continue?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final authenticatedKey = await showCredentialAuthenticationDialog(
      context,
      title: 'Authenticate',
      reason: 'Authenticate before deleting all credential data.',
    );

    if (authenticatedKey == null || !mounted) {
      return;
    }

    await context.read<CredentialService>().deleteAllCredentials();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All credential data deleted.')),
    );
  }

  Future<String?> _showNewKeyDialog() {
    final keyController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('New Encryption Key'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: keyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Encryption Key',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Key',
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final newKey = keyController.text.trim();
                  final confirmKey = confirmController.text.trim();
                  if (newKey.isEmpty || confirmKey.isEmpty) {
                    setDialogState(() {
                      errorText = 'New encryption key is required';
                    });
                    return;
                  }
                  if (newKey != confirmKey) {
                    setDialogState(() {
                      errorText = 'Keys do not match';
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop(newKey);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      keyController.dispose();
      confirmController.dispose();
    });
  }
}
