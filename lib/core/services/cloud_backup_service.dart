import 'cancellable_task.dart';
import 'cloud_sync_service.dart';

class CloudBackupService {
  const CloudBackupService({required CloudSyncService cloudSyncService})
    : _cloudSyncService = cloudSyncService;

  final CloudSyncService _cloudSyncService;

  Future<void> runBackup({
    bool interactive = true,
    String? credentialEncryptionKey,
    AppCancellationToken? cancellationToken,
  }) {
    return _cloudSyncService.uploadDataToCloud(
      interactive: interactive,
      credentialEncryptionKey: credentialEncryptionKey,
      cancellationToken: cancellationToken,
    );
  }
}
