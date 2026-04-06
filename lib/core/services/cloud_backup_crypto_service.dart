import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../models/cloud_sync_models.dart';

class CloudBackupCryptoService {
  CloudBackupCryptoService()
    : _pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 100000,
        bits: 256,
      ),
      _aesGcm = AesGcm.with256bits();

  final Pbkdf2 _pbkdf2;
  final AesGcm _aesGcm;
  final Random _random = Random.secure();

  Future<EncryptedCloudPayload> encryptText({
    required String plainText,
    required String encryptionKey,
  }) {
    return _encryptBytes(
      bytes: utf8.encode(plainText),
      encryptionKey: encryptionKey,
    );
  }

  Future<String> decryptText({
    required EncryptedCloudPayload payload,
    required String encryptionKey,
  }) async {
    final decryptedBytes = await _decryptBytes(
      encryptedPayload: payload.encryptedPayload,
      saltBase64: payload.saltBase64,
      nonceBase64: payload.nonceBase64,
      encryptionKey: encryptionKey,
    );
    return utf8.decode(decryptedBytes);
  }

  Future<EncryptedCloudPayload> _encryptBytes({
    required List<int> bytes,
    required String encryptionKey,
  }) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _deriveSecretKey(
      encryptionKey: encryptionKey,
      salt: salt,
    );
    final secretBox = await _aesGcm.encrypt(
      bytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptedCloudPayload(
      encryptedPayload: base64Encode(secretBox.concatenation()),
      saltBase64: base64Encode(salt),
      nonceBase64: base64Encode(nonce),
    );
  }

  Future<List<int>> _decryptBytes({
    required String encryptedPayload,
    required String saltBase64,
    required String nonceBase64,
    required String encryptionKey,
  }) async {
    final salt = base64Decode(saltBase64);
    final nonce = base64Decode(nonceBase64);
    final secretKey = await _deriveSecretKey(
      encryptionKey: encryptionKey,
      salt: salt,
    );
    final secretBox = SecretBox.fromConcatenation(
      base64Decode(encryptedPayload),
      nonceLength: nonce.length,
      macLength: 16,
      copy: true,
    );
    return _aesGcm.decrypt(secretBox, secretKey: secretKey);
  }

  Future<SecretKey> _deriveSecretKey({
    required String encryptionKey,
    required List<int> salt,
  }) {
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(encryptionKey)),
      nonce: salt,
    );
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }
}
