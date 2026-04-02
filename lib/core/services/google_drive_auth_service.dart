import 'dart:async';
import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'google_drive_oauth_config.dart';

class GoogleDriveAuthService {
  GoogleDriveAuthService({
    FlutterAppAuth? appAuth,
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  }) : _appAuth = appAuth ?? FlutterAppAuth(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _httpClient = httpClient ?? http.Client();

  static const List<String> scopes = <String>[
    'openid',
    'email',
    'profile',
    'https://www.googleapis.com/auth/drive.file',
  ];

  static const AuthorizationServiceConfiguration _serviceConfiguration =
      AuthorizationServiceConfiguration(
        authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
        tokenEndpoint: 'https://oauth2.googleapis.com/token',
      );

  static final Uri _userInfoUri = Uri.parse(
    'https://openidconnect.googleapis.com/v1/userinfo',
  );
  static final Uri _revokeUri = Uri.parse(
    'https://oauth2.googleapis.com/revoke',
  );

  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;

  bool _initialized = false;
  GoogleDriveAccount? _currentUser;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (GoogleDriveOAuthConfig.clientId == null) {
      throw const GoogleDriveAuthConfigurationException(
        'Google Drive OAuth is not configured. Provide '
        'GOOGLE_DRIVE_OAUTH_CLIENT_ID or GOOGLE_DRIVE_CLIENT_ID as a Dart define.',
      );
    }

    _initialized = true;
  }

  Future<GoogleDriveAccount?> restoreSession() async {
    await initialize();
    final stored = await _readStoredSession();
    if (stored == null) {
      _currentUser = null;
      return null;
    }

    if (!_isExpired(stored)) {
      _currentUser = GoogleDriveAccount(email: stored.email);
      return _currentUser;
    }

    if (stored.refreshToken == null || stored.refreshToken!.isEmpty) {
      await _clearStoredSession();
      _currentUser = null;
      return null;
    }

    final refreshed = await _appAuth.token(
      TokenRequest(
        GoogleDriveOAuthConfig.clientId!,
        GoogleDriveOAuthConfig.redirectUri,
        serviceConfiguration: _serviceConfiguration,
        refreshToken: stored.refreshToken,
        scopes: scopes,
      ),
    );
    if (refreshed == null || refreshed.accessToken == null) {
      await _clearStoredSession();
      _currentUser = null;
      return null;
    }

    final email = stored.email.isNotEmpty
        ? stored.email
        : await _fetchUserEmail(refreshed.accessToken!);
    final account = await _persistSession(
      accessToken: refreshed.accessToken!,
      refreshToken: refreshed.refreshToken ?? stored.refreshToken,
      accessTokenExpiration:
          refreshed.accessTokenExpirationDateTime ??
          stored.accessTokenExpiration,
      email: email,
    );
    _currentUser = account;
    return account;
  }

  Future<GoogleDriveAccount> authenticateInteractively() async {
    await initialize();
    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        GoogleDriveOAuthConfig.clientId!,
        GoogleDriveOAuthConfig.redirectUri,
        serviceConfiguration: _serviceConfiguration,
        scopes: scopes,
        additionalParameters: const <String, String>{
          'access_type': 'offline',
          'prompt': 'consent select_account',
        },
      ),
    );
    if (response == null || response.accessToken == null) {
      throw StateError('Google account authentication was cancelled.');
    }

    final account = await _persistSession(
      accessToken: response.accessToken!,
      refreshToken: response.refreshToken,
      accessTokenExpiration: response.accessTokenExpirationDateTime,
      email: await _fetchUserEmail(response.accessToken!),
    );
    _currentUser = account;
    return account;
  }

  Future<GoogleDriveAccount> requireUser({required bool interactive}) async {
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
    final session = interactive
        ? await _resolveInteractiveSession()
        : await _resolveStoredSession();
    return <String, String>{'Authorization': 'Bearer ${session.accessToken}'};
  }

  Future<String?> currentUserEmail({required bool interactive}) async {
    final account = await requireUser(interactive: interactive);
    return account.email;
  }

  Future<String?> restoreCurrentUserEmail() async {
    final user = await restoreSession();
    return user?.email;
  }

  Future<void> signOut() async {
    await initialize();
    final session = await _readStoredSession();
    final tokenForRevocation = session?.refreshToken ?? session?.accessToken;
    if (tokenForRevocation != null && tokenForRevocation.isNotEmpty) {
      try {
        await _httpClient.post(
          _revokeUri,
          headers: const <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: 'token=${Uri.encodeQueryComponent(tokenForRevocation)}',
        );
      } catch (_) {}
    }

    await _clearStoredSession();
    _currentUser = null;
  }

  Future<GoogleDriveStoredSession> _resolveInteractiveSession() async {
    final account = await authenticateInteractively();
    final stored = await _readStoredSession();
    if (stored == null) {
      throw StateError(
        'Google Drive authorization is not available for ${account.email}.',
      );
    }
    return stored;
  }

  Future<GoogleDriveStoredSession> _resolveStoredSession() async {
    await restoreSession();
    final stored = await _readStoredSession();
    if (stored == null || stored.accessToken.isEmpty) {
      throw StateError('Google Drive authorization is not available.');
    }
    return stored;
  }

  Future<String> _fetchUserEmail(String accessToken) async {
    final response = await _httpClient.get(
      _userInfoUri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Unable to read Google account details (${response.statusCode}).',
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final email = payload['email'] as String?;
    if (email == null || email.trim().isEmpty) {
      throw StateError('Google account email was not returned.');
    }
    return email;
  }

  Future<GoogleDriveAccount> _persistSession({
    required String accessToken,
    required String email,
    String? refreshToken,
    DateTime? accessTokenExpiration,
  }) async {
    final session = GoogleDriveStoredSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiration:
          accessTokenExpiration ?? DateTime.now().add(const Duration(hours: 1)),
      email: email,
    );
    await _secureStorage.write(
      key: _StorageKeys.accessToken,
      value: session.accessToken,
    );
    await _secureStorage.write(
      key: _StorageKeys.refreshToken,
      value: session.refreshToken,
    );
    await _secureStorage.write(
      key: _StorageKeys.expiration,
      value: session.accessTokenExpiration.toIso8601String(),
    );
    await _secureStorage.write(key: _StorageKeys.email, value: session.email);
    return GoogleDriveAccount(email: session.email);
  }

  Future<GoogleDriveStoredSession?> _readStoredSession() async {
    final values = await _secureStorage.readAll();
    final accessToken = values[_StorageKeys.accessToken];
    final email = values[_StorageKeys.email];
    final expirationRaw = values[_StorageKeys.expiration];
    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        email == null ||
        email.trim().isEmpty) {
      return null;
    }

    return GoogleDriveStoredSession(
      accessToken: accessToken,
      refreshToken: values[_StorageKeys.refreshToken],
      accessTokenExpiration:
          DateTime.tryParse(expirationRaw ?? '') ??
          DateTime.now().subtract(const Duration(minutes: 1)),
      email: email,
    );
  }

  Future<void> _clearStoredSession() async {
    await _secureStorage.delete(key: _StorageKeys.accessToken);
    await _secureStorage.delete(key: _StorageKeys.refreshToken);
    await _secureStorage.delete(key: _StorageKeys.expiration);
    await _secureStorage.delete(key: _StorageKeys.email);
  }

  bool _isExpired(GoogleDriveStoredSession session) {
    return DateTime.now().isAfter(
      session.accessTokenExpiration.subtract(const Duration(minutes: 1)),
    );
  }
}

class GoogleDriveAccount {
  const GoogleDriveAccount({required this.email});

  final String email;
}

class GoogleDriveStoredSession {
  const GoogleDriveStoredSession({
    required this.accessToken,
    required this.accessTokenExpiration,
    required this.email,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime accessTokenExpiration;
  final String email;
}

class _StorageKeys {
  static const String accessToken = 'google_drive_access_token';
  static const String refreshToken = 'google_drive_refresh_token';
  static const String expiration = 'google_drive_access_token_expiration';
  static const String email = 'google_drive_account_email';
}

class GoogleDriveAuthConfigurationException implements Exception {
  const GoogleDriveAuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}
