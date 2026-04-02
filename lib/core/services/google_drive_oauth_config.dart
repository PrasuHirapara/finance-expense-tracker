class GoogleDriveOAuthConfig {
  GoogleDriveOAuthConfig._();

  static const String legacyClientId = String.fromEnvironment(
    'GOOGLE_DRIVE_CLIENT_ID',
  );
  static const String oauthClientId = String.fromEnvironment(
    'GOOGLE_DRIVE_OAUTH_CLIENT_ID',
  );
  static const String redirectUriOverride = String.fromEnvironment(
    'GOOGLE_DRIVE_OAUTH_REDIRECT_URI',
  );
  static const String redirectScheme = 'com.prasu.daily.use';
  static const String redirectPath = '/oauth2redirect';

  static String? get clientId {
    if (oauthClientId.trim().isNotEmpty) {
      return oauthClientId;
    }
    if (legacyClientId.trim().isNotEmpty) {
      return legacyClientId;
    }
    return null;
  }

  static String get redirectUri {
    if (redirectUriOverride.trim().isNotEmpty) {
      return redirectUriOverride;
    }
    return '$redirectScheme:$redirectPath';
  }
}
