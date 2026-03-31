import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../features/credentials/domain/models/credential_models.dart';

class CredentialCryptoService {
  CredentialCryptoService()
    : _pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 100000,
        bits: 256,
      ),
      _aesGcm = AesGcm.with256bits();

  final Pbkdf2 _pbkdf2;
  final AesGcm _aesGcm;
  final Random _random = Random.secure();

  Future<EncryptedCredentialPayload> encryptFields({
    required List<CredentialField> fields,
    required String encryptionKey,
  }) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _deriveSecretKey(
      encryptionKey: encryptionKey,
      salt: salt,
    );
    final encodedFields = utf8.encode(
      jsonEncode(
        fields.map((field) => field.toJson()).toList(growable: false),
      ),
    );
    final secretBox = await _aesGcm.encrypt(
      encodedFields,
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptedCredentialPayload(
      encryptedPayload: base64Encode(secretBox.concatenation()),
      saltBase64: base64Encode(salt),
      nonceBase64: base64Encode(nonce),
    );
  }

  Future<List<CredentialField>> decryptFields({
    required CredentialRecord record,
    required String encryptionKey,
  }) async {
    final salt = base64Decode(record.saltBase64);
    final nonce = base64Decode(record.nonceBase64);
    final secretKey = await _deriveSecretKey(
      encryptionKey: encryptionKey,
      salt: salt,
    );
    final secretBox = SecretBox.fromConcatenation(
      base64Decode(record.encryptedPayload),
      nonceLength: nonce.length,
      macLength: 16,
      copy: true,
    );
    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    final decoded = jsonDecode(utf8.decode(decryptedBytes));

    if (decoded is! List) {
      return const <CredentialField>[];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => CredentialField.fromJson(
            item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);
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
