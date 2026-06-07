import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/cloud_sync_service.dart';

import '../../../../core/services/app_data_reset_service.dart';
import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/firebase_cloud_sync_auth_service.dart';
import '../../../../core/services/firebase_runtime_service.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/cancellable_blocking_overlay.dart';
import '../../../auth/presentation/pages/auth_page.dart';

class UserSettingsSection extends StatefulWidget {
  const UserSettingsSection({super.key});

  @override
  State<UserSettingsSection> createState() => _UserSettingsSectionState();
}

class _UserSettingsSectionState extends State<UserSettingsSection> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<FirebaseCloudSyncAuthService>();

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildFirebaseAccountContent(context, theme, authService),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => _deleteAllData(context),
              style: FilledButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete All Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseAccountContent(
    BuildContext context,
    ThemeData theme,
    FirebaseCloudSyncAuthService authService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Firebase Account', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.42,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: StreamBuilder<FirebaseCloudSyncAccount?>(
            stream: authService.authStateChanges(),
            initialData: authService.currentAccount,
            builder: (context, snapshot) {
              final account = snapshot.data;
              final providerLabel = _providerSummary(account);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    account?.displayName?.trim().isNotEmpty == true
                        ? account!.displayName!.trim()
                        : account?.email ?? 'Not connected',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account?.email ?? 'No active Firebase session.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    providerLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!authService.isAvailable) ...<Widget>[
                    Text(
                      '$firebaseConfigMissingMessage Login and cloud backup are disabled on this build.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (authService.isAvailable && account == null)
                    FilledButton.icon(
                      onPressed: () => _openFirebaseAuthPage(context),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Login or Sign Up'),
                    ),
                  if (authService.isAvailable && account != null)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: _isSigningOut
                              ? null
                              : () => _signOutFirebaseAccount(context),
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(
                            _isSigningOut ? 'Signing Out...' : 'Sign Out',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isSigningOut
                              ? null
                              : () => _deleteFirebaseAccount(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete Account'),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _providerSummary(FirebaseCloudSyncAccount? account) {
    if (account == null || account.providerIds.isEmpty) {
      return 'Provider: Firebase Authentication';
    }

    final labels = account.providerIds
        .map((providerId) {
          return switch (providerId) {
            'google.com' => 'Google',
            'password' => 'Email and Password',
            _ => providerId,
          };
        })
        .join(' | ');

    return 'Provider: $labels';
  }

  Future<void> _signOutFirebaseAccount(BuildContext context) async {
    setState(() {
      _isSigningOut = true;
    });
    try {
      await runWithCancellableBlockingOverlay<void>(
        context: context,
        title: 'Signing out',
        statusText: 'Signing out of your Firebase account...',
        task: (token) => context.read<FirebaseCloudSyncAuthService>().signOut(
          cancellationToken: token,
        ),
      );
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: 'Firebase account signed out.');
    } on AppTaskCancelledException {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Sign out canceled.',
        type: AppSnackBarType.warning,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to sign out: $error',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<void> _deleteFirebaseAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Firebase Account'),
        content: const Text(
          'Are you sure you want to permanently delete your Firebase account?\n\n'
          'This will permanently destroy all your Firestore cloud sync and backup data, and delete your profile. This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final cloudSyncService = context.read<CloudSyncService>();
    final authService = context.read<FirebaseCloudSyncAuthService>();

    try {
      await runWithCancellableBlockingOverlay<void>(
        context: context,
        title: 'Deleting Account',
        statusText: 'Deleting cloud backups and account profile...',
        task: (token) async {
          // 1. Delete all Firestore data for this user
          await cloudSyncService.deleteCloudDataForce('Daily Use');
          token.throwIfCancelled();

          // 2. Delete the user profile document and the Auth user account
          await authService.deleteAccount(cancellationToken: token);
        },
      );

      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Your Firebase account was successfully deleted.',
      );
    } on AppTaskCancelledException {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Account deletion canceled.',
        type: AppSnackBarType.warning,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) {
        return;
      }
      if (e.code == 'requires-recent-login') {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Recent Login Required'),
            content: const Text(
              'Deleting your account is a sensitive operation. For security reasons, you must sign out, sign back in, and then try deleting the account again immediately.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showAppSnackBar(
          context,
          message: 'Unable to delete account: ${e.message}',
          type: AppSnackBarType.error,
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to delete account: $error',
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This deletes all Credential, Expense, and Task data. Continue?',
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await context.read<AppDataResetService>().deleteAllData();
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, message: 'All app data deleted.');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: 'Unable to delete all data: $error',
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _openFirebaseAuthPage(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const AuthPage(closeOnSuccess: true),
      ),
    );
  }
}
