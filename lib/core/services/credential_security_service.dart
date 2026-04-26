import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class CredentialSecurityService {
  CredentialSecurityService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
      _localAuth = LocalAuthentication();

  static const String _encryptionKeyStorageKey =
      'credential.encryption_key.value';
  static const String _biometricEnabledStorageKey =
      'credential.biometric_unlock.enabled';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  Future<bool> hasEncryptionKey() async {
    final value = await _storage.read(key: _encryptionKeyStorageKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> setEncryptionKey(String encryptionKey) {
    return _storage.write(key: _encryptionKeyStorageKey, value: encryptionKey);
  }

  Future<String?> readEncryptionKey() {
    return _storage.read(key: _encryptionKeyStorageKey);
  }

  Future<bool> verifyEncryptionKey(String encryptionKey) async {
    final storedKey = await readEncryptionKey();
    return storedKey != null && storedKey == encryptionKey;
  }

  Future<void> clearStoredEncryptionKey() async {
    await _storage.delete(key: _encryptionKeyStorageKey);
    await setBiometricUnlockEnabled(false);
  }

  Future<bool> isBiometricUnlockEnabled() async {
    final value = await _storage.read(key: _biometricEnabledStorageKey);
    return value == 'true';
  }

  Future<void> setBiometricUnlockEnabled(bool enabled) {
    return _storage.write(
      key: _biometricEnabledStorageKey,
      value: enabled.toString(),
    );
  }

  Future<bool> canUseBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isSupported;
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return const <BiometricType>[];
    }
  }

  Future<bool> authenticateWithBiometrics({required String reason}) async {
    try {
      if (!await canUseBiometrics()) {
        return false;
      }
      final biometrics = await availableBiometrics();
      if (biometrics.isEmpty) {
        return false;
      }
      return _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint('Credential biometric authentication failed: ${error.code}');
      }
      if (error.code == auth_error.notAvailable ||
          error.code == auth_error.notEnrolled ||
          error.code == auth_error.lockedOut ||
          error.code == auth_error.permanentlyLockedOut) {
        return false;
      }
      return false;
    }
  }
}
