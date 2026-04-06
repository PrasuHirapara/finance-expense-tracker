import 'dart:io';

import '../models/app_preferences.dart';
import '../models/cloud_sync_models.dart';
import 'app_preferences_effects_service.dart';
import 'app_settings_repository.dart';
import 'cancellable_task.dart';
import 'cloud_sync_payload_service.dart';
import 'cloud_sync_security_service.dart';
import 'credential_security_service.dart';
import 'firebase_cloud_sync_auth_service.dart';
import 'firestore_cloud_sync_store_service.dart';

class CloudSyncService {
  CloudSyncService({
    required AppSettingsRepository appSettingsRepository,
    required FirebaseCloudSyncAuthService authService,
    required FirestoreCloudSyncStoreService remoteStoreService,
    required CloudSyncPayloadService payloadService,
    required CloudSyncSecurityService cloudSyncSecurityService,
    required CredentialSecurityService credentialSecurityService,
    required AppPreferencesEffectsService appPreferencesEffectsService,
  }) : _appSettingsRepository = appSettingsRepository,
       _authService = authService,
       _remoteStoreService = remoteStoreService,
       _payloadService = payloadService,
       _cloudSyncSecurityService = cloudSyncSecurityService,
       _credentialSecurityService = credentialSecurityService,
       _appPreferencesEffectsService = appPreferencesEffectsService;

  final AppSettingsRepository _appSettingsRepository;
  final FirebaseCloudSyncAuthService _authService;
  final FirestoreCloudSyncStoreService _remoteStoreService;
  final CloudSyncPayloadService _payloadService;
  final CloudSyncSecurityService _cloudSyncSecurityService;
  final CredentialSecurityService _credentialSecurityService;
  final AppPreferencesEffectsService _appPreferencesEffectsService;

  Future<void> setCloudSyncEnabled(bool enabled) async {
    final settings = await _appSettingsRepository.getSettings();
    final nextCloudSync = settings.cloudSync.copyWith(enabled: enabled);
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);
    await _appPreferencesEffectsService.apply(
      settings.copyWith(cloudSync: nextCloudSync),
    );
  }

  Future<void> setCredentialSyncEnabled(bool enabled) async {
    final settings = await _appSettingsRepository.getSettings();
    final current = settings.cloudSync;
    if (current.syncCredentials == enabled) {
      return;
    }

    if (!enabled && current.enabled) {
      await deleteCloudData('Credential');
    }

    await _appSettingsRepository.updateCloudSyncPreferences(
      current.copyWith(syncCredentials: enabled),
    );
  }

  Future<void> uploadDataToCloud({
    bool interactive = true,
    String? credentialEncryptionKey,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final settings = await _appSettingsRepository.getSettings();
    _ensureEnabled(settings);

    cancellationToken?.throwIfCancelled();
    final account = await _authService.requireUser(interactive: interactive);
    final nonCredentialEncryptionKey = _cloudSyncSecurityService
        .buildCloudPayloadEncryptionKey(userId: account.uid);
    final bundle = await _payloadService.buildBackupBundle(
      accountEmail: account.email,
      credentialEncryptionKey:
          credentialEncryptionKey ??
          await _credentialSecurityService.readEncryptionKey(),
      nonCredentialEncryptionKey: nonCredentialEncryptionKey,
      includeCredentialsInBundle: settings.cloudSync.syncCredentials,
      cancellationToken: cancellationToken,
    );
    cancellationToken?.throwIfCancelled();
    final uploadResult = await _remoteStoreService.uploadBundle(
      userId: account.uid,
      bundle: bundle,
      cancellationToken: cancellationToken,
    );
    final syncCompletedAt = DateTime.now();

    final nextCloudSync = settings.cloudSync.copyWith(
      lastSuccessfulSyncAt: syncCompletedAt,
      lastKnownCloudBackupAt: uploadResult.manifest.exportedAt,
      lastSyncedAccountEmail: account.email,
    );
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);
  }

  Future<CloudRestoreCheck> inspectRestoreState({
    bool interactive = true,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final manifest = await _downloadManifest(
      interactive: interactive,
      cancellationToken: cancellationToken,
    );
    final localLatestAt = await _payloadService
        .computeLocalLatestChangeAtWithCancellation(
          cancellationToken: cancellationToken,
        );
    return CloudRestoreCheck(
      localLatestAt: localLatestAt,
      remoteLatestAt: manifest.localLatestAt,
      remoteManifest: manifest,
    );
  }

  Future<void> downloadDataFromCloud({
    bool interactive = true,
    bool forceOverwrite = false,
    String? credentialEncryptionKey,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final settings = await _appSettingsRepository.getSettings();
    _ensureEnabled(settings);

    cancellationToken?.throwIfCancelled();
    final account = await _authService.requireUser(interactive: interactive);
    final bundle = await _remoteStoreService.getBundle(
      account.uid,
      cancellationToken: cancellationToken,
    );
    if (bundle == null) {
      throw const FileSystemException(
        'No cloud backup was found for this account.',
      );
    }

    cancellationToken?.throwIfCancelled();
    final nonCredentialEncryptionKey = _cloudSyncSecurityService
        .buildCloudPayloadEncryptionKey(userId: account.uid);
    final localLatestAt = await _payloadService
        .computeLocalLatestChangeAtWithCancellation(
          cancellationToken: cancellationToken,
        );
    if (!forceOverwrite &&
        localLatestAt.isAfter(bundle.manifest.localLatestAt)) {
      throw CloudSyncConflictException(
        'Your local data is newer. Sync first to avoid losing changes.',
      );
    }

    cancellationToken?.throwIfCancelled();
    final localRollback = await _payloadService.buildBackupBundle(
      encryptCredentialTitlesForCloud: false,
      encryptNonCredentialPayloadsForCloud: false,
      cancellationToken: cancellationToken,
    );
    try {
      cancellationToken?.throwIfCancelled();
      await _payloadService.restoreBundle(
        credentialPayload: bundle.credentialPayload,
        expensePayload: bundle.expensePayload,
        taskPayload: bundle.taskPayload,
        settingsPayload: bundle.settingsPayload,
        credentialEncryptionKey:
            credentialEncryptionKey ??
            await _credentialSecurityService.readEncryptionKey(),
        nonCredentialEncryptionKey: nonCredentialEncryptionKey,
        restoreCredentials: bundle.containsCredentialPayload,
        restoreSettings: bundle.containsSettingsPayload,
        cancellationToken: cancellationToken,
      );
    } catch (error) {
      await _payloadService.restoreBundle(
        credentialPayload: localRollback.credentialPayload,
        expensePayload: localRollback.expensePayload,
        taskPayload: localRollback.taskPayload,
        settingsPayload: localRollback.settingsPayload,
        restoreCredentials: true,
        restoreSettings: true,
      );
      rethrow;
    }

    final restoredSettings = await _appSettingsRepository.getSettings();
    await _appSettingsRepository.updateCloudSyncPreferences(
      restoredSettings.cloudSync.copyWith(
        lastRestoreAt: DateTime.now(),
        lastKnownCloudBackupAt: bundle.manifest.exportedAt,
        lastSyncedAccountEmail: account.email,
      ),
    );
    final refreshedSettings = await _appSettingsRepository.getSettings();
    await _appPreferencesEffectsService.apply(refreshedSettings);
  }

  Future<void> deleteCloudData(String folderName) async {
    final settings = await _appSettingsRepository.getSettings();
    if (!settings.cloudSync.enabled) {
      return;
    }

    final account = await _authService.requireUser(interactive: false);
    await _remoteStoreService.deleteCloudData(
      userId: account.uid,
      folderName: folderName,
    );
  }
  void _ensureEnabled(AppPreferences settings) {
    if (!settings.cloudSync.enabled) {
      throw const CloudSyncDisabledException(
        'Cloud Sync is disabled in Settings.',
      );
    }
  }

  Future<CloudSyncManifest> _downloadManifest({
    required bool interactive,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final account = await _authService.requireUser(interactive: interactive);
    cancellationToken?.throwIfCancelled();
    final manifest = await _remoteStoreService.getManifest(
      account.uid,
      cancellationToken: cancellationToken,
    );
    if (manifest == null) {
      throw const FileSystemException('No cloud backup manifest was found.');
    }
    return manifest;
  }
}

class CloudSyncDisabledException implements Exception {
  const CloudSyncDisabledException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudSyncConflictException implements Exception {
  const CloudSyncConflictException(this.message);

  final String message;

  @override
  String toString() => message;
}
