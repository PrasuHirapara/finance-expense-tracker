import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../models/cloud_sync_models.dart';
import 'app_settings_repository.dart';
import 'cloud_sync_payload_service.dart';
import 'cloud_sync_scheduler.dart';
import 'google_drive_api_service.dart';
import 'google_drive_auth_service.dart';

class CloudSyncService {
  CloudSyncService({
    required AppSettingsRepository appSettingsRepository,
    required GoogleDriveAuthService authService,
    required GoogleDriveApiService driveApiService,
    required CloudSyncPayloadService payloadService,
    required CloudSyncScheduler scheduler,
  }) : _appSettingsRepository = appSettingsRepository,
       _authService = authService,
       _driveApiService = driveApiService,
       _payloadService = payloadService,
       _scheduler = scheduler;

  final AppSettingsRepository _appSettingsRepository;
  final GoogleDriveAuthService _authService;
  final GoogleDriveApiService _driveApiService;
  final CloudSyncPayloadService _payloadService;
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

  Future<void> uploadDataToDrive({
    bool interactive = true,
    bool triggeredByScheduler = false,
  }) async {
    final settings = await _appSettingsRepository.getSettings();
    _ensureEnabled(settings);
    if (!await _hasInternetConnection()) {
      throw const SocketException('No internet connection available.');
    }

    final headers = await _authService.authorizationHeaders(
      interactive: interactive,
    );
    final email = await _authService.currentUserEmail(interactive: interactive);
    final folders = await _driveApiService.ensureFolderHierarchy(headers);
    final bundle = await _payloadService.buildBackupBundle(accountEmail: email);

    await Future.wait<void>(<Future<void>>[
      _driveApiService.uploadTextFile(
        authorizationHeaders: headers,
        parentId: folders[GoogleDriveApiService.appFolderName]!,
        fileName: 'manifest.json',
        content: bundle.manifest.encode(),
      ),
      _driveApiService.uploadTextFile(
        authorizationHeaders: headers,
        parentId: folders[CloudSyncDomain.credential.folderName]!,
        fileName: CloudSyncDomain.credential.fileName,
        content: bundle.credentialPayload,
      ),
      _driveApiService.uploadTextFile(
        authorizationHeaders: headers,
        parentId: folders[CloudSyncDomain.expense.folderName]!,
        fileName: CloudSyncDomain.expense.fileName,
        content: bundle.expensePayload,
      ),
      _driveApiService.uploadTextFile(
        authorizationHeaders: headers,
        parentId: folders[CloudSyncDomain.task.folderName]!,
        fileName: CloudSyncDomain.task.fileName,
        content: bundle.taskPayload,
      ),
    ]);

    final nextCloudSync = settings.cloudSync.copyWith(
      lastSuccessfulSyncAt: bundle.manifest.exportedAt,
      lastKnownCloudBackupAt: bundle.manifest.exportedAt,
      lastSyncedAccountEmail: email,
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

  Future<void> downloadDataFromDrive({
    bool interactive = true,
    bool forceOverwrite = false,
  }) async {
    final settings = await _appSettingsRepository.getSettings();
    _ensureEnabled(settings);
    if (!await _hasInternetConnection()) {
      throw const SocketException('No internet connection available.');
    }

    final headers = await _authService.authorizationHeaders(
      interactive: interactive,
    );
    final rootFolder = await _driveApiService.findChildByName(
      authorizationHeaders: headers,
      folderName: GoogleDriveApiService.appFolderName,
      mimeType: 'application/vnd.google-apps.folder',
    );
    if (rootFolder == null) {
      throw const FileSystemException(
        'Daily Use folder was not found in Drive.',
      );
    }
    final manifest = await _downloadManifest(
      interactive: interactive,
      authorizationHeaders: headers,
      rootFolderId: rootFolder.id,
    );
    final localLatestAt = await _payloadService.computeLocalLatestChangeAt();
    if (!forceOverwrite && localLatestAt.isAfter(manifest.localLatestAt)) {
      throw CloudSyncConflictException(
        'Your local data is newer. Sync first to avoid losing changes.',
      );
    }

    final localRollback = await _payloadService.buildBackupBundle();
    final credentialFolder = await _driveApiService.findChildByName(
      authorizationHeaders: headers,
      folderName: CloudSyncDomain.credential.folderName,
      parentId: rootFolder.id,
      mimeType: 'application/vnd.google-apps.folder',
    );
    final expenseFolder = await _driveApiService.findChildByName(
      authorizationHeaders: headers,
      folderName: CloudSyncDomain.expense.folderName,
      parentId: rootFolder.id,
      mimeType: 'application/vnd.google-apps.folder',
    );
    final taskFolder = await _driveApiService.findChildByName(
      authorizationHeaders: headers,
      folderName: CloudSyncDomain.task.folderName,
      parentId: rootFolder.id,
      mimeType: 'application/vnd.google-apps.folder',
    );
    if (credentialFolder == null ||
        expenseFolder == null ||
        taskFolder == null) {
      throw const FileSystemException(
        'One or more Daily Use backup folders are missing from Drive.',
      );
    }
    final credentialFile = await _findRequiredFile(
      authorizationHeaders: headers,
      parentId: credentialFolder.id,
      fileName: CloudSyncDomain.credential.fileName,
    );
    final expenseFile = await _findRequiredFile(
      authorizationHeaders: headers,
      parentId: expenseFolder.id,
      fileName: CloudSyncDomain.expense.fileName,
    );
    final taskFile = await _findRequiredFile(
      authorizationHeaders: headers,
      parentId: taskFolder.id,
      fileName: CloudSyncDomain.task.fileName,
    );

    final credentialPayload = await _driveApiService.downloadTextFile(
      authorizationHeaders: headers,
      fileId: credentialFile.id,
    );
    final expensePayload = await _driveApiService.downloadTextFile(
      authorizationHeaders: headers,
      fileId: expenseFile.id,
    );
    final taskPayload = await _driveApiService.downloadTextFile(
      authorizationHeaders: headers,
      fileId: taskFile.id,
    );

    try {
      await _payloadService.restoreBundle(
        credentialPayload: credentialPayload,
        expensePayload: expensePayload,
        taskPayload: taskPayload,
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
        lastKnownCloudBackupAt: manifest.exportedAt,
      ),
    );
  }

  Future<void> deleteDriveFolder(String folderName) async {
    final settings = await _appSettingsRepository.getSettings();
    if (!settings.cloudSync.enabled) {
      return;
    }

    final headers = await _authService.authorizationHeaders(interactive: false);
    final root = await _driveApiService.findChildByName(
      authorizationHeaders: headers,
      folderName: GoogleDriveApiService.appFolderName,
      mimeType: 'application/vnd.google-apps.folder',
    );
    if (root == null) {
      return;
    }

    final target = folderName == GoogleDriveApiService.appFolderName
        ? root
        : await _driveApiService.findChildByName(
            authorizationHeaders: headers,
            folderName: folderName,
            parentId: root.id,
            mimeType: 'application/vnd.google-apps.folder',
          );
    if (target == null) {
      return;
    }

    await _driveApiService.deleteFileOrFolder(
      authorizationHeaders: headers,
      fileId: target.id,
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

    await uploadDataToDrive(interactive: false, triggeredByScheduler: true);
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
    Map<String, String>? authorizationHeaders,
    String? rootFolderId,
  }) async {
    final headers =
        authorizationHeaders ??
        await _authService.authorizationHeaders(interactive: interactive);
    final root = rootFolderId == null
        ? await _driveApiService.findChildByName(
            authorizationHeaders: headers,
            folderName: GoogleDriveApiService.appFolderName,
            mimeType: 'application/vnd.google-apps.folder',
          )
        : DriveFileResource(
            id: rootFolderId,
            name: GoogleDriveApiService.appFolderName,
            mimeType: 'application/vnd.google-apps.folder',
          );
    if (root == null) {
      throw const FileSystemException(
        'Daily Use folder was not found in Drive.',
      );
    }

    final manifestFile = await _findRequiredFile(
      authorizationHeaders: headers,
      parentId: root.id,
      fileName: 'manifest.json',
    );
    final manifestContent = await _driveApiService.downloadTextFile(
      authorizationHeaders: headers,
      fileId: manifestFile.id,
    );
    return CloudSyncManifest.fromEncoded(manifestContent);
  }

  Future<DriveFileResource> _findRequiredFile({
    required Map<String, String> authorizationHeaders,
    required String parentId,
    required String fileName,
  }) async {
    final file = await _driveApiService.findChildByName(
      authorizationHeaders: authorizationHeaders,
      folderName: fileName,
      parentId: parentId,
    );
    if (file == null) {
      throw FileSystemException(
        '$fileName is missing from Google Drive backup.',
      );
    }
    return file;
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
