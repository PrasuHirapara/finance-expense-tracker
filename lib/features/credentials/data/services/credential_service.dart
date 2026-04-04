import '../../domain/models/credential_models.dart';
import '../repositories/credential_repository.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/services/credential_crypto_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/credential_security_service.dart';

class CredentialService {
  CredentialService({
    required CredentialRepository repository,
    required CredentialCryptoService cryptoService,
    required CredentialSecurityService securityService,
    required NotificationService notificationService,
  }) : _repository = repository,
       _cryptoService = cryptoService,
       _securityService = securityService,
       _notificationService = notificationService;

  static const int _expiringSoonThresholdDays = 30;

  final CredentialRepository _repository;
  final CredentialCryptoService _cryptoService;
  final CredentialSecurityService _securityService;
  final NotificationService _notificationService;

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
      fields: _withMetadataFields(draft),
      encryptionKey: encryptionKey,
    );
    await _repository.addCredential(title: draft.title, payload: payload);
    _refreshCredentialExpiryNotifications();
  }

  Future<void> updateCredential({
    required int id,
    required CredentialDraft draft,
  }) async {
    final encryptionKey = await _requireStoredEncryptionKey();
    final payload = await _cryptoService.encryptFields(
      fields: _withMetadataFields(draft),
      encryptionKey: encryptionKey,
    );
    await _repository.updateCredential(
      id: id,
      title: draft.title,
      payload: payload,
    );
    _refreshCredentialExpiryNotifications();
  }

  Future<DecryptedCredential> decryptCredential({
    required CredentialRecord record,
    required String encryptionKey,
  }) async {
    final fields = await _cryptoService.decryptFields(
      record: record,
      encryptionKey: encryptionKey,
    );
    return _mapDecryptedCredential(record: record, fields: fields);
  }

  Future<List<DecryptedCredential>> decryptCredentials({
    required List<CredentialRecord> records,
    required String encryptionKey,
  }) async {
    return Future.wait(
      records.map(
        (record) =>
            decryptCredential(record: record, encryptionKey: encryptionKey),
      ),
    );
  }

  Future<CredentialSecurityReport> buildSecurityReport({
    required String encryptionKey,
    String query = '',
  }) async {
    final records = await _repository.loadCredentials(query: query);
    final credentials = await decryptCredentials(
      records: records,
      encryptionKey: encryptionKey,
    );

    final reusedPasswords = <CredentialPasswordIssue>[];
    final passwordUsage = <String, List<_PasswordUsage>>{};
    final today = DateTime.now().startOfDay;

    for (final credential in credentials) {
      final sensitiveFields = credential.fields
          .where((field) => _isSensitiveField(field.keyLabel))
          .toList(growable: false);

      for (final field in sensitiveFields) {
        final normalizedSecret = field.value.trim();
        if (normalizedSecret.isNotEmpty) {
          passwordUsage.putIfAbsent(normalizedSecret, () => <_PasswordUsage>[]).add(
            _PasswordUsage(
              credentialId: credential.id,
              credentialTitle: credential.title,
              fieldLabel: field.keyLabel,
            ),
          );
        }
      }
    }

    for (final usages in passwordUsage.values) {
      if (usages.length < 2) {
        continue;
      }
      for (final usage in usages) {
        reusedPasswords.add(
          CredentialPasswordIssue(
            credentialId: usage.credentialId,
            credentialTitle: usage.credentialTitle,
            fieldLabel: usage.fieldLabel,
            description: 'This secret appears in multiple credentials.',
          ),
        );
      }
    }

    final expiredItems = <CredentialExpiryReminder>[];
    final expiringSoonItems = <CredentialExpiryReminder>[];
    for (final credential in credentials) {
      final expiryDate = credential.expiryDate;
      if (expiryDate == null) {
        continue;
      }

      final daysRemaining = expiryDate.startOfDay.difference(today).inDays;
      final reminder = CredentialExpiryReminder(
        credentialId: credential.id,
        credentialTitle: credential.title,
        expiryDate: expiryDate,
        daysRemaining: daysRemaining,
      );

      if (daysRemaining < 0) {
        expiredItems.add(reminder);
      } else if (daysRemaining <= _expiringSoonThresholdDays) {
        expiringSoonItems.add(reminder);
      }
    }

    expiredItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    expiringSoonItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return CredentialSecurityReport(
      reusedPasswords: _dedupeIssues(reusedPasswords),
      expiredItems: expiredItems,
      expiringSoonItems: expiringSoonItems,
    );
  }

  Future<void> deleteCredential(int id) async {
    await _repository.deleteCredential(id);
    _refreshCredentialExpiryNotifications();
  }

  Future<void> deleteAllCredentials() async {
    await _repository.deleteAllCredentials();
    _refreshCredentialExpiryNotifications();
  }

  Future<void> rotateEncryptionKey({
    required String oldEncryptionKey,
    required String newEncryptionKey,
  }) async {
    final records = await _repository.loadCredentials();
    for (final record in records) {
      final decrypted = await decryptCredential(
        record: record,
        encryptionKey: oldEncryptionKey,
      );
      final newPayload = await _cryptoService.encryptFields(
        fields: _withMetadataFields(
          CredentialDraft(
            title: decrypted.title,
            fields: decrypted.fields,
            expiryDate: decrypted.expiryDate,
          ),
        ),
        encryptionKey: newEncryptionKey,
      );
      await _repository.updateCredential(
        id: record.id,
        title: record.title,
        payload: newPayload,
      );
    }

    await _securityService.setEncryptionKey(newEncryptionKey);
    _refreshCredentialExpiryNotifications();
  }

  List<CredentialField> _withMetadataFields(CredentialDraft draft) {
    return withCredentialExpiryMetadataFields(
      fields: draft.fields,
      expiryDate: draft.expiryDate,
    );
  }

  DecryptedCredential _mapDecryptedCredential({
    required CredentialRecord record,
    required List<CredentialField> fields,
  }) {
    final expiryDate = extractCredentialExpiryDate(fields);
    final visibleFields = withoutCredentialMetadataFields(fields);

    return DecryptedCredential(
      id: record.id,
      title: record.title,
      fields: visibleFields,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      expiryDate: expiryDate,
    );
  }

  bool _isSensitiveField(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized.contains('password') ||
        normalized.contains('passcode') ||
        normalized == 'pin' ||
        normalized.contains('pin ');
  }

  List<CredentialPasswordIssue> _dedupeIssues(
    List<CredentialPasswordIssue> issues,
  ) {
    final seen = <String>{};
    final result = <CredentialPasswordIssue>[];
    for (final issue in issues) {
      final key = '${issue.credentialId}:${issue.fieldLabel.toLowerCase()}';
      if (seen.add(key)) {
        result.add(issue);
      }
    }
    return result;
  }

  Future<String> _requireStoredEncryptionKey() async {
    final encryptionKey = await _securityService.readEncryptionKey();
    if (encryptionKey == null || encryptionKey.isEmpty) {
      throw StateError('Encryption key has not been configured.');
    }
    return encryptionKey;
  }

  void _refreshCredentialExpiryNotifications() {
    _notificationService.requestCredentialExpiryNotificationSync();
  }
}

class _PasswordUsage {
  const _PasswordUsage({
    required this.credentialId,
    required this.credentialTitle,
    required this.fieldLabel,
  });

  final int credentialId;
  final String credentialTitle;
  final String fieldLabel;
}
