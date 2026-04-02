import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

import 'google_drive_oauth_config.dart';

class GoogleDriveAuthService {
  GoogleDriveAuthService();

  static const List<String> scopes = <String>[
    'https://www.googleapis.com/auth/drive.file',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _googleSignIn.initialize(
      clientId: GoogleDriveOAuthConfig.effectiveClientId,
      serverClientId: GoogleDriveOAuthConfig.serverClientId.trim().isEmpty
          ? null
          : GoogleDriveOAuthConfig.serverClientId,
    );
    _googleSignIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _currentUser = event.user;
        case GoogleSignInAuthenticationEventSignOut():
          _currentUser = null;
      }
    });
    _initialized = true;
  }

  Future<GoogleSignInAccount?> restoreSession() async {
    await initialize();
    final account = await _googleSignIn.attemptLightweightAuthentication();
    if (account != null) {
      _currentUser = account;
    }
    return _currentUser;
  }

  Future<GoogleSignInAccount> authenticateInteractively() async {
    await initialize();
    final account = await _googleSignIn.authenticate(scopeHint: scopes);
    _currentUser = account;
    return account;
  }

  Future<GoogleSignInAccount> requireUser({required bool interactive}) async {
    final account = interactive
        ? await authenticateInteractively()
        : await restoreSession();
    if (account == null) {
      throw StateError(
        interactive
            ? 'Google account authentication was cancelled.'
            : 'No active Google account session is available for background sync.',
      );
    }
    return account;
  }

  Future<Map<String, String>> authorizationHeaders({
    required bool interactive,
  }) async {
    final user = await requireUser(interactive: interactive);
    final headers = await user.authorizationClient.authorizationHeaders(
      scopes,
      promptIfNecessary: interactive,
    );
    if (headers == null) {
      throw StateError('Google Drive authorization is not available.');
    }
    return headers;
  }

  Future<String?> currentUserEmail({required bool interactive}) async {
    final user = await requireUser(interactive: interactive);
    return user.email;
  }
}
