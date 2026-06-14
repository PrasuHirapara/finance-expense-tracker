// ignore_for_file: file_names

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:finance_analytics_app/core/models/module_export_models.dart';
import 'package:finance_analytics_app/core/services/app_settings_repository.dart';
import 'package:finance_analytics_app/core/services/credential_crypto_service.dart';
import 'package:finance_analytics_app/core/services/module_data_export_service.dart';
import 'package:finance_analytics_app/core/services/module_data_import_service.dart';
import 'package:finance_analytics_app/data/database/app_database.dart';
import 'package:finance_analytics_app/features/credentials/data/repositories/credential_repository.dart';
import 'package:finance_analytics_app/features/credentials/domain/models/credential_models.dart';
import 'package:finance_analytics_app/features/expense/data/repositories/expense_repository.dart';
import 'package:finance_analytics_app/features/tasks/data/repositories/task_repository.dart';
import 'package:finance_analytics_app/features/tasks/domain/models/task_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/testHelpers.dart';

void main() {
  initializeProductionTestEnvironment();

  group('Import and export production scenarios', () {
    late Directory testRoot;
    late AppDatabase database;
    late AppSettingsRepository appSettingsRepository;
    late CredentialCryptoService credentialCryptoService;
    late ExpenseRepository expenseRepository;
    late TaskRepository taskRepository;
    late ModuleDataImportService importService;
    late ModuleDataExportService exportService;

    setUp(() async {
      testRoot = await createTestRoot();
      installPathProviderMock(testRoot);
      database = createTestDatabase();
      appSettingsRepository = settingsRepository(testRoot);
      credentialCryptoService = CredentialCryptoService();
      expenseRepository = ExpenseRepository(database);
      taskRepository = TaskRepository(database);
      importService = ModuleDataImportService(
        database: database,
        appSettingsRepository: appSettingsRepository,
        credentialCryptoService: credentialCryptoService,
        notificationService: notificationService(
          database,
          appSettingsRepository,
          credentialCryptoService,
        ),
      );
      exportService = ModuleDataExportService(appSettingsRepository, database);
    });

    tearDown(() async {
      clearPathProviderMock();
      await appSettingsRepository.dispose();
      await database.close();
      await deleteTestRoot(testRoot);
    });

    test('imports valid Excel rows and exports all modules to Excel', () async {
      await expenseRepository.seedDefaults();
      final exportDirectory = Directory(
        '${testRoot.path}${Platform.pathSeparator}exports',
      );
      await appSettingsRepository.updateExportDirectoryPath(
        exportDirectory.path,
      );

      final expenseImportPath = await writeExpenseWorkbook(testRoot);
      final expenseResult = await importService.importExpenseExcel(
        expenseImportPath,
      );
      expect(expenseResult.savedItems, 1);
      expect(
        (await expenseRepository.loadEntries()).single.title,
        'Team lunch',
      );

      final credentialImportPath = await writeCredentialWorkbook(testRoot);
      final credentialResult = await importService.importCredentialExcel(
        credentialImportPath,
        encryptionKey: testCredentialKey,
      );
      expect(credentialResult.savedItems, 1);
      expect(credentialResult.validatedRows, 2);

      await taskRepository.addTask(
        TaskDraft(
          title: 'Export report',
          description: 'Send finished workbook',
          category: 'Work',
          date: DateTime(2026, 5, 23),
          priority: 4,
          isDaily: false,
          isCompleted: true,
          checklist: const <TaskChecklistItem>[
            TaskChecklistItem(title: 'Verify totals', isCompleted: true),
          ],
        ),
      );

      final credential = await CredentialRepository(database).loadCredential(1);
      final credentialFields = await credentialCryptoService.decryptFields(
        record: credential!,
        encryptionKey: testCredentialKey,
      );

      final expenseExportPath = await exportService.exportExpenseData(
        range: null,
        format: ModuleExportFormat.excel,
        entries: await expenseRepository.loadEntries(),
      );
      final taskExportPath = await exportService.exportTaskData(
        range: null,
        format: ModuleExportFormat.excel,
        tasks: await taskRepository.loadAllTasks(),
      );
      final credentialExportPath = await exportService.exportCredentialData(
        format: ModuleExportFormat.excel,
        credentials: <DecryptedCredential>[
          DecryptedCredential(
            id: credential.id,
            title: credential.title,
            fields: withoutCredentialMetadataFields(credentialFields),
            expiryDate: extractCredentialExpiryDate(credentialFields),
            createdAt: credential.createdAt,
            updatedAt: credential.updatedAt,
          ),
        ],
      );

      expect(File(expenseExportPath).existsSync(), isTrue);
      expect(File(taskExportPath).existsSync(), isTrue);
      expect(File(credentialExportPath).existsSync(), isTrue);
      expect(
        Excel.decodeBytes(
          File(expenseExportPath).readAsBytesSync(),
        ).tables.keys,
        containsAll(<String>['Summary', 'Entries']),
      );
      expect(
        Excel.decodeBytes(File(taskExportPath).readAsBytesSync()).tables.keys,
        containsAll(<String>['Summary', 'Tasks']),
      );
      expect(
        Excel.decodeBytes(
          File(credentialExportPath).readAsBytesSync(),
        ).tables.keys,
        containsAll(<String>['Summary', 'Credentials']),
      );
    });

    test(
      'imports task with hyphens for empty description and checklist, and exports them as hyphens',
      () async {
        final exportDirectory = Directory(
          '${testRoot.path}${Platform.pathSeparator}exports',
        );
        await appSettingsRepository.updateExportDirectoryPath(
          exportDirectory.path,
        );

        final taskImportPath = await writeTaskWorkbook(
          testRoot,
          description: '-',
          checklist: '-',
        );

        final importResult = await importService.importTaskExcel(
          taskImportPath,
        );
        expect(importResult.savedItems, 1);

        final importedTasks = await taskRepository.loadAllTasks();
        expect(importedTasks.length, 1);
        expect(importedTasks.single.title, 'Test import task');
        expect(importedTasks.single.description, isEmpty);
        expect(importedTasks.single.checklist, isEmpty);

        final taskExportPath = await exportService.exportTaskData(
          range: null,
          format: ModuleExportFormat.excel,
          tasks: importedTasks,
        );

        expect(File(taskExportPath).existsSync(), isTrue);

        final excel = Excel.decodeBytes(File(taskExportPath).readAsBytesSync());
        final sheet = excel['Tasks'];
        final row = sheet.row(1);
        final exportedChecklist = row[6]?.value?.toString();
        final exportedDescription = row[7]?.value?.toString();

        expect(exportedChecklist, '-');
        expect(exportedDescription, '-');
      },
    );

    test(
      'imports and exports investment Excel data correctly, skipping summary rows',
      () async {
        final exportDirectory = Directory(
          '${testRoot.path}${Platform.pathSeparator}exports',
        );
        await appSettingsRepository.updateExportDirectoryPath(
          exportDirectory.path,
        );

        final categoryId = await database
            .into(database.dbInvestmentCategories)
            .insert(
              DbInvestmentCategoriesCompanion.insert(
                name: 'Equity / Stocks',
                iconCodePoint: 0xe62e,
                colorValue: 0xFF2196F3,
              ),
            );

        final buyId = await database
            .into(database.dbInvestmentEntries)
            .insert(
              DbInvestmentEntriesCompanion.insert(
                categoryId: categoryId,
                symbol: 'RELIANCE',
                qty: 10,
                buyDate: DateTime(2026, 5, 10),
                buyRate: 2450.00,
                buyAmt: 24500.00,
                createdAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );

        await database
            .into(database.dbSellEntries)
            .insert(
              DbSellEntriesCompanion.insert(
                buyEntryId: buyId,
                symbol: 'RELIANCE',
                sellQty: 4,
                sellDate: DateTime(2026, 5, 20),
                sellRate: 2500.00,
                sellAmt: 10000.00,
                createdAt: Value(DateTime.now()),
              ),
            );

        final exportPath = await exportService.exportInvestmentData(
          range: null,
          format: ModuleExportFormat.excel,
        );

        expect(File(exportPath).existsSync(), isTrue);

        final exportedWorkbook = Excel.decodeBytes(
          File(exportPath).readAsBytesSync(),
        );
        expect(exportedWorkbook.tables.keys, contains('Investments'));

        await (database.delete(database.dbSellEntries)).go();
        await (database.delete(database.dbInvestmentEntries)).go();
        await (database.delete(database.dbInvestmentCategories)).go();

        final importResult = await importService.importInvestmentExcel(
          exportPath,
        );
        final validRows = importResult.rows.where((r) => r.isValid).toList();
        final savedCount = await importService.saveInvestmentImport(validRows);

        expect(savedCount, 2);

        final importedBuys = await (database.select(
          database.dbInvestmentEntries,
        )).get();
        expect(importedBuys.length, 2);
        expect(importedBuys.any((b) => b.qty == 4), isTrue);
        expect(importedBuys.any((b) => b.qty == 6), isTrue);
      },
    );

    test('rejects invalid imports and unusable export destinations', () async {
      await expenseRepository.seedDefaults();
      final invalidImportPath = await writeInvalidExpenseWorkbook(testRoot);

      await expectLater(
        importService.importExpenseExcel(invalidImportPath),
        throwsA(isA<ModuleImportException>()),
      );

      final blockedBase = File(
        '${testRoot.path}${Platform.pathSeparator}not_a_directory',
      );
      await blockedBase.writeAsString('blocked');
      await appSettingsRepository.updateExportDirectoryPath(blockedBase.path);

      await expectLater(
        exportService.exportTaskData(
          range: null,
          format: ModuleExportFormat.excel,
          tasks: const <TaskItem>[],
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
