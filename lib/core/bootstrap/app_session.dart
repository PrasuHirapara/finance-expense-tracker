import '../../data/database/app_database.dart';
import '../../data/repositories/export_repository_impl.dart';
import '../../data/repositories/finance_repository_impl.dart';
import '../../data/services/export/csv_export_service.dart';
import '../../data/services/export/pdf_export_service.dart';
import '../../data/services/seed_service.dart';
import '../../domain/repositories/export_repository.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../features/credentials/data/repositories/credential_repository.dart';
import '../../features/credentials/data/services/credential_service.dart';
import '../../features/expense/data/repositories/expense_repository.dart';
import '../../features/tasks/data/repositories/task_category_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../models/app_preferences.dart';
import '../services/android_battery_optimization_service.dart';
import '../services/app_data_reset_service.dart';
import '../services/app_preferences_effects_service.dart';
import '../services/app_settings_repository.dart';
import '../services/auto_backup_scheduler_service.dart';
import '../services/cloud_backup_crypto_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/cloud_sync_payload_service.dart';
import '../services/cloud_sync_security_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/credential_crypto_service.dart';
import '../services/credential_security_service.dart';
import '../services/file_launcher_service.dart';
import '../services/firebase_cloud_sync_auth_service.dart';
import '../services/firestore_cloud_sync_store_service.dart';
import '../services/module_data_export_service.dart';
import '../services/module_data_import_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_settings_repository.dart';

class AppSession {
  AppSession._({
    required this.database,
    required this.appSettingsRepository,
    required this.expenseRepository,
    required this.credentialRepository,
    required this.credentialCryptoService,
    required this.credentialSecurityService,
    required this.credentialService,
    required this.financeRepository,
    required this.exportRepository,
    required this.taskRepository,
    required this.notificationService,
    required this.fileLauncherService,
    required this.moduleDataExportService,
    required this.moduleDataImportService,
    required this.taskCategoryRepository,
    required this.reminderSettingsRepository,
    required this.cloudBackupCryptoService,
    required this.firebaseCloudSyncAuthService,
    required this.firestoreCloudSyncStoreService,
    required this.cloudSyncSecurityService,
    required this.appPreferencesEffectsService,
    required this.cloudSyncService,
    required this.cloudBackupService,
    required this.autoBackupSchedulerService,
    required this.androidBatteryOptimizationService,
    required this.appDataResetService,
  });

  factory AppSession.create() {
    final database = AppDatabase();
    final appSettingsRepository = AppSettingsRepository();
    final expenseRepository = ExpenseRepository(database);
    final credentialRepository = CredentialRepository(database);
    final credentialCryptoService = CredentialCryptoService();
    final credentialSecurityService = CredentialSecurityService();
    final reminderSettingsRepository = ReminderSettingsRepository();
    final notificationService = NotificationService(
      reminderSettingsRepository: reminderSettingsRepository,
      appSettingsRepository: appSettingsRepository,
      credentialRepository: credentialRepository,
      credentialCryptoService: credentialCryptoService,
      credentialSecurityService: credentialSecurityService,
    );
    final credentialService = CredentialService(
      repository: credentialRepository,
      cryptoService: credentialCryptoService,
      securityService: credentialSecurityService,
      notificationService: notificationService,
    );
    final financeRepository = FinanceRepositoryImpl(
      database: database,
      seedService: SeedService(database),
    );
    final exportRepository = ExportRepositoryImpl(
      csvExportService: CsvExportService(),
      pdfExportService: PdfExportService(),
    );
    final taskRepository = TaskRepository(database);
    final taskCategoryRepository = TaskCategoryRepository(taskRepository);
    final cloudBackupCryptoService = CloudBackupCryptoService();
    final firebaseCloudSyncAuthService = FirebaseCloudSyncAuthService();
    final firestoreCloudSyncStoreService = FirestoreCloudSyncStoreService();
    final cloudSyncSecurityService = CloudSyncSecurityService();
    final fileLauncherService = FileLauncherService();
    final moduleDataExportService = ModuleDataExportService(
      appSettingsRepository,
      database,
    );
    final moduleDataImportService = ModuleDataImportService(
      database: database,
      appSettingsRepository: appSettingsRepository,
      credentialCryptoService: credentialCryptoService,
      notificationService: notificationService,
    );
    final appPreferencesEffectsService = AppPreferencesEffectsService(
      notificationService: notificationService,
    );
    final cloudSyncService = CloudSyncService(
      appSettingsRepository: appSettingsRepository,
      authService: firebaseCloudSyncAuthService,
      remoteStoreService: firestoreCloudSyncStoreService,
      payloadService: CloudSyncPayloadService(
        database: database,
        taskRepository: taskRepository,
        taskCategoryRepository: taskCategoryRepository,
        appSettingsRepository: appSettingsRepository,
        reminderSettingsRepository: reminderSettingsRepository,
        credentialCryptoService: credentialCryptoService,
        cloudBackupCryptoService: cloudBackupCryptoService,
      ),
      cloudSyncSecurityService: cloudSyncSecurityService,
      credentialSecurityService: credentialSecurityService,
      appPreferencesEffectsService: appPreferencesEffectsService,
    );
    final cloudBackupService = CloudBackupService(
      cloudSyncService: cloudSyncService,
    );
    final autoBackupSchedulerService = AutoBackupSchedulerService(
      appSettingsRepository: appSettingsRepository,
    );
    final androidBatteryOptimizationService =
        AndroidBatteryOptimizationService();
    final appDataResetService = AppDataResetService(
      credentialService: credentialService,
      expenseRepository: expenseRepository,
      taskRepository: taskRepository,
      taskCategoryRepository: taskCategoryRepository,
      reminderSettingsRepository: reminderSettingsRepository,
      appSettingsRepository: appSettingsRepository,
      notificationService: notificationService,
      cloudSyncService: cloudSyncService,
    );

    return AppSession._(
      database: database,
      appSettingsRepository: appSettingsRepository,
      expenseRepository: expenseRepository,
      credentialRepository: credentialRepository,
      credentialCryptoService: credentialCryptoService,
      credentialSecurityService: credentialSecurityService,
      credentialService: credentialService,
      financeRepository: financeRepository,
      exportRepository: exportRepository,
      taskRepository: taskRepository,
      notificationService: notificationService,
      fileLauncherService: fileLauncherService,
      moduleDataExportService: moduleDataExportService,
      moduleDataImportService: moduleDataImportService,
      taskCategoryRepository: taskCategoryRepository,
      reminderSettingsRepository: reminderSettingsRepository,
      cloudBackupCryptoService: cloudBackupCryptoService,
      firebaseCloudSyncAuthService: firebaseCloudSyncAuthService,
      firestoreCloudSyncStoreService: firestoreCloudSyncStoreService,
      cloudSyncSecurityService: cloudSyncSecurityService,
      appPreferencesEffectsService: appPreferencesEffectsService,
      cloudSyncService: cloudSyncService,
      cloudBackupService: cloudBackupService,
      autoBackupSchedulerService: autoBackupSchedulerService,
      androidBatteryOptimizationService: androidBatteryOptimizationService,
      appDataResetService: appDataResetService,
    );
  }

  final AppDatabase database;
  final AppSettingsRepository appSettingsRepository;
  final ExpenseRepository expenseRepository;
  final CredentialRepository credentialRepository;
  final CredentialCryptoService credentialCryptoService;
  final CredentialSecurityService credentialSecurityService;
  final CredentialService credentialService;
  final FinanceRepository financeRepository;
  final ExportRepository exportRepository;
  final TaskRepository taskRepository;
  final NotificationService notificationService;
  final FileLauncherService fileLauncherService;
  final ModuleDataExportService moduleDataExportService;
  final ModuleDataImportService moduleDataImportService;
  final TaskCategoryRepository taskCategoryRepository;
  final ReminderSettingsRepository reminderSettingsRepository;
  final CloudBackupCryptoService cloudBackupCryptoService;
  final FirebaseCloudSyncAuthService firebaseCloudSyncAuthService;
  final FirestoreCloudSyncStoreService firestoreCloudSyncStoreService;
  final CloudSyncSecurityService cloudSyncSecurityService;
  final AppPreferencesEffectsService appPreferencesEffectsService;
  final CloudSyncService cloudSyncService;
  final CloudBackupService cloudBackupService;
  final AutoBackupSchedulerService autoBackupSchedulerService;
  final AndroidBatteryOptimizationService androidBatteryOptimizationService;
  final AppDataResetService appDataResetService;

  Future<AppPreferences> bootstrap() async {
    final appPreferences = await appSettingsRepository.getSettings();
    await expenseRepository.seedDefaults();
    await taskCategoryRepository.ensureSeeded();
    await notificationService.initialize();
    await appPreferencesEffectsService.apply(appPreferences);
    await autoBackupSchedulerService.reconcileScheduledBackup();
    return appPreferences;
  }

  Future<void> dispose() async {
    reminderSettingsRepository.dispose();
    await appSettingsRepository.flush();
    await database.close();
    await appSettingsRepository.dispose();
  }
}
