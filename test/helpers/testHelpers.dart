// ignore_for_file: file_names

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:finance_analytics_app/core/services/app_settings_repository.dart';
import 'package:finance_analytics_app/core/services/cloud_backup_crypto_service.dart';
import 'package:finance_analytics_app/core/services/cloud_sync_payload_service.dart';
import 'package:finance_analytics_app/core/services/credential_crypto_service.dart';
import 'package:finance_analytics_app/core/services/credential_security_service.dart';
import 'package:finance_analytics_app/core/services/notification_service.dart';
import 'package:finance_analytics_app/core/services/reminder_settings_repository.dart';
import 'package:finance_analytics_app/data/database/app_database.dart';
import 'package:finance_analytics_app/features/credentials/data/repositories/credential_repository.dart';
import 'package:finance_analytics_app/features/credentials/domain/models/credential_models.dart';
import 'package:finance_analytics_app/features/expense/data/repositories/expense_repository.dart';
import 'package:finance_analytics_app/features/expense/domain/models/expense_models.dart';
import 'package:finance_analytics_app/features/tasks/data/repositories/task_category_repository.dart';
import 'package:finance_analytics_app/features/tasks/data/repositories/task_repository.dart';
import 'package:finance_analytics_app/features/tasks/domain/models/task_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const testCredentialKey = 'production-credential-key';
const testCloudKey = 'production-cloud-key';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void initializeProductionTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}

AppDatabase createTestDatabase() => AppDatabase.test(NativeDatabase.memory());

Future<Directory> createTestRoot() {
  return Directory.systemTemp.createTemp('daily_use_tests_');
}

Future<void> deleteTestRoot(Directory root) async {
  if (await root.exists()) {
    await root.delete(recursive: true);
  }
}

void installPathProviderMock(Directory root) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, (call) async {
        switch (call.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
          case 'getTemporaryDirectory':
            return root.path;
        }
        return null;
      });
}

void clearPathProviderMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pathProviderChannel, null);
}

AppSettingsRepository settingsRepository(Directory root) {
  return AppSettingsRepository(
    settingsFileResolver: () async {
      if (!await root.exists()) {
        await root.create(recursive: true);
      }
      return File('${root.path}${Platform.pathSeparator}app_settings.json');
    },
  );
}

CloudSyncPayloadService cloudPayloadService(
  AppDatabase database,
  AppSettingsRepository settingsRepository,
) {
  final taskRepository = TaskRepository(database);
  return CloudSyncPayloadService(
    database: database,
    taskRepository: taskRepository,
    taskCategoryRepository: TaskCategoryRepository(taskRepository),
    appSettingsRepository: settingsRepository,
    reminderSettingsRepository: ReminderSettingsRepository(),
    credentialCryptoService: CredentialCryptoService(),
    cloudBackupCryptoService: CloudBackupCryptoService(),
  );
}

NotificationService notificationService(
  AppDatabase database,
  AppSettingsRepository settingsRepository,
  CredentialCryptoService credentialCryptoService,
) {
  return NotificationService(
    reminderSettingsRepository: ReminderSettingsRepository(),
    appSettingsRepository: settingsRepository,
    credentialRepository: CredentialRepository(database),
    credentialCryptoService: credentialCryptoService,
    credentialSecurityService: CredentialSecurityService(),
  );
}

Future<void> seedSyncData(AppDatabase database) async {
  final expenseRepository = ExpenseRepository(database);
  await expenseRepository.seedDefaults();
  final category = (await database.getCategories()).first;
  await expenseRepository.addExpense(
    ExpenseDraft(
      title: 'Sync expense',
      amount: 100,
      type: 'expense',
      categoryId: category.id,
      date: DateTime(2026, 5, 23),
      paymentMode: 'UPI',
      notes: '',
    ),
  );
  await TaskRepository(database).addTask(
    TaskDraft(
      title: 'Sync task',
      description: '',
      category: 'Work',
      date: DateTime(2026, 5, 23),
      priority: 3,
      isDaily: false,
      isCompleted: false,
    ),
  );
  await seedCredential(database);
}

Future<void> seedCredential(AppDatabase database) async {
  final cryptoService = CredentialCryptoService();
  final payload = await cryptoService.encryptFields(
    fields: const <CredentialField>[
      CredentialField(keyLabel: 'Token', value: 'abc123'),
    ],
    encryptionKey: testCredentialKey,
  );
  await CredentialRepository(
    database,
  ).addCredential(title: 'Sync Credential', payload: payload);
}

Future<String> writeExpenseWorkbook(Directory root) async {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != 'Expenses') {
    excel.rename(defaultSheet, 'Expenses');
  }
  final sheet = excel['Expenses'];
  sheet.appendRow(<CellValue?>[
    TextCellValue('Title'),
    TextCellValue('Amount'),
    TextCellValue('Type'),
    TextCellValue('Category'),
    TextCellValue('Bank'),
    TextCellValue('Date'),
    TextCellValue('Payment Mode'),
    TextCellValue('Counterparty'),
    TextCellValue('Notes'),
  ]);
  sheet.appendRow(<CellValue?>[
    TextCellValue('Team lunch'),
    DoubleCellValue(875.5),
    TextCellValue('Expense'),
    TextCellValue('Office'),
    TextCellValue('HDFC'),
    TextCellValue('2026-05-23'),
    TextCellValue('UPI'),
    TextCellValue('Team'),
    TextCellValue('Production import row'),
  ]);
  return writeWorkbook(root, 'expense-import.xlsx', excel);
}

Future<String> writeInvalidExpenseWorkbook(Directory root) async {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != 'Expenses') {
    excel.rename(defaultSheet, 'Expenses');
  }
  final sheet = excel['Expenses'];
  sheet.appendRow(<CellValue?>[
    TextCellValue('Title'),
    TextCellValue('Amount'),
    TextCellValue('Type'),
    TextCellValue('Category'),
    TextCellValue('Date'),
    TextCellValue('Payment Mode'),
  ]);
  sheet.appendRow(<CellValue?>[
    TextCellValue('Bad row'),
    DoubleCellValue(-25),
    TextCellValue('Unknown'),
    TextCellValue('Office'),
    TextCellValue('not-a-date'),
    TextCellValue('Cheque'),
  ]);
  return writeWorkbook(root, 'expense-invalid.xlsx', excel);
}

Future<String> writeCredentialWorkbook(Directory root) async {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != 'Credentials') {
    excel.rename(defaultSheet, 'Credentials');
  }
  final sheet = excel['Credentials'];
  sheet.appendRow(<CellValue?>[
    TextCellValue('Title'),
    TextCellValue('Expiry Date'),
    TextCellValue('Field'),
    TextCellValue('Value'),
  ]);
  sheet.appendRow(<CellValue?>[
    TextCellValue('Bitbucket'),
    TextCellValue('2026-12-31'),
    TextCellValue('Username'),
    TextCellValue('daily-user'),
  ]);
  sheet.appendRow(<CellValue?>[
    TextCellValue('Bitbucket'),
    TextCellValue('2026-12-31'),
    TextCellValue('Password'),
    TextCellValue('daily-secret'),
  ]);
  return writeWorkbook(root, 'credential-import.xlsx', excel);
}

Future<String> writeTaskWorkbook(
  Directory root, {
  required String description,
  required String checklist,
}) async {
  final excel = Excel.createExcel();
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null && defaultSheet != 'Tasks') {
    excel.rename(defaultSheet, 'Tasks');
  }
  final sheet = excel['Tasks'];
  sheet.appendRow(<CellValue?>[
    TextCellValue('Date'),
    TextCellValue('Title'),
    TextCellValue('Category'),
    TextCellValue('Priority'),
    TextCellValue('Daily'),
    TextCellValue('Completed'),
    TextCellValue('Checklist'),
    TextCellValue('Description'),
  ]);
  sheet.appendRow(<CellValue?>[
    TextCellValue('2026-05-23'),
    TextCellValue('Test import task'),
    TextCellValue('Personal'),
    IntCellValue(3),
    TextCellValue('No'),
    TextCellValue('No'),
    TextCellValue(checklist),
    TextCellValue(description),
  ]);
  return writeWorkbook(root, 'task-import.xlsx', excel);
}

Future<String> writeWorkbook(
  Directory root,
  String fileName,
  Excel excel,
) async {
  final bytes = excel.save();
  if (bytes == null) {
    throw StateError('Unable to write test workbook.');
  }
  final file = File('${root.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}
