import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/credential_service.dart';
import '../../domain/models/credential_models.dart';
import '../widgets/credential_auth_dialog.dart';
import 'credential_editor_page.dart';

class CredentialDetailArgs {
  const CredentialDetailArgs({required this.credentialId});

  final int credentialId;
}

class CredentialDetailPage extends StatefulWidget {
  const CredentialDetailPage({super.key, required this.args});

  final CredentialDetailArgs args;

  @override
  State<CredentialDetailPage> createState() => _CredentialDetailPageState();
}

class _CredentialDetailPageState extends State<CredentialDetailPage> {
  bool _isLoading = true;
  DecryptedCredential? _credential;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unlockCredential();
    });
  }

  @override
  Widget build(BuildContext context) {
    final credential = _credential;

    return Scaffold(
      appBar: AppBar(title: Text(credential?.title ?? 'Credential')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : credential == null
          ? const Center(child: Text('Credential not found.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        credential.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Updated ${AppConstants.longDateFormat.format(credential.updatedAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          if (credential.expiryDate != null)
                            _CredentialBadge(
                              label:
                                  'Expiry ${AppConstants.shortDateFormat.format(credential.expiryDate!)}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...credential.fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppPanel(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  field.keyLabel,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                SelectableText(field.value),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: field.value),
                              );
                              if (!context.mounted) {
                                return;
                              }
                              showAppSnackBar(
                                context,
                                message: '${field.keyLabel} copied.',
                              );
                            },
                            icon: const Icon(Icons.copy_all_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: credential == null || _isLoading
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _editCredential,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _deleteCredential,
                      style: FilledButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _unlockCredential() async {
    final service = context.read<CredentialService>();
    final record = await service.loadCredential(widget.args.credentialId);

    if (!mounted) {
      return;
    }

    if (record == null) {
      setState(() {
        _isLoading = false;
        _credential = null;
      });
      return;
    }

    final encryptionKey = await showCredentialAuthenticationDialog(
      context,
      title: 'Unlock Credential',
      reason: 'Authenticate to view secure credential data.',
    );

    if (!mounted) {
      return;
    }

    if (encryptionKey == null) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final credential = await service.decryptCredential(
        record: record,
        encryptionKey: encryptionKey,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _credential = credential;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message:
            'Unable to decrypt this credential with the provided authentication.',
        type: AppSnackBarType.error,
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _editCredential() async {
    final credential = _credential;
    if (credential == null) {
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CredentialEditorPage(
          args: CredentialEditorArgs(credential: credential),
        ),
      ),
    );

    if (updated == true && mounted) {
      setState(() {
        _isLoading = true;
      });
      await _unlockCredential();
    }
  }

  Future<void> _deleteCredential() async {
    final credential = _credential;
    if (credential == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Credential'),
        content: Text('Delete "${credential.title}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<CredentialService>().deleteCredential(credential.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }
}

class _CredentialBadge extends StatelessWidget {
  const _CredentialBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.65,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
