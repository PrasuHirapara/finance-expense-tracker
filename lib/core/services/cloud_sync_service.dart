import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../models/cloud_sync_models.dart';
import 'app_settings_repository.dart';
import 'cloud_sync_payload_service.dart';
import 'cloud_sync_scheduler.dart';
import 'credential_security_service.dart';
import 'firebase_cloud_sync_auth_service.dart';
import 'firestore_cloud_sync_store_service.dart';

class CloudSyncService {
  CloudSyncService({
    required AppSettingsRepository appSettingsRepository,
    required FirebaseCloudSyncAuthService authService,
    required FirestoreCloudSyncStoreService remoteStoreService,
    required CloudSyncPayloadService payloadService,
    required CredentialSecurityService credentialSecurityService,
    required CloudSyncScheduler scheduler,
  }) : _appSettingsRepository = appSettingsRepository,
       _authService = authService,
       _remoteStoreService = remoteStoreService,
       _payloadService = payloadService,
       _credentialSecurityService = credentialSecurityService,
       _scheduler = scheduler;

  final AppSettingsRepository _appSettingsRepository;
  final FirebaseCloudSyncAuthService _authService;
  final FirestoreCloudSyncStoreService _remoteStoreService;
  final CloudSyncPayloadService _payloadService;
  final CredentialSecurityService _credentialSecurityService;
  final CloudSyncScheduler _scheduler;

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
  }) async {
    final settings = await _appSettingsRepository.getSettings();
    _ensureEnabled(settings);
    if (!await _hasInternetConnection()) {
      throw const SocketException('No internet connection available.');
    }

    final account = await _authService.requireUser(interactive: interactive);
    final bundle = await _payloadService.buildBackupBundle(
      accountEmail: account.email,
      credentialEncryptionKey:
          credentialEncryptionKey ??
          await _credentialSecurityService.readEncryptionKey(),
    );
    await _remoteStoreService.uploadBundle(userId: account.uid, bundle: bundle);

    final nextCloudSync = settings.cloudSync.copyWith(
      lastSuccessfulSyncAt: bundle.manifest.exportedAt,
      lastKnownCloudBackupAt: bundle.manifest.exportedAt,
      lastSyncedAccountEmail: account.email,
      lastAutoBackupAt: triggeredByScheduler
          ? bundle.manifest.exportedAt
          : settings.cloudSync.lastAutoBackupAt,
    );
    await _appSettingsRepository.updateCloudSyncPreferences(nextCloudSync);
  }

  Future<CloudRestoreCheck> inspectRestoreState({
    bool interactive = true,
  }) async {
    final manifest = await _downloadManifest(interactive: interactive);
    final localLatestAt = await _payloadService.computeLocalLatestChangeAt();
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
  }) async {
    final settings = await _appSettingsRepository.getSettings();
    _ensureEnabled(settings);
    if (!await _hasInternetConnection()) {
      throw const SocketException('No internet connection available.');
    }

    final account = await _authService.requireUser(interactive: interactive);
    final bundle = await _remoteStoreService.getBundle(account.uid);
    if (bundle == null) {
      throw const FileSystemException(
        'No cloud backup was found for this account.',
      );
    }

    final localLatestAt = await _payloadService.computeLocalLatestChangeAt();
    if (!forceOverwrite &&
        localLatestAt.isAfter(bundle.manifest.localLatestAt)) {
      throw CloudSyncConflictException(
        'Your local data is newer. Sync first to avoid losing changes.',
      );
    }

    final localRollback = await _payloadService.buildBackupBundle(
      encryptCredentialTitlesForCloud: false,
    );
    try {
      await _payloadService.restoreBundle(
        credentialPayload: bundle.credentialPayload,
        expensePayload: bundle.expensePayload,
        taskPayload: bundle.taskPayload,
        credentialEncryptionKey:
            credentialEncryptionKey ??
            await _credentialSecurityService.readEncryptionKey(),
      );
    } catch (error) {
      await _payloadService.restoreBundle(
        credentialPayload: localRollback.credentialPayload,
        expensePayload: localRollback.expensePayload,
        taskPayload: localRollback.taskPayload,
      );
      rethrow;
    }

    await _appSettingsRepository.updateCloudSyncPreferences(
      settings.cloudSync.copyWith(
        lastRestoreAt: DateTime.now(),
        lastKnownCloudBackupAt: bundle.manifest.exportedAt,
      ),
    );
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

  Future<void> runAutomaticBackupIfDue() async {
    final settings = await _appSettingsRepository.getSettings();
    if (!settings.cloudSync.enabled || !settings.cloudSync.autoBackupEnabled) {
      return;
    }

    final now = DateTime.now();
    if (!_isBackupDue(settings.cloudSync, now)) {
      return;
    }

    await uploadDataToCloud(interactive: false, triggeredByScheduler: true);
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
  }) async {
    final account = await _authService.requireUser(interactive: interactive);
    final manifest = await _remoteStoreService.getManifest(account.uid);
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
