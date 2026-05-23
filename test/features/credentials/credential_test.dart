// ignore_for_file: file_names

import 'package:finance_analytics_app/data/database/app_database.dart';
import 'package:finance_analytics_app/core/services/credential_crypto_service.dart';
import 'package:finance_analytics_app/features/credentials/data/repositories/credential_repository.dart';
import 'package:finance_analytics_app/features/credentials/domain/models/credential_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/testHelpers.dart';

void main() {
  initializeProductionTestEnvironment();

  group('Credential production scenarios', () {
    late AppDatabase database;

    setUp(() {
      database = createTestDatabase();
    });

    tearDown(() => database.close());

    test('stores encrypted credentials and rejects the wrong key', () async {
      final cryptoService = CredentialCryptoService();
      final repository = CredentialRepository(database);
      final payload = await cryptoService.encryptFields(
        fields: const <CredentialField>[
          CredentialField(keyLabel: 'Username', value: 'daily-user'),
          CredentialField(keyLabel: 'Password', value: 'S3cure-pass'),
        ],
        encryptionKey: testCredentialKey,
      );

      final id = await repository.addCredential(
        title: '  GitHub  ',
        payload: payload,
      );

      final record = await repository.loadCredential(id);
      expect(record, isNotNull);
      expect(record!.title, 'GitHub');
      expect(record.encryptedPayload, isNot(contains('S3cure-pass')));

      final decryptedFields = await cryptoService.decryptFields(
        record: record,
        encryptionKey: testCredentialKey,
      );
      expect(
        decryptedFields,
        contains(
          const CredentialField(keyLabel: 'Password', value: 'S3cure-pass'),
        ),
      );

      await expectLater(
        cryptoService.decryptFields(record: record, encryptionKey: 'wrong-key'),
        throwsA(anything),
      );
    });

    test(
      'updates, searches, and deletes credentials by production rules',
      () async {
        final cryptoService = CredentialCryptoService();
        final repository = CredentialRepository(database);
        final githubPayload = await cryptoService.encryptFields(
          fields: const <CredentialField>[
            CredentialField(keyLabel: 'Username', value: 'old-user'),
          ],
          encryptionKey: testCredentialKey,
        );
        final bankPayload = await cryptoService.encryptFields(
          fields: const <CredentialField>[
            CredentialField(keyLabel: 'Pin', value: '4321'),
          ],
          encryptionKey: testCredentialKey,
        );

        final githubId = await repository.addCredential(
          title: 'GitHub',
          payload: githubPayload,
        );
        await repository.addCredential(
          title: 'Bank Login',
          payload: bankPayload,
        );

        final updatedPayload = await cryptoService.encryptFields(
          fields: const <CredentialField>[
            CredentialField(keyLabel: 'Username', value: 'new-user'),
            CredentialField(keyLabel: 'Token', value: 'rotated-token'),
          ],
          encryptionKey: testCredentialKey,
        );
        await repository.updateCredential(
          id: githubId,
          title: '  GitHub Main  ',
          payload: updatedPayload,
        );

        final searched = await repository.loadCredentials(query: 'github');
        expect(searched, hasLength(1));
        expect(searched.single.title, 'GitHub Main');
        final decryptedFields = await cryptoService.decryptFields(
          record: searched.single,
          encryptionKey: testCredentialKey,
        );
        expect(
          decryptedFields,
          contains(
            const CredentialField(keyLabel: 'Token', value: 'rotated-token'),
          ),
        );

        await repository.deleteCredential(githubId);
        expect(await repository.loadCredential(githubId), isNull);
        expect(await repository.loadCredentials(), hasLength(1));
      },
    );

    test(
      'treats missing credential updates and deletes as safe no-ops',
      () async {
        final cryptoService = CredentialCryptoService();
        final repository = CredentialRepository(database);
        final payload = await cryptoService.encryptFields(
          fields: const <CredentialField>[
            CredentialField(keyLabel: 'Email', value: 'user@example.com'),
          ],
          encryptionKey: testCredentialKey,
        );

        final id = await repository.addCredential(
          title: 'Email',
          payload: payload,
        );

        await repository.updateCredential(
          id: 9999,
          title: 'Missing',
          payload: payload,
        );
        await repository.deleteCredential(9999);

        final records = await repository.loadCredentials();
        expect(records, hasLength(1));
        expect(records.single.id, id);
        expect(records.single.title, 'Email');
        expect(await repository.loadCredential(9999), isNull);
      },
    );
  });
}
