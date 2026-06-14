import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../utils/log_console.dart';

import '../models/app_preferences.dart';
import '../models/module_export_models.dart';
import 'app_settings_repository.dart';
import 'firebase_cloud_sync_auth_service.dart';
import 'module_data_export_service.dart';
import 'cancellable_task.dart';
import '../../features/expense/data/repositories/expense_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../../features/credentials/data/services/credential_service.dart';
import '../../features/credentials/domain/models/credential_models.dart';
import '../../features/investment/data/repositories/investment_repository.dart';

class GoogleDriveBackupFile {
  const GoogleDriveBackupFile({
    required this.id,
    required this.name,
    required this.year,
    required this.month,
    required this.backupDate,
    required this.fileSize,
    required this.modules,
    this.monthFolderId,
    this.yearFolderId,
  });

  final String id;
  final String name;
  final String year;
  final String month;
  final DateTime backupDate;
  final String fileSize;
  final String modules;
  final String? monthFolderId;
  final String? yearFolderId;
}

class GoogleDriveBackupService {
  GoogleDriveBackupService({
    required FirebaseCloudSyncAuthService authService,
    required AppSettingsRepository appSettingsRepository,
    required ModuleDataExportService exportService,
    required ExpenseRepository expenseRepository,
    required TaskRepository taskRepository,
    required CredentialService credentialService,
    required InvestmentRepository investmentRepository,
  }) : _authService = authService,
       _appSettingsRepository = appSettingsRepository,
       _exportService = exportService,
       _expenseRepository = expenseRepository,
       _taskRepository = taskRepository,
       _credentialService = credentialService;

  final FirebaseCloudSyncAuthService _authService;
  final AppSettingsRepository _appSettingsRepository;
  final ModuleDataExportService _exportService;
  final ExpenseRepository _expenseRepository;
  final TaskRepository _taskRepository;
  final CredentialService _credentialService;

  GoogleSignInAccount? _cachedGoogleAccount;

  static const List<String> _requiredScopes = [
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

  Future<bool> isEligible() async {
    final account = _authService.currentAccount;
    return account != null && account.providerIds.contains('google.com');
  }

  Future<GoogleSignInAccount> _getGoogleAccount() async {
    LogConsole.log('GoogleDriveBackupService: _getGoogleAccount requested');
    // Ensure the GoogleSignIn instance is initialized with serverClientId
    await _authService.initialize(prepareInteractiveSignIn: true);

    if (_cachedGoogleAccount != null) {
      LogConsole.log(
        'GoogleDriveBackupService: Returning cached GoogleSignInAccount',
      );
      return _cachedGoogleAccount!;
    }
    LogConsole.log(
      'GoogleDriveBackupService: Attempting lightweight authentication...',
    );
    final future = _authService.googleSignIn.attemptLightweightAuthentication();
    final silentAccount = future != null ? await future : null;
    if (silentAccount != null) {
      LogConsole.log(
        'GoogleDriveBackupService: Lightweight authentication succeeded',
      );
      _cachedGoogleAccount = silentAccount;
      return silentAccount;
    }
    LogConsole.log(
      'GoogleDriveBackupService: Lightweight authentication returned null. Prompting user authentication...',
    );
    final interactiveAccount = await _authService.googleSignIn.authenticate();
    LogConsole.log(
      'GoogleDriveBackupService: Interactive authentication complete. Account: ${interactiveAccount.email}',
    );
    _cachedGoogleAccount = interactiveAccount;
    return interactiveAccount;
  }

  Future<bool> hasDriveScope() async {
    if (!await isEligible()) return false;
    try {
      final googleUser = await _getGoogleAccount();
      final auth = await googleUser.authorizationClient.authorizationForScopes(
        _requiredScopes,
      );
      return auth != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestDriveScope() async {
    if (!await isEligible()) return false;
    try {
      final googleUser = await _getGoogleAccount();
      await googleUser.authorizationClient.authorizeScopes(_requiredScopes);
      return true;
    } catch (e) {
      throw StateError('Google Drive authorization failed: $e');
    }
  }

  Future<String> _getAccessToken() async {
    LogConsole.log('GoogleDriveBackupService: _getAccessToken requested');
    final googleUser = await _getGoogleAccount();
    LogConsole.log(
      'GoogleDriveBackupService: Checking existing authorization scopes',
    );
    final auth = await googleUser.authorizationClient.authorizationForScopes(
      _requiredScopes,
    );
    final token = auth?.accessToken;
    if (token == null) {
      LogConsole.log(
        'GoogleDriveBackupService: Existing accessToken is null. Authorizing scopes interactively...',
      );
      final authorized = await googleUser.authorizationClient.authorizeScopes(
        _requiredScopes,
      );
      LogConsole.log(
        'GoogleDriveBackupService: Interactive authorization complete. AccessToken: ${authorized.accessToken.isNotEmpty ? "SUCCESS" : "EMPTY"}',
      );
      return authorized.accessToken;
    }
    LogConsole.log(
      'GoogleDriveBackupService: Returning valid cached AccessToken',
    );
    return token;
  }

  Future<void> runBackup({
    String? credentialEncryptionKey,
    AppCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();

    if (!await isEligible()) {
      throw StateError('Account is not eligible for Google Drive backup.');
    }

    final hasScope = await hasDriveScope();
    if (!hasScope) {
      final granted = await requestDriveScope();
      if (!granted) {
        throw StateError('Google Drive access scope was not granted.');
      }
    }

    cancellationToken?.throwIfCancelled();

    final settings = await _appSettingsRepository.getSettings();
    final cloudSync = settings.cloudSync;

    final modules = <String>[];
    final tempFiles = <File>[];

    final tempDir = await getTemporaryDirectory();
    final backupTempFolder = Directory(
      path.join(tempDir.path, 'gdrive_backup_temp'),
    );
    if (await backupTempFolder.exists()) {
      await backupTempFolder.delete(recursive: true);
    }
    await backupTempFolder.create(recursive: true);

    try {
      // 1. Export Expenses
      if (cloudSync.syncExpense) {
        cancellationToken?.throwIfCancelled();
        final entries = await _expenseRepository.loadEntries(filter: null);
        if (entries.isNotEmpty) {
          final filePath = await _exportService.exportExpenseData(
            range: null,
            format: ModuleExportFormat.excel,
            entries: entries,
          );
          final destFile = File(
            path.join(backupTempFolder.path, 'expenses.xlsx'),
          );
          await File(filePath).copy(destFile.path);
          tempFiles.add(destFile);
          modules.add('Expenses');
        }
      }

      // 2. Export Tasks
      if (cloudSync.syncTasks) {
        cancellationToken?.throwIfCancelled();
        final tasks = await _taskRepository.loadAllTasks();
        if (tasks.isNotEmpty) {
          final filePath = await _exportService.exportTaskData(
            range: null,
            format: ModuleExportFormat.excel,
            tasks: tasks,
          );
          final destFile = File(path.join(backupTempFolder.path, 'tasks.xlsx'));
          await File(filePath).copy(destFile.path);
          tempFiles.add(destFile);
          modules.add('Tasks');
        }
      }

      // 3. Export Credentials
      if (cloudSync.syncCredentials) {
        cancellationToken?.throwIfCancelled();
        final records = await _credentialService.loadCredentials();
        if (records.isNotEmpty) {
          String? key = credentialEncryptionKey;
          if (key == null || key.isEmpty) {
            key = await _credentialService.readStoredEncryptionKey();
          }

          if (key == null || key.isEmpty) {
            throw StateError(
              'Credential master key is required to back up credentials.',
            );
          }

          final decrypted = <DecryptedCredential>[];
          for (final record in records) {
            decrypted.add(
              await _credentialService.decryptCredential(
                record: record,
                encryptionKey: key,
                cancellationToken: cancellationToken,
              ),
            );
          }

          final filePath = await _exportService.exportCredentialData(
            format: ModuleExportFormat.excel,
            credentials: decrypted,
          );
          final destFile = File(
            path.join(backupTempFolder.path, 'credentials.xlsx'),
          );
          await File(filePath).copy(destFile.path);
          tempFiles.add(destFile);
          modules.add('Credentials');
        }
      }

      // 4. Export Investments
      if (cloudSync.syncInvestment) {
        cancellationToken?.throwIfCancelled();
        final filePath = await _exportService.exportInvestmentData(
          range: null,
          format: ModuleExportFormat.excel,
        );
        final destFile = File(
          path.join(backupTempFolder.path, 'investments.xlsx'),
        );
        await File(filePath).copy(destFile.path);
        tempFiles.add(destFile);
        modules.add('Investments');
      }

      // 5. Export Settings
      if (cloudSync.syncDefaults) {
        cancellationToken?.throwIfCancelled();
        final settingsMap = await _appSettingsRepository.exportForCloud();
        final settingsFile = File(
          path.join(backupTempFolder.path, 'settings.json'),
        );
        await settingsFile.writeAsString(jsonEncode(settingsMap));
        tempFiles.add(settingsFile);
        modules.add('Settings');
      }

      if (tempFiles.isEmpty) {
        throw StateError(
          'No data available to backup for the selected modules.',
        );
      }

      cancellationToken?.throwIfCancelled();

      // Compress into one ZIP
      final archive = Archive();
      for (final file in tempFiles) {
        final bytes = await file.readAsBytes();
        archive.addFile(
          ArchiveFile(path.basename(file.path), bytes.length, bytes),
        );
      }

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        throw StateError('Failed to generate ZIP archive.');
      }

      final zipFile = File(path.join(backupTempFolder.path, 'backup.zip'));
      await zipFile.writeAsBytes(zipBytes);

      cancellationToken?.throwIfCancelled();

      // Upload to Google Drive
      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Retrieving access token',
      );
      final token = await _getAccessToken();
      final now = DateTime.now();
      final yearLabel = now.year.toString();
      final monthLabel = now.month.toString().padLeft(
        2,
        '0',
      ); // Numerical zero-padded Month name e.g. "06"
      final sizeString = _formatBytes(zipBytes.length);
      final modulesString = modules.join(', ');

      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Finding or creating folder "Daily Use Backup"',
      );
      final rootFolderId = await _findOrCreateFolder(
        token,
        'Daily Use Backup',
        null,
      );
      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Root folder ID: $rootFolderId',
      );

      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Finding or creating year folder "$yearLabel"',
      );
      final yearFolderId = await _findOrCreateFolder(
        token,
        yearLabel,
        rootFolderId,
      );
      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Year folder ID: $yearFolderId',
      );

      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Finding or creating month folder "$monthLabel"',
      );
      final monthFolderId = await _findOrCreateFolder(
        token,
        monthLabel,
        yearFolderId,
      );
      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Month folder ID: $monthFolderId',
      );

      // Check if backup.zip already exists
      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Checking if existing backup.zip exists in month folder',
      );
      final existingFileId = await _findFile(
        token,
        'backup.zip',
        monthFolderId,
      );
      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Existing backup.zip ID: $existingFileId',
      );

      final appProperties = {
        'backupDate': now.toUtc().toIso8601String(),
        'fileSize': sizeString,
        'modules': modulesString,
      };

      if (existingFileId != null) {
        LogConsole.log(
          'GoogleDriveBackupService: runBackup - Replacing current month\'s backup file (updating metadata & content)',
        );
        await _updateFileMetadata(token, existingFileId, appProperties);
        await _uploadFileContent(token, existingFileId, zipBytes);
      } else {
        LogConsole.log(
          'GoogleDriveBackupService: runBackup - Creating new backup.zip (creating metadata & content)',
        );
        final newFileId = await _createFileMetadata(
          token,
          'backup.zip',
          monthFolderId,
          appProperties,
        );
        LogConsole.log(
          'GoogleDriveBackupService: runBackup - New backup file ID created: $newFileId. Uploading content...',
        );
        await _uploadFileContent(token, newFileId, zipBytes);
      }
      LogConsole.log(
        'GoogleDriveBackupService: runBackup - Backup completed successfully!',
      );

      // Update Backup Details after success
      final backupPref = GoogleDriveBackupPreferences(
        lastBackupAt: now,
        backupStatus: 'Success',
        lastUploadedFileName: 'backup.zip',
        backupGoogleAccount: _authService.currentAccount?.email ?? 'Connected',
        backupIncludedModules: modulesString,
        backupTotalSize: sizeString,
      );

      await _appSettingsRepository.updateGoogleDriveBackupPreferences(
        backupPref,
      );
    } catch (e, st) {
      LogConsole.log(
        'GoogleDriveBackupService: runBackup failed with error: $e\n$st',
      );
      // Update Backup Details on failure
      final currentPref = settings.googleDriveBackup;
      final backupPref = currentPref.copyWith(
        backupStatus: 'Failed to take backup',
      );
      await _appSettingsRepository.updateGoogleDriveBackupPreferences(
        backupPref,
      );
      rethrow;
    } finally {
      // Clean up temporary files
      try {
        if (await backupTempFolder.exists()) {
          await backupTempFolder.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  Future<List<GoogleDriveBackupFile>> listBackups() async {
    if (!await isEligible()) return [];
    if (!await hasDriveScope()) return [];

    final token = await _getAccessToken();
    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?q=trashed=false%20and%20(name=\'backup.zip\'%20or%20mimeType=\'application/vnd.google-apps.folder\')&fields=files(id,name,mimeType,parents,size,createdTime,appProperties)&pageSize=1000',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to list backups from Google Drive: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final filesList = data['files'] as List<dynamic>? ?? [];

    final folders = <String, String>{}; // id -> name
    final parents = <String, String>{}; // childId -> parentId
    final zipFiles = <Map<String, dynamic>>[];

    for (final item in filesList) {
      final id = item['id'] as String?;
      final name = item['name'] as String?;
      final mimeType = item['mimeType'] as String?;
      final itemParents = item['parents'] as List<dynamic>? ?? [];

      if (id == null || name == null) continue;

      if (mimeType == 'application/vnd.google-apps.folder') {
        folders[id] = name;
        if (itemParents.isNotEmpty) {
          parents[id] = itemParents.first.toString();
        }
      } else if (name == 'backup.zip') {
        zipFiles.add(item as Map<String, dynamic>);
      }
    }

    final backups = <GoogleDriveBackupFile>[];

    for (final file in zipFiles) {
      final id = file['id'] as String;
      final itemParents = file['parents'] as List<dynamic>? ?? [];
      if (itemParents.isEmpty) continue;

      final monthId = itemParents.first.toString();
      final monthName = folders[monthId] ?? 'Unknown';
      final yearId = parents[monthId] ?? '';
      final yearName = folders[yearId] ?? 'Unknown';

      final appProperties =
          file['appProperties'] as Map<String, dynamic>? ?? {};
      final backupDateStr = appProperties['backupDate'] as String?;
      final backupDate = backupDateStr != null
          ? DateTime.tryParse(backupDateStr)?.toLocal() ?? DateTime.now()
          : DateTime.tryParse(
                  file['createdTime'] as String? ?? '',
                )?.toLocal() ??
                DateTime.now();

      final sizeBytes = int.tryParse(file['size'] as String? ?? '') ?? 0;
      final fileSize =
          appProperties['fileSize'] as String? ?? _formatBytes(sizeBytes);
      final modules = appProperties['modules'] as String? ?? 'All modules';

      backups.add(
        GoogleDriveBackupFile(
          id: id,
          name: 'backup.zip',
          year: yearName,
          month: monthName,
          backupDate: backupDate,
          fileSize: fileSize,
          modules: modules,
          monthFolderId: monthId,
          yearFolderId: yearId,
        ),
      );
    }

    // Sort backups by date descending
    backups.sort((a, b) => b.backupDate.compareTo(a.backupDate));
    return backups;
  }

  Future<String> downloadBackup(
    String fileId,
    String year,
    String month,
  ) async {
    final token = await _getAccessToken();
    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to download backup: ${response.body}');
    }

    final bytes = response.bodyBytes;

    final exportsDir = await _resolveExportDirectory();
    final destFolder = Directory(path.join(exportsDir.path, 'backups'));
    if (!await destFolder.exists()) {
      await destFolder.create(recursive: true);
    }

    final fileName =
        'backup_${year}_${month}_${DateTime.now().millisecondsSinceEpoch}.zip';
    final destFile = File(path.join(destFolder.path, fileName));
    await destFile.writeAsBytes(bytes);

    return destFile.path;
  }

  Future<void> deleteAllCloudBackups() async {
    // DO NOT delete Google Drive files when user deletes account or resets all application data.
    // We only reset the local Backup Details metadata preferences.
    final backupPref = const GoogleDriveBackupPreferences(
      lastBackupAt: null,
      backupStatus: 'No Backups',
      lastUploadedFileName: 'N/A',
      backupGoogleAccount: 'Not connected',
      backupIncludedModules: 'None',
      backupTotalSize: '0 B',
    );
    await _appSettingsRepository.updateGoogleDriveBackupPreferences(backupPref);
  }

  Future<void> deleteFileOrFolder(String id) async {
    final token = await _getAccessToken();
    final url = Uri.parse('https://www.googleapis.com/drive/v3/files/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete file/folder: ${response.body}');
    }
  }

  Future<Directory> _resolveExportDirectory() async {
    final preferences = await _appSettingsRepository.getSettings();
    if (preferences.exportDirectoryPath != null) {
      final dir = Directory(preferences.exportDirectoryPath!);
      if (await dir.exists()) return dir;
    }
    final docDir = await getApplicationDocumentsDirectory();
    final defaultDir = Directory(path.join(docDir.path, 'exports'));
    if (!await defaultDir.exists()) {
      await defaultDir.create(recursive: true);
    }
    return defaultDir;
  }

  Future<String?> _findFile(
    String token,
    String name,
    String? parentId, {
    bool foldersOnly = false,
  }) async {
    final query =
        "name = '$name' and trashed = false"
        "${parentId != null ? " and '$parentId' in parents" : ""}"
        "${foldersOnly ? " and mimeType = 'application/vnd.google-apps.folder'" : ""}";

    LogConsole.log('GoogleDriveBackupService: _findFile query: $query');
    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(query)}&fields=files(id)',
    );
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    LogConsole.log(
      'GoogleDriveBackupService: _findFile response status code: ${response.statusCode}',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final files = data['files'] as List<dynamic>? ?? [];
      if (files.isNotEmpty) {
        final id = files.first['id'] as String?;
        LogConsole.log(
          'GoogleDriveBackupService: _findFile found file "$name" with ID: $id',
        );
        return id;
      }
      LogConsole.log(
        'GoogleDriveBackupService: _findFile - file "$name" not found',
      );
    } else {
      LogConsole.log(
        'GoogleDriveBackupService: _findFile failed: ${response.body}',
      );
    }
    return null;
  }

  Future<String> _findOrCreateFolder(
    String token,
    String name,
    String? parentId,
  ) async {
    LogConsole.log(
      'GoogleDriveBackupService: _findOrCreateFolder checking for folder "$name" under parent: $parentId',
    );
    final existingId = await _findFile(
      token,
      name,
      parentId,
      foldersOnly: true,
    );
    if (existingId != null) {
      LogConsole.log(
        'GoogleDriveBackupService: _findOrCreateFolder folder "$name" already exists: $existingId',
      );
      return existingId;
    }

    LogConsole.log(
      'GoogleDriveBackupService: _findOrCreateFolder folder "$name" does not exist. Creating folder...',
    );
    final url = Uri.parse('https://www.googleapis.com/drive/v3/files');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'mimeType': 'application/vnd.google-apps.folder',
        'parents': parentId != null
            ? [parentId]
            : ['root'], // Explicitly use 'root' parent to place in My Drive
      }),
    );

    LogConsole.log(
      'GoogleDriveBackupService: _findOrCreateFolder post status code: ${response.statusCode}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final newFolderId = data['id'] as String;
      LogConsole.log(
        'GoogleDriveBackupService: _findOrCreateFolder successfully created folder "$name" with ID: $newFolderId',
      );
      return newFolderId;
    } else {
      LogConsole.log(
        'GoogleDriveBackupService: _findOrCreateFolder failed to create folder: ${response.body}',
      );
      throw Exception('Failed to create folder "$name": ${response.body}');
    }
  }

  Future<String> _createFileMetadata(
    String token,
    String name,
    String parentId,
    Map<String, String> appProperties,
  ) async {
    LogConsole.log(
      'GoogleDriveBackupService: _createFileMetadata creating metadata for "$name"',
    );
    final url = Uri.parse('https://www.googleapis.com/drive/v3/files');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'parents': [parentId],
        'appProperties': appProperties,
      }),
    );

    LogConsole.log(
      'GoogleDriveBackupService: _createFileMetadata post status code: ${response.statusCode}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final fileId = data['id'] as String;
      LogConsole.log(
        'GoogleDriveBackupService: _createFileMetadata successfully created file metadata with ID: $fileId',
      );
      return fileId;
    } else {
      LogConsole.log(
        'GoogleDriveBackupService: _createFileMetadata failed: ${response.body}',
      );
      throw Exception('Failed to create file metadata: ${response.body}');
    }
  }

  Future<void> _updateFileMetadata(
    String token,
    String fileId,
    Map<String, String> appProperties,
  ) async {
    LogConsole.log(
      'GoogleDriveBackupService: _updateFileMetadata updating metadata for ID: $fileId',
    );
    final url = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'appProperties': appProperties}),
    );

    LogConsole.log(
      'GoogleDriveBackupService: _updateFileMetadata patch status code: ${response.statusCode}',
    );
    if (response.statusCode != 200) {
      LogConsole.log(
        'GoogleDriveBackupService: _updateFileMetadata failed: ${response.body}',
      );
      throw Exception('Failed to update file metadata: ${response.body}');
    }
    LogConsole.log(
      'GoogleDriveBackupService: _updateFileMetadata successfully updated file metadata',
    );
  }

  Future<void> _uploadFileContent(
    String token,
    String fileId,
    List<int> bytes,
  ) async {
    LogConsole.log(
      'GoogleDriveBackupService: _uploadFileContent uploading ${bytes.length} bytes for ID: $fileId',
    );
    final url = Uri.parse(
      'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media',
    );
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/zip',
      },
      body: bytes,
    );

    LogConsole.log(
      'GoogleDriveBackupService: _uploadFileContent patch status code: ${response.statusCode}',
    );
    if (response.statusCode != 200) {
      LogConsole.log(
        'GoogleDriveBackupService: _uploadFileContent failed: ${response.body}',
      );
      throw Exception('Failed to upload file content: ${response.body}');
    }
    LogConsole.log(
      'GoogleDriveBackupService: _uploadFileContent successfully uploaded content',
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
