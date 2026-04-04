import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import '../../data/database/app_database.dart';
import '../../features/credentials/domain/models/credential_models.dart';
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
      TextCellValue('Title*'),
      TextCellValue('Amount*'),
      TextCellValue('Type*'),
      TextCellValue('Category*'),
      TextCellValue('Bank'),
      TextCellValue('Date*'),
      TextCellValue('Payment Mode*'),
      TextCellValue('Counterparty'),
      TextCellValue('Notes'),
    ]);
    expenseSheet.appendRow(<CellValue?>[
      TextCellValue('Lunch with team'),
      DoubleCellValue(450),
      TextCellValue('Expense'),
      TextCellValue(categories.first),
      TextCellValue(banks.isEmpty ? '' : banks.first),
      TextCellValue(DateFormat('yyyy-MM-dd').format(DateTime.now())),
      TextCellValue(AppConstants.paymentModes.first),
      TextCellValue('Office friends'),
      TextCellValue('Sample row, replace with your own data'),
    ]);
    _applyRowStyle(
      expenseSheet,
      rowIndex: 0,
      columnCount: 9,
      style: headerStyle,
    );
    _setColumnWidths(expenseSheet, <double>[
      28,
      14,
      16,
      18,
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
      TextCellValue('Payment Mode'),
      TextCellValue(
        'Required. Use one of: ${AppConstants.paymentModes.join(', ')}',
      ),
    ]);
    referenceSheet.appendRow(<CellValue?>[
      TextCellValue('Counterparty / Notes'),
      TextCellValue('Optional'),
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
          targetRange: 'C2:C200',
          formula: typeRange.asFormula,
        ),
        _ExcelDropdownRule(
          sheetName: 'Expenses',
          targetRange: 'D2:D200',
          formula: categoryRange.asFormula,
        ),
        if (banks.isNotEmpty)
          _ExcelDropdownRule(
            sheetName: 'Expenses',
            targetRange: 'E2:E200',
            formula: bankRange.asFormula,
          ),
        _ExcelDropdownRule(
          sheetName: 'Expenses',
          targetRange: 'G2:G200',
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

  Future<ModuleImportResult> importExpenseExcel(String filePath) async {
    final workbook = await _loadWorkbook(filePath);
    final sheet = _resolveSheet(workbook, preferredSheetName: 'Expenses');
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'title': <String>['title'],
        'amount': <String>['amount'],
        'type': <String>['type'],
        'category': <String>['category'],
        'bank': <String>['bank'],
        'date': <String>['date'],
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

    final errors = <String>[];
    final rows = <_ValidatedExpenseRow>[];

    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.row(rowIndex);
      if (_isBlankRow(row, headerMap.values)) {
        continue;
      }

      try {
        rows.add(
          _validateExpenseRow(
            row: row,
            rowNumber: rowIndex + 1,
            headerMap: headerMap,
          ),
        );
      } on ModuleImportException catch (error) {
        errors.addAll(
          error.errors.isEmpty ? <String>[error.message] : error.errors,
        );
      }
    }

    if (rows.isEmpty) {
      throw const ModuleImportException(
        'No expense rows were found to import.',
        <String>['Add at least one completed row below the header row.'],
      );
    }

    if (errors.isNotEmpty) {
      throw ModuleImportException(
        'Expense import failed because some rows are invalid.',
        errors,
      );
    }

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

      for (final row in rows) {
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

      for (final row in rows) {
        await _database
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
                paymentMode: row.paymentMode,
                notes: Value(row.notes),
                counterparty: Value(row.counterparty),
              ),
            );
      }

      final messageBuffer = StringBuffer(
        '${rows.length} expense row${rows.length == 1 ? '' : 's'} imported successfully.',
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
        savedItems: rows.length,
        validatedRows: rows.length,
        message: messageBuffer.toString(),
      );
    });
  }

  Future<ModuleImportResult> importCredentialExcel(
    String filePath, {
    required String encryptionKey,
  }) async {
    if (encryptionKey.trim().isEmpty) {
      throw const ModuleImportException('A valid encryption key is required.');
    }

    final workbook = await _loadWorkbook(filePath);
    final sheet = _resolveSheet(workbook, preferredSheetName: 'Credentials');
    final headerMap = _resolveHeaderMap(
      headerRow: sheet.row(0),
      aliases: const <String, List<String>>{
        'title': <String>['title'],
        'expiryDate': <String>[
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

    final errors = <String>[];
    final groupedFields = <String, List<CredentialField>>{};
    final groupedExpiryDates = <String, DateTime?>{};
    final titleByGroup = <String, String>{};
    var validatedRows = 0;

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
      final parsedExpiryDate = expiryText.isEmpty ? null : _parseDate(expiryCell);
      if (expiryText.isNotEmpty && parsedExpiryDate == null) {
        rowErrors.add(
          'Expiry Date must be a valid Excel date or text date like yyyy-MM-dd.',
        );
      }

      if (rowErrors.isNotEmpty) {
        errors.add('Row ${rowIndex + 1}: ${rowErrors.join(' ')}');
        continue;
      }

      final groupKey = title.toLowerCase();
      final existingFields = groupedFields.putIfAbsent(
        groupKey,
        () => <CredentialField>[],
      );
      titleByGroup.putIfAbsent(groupKey, () => title);
      final existingExpiryDate = groupedExpiryDates[groupKey];

      if (parsedExpiryDate != null) {
        if (existingExpiryDate != null &&
            !_isSameDate(existingExpiryDate, parsedExpiryDate)) {
          errors.add(
            'Row ${rowIndex + 1}: Expiry Date does not match other rows for credential "$title".',
          );
          continue;
        }
        groupedExpiryDates[groupKey] = parsedExpiryDate;
      } else {
        groupedExpiryDates.putIfAbsent(groupKey, () => null);
      }

      final hasDuplicateField = existingFields.any(
        (existingField) =>
            existingField.keyLabel.toLowerCase() == field.toLowerCase(),
      );
      if (hasDuplicateField) {
        errors.add(
          'Row ${rowIndex + 1}: Field "$field" is duplicated for credential "$title".',
        );
        continue;
      }

      existingFields.add(CredentialField(keyLabel: field, value: value));
      validatedRows += 1;
    }

    if (validatedRows == 0) {
      throw const ModuleImportException(
        'No credential rows were found to import.',
        <String>['Add at least one completed row below the header row.'],
      );
    }

    if (errors.isNotEmpty) {
      throw ModuleImportException(
        'Credential import failed because some rows are invalid.',
        errors,
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
      validatedRows: validatedRows,
      message:
          '${drafts.length} credential${drafts.length == 1 ? '' : 's'} imported successfully from $validatedRows row${validatedRows == 1 ? '' : 's'}.',
    );
  }

  _ValidatedExpenseRow _validateExpenseRow({
    required List<Data?> row,
    required int rowNumber,
    required Map<String, int> headerMap,
  }) {
    final title = _cellText(_cellAt(row, headerMap['title']));
    final category = _cellText(_cellAt(row, headerMap['category']));
    final bank = _cellText(_cellAt(row, headerMap['bank']));
    final paymentModeText = _cellText(_cellAt(row, headerMap['paymentMode']));
    final counterpartyText = _cellText(_cellAt(row, headerMap['counterparty']));
    final notes = _cellText(_cellAt(row, headerMap['notes']));
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
      title: title,
      amount: amount!,
      type: type!,
      categoryName: category,
      bankName: bank.isEmpty ? null : bank,
      date: date!,
      paymentMode: paymentMode!,
      counterparty: counterpartyText.isEmpty ? null : counterpartyText,
      notes: notes,
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
        final text = _cellText(cell).replaceAll(',', '');
        return double.tryParse(text);
    }
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
}

class _ValidatedExpenseRow {
  const _ValidatedExpenseRow({
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryName,
    required this.bankName,
    required this.date,
    required this.paymentMode,
    required this.counterparty,
    required this.notes,
  });

  final String title;
  final double amount;
  final String type;
  final String categoryName;
  final String? bankName;
  final DateTime date;
  final String paymentMode;
  final String? counterparty;
  final String notes;
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
