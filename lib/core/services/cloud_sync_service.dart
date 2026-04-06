import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../models/cloud_sync_models.dart';
import 'app_settings_repository.dart';
import 'cancellable_task.dart';
import 'cloud_sync_payload_service.dart';
import 'cloud_sync_scheduler.dart';
import 'cloud_sync_security_service.dart';
import 'credential_security_service.dart';
import 'firebase_cloud_sync_auth_service.dart';
import 'firestore_cloud_sync_store_service.dart';
import 'notification_service.dart';

class CloudSyncService {
  CloudSyncService({
    required AppSettingsRepository appSettingsRepository,
    required FirebaseCloudSyncAuthService authService,
    required FirestoreCloudSyncStoreService remoteStoreService,
    required CloudSyncPayloadService payloadService,
    required CloudSyncSecurityService cloudSyncSecurityService,
    required CredentialSecurityService credentialSecurityService,
    required CloudSyncScheduler scheduler,
    required NotificationService notificationService,
  }) : _appSettingsRepository = appSettingsRepository,
       _authService = authService,
       _remoteStoreService = remoteStoreService,
       _payloadService = payloadService,
       _cloudSyncSecurityService = cloudSyncSecurityService,
       _credentialSecurityService = credentialSecurityService,
       _scheduler = scheduler,
       _notificationService = notificationService;

  final AppSettingsRepository _appSettingsRepository;
  final FirebaseCloudSyncAuthService _authService;
  final FirestoreCloudSyncStoreService _remoteStoreService;
  final CloudSyncPayloadService _payloadService;
  final CloudSyncSecurityService _cloudSyncSecurityService;
  final CredentialSecurityService _credentialSecurityService;
  final CloudSyncScheduler _scheduler;
  final NotificationService _notificationService;

  Future<void> setCloudSyncEnabled(bool enabled) async {
    final settings = await _appSettingsRepository.getSettings();
    final nextCloudSync = settings.cloudSync.copyWith(
      enabled: enabled,
      autoBackupEnabled: enabled ? settings.cloudSync.autoBackupEnabled : false,
    );
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);

    if (!enabled) {
      await _scheduler.cancel();
      return;
    }

    if (nextCloudSync.autoBackupEnabled) {
      await scheduleAutoBackup(
        TimeOfDay(
          hour: nextCloudSync.autoBackupHour,
          minute: nextCloudSync.autoBackupMinute,
        ),
      );
    }
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

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final settings = await _appSettingsRepository.getSettings();
    final nextCloudSync = settings.cloudSync.copyWith(
      autoBackupEnabled: enabled && settings.cloudSync.enabled,
    );
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);
    if (!settings.cloudSync.enabled || !enabled) {
      await _scheduler.cancel();
      return;
    }

    await scheduleAutoBackup(
      TimeOfDay(
        hour: nextCloudSync.autoBackupHour,
        minute: nextCloudSync.autoBackupMinute,
      ),
    );
  }

  Future<void> scheduleAutoBackup(TimeOfDay time) async {
    final settings = await _appSettingsRepository.getSettings();
    final nextCloudSync = settings.cloudSync.copyWith(
      enabled: settings.cloudSync.enabled,
      autoBackupEnabled: settings.cloudSync.enabled,
      autoBackupHour: time.hour,
      autoBackupMinute: time.minute,
    );
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);
    if (!nextCloudSync.enabled || !nextCloudSync.autoBackupEnabled) {
      await _scheduler.cancel();
      return;
    }
    await _scheduler.schedule(time);
  }

  Future<void> uploadDataToCloud({
    bool interactive = true,
    bool triggeredByScheduler = false,
    String? credentialEncryptionKey,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final settings = await _appSettingsRepository.getSettings();
    _ensureEnabled(settings);
    if (!await _hasInternetConnection()) {
      throw const SocketException('No internet connection available.');
    }

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
      lastAutoBackupAt: triggeredByScheduler
          ? syncCompletedAt
          : settings.cloudSync.lastAutoBackupAt,
      lastBackgroundSyncAttemptAt: triggeredByScheduler
          ? syncCompletedAt
          : settings.cloudSync.lastBackgroundSyncAttemptAt,
      lastBackgroundSyncError: triggeredByScheduler
          ? null
          : settings.cloudSync.lastBackgroundSyncError,
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
    if (!await _hasInternetConnection()) {
      throw const SocketException('No internet connection available.');
    }

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
    if (refreshedSettings.notificationsEnabled) {
      await _notificationService.scheduleDailyReminders();
    } else {
      await _notificationService.cancelDailyReminders();
    }
    if (refreshedSettings.cloudSync.enabled &&
        refreshedSettings.cloudSync.autoBackupEnabled) {
      await _scheduler.schedule(
        TimeOfDay(
          hour: refreshedSettings.cloudSync.autoBackupHour,
          minute: refreshedSettings.cloudSync.autoBackupMinute,
        ),
      );
    } else {
      await _scheduler.cancel();
    }
    _notificationService.requestCredentialExpiryNotificationSync();
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

  Future<bool> runAutomaticBackupIfDue() async {
    final settings = await _appSettingsRepository.getSettings();
    if (!settings.cloudSync.enabled || !settings.cloudSync.autoBackupEnabled) {
      return false;
    }

    final now = DateTime.now();
    if (!_isBackupDue(settings.cloudSync, now)) {
      return false;
    }

    await uploadDataToCloud(interactive: false, triggeredByScheduler: true);
    return true;
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

  bool _isBackupDue(CloudSyncPreferences settings, DateTime now) {
    final scheduledToday = DateTime(
      now.year,
      now.month,
      now.day,
      settings.autoBackupHour,
      settings.autoBackupMinute,
    );
    if (now.isBefore(scheduledToday)) {
      return false;
    }

    final lastAuto = settings.lastAutoBackupAt;
    if (lastAuto == null) {
      return true;
    }

    return lastAuto.year != now.year ||
        lastAuto.month != now.month ||
        lastAuto.day != now.day;
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
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
