import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CloudSyncSecurityService {
  CloudSyncSecurityService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  static const String _backupKeyStorageKey = 'cloud_sync.backup_key.value';

  final FlutterSecureStorage _storage;
  final Random _random = Random.secure();

  Future<String> getOrCreateBackupKey() async {
    final existing = await _storage.read(key: _backupKeyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final generated = base64UrlEncode(bytes);
    await _storage.write(key: _backupKeyStorageKey, value: generated);
    return generated;
  }
}
