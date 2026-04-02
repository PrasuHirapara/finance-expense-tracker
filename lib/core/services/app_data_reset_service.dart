import '../../features/credentials/data/services/credential_service.dart';
import '../../features/expense/data/repositories/expense_repository.dart';
import '../../features/tasks/data/repositories/task_category_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import 'app_settings_repository.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';
import 'reminder_settings_repository.dart';

class AppDataResetService {
  AppDataResetService({
    required CredentialService credentialService,
    required ExpenseRepository expenseRepository,
    required TaskRepository taskRepository,
    required TaskCategoryRepository taskCategoryRepository,
    required ReminderSettingsRepository reminderSettingsRepository,
    required AppSettingsRepository appSettingsRepository,
    required NotificationService notificationService,
    required CloudSyncService cloudSyncService,
  }) : _credentialService = credentialService,
       _expenseRepository = expenseRepository,
       _taskRepository = taskRepository,
       _taskCategoryRepository = taskCategoryRepository,
       _reminderSettingsRepository = reminderSettingsRepository,
       _appSettingsRepository = appSettingsRepository,
       _notificationService = notificationService,
       _cloudSyncService = cloudSyncService;

  final CredentialService _credentialService;
  final ExpenseRepository _expenseRepository;
  final TaskRepository _taskRepository;
  final TaskCategoryRepository _taskCategoryRepository;
  final ReminderSettingsRepository _reminderSettingsRepository;
  final AppSettingsRepository _appSettingsRepository;
  final NotificationService _notificationService;
  final CloudSyncService _cloudSyncService;

  Future<void> deleteAllData() async {
    await _credentialService.deleteAllCredentials();
    await _expenseRepository.clearSectionData();
    await _taskRepository.clearSectionData();
    await _taskCategoryRepository.resetToDefaults();
    await _reminderSettingsRepository.resetExpenseReminder();
    await _reminderSettingsRepository.resetTaskReminder();

    final appSettings = await _appSettingsRepository.getSettings();
    if (appSettings.notificationsEnabled) {
      await _notificationService.scheduleDailyReminders();
    } else {
      await _notificationService.cancelDailyReminders();
    }

    if (appSettings.cloudSync.enabled) {
      await _cloudSyncService.deleteCloudData('Daily Use');
    }
  }
}
