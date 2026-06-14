import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/cancellable_task.dart';
import '../../../../core/services/google_drive_backup_service.dart';
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
