import '../../domain/models/credential_models.dart';
import '../repositories/credential_repository.dart';
import '../../../../core/services/credential_crypto_service.dart';
import '../../../../core/services/credential_security_service.dart';

class CredentialService {
  CredentialService({
    required CredentialRepository repository,
    required CredentialCryptoService cryptoService,
    required CredentialSecurityService securityService,
  }) : _repository = repository,
       _cryptoService = cryptoService,
       _securityService = securityService;

  final CredentialRepository _repository;
  final CredentialCryptoService _cryptoService;
  final CredentialSecurityService _securityService;

  Stream<List<CredentialRecord>> watchCredentials({String query = ''}) {
    return _repository.watchCredentials(query: query);
  }

  Future<CredentialRecord?> loadCredential(int id) {
    return _repository.loadCredential(id);
  }

  Future<List<CredentialRecord>> loadCredentials({String query = ''}) {
    return _repository.loadCredentials(query: query);
  }

  Future<bool> hasEncryptionKey() {
    return _securityService.hasEncryptionKey();
  }

  Future<void> configureEncryptionKey(String encryptionKey) {
    return _securityService.setEncryptionKey(encryptionKey.trim());
  }

  Future<String?> readStoredEncryptionKey() {
    return _securityService.readEncryptionKey();
  }

  Future<bool> verifyEncryptionKey(String encryptionKey) {
    return _securityService.verifyEncryptionKey(encryptionKey.trim());
  }

  Future<bool> validateEncryptionKeyAgainstStoredCredentials(
    String encryptionKey,
  ) async {
    final trimmedKey = encryptionKey.trim();
    if (trimmedKey.isEmpty) {
      return false;
    }

    final records = await _repository.loadCredentials();
    if (records.isEmpty) {
      return true;
    }

    try {
      await _cryptoService.decryptFields(
        record: records.first,
        encryptionKey: trimmedKey,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricUnlockEnabled() {
    return _securityService.isBiometricUnlockEnabled();
  }

  Future<void> setBiometricUnlockEnabled(bool enabled) {
    return _securityService.setBiometricUnlockEnabled(enabled);
  }

  Future<bool> canUseBiometrics() {
    return _securityService.canUseBiometrics();
  }

  Future<bool> authenticateWithBiometrics({required String reason}) {
    return _securityService.authenticateWithBiometrics(reason: reason);
  }

  Future<void> createCredential(CredentialDraft draft) async {
    final encryptionKey = await _requireStoredEncryptionKey();
    final payload = await _cryptoService.encryptFields(
      fields: draft.fields,
      encryptionKey: encryptionKey,
    );
    await _repository.addCredential(title: draft.title, payload: payload);
  }

  Future<void> updateCredential({
    required int id,
    required CredentialDraft draft,
  }) async {
    final encryptionKey = await _requireStoredEncryptionKey();
    final payload = await _cryptoService.encryptFields(
      fields: draft.fields,
      encryptionKey: encryptionKey,
    );
    await _repository.updateCredential(
      id: id,
      title: draft.title,
      payload: payload,
    );
  }

  Future<DecryptedCredential> decryptCredential({
    required CredentialRecord record,
    required String encryptionKey,
  }) async {
    final fields = await _cryptoService.decryptFields(
      record: record,
      encryptionKey: encryptionKey,
    );
    return DecryptedCredential(
      id: record.id,
      title: record.title,
      fields: fields,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  Future<void> deleteCredential(int id) {
    return _repository.deleteCredential(id);
  }

  Future<void> deleteAllCredentials() {
    return _repository.deleteAllCredentials();
  }

  Future<void> rotateEncryptionKey({
    required String oldEncryptionKey,
    required String newEncryptionKey,
  }) async {
    final records = await _repository.loadCredentials();
    for (final record in records) {
      final decryptedFields = await _cryptoService.decryptFields(
        record: record,
        encryptionKey: oldEncryptionKey,
      );
      final newPayload = await _cryptoService.encryptFields(
        fields: decryptedFields,
        encryptionKey: newEncryptionKey,
      );
      await _repository.updateCredential(
        id: record.id,
        title: record.title,
        payload: newPayload,
      );
    }

    await _securityService.setEncryptionKey(newEncryptionKey);
  }

  Future<String> _requireStoredEncryptionKey() async {
    final encryptionKey = await _securityService.readEncryptionKey();
    if (encryptionKey == null || encryptionKey.isEmpty) {
      throw StateError('Encryption key has not been configured.');
    }
    return encryptionKey;
  }
}
