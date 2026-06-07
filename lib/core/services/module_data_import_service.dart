import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import '../../data/database/app_database.dart';
import '../../features/credentials/domain/models/credential_models.dart';
import '../../features/tasks/domain/models/task_models.dart';
import '../constants/app_constants.dart';
import 'app_settings_repository.dart';
import 'credential_crypto_service.dart';
import 'notification_service.dart';

class ModuleImportResult {
  const ModuleImportResult({
    required this.savedItems,
    required this.validatedRows,
    required this.message,
  });

  final int savedItems;
  final int validatedRows;
  final String message;
}

class ModuleImportException implements Exception {
  const ModuleImportException(this.message, [this.errors = const <String>[]]);

  final String message;
  final List<String> errors;

  @override
  String toString() => message;
}

class ModuleDataImportService {
  ModuleDataImportService({
    required AppDatabase database,
    required AppSettingsRepository appSettingsRepository,
    required CredentialCryptoService credentialCryptoService,
    required NotificationService notificationService,
  }) : _database = database,
       _appSettingsRepository = appSettingsRepository,
       _credentialCryptoService = credentialCryptoService,
       _notificationService = notificationService;

  final AppDatabase _database;
  final AppSettingsRepository _appSettingsRepository;
  final CredentialCryptoService _credentialCryptoService;
  final NotificationService _notificationService;

  Future<String> downloadExpenseSampleExcel() async {
    final file = await _buildOutputFile(
      moduleFolder: 'expense',
      fileNameLabel: 'expense-import-sample',
    );
    final categories = await _loadExpenseSampleCategories();
    final banks = await _loadExpenseSampleBanks();
    final expenseTypes = const <String>[
      'Expense',
      'Income',
      'Borrowed',
      'Lent',
    ];
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Expenses') {
      excel.rename(defaultSheet, 'Expenses');
    }

    final expenseSheet = excel['Expenses'];
    final referenceSheet = excel['Reference'];
    final headerStyle = CellStyle(bold: true);

    expenseSheet.appendRow(<CellValue?>[
      TextCellValue('Entry ID'),
      TextCellValue('Title*'),
      TextCellValue('Amount*'),
      TextCellValue('Type*'),
      TextCellValue('Category*'),
      TextCellValue('Bank'),
      TextCellValue('Date*'),
      TextCellValue('Day'),
      TextCellValue('Payment Mode*'),
      TextCellValue('Counterparty'),
      TextCellValue('Notes'),
    ]);
    expenseSheet.appendRow(<CellValue?>[
      TextCellValue(''),
      TextCellValue('Lunch with team'),
      DoubleCellValue(450),
      TextCellValue('Expense'),
      TextCellValue(categories.first),
      TextCellValue(banks.isEmpty ? '' : banks.first),
      TextCellValue(DateFormat('yyyy-MM-dd').format(DateTime.now())),
      TextCellValue(DateFormat('EEEE').format(DateTime.now())),
      TextCellValue(AppConstants.paymentModes.first),
      TextCellValue('Office friends'),
      TextCellValue('Sample row, replace with your own data'),
    ]);
    _applyRowStyle(
      expenseSheet,
      rowIndex: 0,
      columnCount: 11,
      style: headerStyle,
    );
    _setColumnWidths(expenseSheet, <double>[
      12,
      28,
      14,
      16,
      18,
      16,
      16,
      16,
      18,
      20,
      28,
    ]);

    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Field'),
      TextCellValue('Requirement'),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Entry ID'),
      TextCellValue(
        'Optional. Used automatically by app-generated exports to preserve split metadata.',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Title'),
      TextCellValue('Required'),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Amount'),
      TextCellValue('Required. Must be greater than 0.'),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Type'),
      TextCellValue('Required. Use Expense, Income, Borrowed, or Lent.'),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Category'),
      TextCellValue('Required. New category names are created automatically.'),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Bank'),
      TextCellValue('Optional. New bank names are created automatically.'),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Date'),
      TextCellValue(
        'Required. Prefer yyyy-MM-dd. Excel date cells are also accepted.',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Day'),
      TextCellValue(
        'Optional. If missing, the app derives it from the Date column automatically.',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Payment Mode'),
      TextCellValue(
        'Required. Use one of: ${AppConstants.paymentModes.join(', ')}',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Counterparty / Notes'),
      TextCellValue('Optional'),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Split metadata sheets'),
      TextCellValue(
        'Optional. If the workbook also contains "Split Records", "Split Participants", "Lent Settlements", and "Borrowed Settlements" sheets from an app export, split and borrowed-resolution relationships are restored automatically.',
      ),
    ]);
    referenceSheet.appendRow(const <CellValue?>[]);
    final typeRange = _appendReferenceList(
      referenceSheet,
      title: 'Expense Type Dropdown',
      values: expenseTypes,
    );
    final categoryRange = _appendReferenceList(
      referenceSheet,
      title: 'Category Dropdown',
      values: categories,
    );
    final bankRange = _appendReferenceList(
      referenceSheet,
      title: 'Bank Dropdown',
      values: banks.isEmpty ? const <String>[''] : banks,
    );
    final paymentModeRange = _appendReferenceList(
      referenceSheet,
      title: 'Payment Mode Dropdown',
      values: AppConstants.paymentModes,
    );
    _applyRowStyle(
      referenceSheet,
      rowIndex: 0,
      columnCount: 2,
      style: headerStyle,
    );
    _setColumnWidths(referenceSheet, <double>[24, 72]);

    final bytes = excel.save();
    if (bytes == null) {
      throw const ModuleImportException(
        'Unable to generate the expense sample Excel file.',
      );
    }

    final workbookWithDropdowns = _applyExcelDropdowns(
      Uint8List.fromList(bytes),
      rules: <_ExcelDropdownRule>[
        _ExcelDropdownRule(
          sheetName: 'Expenses',
          targetRange: 'D2:D200',
          formula: typeRange.asFormula,
        ),
        _ExcelDropdownRule(
          sheetName: 'Expenses',
          targetRange: 'E2:E200',
          formula: categoryRange.asFormula,
        ),
        if (banks.isNotEmpty)
          _ExcelDropdownRule(
            sheetName: 'Expenses',
            targetRange: 'F2:F200',
            formula: bankRange.asFormula,
          ),
        _ExcelDropdownRule(
          sheetName: 'Expenses',
          targetRange: 'H2:H200',
          formula: paymentModeRange.asFormula,
        ),
      ],
    );

    await file.writeAsBytes(workbookWithDropdowns);
    return file.path;
  }

  Future<String> downloadCredentialSampleExcel() async {
    final file = await _buildOutputFile(
      moduleFolder: 'credential',
      fileNameLabel: 'credential-import-sample',
    );
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Credentials') {
      excel.rename(defaultSheet, 'Credentials');
    }

    final credentialSheet = excel['Credentials'];
    final referenceSheet = excel['Reference'];
    final headerStyle = CellStyle(bold: true);

    credentialSheet.appendRow(<CellValue?>[
      TextCellValue('Title*'),
      TextCellValue('Expiry Date'),
      TextCellValue('Field*'),
      TextCellValue('Value*'),
    ]);
    credentialSheet.appendRow(<CellValue?>[
      TextCellValue('GitHub'),
      TextCellValue(
        DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().add(const Duration(days: 30))),
      ),
      TextCellValue('Username'),
      TextCellValue('demo_user'),
    ]);
    _applyRowStyle(
      credentialSheet,
      rowIndex: 0,
      columnCount: 4,
      style: headerStyle,
    );
    _setColumnWidths(credentialSheet, <double>[26, 18, 22, 32]);

    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Rule'),
      TextCellValue('Details'),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('One row per field'),
      TextCellValue(
        'Use the same Title on multiple rows to create one credential with many secure fields.',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Required columns'),
      TextCellValue(
        'Title, Field, and Value are required for every non-empty row. Expiry Date is optional.',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Expiry Date'),
      TextCellValue(
        'Optional. Use yyyy-MM-dd when possible. If the same Title appears on multiple rows, keep the same expiry date across those rows.',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Duplicate fields'),
      TextCellValue(
        'The same Field label cannot repeat under the same Title in one import file.',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Sample row'),
      TextCellValue(
        'Row 2 contains dummy sample data. Replace it with your real values or delete it before import.',
      ),
    ]);
    _applyRowStyle(
      referenceSheet,
      rowIndex: 0,
      columnCount: 2,
      style: headerStyle,
    );
    _setColumnWidths(referenceSheet, <double>[24, 76]);

    final bytes = excel.save();
    if (bytes == null) {
      throw const ModuleImportException(
        'Unable to generate the credential sample Excel file.',
      );
    }

    await file.writeAsBytes(Uint8List.fromList(bytes));
    return file.path;
  }

  Future<ExpenseImportPreviewData> previewExpenseExcel(String filePath) async {
    final workbook = await _loadWorkbook(filePath);
    final sheet = _resolveSheet(workbook, preferredSheetName: 'Expenses');
    final splitBundle = _parseExpenseSplitWorkbook(workbook);
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'entryId': <String>['entry id', 'entryid'],
        'title': <String>['title'],
        'amount': <String>['amount'],
        'type': <String>['type'],
        'category': <String>['category'],
        'bank': <String>['bank'],
        'date': <String>['date'],
        'day': <String>['day', 'weekday', 'day of week'],
        'paymentMode': <String>['payment mode', 'paymentmode'],
        'counterparty': <String>['counterparty'],
        'notes': <String>['notes'],
      },
      requiredKeys: const <String>[
        'title',
        'amount',
        'type',
        'category',
        'date',
        'paymentMode',
      ],
    );

    final rows = <ExpenseImportRow>[];

    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }

      try {
        final validated = _validateExpenseRow(
          row: row,
          rowNumber: rowIndex + 1,
          headerMap: headerMap,
        );
        rows.add(
          ExpenseImportRow(
            sourceEntryId: validated.sourceEntryId,
            title: validated.title,
            amount: validated.amount,
            type: validated.type,
            categoryName: validated.categoryName,
            bankName: validated.bankName,
            date: validated.date,
            day: validated.day,
            paymentMode: validated.paymentMode,
            counterparty: validated.counterparty,
            notes: validated.notes,
            isValid: true,
          ),
        );
      } on ModuleImportException catch (error) {
        final sourceEntryId = _parseOptionalInt(
          _cellAt(row, headerMap['entryId']),
        );
        final title = _cellText(_cellAt(row, headerMap['title']));
        final category = _cellText(_cellAt(row, headerMap['category']));
        final bank = _cellText(_cellAt(row, headerMap['bank']));
        final paymentModeText = _cellText(
          _cellAt(row, headerMap['paymentMode']),
        );
        final counterpartyText = _cellText(
          _cellAt(row, headerMap['counterparty']),
        );
        final notes = _cellText(_cellAt(row, headerMap['notes']));
        final dayText = _cellText(_cellAt(row, headerMap['day']));
        final amountCell = _cellAt(row, headerMap['amount']);
        final typeText = _cellText(_cellAt(row, headerMap['type']));
        final dateCell = _cellAt(row, headerMap['date']);

        final amount = _parseAmount(amountCell) ?? 0.0;
        final date = _parseDate(dateCell) ?? DateTime.now();

        rows.add(
          ExpenseImportRow(
            sourceEntryId: sourceEntryId,
            title: title.isEmpty ? 'Untitled' : title,
            amount: amount,
            type: typeText.isEmpty ? 'Expense' : typeText,
            categoryName: category.isEmpty ? 'Miscellaneous' : category,
            bankName: bank.isEmpty ? null : bank,
            date: date,
            day: dayText.isEmpty ? null : dayText,
            paymentMode: paymentModeText.isEmpty ? 'Cash' : paymentModeText,
            counterparty: counterpartyText.isEmpty ? null : counterpartyText,
            notes: notes,
            isValid: false,
            validationError: error.message,
          ),
        );
      }
    }

    return ExpenseImportPreviewData(rows: rows, splitBundle: splitBundle);
  }

  Future<ModuleImportResult> saveExpenseImport(
    List<ExpenseImportRow> validRows,
    ExpenseSplitImportBundle splitBundle,
  ) async {
    final validatedRows = validRows.map((row) {
      return _ValidatedExpenseRow(
        sourceEntryId: row.sourceEntryId,
        title: row.title,
        amount: row.amount,
        type: _normalizeExpenseType(row.type) ?? 'expense',
        categoryName: row.categoryName,
        bankName: row.bankName,
        date: row.date,
        day: row.day,
        paymentMode:
            _normalizePaymentMode(row.paymentMode) ??
            AppConstants.paymentModes.first,
        counterparty: row.counterparty,
        notes: row.notes,
      );
    }).toList();

    final normalizedExpenseImport = _normalizeExpenseImportData(
      rows: validatedRows,
      splitBundle: splitBundle,
    );

    return _database.transaction(() async {
      final existingCategories = await _database.getCategories();
      final categoryIds = <String, int>{
        for (final category in existingCategories)
          category.name.toLowerCase(): category.id,
      };
      final existingBanks = await _database.getBanks();
      final bankIds = <String, int>{
        for (final bank in existingBanks) bank.name.toLowerCase(): bank.id,
      };
      var createdCategories = 0;
      var createdBanks = 0;
      final fallbackCategory = AppConstants.defaultCategories.last;
      final importedEntryIdMap = <int, int>{};

      for (final row in normalizedExpenseImport.rows) {
        final categoryKey = row.categoryName.toLowerCase();
        if (!categoryIds.containsKey(categoryKey)) {
          final categoryId = await _database
              .into(_database.dbCategories)
              .insert(
                DbCategoriesCompanion.insert(
                  name: row.categoryName,
                  iconCodePoint: fallbackCategory.iconCodePoint,
                  colorValue: fallbackCategory.colorValue,
                ),
              );
          categoryIds[categoryKey] = categoryId;
          createdCategories += 1;
        }

        final bankName = row.bankName;
        if (bankName == null) {
          continue;
        }

        final bankKey = bankName.toLowerCase();
        if (!bankIds.containsKey(bankKey)) {
          final bankId = await _database
              .into(_database.dbBanks)
              .insert(DbBanksCompanion.insert(name: bankName));
          bankIds[bankKey] = bankId;
          createdBanks += 1;
        }
      }

      for (final row in normalizedExpenseImport.rows) {
        final insertedId = await _database
            .into(_database.dbFinanceEntries)
            .insert(
              DbFinanceEntriesCompanion.insert(
                title: row.title,
                amount: row.amount,
                type: row.type,
                categoryId: categoryIds[row.categoryName.toLowerCase()]!,
                bankId: Value(
                  row.bankName == null
                      ? null
                      : bankIds[row.bankName!.toLowerCase()],
                ),
                entryDate: row.date,
                entryDay: Value(row.day ?? _dayLabelForDate(row.date)),
                paymentMode: row.paymentMode,
                notes: Value(row.notes),
                counterparty: Value(row.counterparty),
              ),
            );
        if (row.sourceEntryId != null) {
          importedEntryIdMap[row.sourceEntryId!] = insertedId;
        }
      }

      if (normalizedExpenseImport.splitBundle.hasData) {
        await _importExpenseSplitBundle(
          normalizedExpenseImport.splitBundle,
          entryIdMap: importedEntryIdMap,
        );
      }

      final messageBuffer = StringBuffer(
        '${normalizedExpenseImport.rows.length} expense row${normalizedExpenseImport.rows.length == 1 ? '' : 's'} imported successfully.',
      );
      if (createdCategories > 0 || createdBanks > 0) {
        messageBuffer.write(' Added ');
        final additions = <String>[];
        if (createdCategories > 0) {
          additions.add(
            '$createdCategories categor${createdCategories == 1 ? 'y' : 'ies'}',
          );
        }
        if (createdBanks > 0) {
          additions.add('$createdBanks bank${createdBanks == 1 ? '' : 's'}');
        }
        messageBuffer.write(additions.join(' and '));
        messageBuffer.write('.');
      }

      return ModuleImportResult(
        savedItems: normalizedExpenseImport.rows.length,
        validatedRows: validRows.length,
        message: messageBuffer.toString(),
      );
    });
  }

  Future<ModuleImportResult> importExpenseExcel(String filePath) async {
    final preview = await previewExpenseExcel(filePath);
    final errors = preview.rows
        .where((r) => !r.isValid)
        .map((r) => r.validationError ?? 'Invalid row')
        .toList();
    if (errors.isNotEmpty) {
      throw ModuleImportException(
        'Expense import failed because some rows are invalid.',
        errors,
      );
    }
    return saveExpenseImport(preview.rows, preview.splitBundle);
  }

  Future<CredentialImportPreviewData> previewCredentialExcel(
    String filePath,
  ) async {
    final workbook = await _loadWorkbook(filePath);
    final sheet = _resolveSheet(workbook, preferredSheetName: 'Credentials');
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'title': <String>['title'],
        'expiryDate': <String>[
          'expiry',
          'expiry date',
          'expirydate',
          'expiration date',
          'expirationdate',
        ],
        'field': <String>['field'],
        'value': <String>['value'],
      },
      requiredKeys: const <String>['title', 'field', 'value'],
    );

    final rows = <CredentialImportRow>[];
    final groupedFields = <String, List<String>>{};
    final groupedExpiryDates = <String, DateTime?>{};

    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }

      final title = _cellText(_cellAt(row, headerMap['title']));
      final expiryCell = _cellAt(row, headerMap['expiryDate']);
      final expiryText = _cellText(expiryCell);
      final field = _cellText(_cellAt(row, headerMap['field']));
      final value = _cellText(_cellAt(row, headerMap['value']));
      final rowErrors = <String>[];

      if (title.isEmpty) {
        rowErrors.add('Title is required.');
      }
      if (field.isEmpty) {
        rowErrors.add('Field is required.');
      }
      if (value.isEmpty) {
        rowErrors.add('Value is required.');
      }
      final parsedExpiryDate = expiryText.isEmpty
          ? null
          : _parseDate(expiryCell);
      if (expiryText.isNotEmpty && parsedExpiryDate == null) {
        rowErrors.add(
          'Expiry Date must be a valid Excel date or text date like yyyy-MM-dd.',
        );
      }

      final groupKey = title.toLowerCase();

      if (rowErrors.isEmpty) {
        final existingFields = groupedFields.putIfAbsent(
          groupKey,
          () => <String>[],
        );
        final existingExpiryDate = groupedExpiryDates[groupKey];

        if (parsedExpiryDate != null) {
          if (existingExpiryDate != null &&
              !_isSameDate(existingExpiryDate, parsedExpiryDate)) {
            rowErrors.add(
              'Expiry Date does not match other rows for credential "$title".',
            );
          } else {
            groupedExpiryDates[groupKey] = parsedExpiryDate;
          }
        } else {
          groupedExpiryDates.putIfAbsent(groupKey, () => null);
        }

        final hasDuplicateField = existingFields.any(
          (f) => f.toLowerCase() == field.toLowerCase(),
        );
        if (hasDuplicateField) {
          rowErrors.add(
            'Field "$field" is duplicated for credential "$title".',
          );
        } else {
          existingFields.add(field);
        }
      }

      final isValid = rowErrors.isEmpty;
      rows.add(
        CredentialImportRow(
          title: title.isEmpty ? 'Untitled' : title,
          expiryDate: parsedExpiryDate,
          field: field.isEmpty ? 'Username' : field,
          value: value,
          isValid: isValid,
          validationError: isValid ? null : rowErrors.join(' '),
        ),
      );
    }

    return CredentialImportPreviewData(rows: rows);
  }

  Future<ModuleImportResult> saveCredentialImport(
    List<CredentialImportRow> validRows, {
    required String encryptionKey,
  }) async {
    if (encryptionKey.trim().isEmpty) {
      throw const ModuleImportException('A valid encryption key is required.');
    }

    final groupedFields = <String, List<CredentialField>>{};
    final groupedExpiryDates = <String, DateTime?>{};
    final titleByGroup = <String, String>{};

    for (final row in validRows) {
      if (!row.isValid) continue;

      final groupKey = row.title.toLowerCase();
      final existingFields = groupedFields.putIfAbsent(
        groupKey,
        () => <CredentialField>[],
      );
      titleByGroup.putIfAbsent(groupKey, () => row.title);

      if (row.expiryDate != null) {
        groupedExpiryDates[groupKey] = row.expiryDate;
      } else {
        groupedExpiryDates.putIfAbsent(groupKey, () => null);
      }

      existingFields.add(
        CredentialField(keyLabel: row.field, value: row.value),
      );
    }

    final drafts = groupedFields.entries
        .map(
          (entry) => CredentialDraft(
            title: titleByGroup[entry.key]!,
            fields: List<CredentialField>.from(entry.value),
            expiryDate: groupedExpiryDates[entry.key],
          ),
        )
        .toList(growable: false);

    final payloads = <_PreparedCredentialImport>[];
    for (final draft in drafts) {
      final payload = await _credentialCryptoService.encryptFields(
        fields: _withCredentialMetadataFields(draft),
        encryptionKey: encryptionKey.trim(),
      );
      payloads.add(_PreparedCredentialImport(draft: draft, payload: payload));
    }

    await _database.transaction(() async {
      final now = DateTime.now();
      for (final item in payloads) {
        await _database
            .into(_database.dbCredentials)
            .insert(
              DbCredentialsCompanion.insert(
                title: item.draft.title,
                encryptedPayload: item.payload.encryptedPayload,
                saltBase64: item.payload.saltBase64,
                nonceBase64: item.payload.nonceBase64,
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    });

    _notificationService.requestCredentialExpiryNotificationSync();

    return ModuleImportResult(
      savedItems: drafts.length,
      validatedRows: validRows.length,
      message:
          '${drafts.length} credential${drafts.length == 1 ? '' : 's'} imported successfully.',
    );
  }

  Future<ModuleImportResult> importCredentialExcel(
    String filePath, {
    required String encryptionKey,
  }) async {
    final preview = await previewCredentialExcel(filePath);
    final errors = preview.rows
        .where((r) => !r.isValid)
        .map((r) => r.validationError ?? 'Invalid row')
        .toList();
    if (errors.isNotEmpty) {
      throw ModuleImportException(
        'Credential import failed because some rows are invalid.',
        errors,
      );
    }
    return saveCredentialImport(preview.rows, encryptionKey: encryptionKey);
  }

  _ValidatedExpenseRow _validateExpenseRow({
    required List<Data?> row,
    required int rowNumber,
    required Map<String, int> headerMap,
  }) {
    final sourceEntryId = _parseOptionalInt(_cellAt(row, headerMap['entryId']));
    final title = _cellText(_cellAt(row, headerMap['title']));
    final category = _cellText(_cellAt(row, headerMap['category']));
    final bank = _cellText(_cellAt(row, headerMap['bank']));
    final paymentModeText = _cellText(_cellAt(row, headerMap['paymentMode']));
    final counterpartyText = _cellText(_cellAt(row, headerMap['counterparty']));
    final notes = _cellText(_cellAt(row, headerMap['notes']));
    final dayText = _cellText(_cellAt(row, headerMap['day']));
    final amountCell = _cellAt(row, headerMap['amount']);
    final typeText = _cellText(_cellAt(row, headerMap['type']));
    final dateCell = _cellAt(row, headerMap['date']);
    final rowErrors = <String>[];

    if (title.isEmpty) {
      rowErrors.add('Title is required.');
    }

    final amount = _parseAmount(amountCell);
    if (amount == null || amount <= 0) {
      rowErrors.add('Amount must be a valid number greater than 0.');
    }

    final type = _normalizeExpenseType(typeText);
    if (type == null) {
      rowErrors.add('Type must be Expense, Income, Borrowed, or Lent.');
    }

    if (category.isEmpty) {
      rowErrors.add('Category is required.');
    }

    final date = _parseDate(dateCell);
    if (date == null) {
      rowErrors.add(
        'Date must be a valid Excel date or text date like yyyy-MM-dd.',
      );
    }

    final paymentMode = _normalizePaymentMode(paymentModeText);
    if (paymentMode == null) {
      rowErrors.add(
        'Payment Mode must be one of: ${AppConstants.paymentModes.join(', ')}.',
      );
    }

    if (rowErrors.isNotEmpty) {
      throw ModuleImportException(
        'Expense row $rowNumber is invalid.',
        <String>['Row $rowNumber: ${rowErrors.join(' ')}'],
      );
    }

    return _ValidatedExpenseRow(
      sourceEntryId: sourceEntryId,
      title: title,
      amount: amount!,
      type: type!,
      categoryName: category,
      bankName: bank.isEmpty ? null : bank,
      date: date!,
      day: dayText.isEmpty ? null : dayText,
      paymentMode: paymentMode!,
      counterparty: counterpartyText.isEmpty ? null : counterpartyText,
      notes: notes,
    );
  }

  ExpenseSplitImportBundle _parseExpenseSplitWorkbook(Excel workbook) {
    final splitRecordsSheet = workbook.tables['Split Records'];
    final splitParticipantsSheet = workbook.tables['Split Participants'];
    final settlementsSheet = workbook.tables['Lent Settlements'];
    final borrowedSettlementsSheet = workbook.tables['Borrowed Settlements'];

    final splitRecords = splitRecordsSheet == null
        ? const <ImportedSplitRecord>[]
        : _parseSplitRecordSheet(splitRecordsSheet);
    final splitParticipants = splitParticipantsSheet == null
        ? const <ImportedSplitParticipant>[]
        : _parseSplitParticipantSheet(splitParticipantsSheet);
    final settlements = settlementsSheet == null
        ? const <ImportedLentSettlement>[]
        : _parseLentSettlementSheet(settlementsSheet);
    final borrowedSettlements = borrowedSettlementsSheet == null
        ? const <ImportedBorrowedSettlement>[]
        : _parseBorrowedSettlementSheet(borrowedSettlementsSheet);

    return ExpenseSplitImportBundle(
      splitRecords: splitRecords,
      splitParticipants: splitParticipants,
      settlements: settlements,
      borrowedSettlements: borrowedSettlements,
    );
  }

  List<ImportedSplitRecord> _parseSplitRecordSheet(Sheet sheet) {
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'splitRecordId': <String>['split record id', 'splitrecordid'],
        'expenseEntryId': <String>['expense entry id', 'expenseentryid'],
        'lentEntryId': <String>['lent entry id', 'lententryid'],
        'totalAmount': <String>['total amount', 'totalamount'],
        'createdAt': <String>['created at', 'createdat'],
      },
      requiredKeys: const <String>['splitRecordId', 'totalAmount'],
    );

    final rows = <ImportedSplitRecord>[];
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }
      final sourceId = _parseOptionalInt(
        _cellAt(row, headerMap['splitRecordId']),
      );
      final totalAmount = _parseAmount(_cellAt(row, headerMap['totalAmount']));
      if (sourceId == null || totalAmount == null) {
        throw ModuleImportException(
          'The Split Records sheet contains invalid data.',
          <String>[
            'Row ${rowIndex + 1}: Split Record ID and Total Amount are required.',
          ],
        );
      }
      rows.add(
        ImportedSplitRecord(
          sourceId: sourceId,
          sourceExpenseEntryId: _parseOptionalInt(
            _cellAt(row, headerMap['expenseEntryId']),
          ),
          sourceLentEntryId: _parseOptionalInt(
            _cellAt(row, headerMap['lentEntryId']),
          ),
          totalAmount: totalAmount,
          createdAt:
              DateTime.tryParse(
                _cellText(_cellAt(row, headerMap['createdAt'])),
              ) ??
              DateTime.now(),
        ),
      );
    }
    return rows;
  }

  List<ImportedSplitParticipant> _parseSplitParticipantSheet(Sheet sheet) {
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'participantId': <String>['participant id', 'participantid'],
        'splitRecordId': <String>['split record id', 'splitrecordid'],
        'participantName': <String>['participant name', 'participantname'],
        'amount': <String>['amount'],
        'percentage': <String>['percentage'],
        'isSelf': <String>['is self', 'isself'],
        'settledAmount': <String>['settled amount', 'settledamount'],
        'sortOrder': <String>['sort order', 'sortorder'],
        'createdAt': <String>['created at', 'createdat'],
      },
      requiredKeys: const <String>[
        'participantId',
        'splitRecordId',
        'participantName',
        'amount',
        'percentage',
      ],
    );

    final rows = <ImportedSplitParticipant>[];
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }
      final sourceId = _parseOptionalInt(
        _cellAt(row, headerMap['participantId']),
      );
      final sourceSplitRecordId = _parseOptionalInt(
        _cellAt(row, headerMap['splitRecordId']),
      );
      final participantName = _cellText(
        _cellAt(row, headerMap['participantName']),
      );
      final amount = _parseAmount(_cellAt(row, headerMap['amount']));
      final percentage = _parseAmount(_cellAt(row, headerMap['percentage']));
      if (sourceId == null ||
          sourceSplitRecordId == null ||
          participantName.isEmpty ||
          amount == null ||
          percentage == null) {
        throw ModuleImportException(
          'The Split Participants sheet contains invalid data.',
          <String>[
            'Row ${rowIndex + 1}: Participant ID, Split Record ID, Participant Name, Amount, and Percentage are required.',
          ],
        );
      }
      rows.add(
        ImportedSplitParticipant(
          sourceId: sourceId,
          sourceSplitRecordId: sourceSplitRecordId,
          participantName: participantName,
          amount: amount,
          percentage: percentage,
          isSelf: _parseBool(_cellAt(row, headerMap['isSelf'])),
          settledAmount:
              _parseAmount(_cellAt(row, headerMap['settledAmount'])) ?? 0,
          sortOrder:
              _parseOptionalInt(_cellAt(row, headerMap['sortOrder'])) ?? 0,
          createdAt:
              DateTime.tryParse(
                _cellText(_cellAt(row, headerMap['createdAt'])),
              ) ??
              DateTime.now(),
        ),
      );
    }
    return rows;
  }

  List<ImportedLentSettlement> _parseLentSettlementSheet(Sheet sheet) {
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'settlementId': <String>['settlement id', 'settlementid'],
        'splitRecordId': <String>['split record id', 'splitrecordid'],
        'splitParticipantId': <String>[
          'split participant id',
          'splitparticipantid',
        ],
        'incomeEntryId': <String>['income entry id', 'incomeentryid'],
        'settledAmount': <String>['settled amount', 'settledamount'],
        'createdAt': <String>['created at', 'createdat'],
      },
      requiredKeys: const <String>[
        'settlementId',
        'splitRecordId',
        'splitParticipantId',
        'incomeEntryId',
        'settledAmount',
      ],
    );

    final rows = <ImportedLentSettlement>[];
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }
      final sourceId = _parseOptionalInt(
        _cellAt(row, headerMap['settlementId']),
      );
      final sourceSplitRecordId = _parseOptionalInt(
        _cellAt(row, headerMap['splitRecordId']),
      );
      final sourceSplitParticipantId = _parseOptionalInt(
        _cellAt(row, headerMap['splitParticipantId']),
      );
      final sourceIncomeEntryId = _parseOptionalInt(
        _cellAt(row, headerMap['incomeEntryId']),
      );
      final settledAmount = _parseAmount(
        _cellAt(row, headerMap['settledAmount']),
      );
      if (sourceId == null ||
          sourceSplitRecordId == null ||
          sourceSplitParticipantId == null ||
          sourceIncomeEntryId == null ||
          settledAmount == null) {
        throw ModuleImportException(
          'The Lent Settlements sheet contains invalid data.',
          <String>[
            'Row ${rowIndex + 1}: Settlement ID, Split Record ID, Split Participant ID, Income Entry ID, and Settled Amount are required.',
          ],
        );
      }
      rows.add(
        ImportedLentSettlement(
          sourceId: sourceId,
          sourceSplitRecordId: sourceSplitRecordId,
          sourceSplitParticipantId: sourceSplitParticipantId,
          sourceIncomeEntryId: sourceIncomeEntryId,
          settledAmount: settledAmount,
          createdAt:
              DateTime.tryParse(
                _cellText(_cellAt(row, headerMap['createdAt'])),
              ) ??
              DateTime.now(),
        ),
      );
    }
    return rows;
  }

  List<ImportedBorrowedSettlement> _parseBorrowedSettlementSheet(Sheet sheet) {
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'settlementId': <String>['settlement id', 'settlementid'],
        'borrowedEntryId': <String>['borrowed entry id', 'borrowedentryid'],
        'expenseEntryId': <String>['expense entry id', 'expenseentryid'],
        'settledAmount': <String>['settled amount', 'settledamount'],
        'createdAt': <String>['created at', 'createdat'],
      },
      requiredKeys: const <String>[
        'settlementId',
        'borrowedEntryId',
        'expenseEntryId',
        'settledAmount',
      ],
    );

    final rows = <ImportedBorrowedSettlement>[];
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }
      final sourceId = _parseOptionalInt(
        _cellAt(row, headerMap['settlementId']),
      );
      final sourceBorrowedEntryId = _parseOptionalInt(
        _cellAt(row, headerMap['borrowedEntryId']),
      );
      final sourceExpenseEntryId = _parseOptionalInt(
        _cellAt(row, headerMap['expenseEntryId']),
      );
      final settledAmount = _parseAmount(
        _cellAt(row, headerMap['settledAmount']),
      );
      if (sourceId == null ||
          sourceBorrowedEntryId == null ||
          sourceExpenseEntryId == null ||
          settledAmount == null) {
        throw ModuleImportException(
          'The Borrowed Settlements sheet contains invalid data.',
          <String>[
            'Row ${rowIndex + 1}: Settlement ID, Borrowed Entry ID, Expense Entry ID, and Settled Amount are required.',
          ],
        );
      }
      rows.add(
        ImportedBorrowedSettlement(
          sourceId: sourceId,
          sourceBorrowedEntryId: sourceBorrowedEntryId,
          sourceExpenseEntryId: sourceExpenseEntryId,
          settledAmount: settledAmount,
          createdAt:
              DateTime.tryParse(
                _cellText(_cellAt(row, headerMap['createdAt'])),
              ) ??
              DateTime.now(),
        ),
      );
    }
    return rows;
  }

  Future<void> _importExpenseSplitBundle(
    ExpenseSplitImportBundle bundle, {
    required Map<int, int> entryIdMap,
  }) async {
    final splitRecordIdMap = <int, int>{};
    final splitParticipantIdMap = <int, int>{};

    for (final record in bundle.splitRecords) {
      final expenseEntryId = record.sourceExpenseEntryId == null
          ? null
          : entryIdMap[record.sourceExpenseEntryId!];
      final lentEntryId = record.sourceLentEntryId == null
          ? null
          : entryIdMap[record.sourceLentEntryId!];
      final insertedId = await _database
          .into(_database.dbSplitRecords)
          .insert(
            DbSplitRecordsCompanion.insert(
              expenseEntryId: Value(expenseEntryId),
              lentEntryId: Value(lentEntryId),
              totalAmount: record.totalAmount,
              createdAt: Value(record.createdAt),
            ),
          );
      splitRecordIdMap[record.sourceId] = insertedId;
    }

    for (final participant in bundle.splitParticipants) {
      final splitRecordId = splitRecordIdMap[participant.sourceSplitRecordId];
      if (splitRecordId == null) {
        throw ModuleImportException(
          'Split participant import failed because split records are missing.',
          <String>[
            'Participant ${participant.sourceId} references missing Split Record ID ${participant.sourceSplitRecordId}.',
          ],
        );
      }
      final insertedId = await _database
          .into(_database.dbSplitParticipants)
          .insert(
            DbSplitParticipantsCompanion.insert(
              splitRecordId: splitRecordId,
              participantName: participant.participantName,
              amount: participant.amount,
              percentage: participant.percentage,
              isSelf: Value(participant.isSelf),
              settledAmount: Value(participant.settledAmount),
              sortOrder: Value(participant.sortOrder),
              createdAt: Value(participant.createdAt),
            ),
          );
      splitParticipantIdMap[participant.sourceId] = insertedId;
    }

    for (final settlement in bundle.settlements) {
      final splitRecordId = splitRecordIdMap[settlement.sourceSplitRecordId];
      final splitParticipantId =
          splitParticipantIdMap[settlement.sourceSplitParticipantId];
      final incomeEntryId = entryIdMap[settlement.sourceIncomeEntryId];
      if (splitRecordId == null ||
          splitParticipantId == null ||
          incomeEntryId == null) {
        throw ModuleImportException(
          'Lent settlement import failed because linked records are missing.',
          <String>[
            'Settlement ${settlement.sourceId} references a missing split record, participant, or income entry.',
          ],
        );
      }
      await _database
          .into(_database.dbLentSettlements)
          .insert(
            DbLentSettlementsCompanion.insert(
              splitRecordId: splitRecordId,
              splitParticipantId: splitParticipantId,
              incomeEntryId: incomeEntryId,
              settledAmount: settlement.settledAmount,
              createdAt: Value(settlement.createdAt),
            ),
          );
    }

    for (final settlement in bundle.borrowedSettlements) {
      final borrowedEntryId = entryIdMap[settlement.sourceBorrowedEntryId];
      final expenseEntryId = entryIdMap[settlement.sourceExpenseEntryId];
      if (borrowedEntryId == null || expenseEntryId == null) {
        throw ModuleImportException(
          'Borrowed settlement import failed because linked entries are missing.',
          <String>[
            'Settlement ${settlement.sourceId} references a missing borrowed or expense entry.',
          ],
        );
      }
      await _database
          .into(_database.dbBorrowedSettlements)
          .insert(
            DbBorrowedSettlementsCompanion.insert(
              borrowedEntryId: borrowedEntryId,
              expenseEntryId: expenseEntryId,
              settledAmount: settlement.settledAmount,
              createdAt: Value(settlement.createdAt),
            ),
          );
    }
  }

  _NormalizedExpenseImportData _normalizeExpenseImportData({
    required List<_ValidatedExpenseRow> rows,
    required ExpenseSplitImportBundle splitBundle,
  }) {
    if (!splitBundle.hasData) {
      return _NormalizedExpenseImportData(rows: rows, splitBundle: splitBundle);
    }

    final legacyManagedLentEntryIds = splitBundle.splitRecords
        .where(
          (record) =>
              record.sourceExpenseEntryId != null &&
              record.sourceLentEntryId != null,
        )
        .map((record) => record.sourceLentEntryId)
        .whereType<int>()
        .toSet();
    final totalAmountByExpenseEntryId = <int, double>{
      for (final record in splitBundle.splitRecords)
        if (record.sourceExpenseEntryId != null)
          record.sourceExpenseEntryId!: record.totalAmount,
    };

    final normalizedRows = rows
        .where(
          (row) =>
              row.sourceEntryId == null ||
              !legacyManagedLentEntryIds.contains(row.sourceEntryId),
        )
        .map((row) {
          final sourceEntryId = row.sourceEntryId;
          if (sourceEntryId != null &&
              totalAmountByExpenseEntryId.containsKey(sourceEntryId)) {
            return row.copyWith(
              amount: totalAmountByExpenseEntryId[sourceEntryId]!,
            );
          }
          return row;
        })
        .toList(growable: false);

    final normalizedBundle = ExpenseSplitImportBundle(
      splitRecords: splitBundle.splitRecords
          .map(
            (record) => record.copyWith(
              sourceLentEntryId: record.sourceExpenseEntryId != null
                  ? null
                  : record.sourceLentEntryId,
            ),
          )
          .toList(growable: false),
      splitParticipants: splitBundle.splitParticipants,
      settlements: splitBundle.settlements,
      borrowedSettlements: splitBundle.borrowedSettlements,
    );

    return _NormalizedExpenseImportData(
      rows: normalizedRows,
      splitBundle: normalizedBundle,
    );
  }

  Future<Excel> _loadWorkbook(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const ModuleImportException(
        'The selected Excel file could not be found.',
      );
    }

    try {
      return Excel.decodeBytes(await file.readAsBytes());
    } catch (_) {
      throw const ModuleImportException(
        'Unable to read the selected Excel file. Only .xlsx files are supported.',
      );
    }
  }

  Sheet _resolveSheet(Excel workbook, {required String preferredSheetName}) {
    final sheets = workbook.tables;
    final preferredSheet = sheets[preferredSheetName];
    if (preferredSheet != null) {
      return preferredSheet;
    }

    final lowerPreferred = preferredSheetName.toLowerCase();
    final alternativeKeys = <String>[lowerPreferred];
    if (lowerPreferred == 'expenses') {
      alternativeKeys.addAll(['entries', 'expense']);
    } else if (lowerPreferred == 'credentials') {
      alternativeKeys.addAll(['credential', 'creds']);
    } else if (lowerPreferred == 'investments') {
      alternativeKeys.addAll(['investment', 'entries']);
    } else if (lowerPreferred == 'tasks') {
      alternativeKeys.addAll(['task', 'checklist', 'todos']);
    }

    for (final key in sheets.keys) {
      final lowerKey = key.toLowerCase();
      if (alternativeKeys.contains(lowerKey)) {
        return sheets[key]!;
      }
    }

    if (sheets.isEmpty) {
      throw const ModuleImportException(
        'The selected Excel file has no sheets.',
      );
    }
    return sheets.values.first;
  }

  Map<String, int> _resolveHeaderMap({
    required List<Data?> headerRow,
    required Map<String, List<String>> aliases,
    required List<String> requiredKeys,
  }) {
    final normalizedHeaders = <String, int>{};
    for (var index = 0; index < headerRow.length; index++) {
      final header = _normalizeHeader(_cellText(headerRow[index]));
      if (header.isNotEmpty) {
        normalizedHeaders[header] = index;
      }
    }

    final resolved = <String, int>{};
    final missing = <String>[];

    aliases.forEach((key, values) {
      for (final alias in values) {
        final index = normalizedHeaders[_normalizeHeader(alias)];
        if (index != null) {
          resolved[key] = index;
          break;
        }
      }
      if (requiredKeys.contains(key) && !resolved.containsKey(key)) {
        missing.add(values.first);
      }
    });

    if (missing.isNotEmpty) {
      throw ModuleImportException(
        'The Excel file is missing required columns.',
        <String>[
          'Missing column${missing.length == 1 ? '' : 's'}: ${missing.join(', ')}.',
        ],
      );
    }

    return resolved;
  }

  bool _isBlankRow(List<Data?> row, Iterable<int> relevantColumns) {
    return relevantColumns.every(
      (columnIndex) => _cellText(_cellAt(row, columnIndex)).isEmpty,
    );
  }

  Data? _cellAt(List<Data?> row, int? index) {
    if (index == null || index < 0 || index >= row.length) {
      return null;
    }
    return row[index];
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    switch (value) {
      case TextCellValue value:
        return value.value.toString().trim();
      case IntCellValue value:
        return value.value.toString().trim();
      case DoubleCellValue value:
        return _stripTrailingZeros(value.value).trim();
      case BoolCellValue value:
        return value.value.toString().trim();
      case DateCellValue value:
        return DateFormat('yyyy-MM-dd').format(value.asDateTimeLocal()).trim();
      case DateTimeCellValue value:
        return DateFormat('yyyy-MM-dd').format(value.asDateTimeLocal()).trim();
      case TimeCellValue value:
        return value.toString().trim();
      case FormulaCellValue value:
        return value.formula.trim();
      case null:
        return '';
    }
  }

  double? _parseAmount(Data? cell) {
    final value = cell?.value;
    switch (value) {
      case IntCellValue value:
        return value.value.toDouble();
      case DoubleCellValue value:
        return value.value;
      default:
        final text = _cellText(cell).replaceAll(',', '').replaceAll('%', '');
        return double.tryParse(text);
    }
  }

  int? _parseOptionalInt(Data? cell) {
    final value = _parseAmount(cell);
    if (value == null) {
      return null;
    }
    return value.round();
  }

  bool _parseBool(Data? cell) {
    final text = _cellText(cell).trim().toLowerCase();
    return text == 'yes' || text == 'true' || text == '1';
  }

  DateTime? _parseDate(Data? cell) {
    final value = cell?.value;
    switch (value) {
      case DateCellValue value:
        final date = value.asDateTimeLocal();
        return DateTime(date.year, date.month, date.day);
      case DateTimeCellValue value:
        final date = value.asDateTimeLocal();
        return DateTime(date.year, date.month, date.day);
      default:
        final text = _cellText(cell);
        if (text.isEmpty) {
          return null;
        }

        final direct = DateTime.tryParse(text);
        if (direct != null) {
          return DateTime(direct.year, direct.month, direct.day);
        }

        const formats = <String>[
          'yyyy-MM-dd',
          'dd-MM-yyyy',
          'dd/MM/yyyy',
          'MM/dd/yyyy',
          'dd MMM yyyy',
          'dd MMMM yyyy',
        ];

        for (final format in formats) {
          try {
            final parsed = DateFormat(format).parseStrict(text);
            return DateTime(parsed.year, parsed.month, parsed.day);
          } catch (_) {
            continue;
          }
        }

        return null;
    }
  }

  String? _normalizeExpenseType(String value) {
    return switch (value.trim().toLowerCase()) {
      'expense' => 'expense',
      'income' => 'income',
      'borrowed' => 'borrowed',
      'lent' => 'lent',
      _ => null,
    };
  }

  String? _normalizePaymentMode(String value) {
    final normalized = value.trim().toLowerCase();
    for (final paymentMode in AppConstants.paymentModes) {
      if (paymentMode.toLowerCase() == normalized) {
        return paymentMode;
      }
    }
    return null;
  }

  String _normalizeHeader(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String _stripTrailingZeros(double value) {
    final text = value.toString();
    if (!text.contains('.')) {
      return text;
    }
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<List<String>> _loadExpenseSampleCategories() async {
    final existing = await _database.getCategories();
    final names = <String>{
      ...AppConstants.defaultCategories.map((category) => category.name),
      ...existing.map((category) => category.name),
    };
    return names.toList(growable: false)..sort();
  }

  Future<List<String>> _loadExpenseSampleBanks() async {
    final existing = await _database.getBanks();
    final names =
        existing.map((bank) => bank.name).toSet().toList(growable: false)
          ..sort();
    return names;
  }

  _ExcelReferenceRange _appendReferenceList(
    Sheet sheet, {
    required String title,
    required List<String> values,
  }) {
    final startRowIndex = sheet.maxRows;
    sheet.appendRow(<CellValue?>[TextCellValue(title)]);
    for (final value in values) {
      sheet.appendRow(<CellValue?>[TextCellValue(value)]);
    }
    final firstValueRow = startRowIndex + 2;
    final lastValueRow = startRowIndex + values.length + 1;
    return _ExcelReferenceRange(
      sheetName: sheet.sheetName,
      startCell: '\$A\$$firstValueRow',
      endCell: '\$A\$$lastValueRow',
    );
  }

  Uint8List _applyExcelDropdowns(
    Uint8List workbookBytes, {
    required List<_ExcelDropdownRule> rules,
  }) {
    final archive = ZipDecoder().decodeBytes(workbookBytes);
    final workbookFile = archive.findFile('xl/workbook.xml');
    final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
    if (workbookFile == null || relsFile == null) {
      return workbookBytes;
    }

    final workbookDocument = XmlDocument.parse(
      utf8.decode(workbookFile.content as List<int>),
    );
    final relsDocument = XmlDocument.parse(
      utf8.decode(relsFile.content as List<int>),
    );
    final worksheetPathsBySheetName = _resolveWorksheetPaths(
      workbookDocument,
      relsDocument,
    );

    for (final rule in rules) {
      final worksheetPath = worksheetPathsBySheetName[rule.sheetName];
      if (worksheetPath == null) {
        continue;
      }
      final worksheetFile = archive.findFile(worksheetPath);
      if (worksheetFile == null) {
        continue;
      }

      final worksheetDocument = XmlDocument.parse(
        utf8.decode(worksheetFile.content as List<int>),
      );
      final root = worksheetDocument.rootElement;
      final existingNode = root.findElements('dataValidations').isEmpty
          ? null
          : root.findElements('dataValidations').first;
      final validationsNode =
          existingNode ??
          XmlElement(XmlName('dataValidations'), <XmlAttribute>[], <XmlNode>[]);

      if (existingNode == null) {
        root.children.add(validationsNode);
      }

      validationsNode.children.add(
        XmlElement(
          XmlName('dataValidation'),
          <XmlAttribute>[
            XmlAttribute(XmlName('type'), 'list'),
            XmlAttribute(XmlName('allowBlank'), '1'),
            XmlAttribute(XmlName('showErrorMessage'), '1'),
            XmlAttribute(XmlName('sqref'), rule.targetRange),
          ],
          <XmlNode>[
            XmlElement(XmlName('formula1'), <XmlAttribute>[], <XmlNode>[
              XmlText(rule.formula),
            ]),
          ],
        ),
      );

      validationsNode.setAttribute(
        'count',
        validationsNode.findElements('dataValidation').length.toString(),
      );
      final content = utf8.encode(worksheetDocument.toXmlString(pretty: false));
      _replaceArchiveFile(archive, worksheetPath, content);
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      return workbookBytes;
    }
    return Uint8List.fromList(encoded);
  }

  Map<String, String> _resolveWorksheetPaths(
    XmlDocument workbookDocument,
    XmlDocument relsDocument,
  ) {
    final relationshipTargets = <String, String>{};
    for (final relation in relsDocument.findAllElements('Relationship')) {
      final id = relation.getAttribute('Id');
      final target = relation.getAttribute('Target');
      if (id == null || target == null) {
        continue;
      }
      relationshipTargets[id] = target.startsWith('/')
          ? target.substring(1)
          : target.startsWith('xl/')
          ? target
          : 'xl/$target';
    }

    final paths = <String, String>{};
    for (final sheet in workbookDocument.findAllElements('sheet')) {
      final name = sheet.getAttribute('name');
      final relationId =
          sheet.getAttribute(
            'id',
            namespace:
                'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
          ) ??
          sheet.getAttribute('r:id');
      if (name == null || relationId == null) {
        continue;
      }
      final target = relationshipTargets[relationId];
      if (target != null) {
        paths[name] = target;
      }
    }
    return paths;
  }

  void _replaceArchiveFile(Archive archive, String path, List<int> content) {
    final existingFile = archive.findFile(path);
    if (existingFile != null) {
      archive.removeFile(existingFile);
    }
    archive.addFile(ArchiveFile(path, content.length, content));
  }

  void _setColumnWidths(Sheet sheet, List<double> widths) {
    for (var index = 0; index < widths.length; index++) {
      sheet.setColumnWidth(index, widths[index]);
    }
  }

  void _applyRowStyle(
    Sheet sheet, {
    required int rowIndex,
    required int columnCount,
    required CellStyle style,
  }) {
    for (var columnIndex = 0; columnIndex < columnCount; columnIndex++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: columnIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle =
          style;
    }
  }

  Future<File> _buildOutputFile({
    required String moduleFolder,
    required String fileNameLabel,
  }) async {
    final settings = await _appSettingsRepository.getSettings();
    final baseDirectory = settings.exportDirectoryPath == null
        ? Directory(
            path.join(
              (await getApplicationDocumentsDirectory()).path,
              'exports',
            ),
          )
        : Directory(settings.exportDirectoryPath!);
    final outputDirectory = Directory(
      path.join(baseDirectory.path, moduleFolder),
    );
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final dateLabel = AppConstants.exportFileDateFormat.format(DateTime.now());
    var suffix = 1;
    var fileName = '$dateLabel-$fileNameLabel.xlsx';
    var file = File(path.join(outputDirectory.path, fileName));

    while (await file.exists()) {
      suffix += 1;
      fileName = '$dateLabel-$fileNameLabel-$suffix.xlsx';
      file = File(path.join(outputDirectory.path, fileName));
    }

    return file;
  }

  List<CredentialField> _withCredentialMetadataFields(CredentialDraft draft) {
    return withCredentialExpiryMetadataFields(
      fields: draft.fields,
      expiryDate: draft.expiryDate,
    );
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _dayLabelForDate(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  Future<String> downloadInvestmentSampleExcel() async {
    final file = await _buildOutputFile(
      moduleFolder: 'investment',
      fileNameLabel: 'investment-import-sample',
    );
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Investments') {
      excel.rename(defaultSheet, 'Investments');
    }

    final sheet = excel['Investments'];
    final headerStyle = CellStyle(bold: true);

    sheet.appendRow(<CellValue?>[
      TextCellValue(
        'Do not fill: Days, P/L, P/L%, Tax, PAT, PAT% — these are calculated by the app',
      ),
    ]);

    sheet.appendRow(<CellValue?>[
      TextCellValue('Category'),
      TextCellValue('Symbol*'),
      TextCellValue('Qty*'),
      TextCellValue('Buy Date*'),
      TextCellValue('Buy Rate*'),
      TextCellValue('Buy Amt'),
      TextCellValue('Sell Date'),
      TextCellValue('Sell Rate'),
      TextCellValue('Sell Amt'),
      TextCellValue('Notes'),
    ]);

    sheet.appendRow(<CellValue?>[
      TextCellValue('Share Market'),
      TextCellValue('RELIANCE'),
      DoubleCellValue(10.0),
      TextCellValue('2026-05-10'),
      DoubleCellValue(2450.00),
      DoubleCellValue(24500.00),
      TextCellValue('2026-05-20'),
      DoubleCellValue(2500.00),
      DoubleCellValue(25000.00),
      TextCellValue('Long term hold'),
    ]);

    sheet.appendRow(<CellValue?>[
      TextCellValue('Share Market'),
      TextCellValue('TCS'),
      DoubleCellValue(5.0),
      TextCellValue('2026-05-12'),
      DoubleCellValue(3200.00),
      DoubleCellValue(16000.00),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Open position'),
    ]);

    sheet.appendRow(<CellValue?>[
      TextCellValue('IPO Allocation'),
      TextCellValue('LIC IPO'),
      DoubleCellValue(15.0),
      TextCellValue('2026-05-15'),
      DoubleCellValue(949.00),
      DoubleCellValue(14235.00),
      TextCellValue('2026-05-18'),
      DoubleCellValue(900.00),
      DoubleCellValue(13500.00),
      TextCellValue('IPO allocation'),
    ]);

    sheet.appendRow(<CellValue?>[
      TextCellValue('Mutual Fund'),
      TextCellValue('HDFC Index Fund'),
      DoubleCellValue(120.50),
      TextCellValue('2026-05-10'),
      DoubleCellValue(25.50),
      DoubleCellValue(3072.75),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Monthly SIP'),
    ]);

    _applyRowStyle(sheet, rowIndex: 1, columnCount: 10, style: headerStyle);

    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file.path;
  }

  Future<InvestmentImportPreviewData> importInvestmentExcel(
    String filePath,
  ) async {
    final workbook = await _loadWorkbook(filePath);
    final sheet = _resolveSheet(workbook, preferredSheetName: 'Investments');

    var headerRowIndex = 0;
    for (var i = 0; i < 5 && i < sheet.maxRows; i++) {
      final r = sheet.row(i);
      final values = r
          .map((c) => c?.value?.toString().toLowerCase() ?? '')
          .toList();
      if (values.contains('symbol') ||
          values.contains('fund name') ||
          values.contains('qty') ||
          values.contains('quantity')) {
        headerRowIndex = i;
        break;
      }
    }

    final headerRow = sheet.row(headerRowIndex);
    final headerMap = _resolveHeaderMap(
      headerRow: headerRow,
      aliases: const <String, List<String>>{
        'category': <String>['category', 'type'],
        'symbol': <String>[
          'symbol',
          'name',
          'fund name',
          'fundname',
          'stock',
          'scrip',
        ],
        'qty': <String>['qty', 'quantity', 'units', 'shares'],
        'buyDate': <String>[
          'buy date',
          'buydate',
          'date',
          'order date',
          'orderdate',
        ],
        'buyRate': <String>['buy rate', 'buyrate', 'rate', 'price', 'nav'],
        'buyAmt': <String>[
          'buy amt',
          'buyamt',
          'amount',
          'amt',
          'value',
          'buy value',
        ],
        'sellDate': <String>['sell date', 'selldate'],
        'sellRate': <String>['sell rate', 'sellrate'],
        'sellAmt': <String>['sell amt', 'sellamt'],
        'notes': <String>['notes', 'remarks', 'comment'],
        'type': <String>['type', 'action', 'transaction type'],
      },
      requiredKeys: const <String>['symbol', 'qty', 'buyDate', 'buyRate'],
    );

    final rows = <InvestmentImportRow>[];
    final unrecognizedSections = <String>[];
    var currentCategorySection = 'Equity / Stocks';

    for (
      var rowIndex = headerRowIndex + 1;
      rowIndex < sheet.maxRows;
      rowIndex++
    ) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }

      final nonBlankCells = row
          .where(
            (c) => c?.value != null && c!.value.toString().trim().isNotEmpty,
          )
          .toList();
      if (nonBlankCells.length == 1) {
        final sectionText = nonBlankCells.first!.value.toString().trim();
        final detected = _detectCategoryFromKeyword(sectionText);
        if (detected != null) {
          currentCategorySection = detected;
        } else {
          unrecognizedSections.add(sectionText);
          currentCategorySection = sectionText;
        }
        continue;
      }

      try {
        final symbol = _parseStringCell(row, headerMap['symbol']);
        final qtyVal = _parseNumericCell(row, headerMap['qty']);
        final buyDateVal = _parseDateCell(row, headerMap['buyDate']);
        final buyRateVal = _parseNumericCell(row, headerMap['buyRate']);
        final buyAmtVal = _parseNumericCell(row, headerMap['buyAmt']);
        final sellDateVal = _parseDateCell(row, headerMap['sellDate']);
        final sellRateVal = _parseNumericCell(row, headerMap['sellRate']);
        final sellAmtVal = _parseNumericCell(row, headerMap['sellAmt']);
        final notesVal = _parseStringCell(row, headerMap['notes']);

        var rowCategory = currentCategorySection;
        if (headerMap.containsKey('category')) {
          final catCellVal = _parseStringCell(row, headerMap['category']);
          if (catCellVal.isNotEmpty) {
            final parsedCat =
                _detectCategoryFromKeyword(catCellVal) ?? catCellVal;
            rowCategory = parsedCat;
          }
        }

        var finalBuyDate = buyDateVal;
        var finalBuyRate = buyRateVal;
        var finalBuyAmt =
            buyAmtVal ??
            ((qtyVal != null && buyRateVal != null)
                ? qtyVal * buyRateVal
                : 0.0);
        DateTime? finalSellDate = sellDateVal;
        double? finalSellRate = sellRateVal;
        double? finalSellAmt = sellAmtVal;

        if (headerMap.containsKey('type')) {
          final typeCellVal = _parseStringCell(
            row,
            headerMap['type'],
          ).toLowerCase();
          if (typeCellVal == 'sell' || typeCellVal == 'redemption') {
            finalSellDate = buyDateVal;
            finalSellRate = buyRateVal;
            finalSellAmt =
                buyAmtVal ??
                ((qtyVal != null && buyRateVal != null)
                    ? qtyVal * buyRateVal
                    : 0.0);
            finalBuyDate = null;
            finalBuyRate = null;
            finalBuyAmt = 0.0;
          }
        }

        final isRowValid =
            symbol.isNotEmpty &&
            qtyVal != null &&
            qtyVal > 0 &&
            (finalBuyDate != null || finalSellDate != null);
        String? validationError;
        if (!isRowValid) {
          final missing = <String>[];
          if (symbol.isEmpty) missing.add('Symbol');
          if (qtyVal == null || qtyVal <= 0) missing.add('Qty');
          if (finalBuyDate == null && finalSellDate == null)
            missing.add('Date');
          validationError = 'Missing required fields: ${missing.join(", ")}';
        }

        rows.add(
          InvestmentImportRow(
            symbol: symbol,
            qty: qtyVal ?? 0.0,
            buyDate: finalBuyDate ?? finalSellDate ?? DateTime.now(),
            buyRate: finalBuyRate ?? finalSellRate ?? 0.0,
            buyAmt: finalBuyAmt,
            sellDate: finalSellDate,
            sellRate: finalSellRate,
            sellAmt: finalSellAmt,
            categoryName: rowCategory,
            notes: notesVal.isEmpty ? null : notesVal,
            isValid: isRowValid,
            validationError: validationError,
          ),
        );
      } catch (e) {
        rows.add(
          InvestmentImportRow(
            symbol: '',
            qty: 0.0,
            buyDate: DateTime.now(),
            buyRate: 0.0,
            buyAmt: 0.0,
            categoryName: currentCategorySection,
            isValid: false,
            validationError: 'Error parsing row: ${e.toString()}',
          ),
        );
      }
    }

    return InvestmentImportPreviewData(
      rows: rows,
      unrecognizedSections: unrecognizedSections.toSet().toList(),
    );
  }

  String? _detectCategoryFromKeyword(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('share') ||
        lower.contains('equity') ||
        lower.contains('stock') ||
        lower.contains('demat')) {
      return 'Equity / Stocks';
    }
    if (lower.contains('ipo')) {
      return 'IPO (Allocation)';
    }
    if (lower.contains('mutual') ||
        lower.contains('mf') ||
        lower.contains('fund')) {
      return 'Mutual Fund';
    }
    if (lower.contains('gold')) {
      return 'Gold';
    }
    if (lower.contains('bond') || lower.contains('debt')) {
      return 'Bond / Debt';
    }
    if (lower.contains('fd') ||
        lower.contains('fixed') ||
        lower.contains('savings')) {
      return 'Fixed Deposit';
    }
    return null;
  }

  Future<int> saveInvestmentImport(List<InvestmentImportRow> rows) async {
    final existingCategories = await (_database.select(
      _database.dbInvestmentCategories,
    )).get();
    final categoryIds = {
      for (final c in existingCategories) c.name.toLowerCase(): c.id,
    };

    final existingBrokers = await (_database.select(
      _database.dbInvestmentTaxProfiles,
    )).get();
    final defaultBrokerId = existingBrokers.isNotEmpty
        ? existingBrokers.first.id
        : null;

    var savedCount = 0;

    for (final row in rows) {
      if (!row.isValid) continue;

      try {
        await _database.transaction(() async {
          final catKey = row.categoryName.toLowerCase();
          var catId = categoryIds[catKey];
          if (catId == null) {
            catId = await _database
                .into(_database.dbInvestmentCategories)
                .insert(
                  DbInvestmentCategoriesCompanion.insert(
                    name: row.categoryName,
                    iconCodePoint: 0xe62e,
                    colorValue: 0xFF2196F3,
                  ),
                );
            categoryIds[catKey] = catId;
          }

          final buyId = await _database
              .into(_database.dbInvestmentEntries)
              .insert(
                DbInvestmentEntriesCompanion.insert(
                  categoryId: catId,
                  symbol: row.symbol.trim().toUpperCase(),
                  qty: row.qty,
                  buyDate: row.buyDate,
                  buyRate: row.buyRate,
                  buyAmt: row.buyAmt,
                  taxProfileId: Value(defaultBrokerId),
                  notes: Value(row.notes),
                  createdAt: Value(DateTime.now()),
                  updatedAt: Value(DateTime.now()),
                ),
              );

          if (row.sellDate != null &&
              row.sellRate != null &&
              row.sellQty != null) {
            final sellAmt = row.sellAmt ?? (row.sellQty! * row.sellRate!);
            await _database
                .into(_database.dbSellEntries)
                .insert(
                  DbSellEntriesCompanion.insert(
                    buyEntryId: buyId,
                    symbol: row.symbol.trim().toUpperCase(),
                    sellQty: row.sellQty!,
                    sellDate: row.sellDate!,
                    sellRate: row.sellRate!,
                    sellAmt: sellAmt,
                    createdAt: Value(DateTime.now()),
                  ),
                );
          }
          savedCount++;
        });
      } catch (e) {
        debugPrint('Skipping investment row due to database error: $e');
      }
    }

    return savedCount;
  }

  Future<String> downloadTaskSampleExcel() async {
    final file = await _buildOutputFile(
      moduleFolder: 'task',
      fileNameLabel: 'task-import-sample',
    );
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Tasks') {
      excel.rename(defaultSheet, 'Tasks');
    }

    final taskSheet = excel['Tasks'];
    final headerStyle = CellStyle(bold: true);

    taskSheet.appendRow(<CellValue?>[
      TextCellValue('Date*'),
      TextCellValue('Title*'),
      TextCellValue('Category'),
      TextCellValue('Priority'),
      TextCellValue('Daily'),
      TextCellValue('Completed'),
      TextCellValue('Checklist'),
      TextCellValue('Description'),
    ]);
    taskSheet.appendRow(<CellValue?>[
      TextCellValue(DateFormat('yyyy-MM-dd').format(DateTime.now())),
      TextCellValue('Buy groceries'),
      TextCellValue('Personal'),
      IntCellValue(3),
      TextCellValue('No'),
      TextCellValue('No'),
      TextCellValue('[ ] Milk | [x] Eggs | [ ] Bread'),
      TextCellValue('Buy weekly groceries from supermarket'),
    ]);
    _applyRowStyle(taskSheet, rowIndex: 0, columnCount: 8, style: headerStyle);
    _setColumnWidths(taskSheet, <double>[14, 26, 18, 12, 12, 14, 30, 32]);

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Unable to generate the task Excel import sample.');
    }
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<TaskImportPreviewData> previewTaskExcel(String filePath) async {
    final workbook = await _loadWorkbook(filePath);
    final sheet = _resolveSheet(workbook, preferredSheetName: 'Tasks');
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'date': <String>['date', 'task date', 'taskdate'],
        'title': <String>['title', 'task title', 'tasktitle'],
        'category': <String>['category', 'task category'],
        'priority': <String>['priority'],
        'daily': <String>['daily', 'is daily', 'isdaily'],
        'completed': <String>['completed', 'is completed', 'iscompleted'],
        'checklist': <String>['checklist', 'subtasks', 'subtask'],
        'description': <String>['description', 'desc', 'notes'],
      },
      requiredKeys: const <String>['date', 'title'],
    );

    final rows = <TaskImportRow>[];

    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }

      try {
        final validated = _validateTaskRow(
          row: row,
          rowNumber: rowIndex + 1,
          headerMap: headerMap,
        );
        rows.add(validated);
      } on ModuleImportException catch (error) {
        final title = _cellText(_cellAt(row, headerMap['title']));
        final category = _cellText(_cellAt(row, headerMap['category']));
        final rawDescription = _cellText(
          _cellAt(row, headerMap['description']),
        ).trim();
        final description = rawDescription == '-' ? '' : rawDescription;
        final checklistText = _cellText(_cellAt(row, headerMap['checklist']));
        final priorityText = _cellText(_cellAt(row, headerMap['priority']));
        final dailyText = _cellText(_cellAt(row, headerMap['daily']));
        final completedText = _cellText(_cellAt(row, headerMap['completed']));

        final dateCell = _cellAt(row, headerMap['date']);
        final date = _parseDate(dateCell) ?? DateTime.now();

        var priority = 3;
        if (priorityText.isNotEmpty) {
          priority = int.tryParse(priorityText) ?? 3;
        }

        final isDaily =
            dailyText.toLowerCase().trim() == 'yes' ||
            dailyText.toLowerCase().trim() == 'true';
        final isCompleted =
            completedText.toLowerCase().trim() == 'yes' ||
            completedText.toLowerCase().trim() == 'true';

        rows.add(
          TaskImportRow(
            date: date,
            title: title.isEmpty ? 'Untitled Task' : title,
            categoryName: category.isEmpty ? 'General' : category,
            priority: priority,
            isDaily: isDaily,
            isCompleted: isCompleted,
            checklist: _parseTaskChecklist(checklistText),
            description: description,
            isValid: false,
            validationError: error.message,
          ),
        );
      }
    }

    return TaskImportPreviewData(rows: rows);
  }

  TaskImportRow _validateTaskRow({
    required List<Data?> row,
    required int rowNumber,
    required Map<String, int> headerMap,
  }) {
    final titleCell = _cellAt(row, headerMap['title']);
    final dateCell = _cellAt(row, headerMap['date']);

    final title = _cellText(titleCell).trim();
    if (title.isEmpty) {
      throw ModuleImportException('Row $rowNumber: Title is empty.');
    }

    final date = _parseDate(dateCell);
    if (date == null) {
      throw ModuleImportException('Row $rowNumber: Invalid or missing date.');
    }

    final category = _cellText(_cellAt(row, headerMap['category'])).trim();
    final rawDescription = _cellText(
      _cellAt(row, headerMap['description']),
    ).trim();
    final description = rawDescription == '-' ? '' : rawDescription;
    final checklistText = _cellText(
      _cellAt(row, headerMap['checklist']),
    ).trim();

    final priorityText = _cellText(_cellAt(row, headerMap['priority'])).trim();
    var priority = 3;
    if (priorityText.isNotEmpty) {
      final val = int.tryParse(priorityText);
      if (val == null || val < 1 || val > 5) {
        throw ModuleImportException(
          'Row $rowNumber: Priority must be between 1 and 5.',
        );
      }
      priority = val;
    }

    final dailyText = _cellText(
      _cellAt(row, headerMap['daily']),
    ).trim().toLowerCase();
    final isDaily = dailyText == 'yes' || dailyText == 'true';

    final completedText = _cellText(
      _cellAt(row, headerMap['completed']),
    ).trim().toLowerCase();
    final isCompleted = completedText == 'yes' || completedText == 'true';

    return TaskImportRow(
      date: date,
      title: title,
      categoryName: category.isEmpty ? 'General' : category,
      priority: priority,
      isDaily: isDaily,
      isCompleted: isCompleted,
      checklist: _parseTaskChecklist(checklistText),
      description: description,
      isValid: true,
    );
  }

  List<TaskChecklistItem> _parseTaskChecklist(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return const <TaskChecklistItem>[];
    }
    final items = <TaskChecklistItem>[];
    final parts = text.split('|');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('[x]') || trimmed.startsWith('[X]')) {
        items.add(
          TaskChecklistItem(
            title: trimmed.substring(3).trim(),
            isCompleted: true,
          ),
        );
      } else if (trimmed.startsWith('[ ]')) {
        items.add(
          TaskChecklistItem(
            title: trimmed.substring(3).trim(),
            isCompleted: false,
          ),
        );
      } else {
        items.add(TaskChecklistItem(title: trimmed, isCompleted: false));
      }
    }
    return items;
  }

  Future<int> saveTaskImport(List<TaskImportRow> rows) async {
    final cleanRows = rows.where((row) => row.isValid).toList();
    if (cleanRows.isEmpty) return 0;

    var savedCount = 0;
    for (final row in cleanRows) {
      try {
        await _database.transaction(() async {
          final dbDescription = _encodeTaskContent(
            description: row.description.trim(),
            checklist: row.checklist,
          );

          await _database
              .into(_database.dbTasks)
              .insert(
                DbTasksCompanion.insert(
                  title: row.title.trim(),
                  description: Value(dbDescription),
                  category: row.categoryName.trim(),
                  taskDate: row.date,
                  priority: Value(row.priority),
                  isDaily: Value(row.isDaily),
                  isCompleted: Value(row.isCompleted),
                  createdAt: Value(DateTime.now()),
                ),
              );
          savedCount++;
        });
      } catch (e) {
        debugPrint('Skipping task row due to database error: $e');
      }
    }
    return savedCount;
  }

  String _encodeTaskContent({
    required String description,
    required List<TaskChecklistItem> checklist,
  }) {
    final normalizedChecklist = checklist
        .map(
          (item) => TaskChecklistItem(
            title: item.title.trim(),
            isCompleted: item.isCompleted,
          ),
        )
        .where((item) => item.title.isNotEmpty)
        .toList(growable: false);

    if (normalizedChecklist.isEmpty) {
      return description;
    }

    return '__task_content_v1__${jsonEncode(<String, dynamic>{'description': description, 'checklist': normalizedChecklist.map((item) => item.toJson()).toList(growable: false)})}';
  }

  Future<ModuleImportResult> importTaskExcel(String filePath) async {
    final preview = await previewTaskExcel(filePath);
    final validRows = preview.rows.where((r) => r.isValid).toList();
    final savedCount = await saveTaskImport(validRows);

    return ModuleImportResult(
      savedItems: savedCount,
      validatedRows: preview.rows.length,
      message:
          '$savedCount task${savedCount == 1 ? '' : 's'} imported successfully out of ${preview.rows.length} row${preview.rows.length == 1 ? '' : 's'}.',
    );
  }

  String _parseStringCell(List<Data?> row, int? index) =>
      _cellText(_cellAt(row, index));
  double? _parseNumericCell(List<Data?> row, int? index) =>
      _parseAmount(_cellAt(row, index));
  DateTime? _parseDateCell(List<Data?> row, int? index) =>
      _parseDate(_cellAt(row, index));
}

class InvestmentImportRow {
  InvestmentImportRow({
    required this.symbol,
    required this.qty,
    required this.buyDate,
    required this.buyRate,
    required this.buyAmt,
    this.sellDate,
    this.sellRate,
    this.sellAmt,
    required this.categoryName,
    this.notes,
    this.isValid = true,
    this.validationError,
    this.isDuplicate = false,
  });

  String symbol;
  double qty;
  DateTime buyDate;
  double buyRate;
  double buyAmt;
  DateTime? sellDate;
  double? sellRate;
  double? sellAmt;
  String categoryName;
  String? notes;
  bool isValid;
  String? validationError;
  bool isDuplicate;

  double? get sellQty => sellDate != null ? qty : null;
}

class InvestmentImportPreviewData {
  InvestmentImportPreviewData({
    required this.rows,
    required this.unrecognizedSections,
  });

  final List<InvestmentImportRow> rows;
  final List<String> unrecognizedSections;
}

class ExpenseImportRow {
  ExpenseImportRow({
    this.sourceEntryId,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryName,
    this.bankName,
    required this.date,
    this.day,
    required this.paymentMode,
    this.counterparty,
    required this.notes,
    required this.isValid,
    this.validationError,
  });

  final int? sourceEntryId;
  final String title;
  final double amount;
  final String type;
  final String categoryName;
  final String? bankName;
  final DateTime date;
  final String? day;
  final String paymentMode;
  final String? counterparty;
  final String notes;
  final bool isValid;
  final String? validationError;
}

class ExpenseImportPreviewData {
  ExpenseImportPreviewData({required this.rows, required this.splitBundle});

  final List<ExpenseImportRow> rows;
  final ExpenseSplitImportBundle splitBundle;
}

class CredentialImportRow {
  CredentialImportRow({
    required this.title,
    this.expiryDate,
    required this.field,
    required this.value,
    this.isValid = true,
    this.validationError,
  });

  final String title;
  final DateTime? expiryDate;
  final String field;
  final String value;
  final bool isValid;
  final String? validationError;
}

class CredentialImportPreviewData {
  CredentialImportPreviewData({required this.rows});

  final List<CredentialImportRow> rows;
}

class _ValidatedExpenseRow {
  const _ValidatedExpenseRow({
    required this.sourceEntryId,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryName,
    required this.bankName,
    required this.date,
    required this.day,
    required this.paymentMode,
    required this.counterparty,
    required this.notes,
  });

  final int? sourceEntryId;
  final String title;
  final double amount;
  final String type;
  final String categoryName;
  final String? bankName;
  final DateTime date;
  final String? day;
  final String paymentMode;
  final String? counterparty;
  final String notes;

  _ValidatedExpenseRow copyWith({
    int? sourceEntryId,
    String? title,
    double? amount,
    String? type,
    String? categoryName,
    String? bankName,
    DateTime? date,
    Object? day = _moduleImportUnset,
    String? paymentMode,
    Object? counterparty = _moduleImportUnset,
    String? notes,
  }) {
    return _ValidatedExpenseRow(
      sourceEntryId: sourceEntryId ?? this.sourceEntryId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryName: categoryName ?? this.categoryName,
      bankName: bankName ?? this.bankName,
      date: date ?? this.date,
      day: identical(day, _moduleImportUnset) ? this.day : day as String?,
      paymentMode: paymentMode ?? this.paymentMode,
      counterparty: identical(counterparty, _moduleImportUnset)
          ? this.counterparty
          : counterparty as String?,
      notes: notes ?? this.notes,
    );
  }
}

class ExpenseSplitImportBundle {
  const ExpenseSplitImportBundle({
    this.splitRecords = const <ImportedSplitRecord>[],
    this.splitParticipants = const <ImportedSplitParticipant>[],
    this.settlements = const <ImportedLentSettlement>[],
    this.borrowedSettlements = const <ImportedBorrowedSettlement>[],
  });

  final List<ImportedSplitRecord> splitRecords;
  final List<ImportedSplitParticipant> splitParticipants;
  final List<ImportedLentSettlement> settlements;
  final List<ImportedBorrowedSettlement> borrowedSettlements;

  bool get hasData =>
      splitRecords.isNotEmpty ||
      splitParticipants.isNotEmpty ||
      settlements.isNotEmpty ||
      borrowedSettlements.isNotEmpty;
}

class ImportedSplitRecord {
  const ImportedSplitRecord({
    required this.sourceId,
    required this.sourceExpenseEntryId,
    required this.sourceLentEntryId,
    required this.totalAmount,
    required this.createdAt,
  });

  final int sourceId;
  final int? sourceExpenseEntryId;
  final int? sourceLentEntryId;
  final double totalAmount;
  final DateTime createdAt;

  ImportedSplitRecord copyWith({
    int? sourceId,
    Object? sourceExpenseEntryId = _moduleImportUnset,
    Object? sourceLentEntryId = _moduleImportUnset,
    double? totalAmount,
    DateTime? createdAt,
  }) {
    return ImportedSplitRecord(
      sourceId: sourceId ?? this.sourceId,
      sourceExpenseEntryId: identical(sourceExpenseEntryId, _moduleImportUnset)
          ? this.sourceExpenseEntryId
          : sourceExpenseEntryId as int?,
      sourceLentEntryId: identical(sourceLentEntryId, _moduleImportUnset)
          ? this.sourceLentEntryId
          : sourceLentEntryId as int?,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ImportedSplitParticipant {
  const ImportedSplitParticipant({
    required this.sourceId,
    required this.sourceSplitRecordId,
    required this.participantName,
    required this.amount,
    required this.percentage,
    required this.isSelf,
    required this.settledAmount,
    required this.sortOrder,
    required this.createdAt,
  });

  final int sourceId;
  final int sourceSplitRecordId;
  final String participantName;
  final double amount;
  final double percentage;
  final bool isSelf;
  final double settledAmount;
  final int sortOrder;
  final DateTime createdAt;
}

class _NormalizedExpenseImportData {
  const _NormalizedExpenseImportData({
    required this.rows,
    required this.splitBundle,
  });

  final List<_ValidatedExpenseRow> rows;
  final ExpenseSplitImportBundle splitBundle;
}

const Object _moduleImportUnset = Object();

class ImportedLentSettlement {
  const ImportedLentSettlement({
    required this.sourceId,
    required this.sourceSplitRecordId,
    required this.sourceSplitParticipantId,
    required this.sourceIncomeEntryId,
    required this.settledAmount,
    required this.createdAt,
  });

  final int sourceId;
  final int sourceSplitRecordId;
  final int sourceSplitParticipantId;
  final int sourceIncomeEntryId;
  final double settledAmount;
  final DateTime createdAt;
}

class ImportedBorrowedSettlement {
  const ImportedBorrowedSettlement({
    required this.sourceId,
    required this.sourceBorrowedEntryId,
    required this.sourceExpenseEntryId,
    required this.settledAmount,
    required this.createdAt,
  });

  final int sourceId;
  final int sourceBorrowedEntryId;
  final int sourceExpenseEntryId;
  final double settledAmount;
  final DateTime createdAt;
}

class _PreparedCredentialImport {
  const _PreparedCredentialImport({required this.draft, required this.payload});

  final CredentialDraft draft;
  final EncryptedCredentialPayload payload;
}

class _ExcelReferenceRange {
  const _ExcelReferenceRange({
    required this.sheetName,
    required this.startCell,
    required this.endCell,
  });

  final String sheetName;
  final String startCell;
  final String endCell;

  String get asFormula => "'$sheetName'!$startCell:$endCell";
}

class _ExcelDropdownRule {
  const _ExcelDropdownRule({
    required this.sheetName,
    required this.targetRange,
    required this.formula,
  });

  final String sheetName;
  final String targetRange;
  final String formula;
}

class TaskImportRow {
  TaskImportRow({
    required this.date,
    required this.title,
    required this.categoryName,
    required this.priority,
    required this.isDaily,
    required this.isCompleted,
    required this.checklist,
    required this.description,
    this.isValid = true,
    this.validationError,
  });

  final DateTime date;
  final String title;
  final String categoryName;
  final int priority;
  final bool isDaily;
  final bool isCompleted;
  final List<TaskChecklistItem> checklist;
  final String description;
  final bool isValid;
  final String? validationError;
}

class TaskImportPreviewData {
  const TaskImportPreviewData({required this.rows});

  final List<TaskImportRow> rows;
}
