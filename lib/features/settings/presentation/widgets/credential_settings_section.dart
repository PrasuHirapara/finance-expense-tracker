import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/app_settings_repository.dart';
import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/services/module_data_import_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/cancellable_blocking_overlay.dart';
import '../../../../shared/widgets/download_result_snackbar.dart';
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
  bool _credentialExpiryNotificationEnabled = false;
  bool _isLoading = true;
  bool _isDownloadingSample = false;
  bool _isImporting = false;

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
                              if (!_biometricAvailable) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  'Biometric authentication is not available on this device.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
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
                                'Expiry Notification',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Notify 1 day before a saved credential expiry date.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _credentialExpiryNotificationEnabled,
                          onChanged: _toggleCredentialExpiryNotification,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Credential Import',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Download the sample Excel file, fill each row, then import. Every filled row must be valid before anything is saved.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Expected columns: Title, Expiry Date, Field, Value',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            FilledButton.tonalIcon(
                              onPressed: _isDownloadingSample || _isImporting
                                  ? null
                                  : _downloadCredentialSample,
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
                                  : _importCredentials,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(
                                _isImporting ? 'Importing...' : 'Import Excel',
                              ),
                            ),
                          ],
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
    final settingsRepository = context.read<AppSettingsRepository>();
    final hasEncryptionKey = await service.hasEncryptionKey();
    final biometricEnabled = await service.isBiometricUnlockEnabled();
    final biometricAvailable = await service.canUseBiometrics();
    final settings = await settingsRepository.getSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _hasEncryptionKey = hasEncryptionKey;
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = biometricAvailable;
      _credentialExpiryNotificationEnabled =
          settings.credentialExpiryNotificationEnabled;
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
    final credentialService = context.read<CredentialService>();
    final settingsRepository = context.read<AppSettingsRepository>();
    final cloudSyncService = context.read<CloudSyncService>();
    final messenger = ScaffoldMessenger.of(context);
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
      await credentialService.rotateEncryptionKey(
        oldEncryptionKey: oldKey,
        newEncryptionKey: newKey,
      );

      final settings = await settingsRepository.getSettings();
      if (settings.cloudSync.enabled && settings.cloudSync.syncCredentials) {
        await cloudSyncService.uploadDataToCloud(
          credentialEncryptionKey: newKey,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Unable to update encryption key: $error',
          type: AppSnackBarType.error,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      buildAppSnackBar(
        context,
        message: 'Encryption key updated. Cloud backup refreshed if enabled.',
      ),
    );
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

  Future<void> _toggleCredentialExpiryNotification(bool enabled) async {
    final settingsRepository = context.read<AppSettingsRepository>();
    final notificationService = context.read<NotificationService>();
    final previousValue = _credentialExpiryNotificationEnabled;
    if (mounted) {
      setState(() {
        _credentialExpiryNotificationEnabled = enabled;
      });
    }

    try {
      await settingsRepository.updateCredentialExpiryNotificationEnabled(
        enabled,
      );
      if (enabled) {
        await _runBlockingOperation<void>(
          statusText: 'Scheduling credential expiry notifications...',
          task: (token) => notificationService
              .syncCredentialExpiryNotifications(cancellationToken: token),
        );
      } else {
        await notificationService.cancelCredentialExpiryNotifications();
      }
    } on AppTaskCancelledException {
      await settingsRepository.updateCredentialExpiryNotificationEnabled(
        previousValue,
      );
      await notificationService.cancelCredentialExpiryNotifications();
      if (mounted) {
        setState(() {
          _credentialExpiryNotificationEnabled = previousValue;
        });
      }
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Expiry notification setup canceled.',
        type: AppSnackBarType.warning,
      );
    } catch (error) {
      await settingsRepository.updateCredentialExpiryNotificationEnabled(
        previousValue,
      );
      if (mounted) {
        setState(() {
          _credentialExpiryNotificationEnabled = previousValue;
        });
      }
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to update expiry notifications: $error',
        type: AppSnackBarType.error,
      );
    }
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

    final credentialService = context.read<CredentialService>();
    final cloudSyncService = context.read<CloudSyncService>();
    await credentialService.deleteAllCredentials();
    String? cloudCleanupWarning;
    try {
      await cloudSyncService.deleteCloudData('Credential');
    } catch (error) {
      cloudCleanupWarning = ' Cloud backup cleanup failed: $error';
    }
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: 'All credential data deleted.${cloudCleanupWarning ?? ''}',
      type: cloudCleanupWarning == null
          ? AppSnackBarType.info
          : AppSnackBarType.warning,
    );
  }

  Future<void> _downloadCredentialSample() async {
    setState(() {
      _isDownloadingSample = true;
    });

    try {
      final path = await context
          .read<ModuleDataImportService>()
          .downloadCredentialSampleExcel();
      if (!mounted) {
        return;
      }
      showDownloadResultSnackBar(
        context,
        message: 'Credential sample Excel saved to $path',
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

  Future<void> _importCredentials() async {
    final file = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select credential Excel file',
      type: FileType.custom,
      allowedExtensions: const <String>['xlsx'],
    );

    if (file == null || file.files.single.path == null || !mounted) {
      return;
    }

    final authenticatedKey = await showCredentialAuthenticationDialog(
      context,
      title: 'Authenticate',
      reason: 'Authenticate before importing credential data.',
    );

    if (authenticatedKey == null || !mounted) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await context
          .read<ModuleDataImportService>()
          .importCredentialExcel(
            file.files.single.path!,
            encryptionKey: authenticatedKey,
          );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: result.message);
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

  Future<T> _runBlockingOperation<T>({
    required String statusText,
    required Future<T> Function(AppCancellationToken token) task,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final token = AppCancellationToken();
    final route = createCancellableBlockingOverlayRoute<void>(
      statusText: statusText,
      onCancel: token.cancel,
    );
    unawaited(navigator.push<void>(route));
    await Future<void>.delayed(Duration.zero);

    try {
      return await task(token);
    } finally {
      if (route.isActive) {
        navigator.removeRoute(route);
      }
    }
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
                Text(
                  'Use at least 7 characters with A, a, 1, and @.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
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
                  final validationError = validateCredentialEncryptionKey(
                    newKey,
                  );
                  if (validationError != null) {
                    setDialogState(() {
                      errorText = validationError;
                    });
                    return;
                  }
                  if (confirmKey.isEmpty) {
                    setDialogState(() {
                      errorText = 'Confirm new key is required';
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
