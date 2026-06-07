import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/cloud_sync_models.dart';
import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/services/firebase_cloud_sync_auth_service.dart';
import '../../../../core/services/firebase_runtime_service.dart';
import '../../../../features/credentials/data/services/credential_service.dart';
import '../../../../features/credentials/presentation/widgets/credential_key_entry_dialog.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/cancellable_blocking_overlay.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.closeOnSuccess = false});

  final bool closeOnSuccess;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoginMode = true;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<FirebaseCloudSyncAuthService>();
    final cloudSyncAvailable = authService.isAvailable;
    final googleSignInAvailable =
        cloudSyncAvailable && authService.supportsGoogleSignIn;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.tertiary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.72,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Daily Use',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in with Firebase to keep your data connected across authentication and Firestore cloud backup.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppPanel(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _isLoginMode ? 'Login' : 'Register',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              !cloudSyncAvailable
                                  ? '$firebaseConfigMissingMessage Cloud authentication is disabled.'
                                  : _isLoginMode
                                  ? 'Use your email and password or continue with Google.'
                                  : 'Create a Firebase account, then your profile will be stored in Firestore.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SegmentedButton<bool>(
                              segments: const <ButtonSegment<bool>>[
                                ButtonSegment<bool>(
                                  value: true,
                                  label: Text('Login'),
                                  icon: Icon(Icons.login_rounded),
                                ),
                                ButtonSegment<bool>(
                                  value: false,
                                  label: Text('Register'),
                                  icon: Icon(Icons.person_add_alt_1_rounded),
                                ),
                              ],
                              selected: <bool>{_isLoginMode},
                              onSelectionChanged: _isSubmitting
                                  ? null
                                  : (selection) {
                                      setState(() {
                                        _isLoginMode = selection.first;
                                      });
                                    },
                            ),
                            const SizedBox(height: 18),
                            if (!_isLoginMode) ...<Widget>[
                              TextFormField(
                                controller: _displayNameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.badge_rounded),
                                ),
                                validator: (value) {
                                  if (_isLoginMode) {
                                    return null;
                                  }
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Enter your name.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) {
                                final email = (value ?? '').trim();
                                if (email.isEmpty) {
                                  return 'Enter your email.';
                                }
                                if (!email.contains('@')) {
                                  return 'Enter a valid email.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: _isLoginMode
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.isEmpty) {
                                  return 'Enter your password.';
                                }
                                if (!_isLoginMode && password.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                if (_isLoginMode) {
                                  _submitEmailPassword();
                                }
                              },
                            ),
                            if (!_isLoginMode) ...<Widget>[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon: const Icon(
                                    Icons.verified_user_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (_isLoginMode) {
                                    return null;
                                  }
                                  if ((value ?? '').isEmpty) {
                                    return 'Confirm your password.';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submitEmailPassword(),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isSubmitting || !cloudSyncAvailable
                                    ? null
                                    : _submitEmailPassword,
                                icon: Icon(
                                  _isLoginMode
                                      ? Icons.login_rounded
                                      : Icons.person_add_alt_1_rounded,
                                ),
                                label: Text(
                                  _isSubmitting
                                      ? 'Please wait...'
                                      : _isLoginMode
                                      ? 'Login with Email'
                                      : 'Create Account',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'or',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isSubmitting || !googleSignInAvailable
                                    ? null
                                    : _continueWithGoogle,
                                icon: const Icon(Icons.g_mobiledata_rounded),
                                label: Text(
                                  googleSignInAvailable
                                      ? 'Continue with Google'
                                      : 'Google Sign-In Unavailable',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEmailPassword() async {
    final authService = context.read<FirebaseCloudSyncAuthService>();
    if (!authService.isAvailable) {
      _showMessage(firebaseConfigMissingMessage);
      return;
    }

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await runWithCancellableBlockingOverlay<void>(
        context: context,
        title: _isLoginMode ? 'Logging in' : 'Creating account',
        statusText: _isLoginMode
            ? 'Signing in to your Firebase account...'
            : 'Creating your Firebase account...',
        task: (token) async {
          if (_isLoginMode) {
            await authService.signInWithEmailPassword(
              email: _emailController.text,
              password: _passwordController.text,
              cancellationToken: token,
            );
            return;
          }

          await authService.registerWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _displayNameController.text,
            cancellationToken: token,
          );
        },
      );
      await _handleAuthSuccess();
    } on AppTaskCancelledException {
      _showMessage(_isLoginMode ? 'Login canceled.' : 'Registration canceled.');
    } on FirebaseAuthException catch (error) {
      _showMessage(_friendlyFirebaseAuthMessage(error));
    } catch (error) {
      _showMessage('Unable to continue: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    final authService = context.read<FirebaseCloudSyncAuthService>();
    if (!authService.isAvailable) {
      _showMessage(firebaseConfigMissingMessage);
      return;
    }
    if (!authService.supportsGoogleSignIn) {
      _showMessage('Google sign-in is not available on this platform.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await runWithCancellableBlockingOverlay<void>(
        context: context,
        title: 'Signing in',
        statusText: 'Connecting to your Google account...',
        task: (token) => authService.signInWithGoogle(cancellationToken: token),
      );
      await _handleAuthSuccess();
    } on AppTaskCancelledException {
      _showMessage('Google sign-in canceled.');
    } on FirebaseAuthException catch (error) {
      _showMessage(_friendlyFirebaseAuthMessage(error));
    } catch (error) {
      _showMessage('Google sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: message,
      type: message.toLowerCase().contains('unable')
          ? AppSnackBarType.error
          : AppSnackBarType.info,
    );
  }

  String _friendlyFirebaseAuthMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'That email address is not valid.',
      'user-not-found' => 'No account was found for that email.',
      'wrong-password' => 'The password is incorrect.',
      'invalid-credential' =>
        'The email or password is incorrect. Please try again.',
      'email-already-in-use' =>
        'That email is already registered. Try logging in instead.',
      'weak-password' =>
        'Choose a stronger password with at least 6 characters.',
      'too-many-requests' =>
        'Too many attempts were made. Please wait and try again.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }

  Future<void> _handleAuthSuccess() async {
    if (!mounted) {
      return;
    }

    try {
      await _restoreDataAfterSignIn();
    } catch (e) {
      _showMessage('Cloud restore failed: $e');
    }

    if (!mounted) {
      return;
    }

    if (widget.closeOnSuccess && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }

    _showMessage('Firebase account connected.');
  }

  Future<void> _restoreDataAfterSignIn() async {
    final cloudSyncService = context.read<CloudSyncService>();
    final credentialService = context.read<CredentialService>();

    // 1. Enable Cloud Sync in settings
    await cloudSyncService.setCloudSyncEnabled(true);

    // 2. Perform restore from cloud with forceOverwrite: true
    try {
      await _performCloudRestore(forceOverwrite: true);
      _showMessage('Cloud restore completed successfully.');
    } on FileSystemException catch (e) {
      // If there is no cloud backup found, that's not an error for a new user/device.
      if (e.message.contains('No cloud backup was found') ||
          e.message.contains('No cloud backup manifest was found')) {
        _showMessage(
          'Firebase account connected. No cloud backup found to restore.',
        );
        return;
      }
      rethrow;
    } on CloudCredentialEncryptionKeyRequiredException {
      final requireConfirmation = !(await credentialService.hasEncryptionKey());
      if (!mounted) return;
      await _promptForCredentialKeyAndRestore(
        forceOverwrite: true,
        requireConfirmation: requireConfirmation,
        reason:
            'Enter your credential encryption key to restore encrypted credential titles from Firestore.',
      );
    } on CloudCredentialEncryptionKeyInvalidException {
      if (!mounted) return;
      await _promptForCredentialKeyAndRestore(
        forceOverwrite: true,
        requireConfirmation: false,
        reason:
            'The saved encryption key did not match the cloud credential backup. Enter the correct key to restore those records.',
      );
    }
  }

  Future<void> _performCloudRestore({
    required bool forceOverwrite,
    String? credentialEncryptionKey,
  }) async {
    final cloudSyncService = context.read<CloudSyncService>();
    await runWithCancellableBlockingOverlay<void>(
      context: context,
      title: 'Restoring data',
      statusText: 'Restoring your cloud backup...',
      task: (token) => cloudSyncService.downloadDataFromCloud(
        forceOverwrite: forceOverwrite,
        credentialEncryptionKey: credentialEncryptionKey,
        cancellationToken: token,
      ),
    );
  }

  Future<bool> _promptForCredentialKeyAndRestore({
    required bool forceOverwrite,
    required bool requireConfirmation,
    required String reason,
  }) async {
    final credentialService = context.read<CredentialService>();
    final enteredKey = await showCredentialKeyEntryDialog(
      context,
      title: 'Credential Key Required',
      reason: reason,
      requireConfirmation: requireConfirmation,
      submitLabel: requireConfirmation ? 'Save & Restore' : 'Restore',
    );

    if (enteredKey == null || !mounted) {
      return false;
    }

    try {
      await _performCloudRestore(
        forceOverwrite: forceOverwrite,
        credentialEncryptionKey: enteredKey,
      );
      await credentialService.configureEncryptionKey(enteredKey);
      _showMessage('Cloud restore completed successfully.');
      return true;
    } on FileSystemException catch (e) {
      if (e.message.contains('No cloud backup was found') ||
          e.message.contains('No cloud backup manifest was found')) {
        _showMessage(
          'Firebase account connected. No cloud backup found to restore.',
        );
        return true;
      }
      rethrow;
    } on CloudCredentialEncryptionKeyRequiredException {
      if (!mounted) return false;
      return _promptForCredentialKeyAndRestore(
        forceOverwrite: forceOverwrite,
        requireConfirmation: requireConfirmation,
        reason:
            'Enter your credential encryption key to restore encrypted credential titles from Firestore.',
      );
    } on CloudCredentialEncryptionKeyInvalidException {
      if (!mounted) return false;
      return _promptForCredentialKeyAndRestore(
        forceOverwrite: forceOverwrite,
        requireConfirmation: false,
        reason:
            'The entered encryption key did not match the cloud credential backup. Please try again.',
      );
    }
  }
}
