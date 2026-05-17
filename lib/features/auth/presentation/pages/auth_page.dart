import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/firebase_cloud_sync_auth_service.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../core/services/firebase_runtime_service.dart';
import '../../../../shared/widgets/app_panel.dart';
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

    if (widget.closeOnSuccess && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }

    _showMessage('Firebase account connected.');
  }
}
