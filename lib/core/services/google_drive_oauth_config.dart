class GoogleDriveOAuthConfig {
  GoogleDriveOAuthConfig._();

  static const String clientId = String.fromEnvironment(
    'GOOGLE_DRIVE_CLIENT_ID',
  );
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_DRIVE_IOS_CLIENT_ID',
  );
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_DRIVE_SERVER_CLIENT_ID',
  );

  static String? get effectiveClientId {
    if (iosClientId.trim().isNotEmpty) {
      return iosClientId;
    }
    if (clientId.trim().isNotEmpty) {
      return clientId;
    }
    return null;
  }
}
