import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/services/app_data_reset_service.dart';
import '../../../../core/services/app_settings_repository.dart';
import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/google_drive_backup_service.dart';
import '../../../../core/services/module_data_import_service.dart';
import '../../../../core/services/reminder_settings_repository.dart';
import '../../../../features/credentials/data/services/credential_service.dart';
import '../../../../features/expense/data/repositories/expense_repository.dart';
import '../../../../features/investment/data/repositories/investment_repository.dart';
import '../../../../features/tasks/data/repositories/task_repository.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/cancellable_blocking_overlay.dart';
import '../../../../shared/widgets/download_result_snackbar.dart';

class GoogleDriveBackupsPage extends StatefulWidget {
  const GoogleDriveBackupsPage({super.key});

  @override
  State<GoogleDriveBackupsPage> createState() => _GoogleDriveBackupsPageState();
}

class _GoogleDriveBackupsPageState extends State<GoogleDriveBackupsPage> {
  late Future<List<GoogleDriveBackupFile>> _backupsFuture;

  @override
  void initState() {
    super.initState();
    _refreshBackups();
  }

  void _refreshBackups() {
    setState(() {
      _backupsFuture = context.read<GoogleDriveBackupService>().listBackups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Backups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshBackups,
          ),
        ],
      ),
      body: FutureBuilder<List<GoogleDriveBackupFile>>(
        future: _backupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load backups',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to view backups: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: _refreshBackups,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final backups = snapshot.data ?? [];
          if (backups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.backup_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No backups found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Any backups you create will appear here. Backups are stored in Google Drive under "Daily Use Backup".',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonal(
                      onPressed: _refreshBackups,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group backups by Year -> Month
          final grouped = <String, Map<String, List<GoogleDriveBackupFile>>>{};
          for (final backup in backups) {
            grouped.putIfAbsent(backup.year, () => {});
            grouped[backup.year]!.putIfAbsent(backup.month, () => []);
            grouped[backup.year]![backup.month]!.add(backup);
          }

          final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: years.length,
            itemBuilder: (context, yearIndex) {
              final year = years[yearIndex];
              final monthsGroup = grouped[year]!;
              final months = monthsGroup.keys.toList()
                ..sort((a, b) => _compareMonths(b, a));

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppPanel(
                  child: ExpansionTile(
                    key: PageStorageKey<String>('year_$year'),
                    initiallyExpanded: yearIndex == 0,
                    title: Text(
                      year,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: Icon(
                      Icons.folder_shared_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    shape:
                        const Border(), // Removes default divider line in ExpansionTile
                    childrenPadding: const EdgeInsets.only(left: 14, bottom: 8),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Delete Year Folder',
                          onPressed: () => _deleteBackupItem(
                            context,
                            id: monthsGroup.values.first.first.yearFolderId,
                            name: '$year Folder',
                            isFolder: true,
                          ),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                    children: months.map((month) {
                      final files = monthsGroup[month]!;

                      return ExpansionTile(
                        key: PageStorageKey<String>('month_${year}_$month'),
                        initiallyExpanded: yearIndex == 0,
                        title: Text(
                          month,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        leading: const Icon(
                          Icons.folder_rounded,
                          color: Colors.amber,
                        ),
                        shape: const Border(),
                        childrenPadding: const EdgeInsets.only(left: 12),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error,
                              ),
                              tooltip: 'Delete Month Folder',
                              onPressed: () => _deleteBackupItem(
                                context,
                                id: files.first.monthFolderId,
                                name: '$month $year Folder',
                                isFolder: true,
                              ),
                            ),
                            const Icon(Icons.expand_more),
                          ],
                        ),
                        children: files.map((file) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Icon(
                                    Icons.archive_outlined,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Row 1: Folder/File name, size, date
                                      Text(
                                        file.name,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${file.fileSize} • ${_formatDate(file.backupDate)}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Row 2: About, download, delete icons on the right side
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.info_outline_rounded,
                                            ),
                                            tooltip: 'Details',
                                            onPressed: () =>
                                                _showBackupDetails(file),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons
                                                  .settings_backup_restore_rounded,
                                            ),
                                            tooltip: 'Import Backup',
                                            onPressed: () =>
                                                _importBackup(file),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.download_rounded,
                                            ),
                                            tooltip: 'Download',
                                            onPressed: () =>
                                                _downloadBackup(file),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color: theme.colorScheme.error,
                                            ),
                                            tooltip: 'Delete',
                                            onPressed: () => _deleteBackupItem(
                                              context,
                                              id: file.id,
                                              name: file.name,
                                              isFolder: false,
                                            ),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteBackupItem(
    BuildContext context, {
    required String? id,
    required String name,
    required bool isFolder,
  }) async {
    final backupService = context.read<GoogleDriveBackupService>();
    final messenger = ScaffoldMessenger.of(context);

    if (id == null || id.isEmpty) {
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Unable to identify Google Drive ID for $name.',
          type: AppSnackBarType.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $name?'),
        content: Text(
          isFolder
              ? 'Are you sure you want to permanently delete this backup folder and all backups inside it from Google Drive? This cannot be undone.'
              : 'Are you sure you want to permanently delete this backup file from Google Drive? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await _runBlockingOperation<void>(
        statusText: 'Deleting $name from Google Drive...',
        task: (token) => backupService.deleteFileOrFolder(id),
      );

      if (!context.mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(context, message: '$name deleted successfully.'),
      );
      _refreshBackups();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Failed to delete $name: $e',
          type: AppSnackBarType.error,
        ),
      );
    }
  }

  Future<void> _downloadBackup(GoogleDriveBackupFile file) async {
    final backupService = context.read<GoogleDriveBackupService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final pathResult = await _runBlockingOperation<String>(
        statusText: 'Downloading backup archive...',
        task: (token) =>
            backupService.downloadBackup(file.id, file.year, file.month),
      );

      if (!mounted) return;
      showDownloadResultSnackBar(
        context,
        message: 'Backup downloaded successfully to: $pathResult',
        path: pathResult,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Failed to download backup: $e',
          type: AppSnackBarType.error,
        ),
      );
    }
  }

  Future<void> _importBackup(GoogleDriveBackupFile file) async {
    final backupService = context.read<GoogleDriveBackupService>();
    final importService = context.read<ModuleDataImportService>();
    final appDataResetService = context.read<AppDataResetService>();
    final credentialService = context.read<CredentialService>();
    final appSettingsRepository = context.read<AppSettingsRepository>();
    final reminderSettingsRepository = context
        .read<ReminderSettingsRepository>();
    final expenseRepository = context.read<ExpenseRepository>();
    final taskRepository = context.read<TaskRepository>();
    final investmentRepository = context.read<InvestmentRepository>();
    final messenger = ScaffoldMessenger.of(context);

    // 1. Download ZIP file first using blocking overlay
    String? zipFilePath;
    try {
      zipFilePath = await _runBlockingOperation<String>(
        statusText: 'Downloading backup archive for import...',
        task: (token) =>
            backupService.downloadBackup(file.id, file.year, file.month),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Failed to download backup: $e',
          type: AppSnackBarType.error,
        ),
      );
      return;
    }

    if (zipFilePath.isEmpty) return;

    if (!mounted) return;

    final errorColor = Theme.of(context).colorScheme.error;
    final onErrorColor = Theme.of(context).colorScheme.onError;

    // 2. Check if data is already in app
    try {
      final expenses = await expenseRepository.loadEntries(filter: null);
      final tasks = await taskRepository.loadAllTasks();
      final credentials = await credentialService.loadCredentials();
      final buys = await investmentRepository.getBuyEntries();
      final sells = await investmentRepository.getSellEntries();

      final hasExistingData =
          expenses.isNotEmpty ||
          tasks.isNotEmpty ||
          credentials.isNotEmpty ||
          buys.isNotEmpty ||
          sells.isNotEmpty;

      if (hasExistingData) {
        if (!mounted) return;
        // Show confirmation popup to override data
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Override Existing Data?'),
            content: const Text(
              'Data already exists in the app. Importing this backup will permanently replace all your current data. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: onErrorColor,
                ),
                child: const Text('Override'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          // User chose not to override, so clean up downloaded zip and exit
          try {
            final fileObj = File(zipFilePath);
            if (await fileObj.exists()) {
              await fileObj.delete();
            }
          } catch (_) {}
          return;
        }
      }

      // 3. User confirmed or no data exists -> Proceed with import
      await _runBlockingOperation<void>(
        statusText: 'Importing data...',
        task: (token) async {
          // Clear current database first (since user requested override or there's no data)
          await appDataResetService.deleteAllData();

          // Read the ZIP archive
          final zipFile = File(zipFilePath!);
          final bytes = await zipFile.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);

          final tempDir = await getTemporaryDirectory();
          final unzipDir = Directory(
            path.join(
              tempDir.path,
              'gdrive_unzip_temp_${DateTime.now().millisecondsSinceEpoch}',
            ),
          );
          await unzipDir.create(recursive: true);

          try {
            // Unzip files
            for (final fileEntry in archive) {
              final filename = fileEntry.name;
              if (fileEntry.isFile) {
                final fileData = fileEntry.content as List<int>;
                final outFile = File(path.join(unzipDir.path, filename));
                await outFile.create(recursive: true);
                await outFile.writeAsBytes(fileData);
              }
            }

            token.throwIfCancelled();

            // Import settings.json first if exists
            final settingsFile = File(
              path.join(unzipDir.path, 'settings.json'),
            );
            if (await settingsFile.exists()) {
              final content = await settingsFile.readAsString();
              final json = jsonDecode(content) as Map<String, dynamic>;
              final appSettings = json['appSettings'];
              final reminderSettings = json['reminderSettings'];
              if (appSettings != null) {
                await appSettingsRepository.restoreFromCloud(appSettings);
              }
              if (reminderSettings != null) {
                await reminderSettingsRepository.restoreFromCloud(
                  reminderSettings,
                );
              }
            }

            token.throwIfCancelled();

            // Import expenses
            final expensesFile = File(
              path.join(unzipDir.path, 'expenses.xlsx'),
            );
            if (await expensesFile.exists()) {
              await importService.importExpenseExcel(expensesFile.path);
            }

            token.throwIfCancelled();

            // Import tasks
            final tasksFile = File(path.join(unzipDir.path, 'tasks.xlsx'));
            if (await tasksFile.exists()) {
              await importService.importTaskExcel(tasksFile.path);
            }

            token.throwIfCancelled();

            // Import credentials
            final credentialsFile = File(
              path.join(unzipDir.path, 'credentials.xlsx'),
            );
            if (await credentialsFile.exists()) {
              // Retrieve or fallback the stored credentials encryption key
              var masterKey = await credentialService.readStoredEncryptionKey();
              if (masterKey == null || masterKey.isEmpty) {
                masterKey = 'default_encryption_key';
              }
              await importService.importCredentialExcel(
                credentialsFile.path,
                encryptionKey: masterKey,
              );
            }

            token.throwIfCancelled();

            // Import investments
            final investmentsFile = File(
              path.join(unzipDir.path, 'investments.xlsx'),
            );
            if (await investmentsFile.exists()) {
              final preview = await importService.importInvestmentExcel(
                investmentsFile.path,
              );
              final validRows = preview.rows.where((r) => r.isValid).toList();
              await importService.saveInvestmentImport(validRows);
            }
          } finally {
            // Clean up temporary unzipped files
            try {
              if (await unzipDir.exists()) {
                await unzipDir.delete(recursive: true);
              }
            } catch (_) {}
          }

          // Clean up downloaded ZIP
          try {
            if (await zipFile.exists()) {
              await zipFile.delete();
            }
          } catch (_) {}
        },
      );

      if (!mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(context, message: 'Data imported successfully.'),
      );

      // Refresh backup list
      _refreshBackups();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        buildAppSnackBar(
          context,
          message: 'Failed to import backup: $e',
          type: AppSnackBarType.error,
        ),
      );
    }
  }

  void _showBackupDetails(GoogleDriveBackupFile file) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backup File Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              _DetailRow(label: 'Filename', value: file.name),
              const Divider(height: 16),
              _DetailRow(label: 'Year', value: file.year),
              const Divider(height: 16),
              _DetailRow(label: 'Month', value: file.month),
              const Divider(height: 16),
              _DetailRow(
                label: 'Backup Date',
                value: _formatDate(file.backupDate),
              ),
              const Divider(height: 16),
              _DetailRow(label: 'File Size', value: file.fileSize),
              const Divider(height: 16),
              _DetailRow(label: 'Included Modules', value: file.modules),
              const Divider(height: 16),
              _DetailRow(
                label: 'Location',
                value:
                    'Google Drive under /Daily Use Backup/${file.year}/${file.month}',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(modalContext).pop();
                    unawaited(_downloadBackup(file));
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download ZIP'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(modalContext).pop();
                    unawaited(_importBackup(file));
                  },
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  label: const Text('Import Backup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<T> _runBlockingOperation<T>({
    required String statusText,
    required Future<T> Function(AppCancellationToken token) task,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final token = AppCancellationToken();
    final route = createCancellableBlockingOverlayRoute<void>(
      statusText: statusText,
      onCancel: token.cancel,
    );
    unawaited(navigator.push<void>(route));
    await Future<void>.delayed(Duration.zero);

    try {
      return await task(token);
    } finally {
      if (route.isActive) {
        navigator.removeRoute(route);
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy HH:mm').format(date);
  }

  int _compareMonths(String a, String b) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final idxA = months.indexOf(a);
    final idxB = months.indexOf(b);
    return idxA.compareTo(idxB);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
