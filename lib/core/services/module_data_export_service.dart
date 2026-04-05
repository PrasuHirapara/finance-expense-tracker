import 'dart:io';

import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/database/app_database.dart';
import '../../features/credentials/domain/models/credential_models.dart';
import '../../features/expense/domain/models/expense_models.dart';
import '../../features/tasks/domain/models/task_models.dart';
import '../constants/app_constants.dart';
import '../formatters/indian_number_formatter.dart';
import '../models/module_export_models.dart';
import 'app_settings_repository.dart';

class ModuleDataExportService {
  ModuleDataExportService(this._appSettingsRepository, this._database);

  final AppSettingsRepository _appSettingsRepository;
  final AppDatabase _database;

  Future<String> exportExpenseData({
    required DateTimeRange range,
    required ModuleExportFormat format,
    required List<ExpenseRecord> entries,
  }) {
    return switch (format) {
      ModuleExportFormat.pdf => _exportExpensePdf(
        range: range,
        entries: entries,
      ),
      ModuleExportFormat.excel => _exportExpenseExcel(
        range: range,
        entries: entries,
      ),
    };
  }

  Future<String> exportTaskData({
    required DateTimeRange range,
    required ModuleExportFormat format,
    required List<TaskItem> tasks,
  }) {
    return switch (format) {
      ModuleExportFormat.pdf => _exportTaskPdf(range: range, tasks: tasks),
      ModuleExportFormat.excel => _exportTaskExcel(range: range, tasks: tasks),
    };
  }

  Future<String> exportCredentialData({
    required ModuleExportFormat format,
    required List<DecryptedCredential> credentials,
  }) {
    return switch (format) {
      ModuleExportFormat.pdf => _exportCredentialPdf(credentials: credentials),
      ModuleExportFormat.excel => _exportCredentialExcel(
        credentials: credentials,
      ),
    };
  }

  Future<String> _exportExpensePdf({
    required DateTimeRange range,
    required List<ExpenseRecord> entries,
  }) async {
    final file = await _buildExportFile(
      moduleFolder: 'expense',
      fileNameLabel: 'expense',
      extension: 'pdf',
    );
    final timestamp = DateTime.now();
    final summary = _ExpenseExportSummary.fromEntries(entries);
    final splitBundle = await _loadExpenseSplitExportBundle(entries);
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => <pw.Widget>[
          pw.Text(
            'Expense Export',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Range: ${_formatRange(range)}'),
          pw.Text(
            'Exported At: ${AppConstants.longDateFormat.format(timestamp)}',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const <String>['Metric', 'Value'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: <List<String>>[
              <String>[
                'Entries',
                IndianNumberFormatter.formatFull(entries.length),
              ],
              <String>[
                'Total Credit',
                IndianNumberFormatter.formatFull(summary.totalCredit),
              ],
              <String>[
                'Total Debit',
                IndianNumberFormatter.formatFull(summary.totalDebit),
              ],
              <String>[
                'Total Borrowed',
                IndianNumberFormatter.formatFull(summary.totalBorrowed),
              ],
              <String>[
                'Total Lent',
                IndianNumberFormatter.formatFull(summary.totalLent),
              ],
              <String>[
                'Net Flow',
                IndianNumberFormatter.formatFull(summary.netFlow),
              ],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Transactions',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            headers: const <String>[
              'Entry ID',
              'Date',
              'Title',
              'Type',
              'Category',
              'Bank',
              'Amount',
              'Mode',
              'Counterparty',
              'Notes',
              'Split Record',
              'Split Pending',
            ],
            data: entries
                .map(
                  (entry) => <String>[
                    entry.id.toString(),
                    AppConstants.shortDateFormat.format(entry.date),
                    entry.title,
                    _expenseTypeLabel(entry.type),
                    entry.category.name,
                    entry.bank?.name ?? '-',
                    IndianNumberFormatter.formatFull(entry.amount),
                    entry.paymentMode,
                    entry.counterparty?.trim().isNotEmpty == true
                        ? entry.counterparty!.trim()
                        : '-',
                    entry.notes.trim().isNotEmpty ? entry.notes.trim() : '-',
                    entry.splitSummary?.recordId.toString() ?? '-',
                    entry.splitSummary == null
                        ? '-'
                        : IndianNumberFormatter.formatFull(
                            entry.splitSummary!.pendingLentAmount,
                          ),
                  ],
                )
                .toList(growable: false),
          ),
          if (splitBundle.records.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            pw.Text(
              'Split Records',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: const <String>[
                'Split Record ID',
                'Expense Entry ID',
                'Lent Entry ID',
                'Total Amount',
                'Pending Lent',
                'Participants',
              ],
              data: splitBundle.records
                  .map(
                    (record) => <String>[
                      record.id.toString(),
                      record.expenseEntryId?.toString() ?? '-',
                      record.lentEntryId?.toString() ?? '-',
                      IndianNumberFormatter.formatFull(record.totalAmount),
                      IndianNumberFormatter.formatFull(
                        splitBundle.pendingAmountByRecordId[record.id] ?? 0,
                      ),
                      (splitBundle.participantCountByRecordId[record.id] ?? 0)
                          .toString(),
                    ],
                  )
                  .toList(growable: false),
            ),
          ],
          if (splitBundle.participants.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            pw.Text(
              'Split Participants',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: const <String>[
                'Participant ID',
                'Split Record ID',
                'Name',
                'Amount',
                'Percentage',
                'Self',
                'Settled Amount',
              ],
              data: splitBundle.participants
                  .map(
                    (participant) => <String>[
                      participant.id.toString(),
                      participant.splitRecordId.toString(),
                      participant.participantName,
                      IndianNumberFormatter.formatFull(participant.amount),
                      participant.percentage.toStringAsFixed(2),
                      participant.isSelf ? 'Yes' : 'No',
                      IndianNumberFormatter.formatFull(participant.settledAmount),
                    ],
                  )
                  .toList(growable: false),
            ),
          ],
          if (splitBundle.settlements.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            pw.Text(
              'Lent Settlements',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: const <String>[
                'Settlement ID',
                'Split Record ID',
                'Participant ID',
                'Income Entry ID',
                'Settled Amount',
              ],
              data: splitBundle.settlements
                  .map(
                    (settlement) => <String>[
                      settlement.id.toString(),
                      settlement.splitRecordId.toString(),
                      settlement.splitParticipantId.toString(),
                      settlement.incomeEntryId.toString(),
                      IndianNumberFormatter.formatFull(
                        settlement.settledAmount,
                      ),
                    ],
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );

    await file.writeAsBytes(await document.save());
    return file.path;
  }

  Future<String> _exportExpenseExcel({
    required DateTimeRange range,
    required List<ExpenseRecord> entries,
  }) async {
    final file = await _buildExportFile(
      moduleFolder: 'expense',
      fileNameLabel: 'expense',
      extension: 'xlsx',
    );
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Summary') {
      excel.rename(defaultSheet, 'Summary');
    }

    final summarySheet = excel['Summary'];
    final entriesSheet = excel['Entries'];
    final summary = _ExpenseExportSummary.fromEntries(entries);
    final splitBundle = await _loadExpenseSplitExportBundle(entries);
    final headerStyle = CellStyle(bold: true);
    final numberStyle = CellStyle(
      numberFormat: const CustomNumericNumFormat(
        formatCode: '#,##,##0.################',
      ),
    );
    final wrappedHeaderStyle = headerStyle.copyWith(
      textWrappingVal: TextWrapping.WrapText,
    );

    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Expense Export'),
      TextCellValue(''),
    ]);
    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Range'),
      TextCellValue(_formatRange(range)),
    ]);
    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Exported At'),
      TextCellValue(AppConstants.longDateFormat.format(DateTime.now())),
    ]);
    summarySheet.appendRow(const <CellValue?>[]);
    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Metric'),
      TextCellValue('Value'),
    ]);
    _applyRowStyle(
      summarySheet,
      rowIndex: 0,
      columnCount: 2,
      style: headerStyle,
    );
    _applyRowStyle(
      summarySheet,
      rowIndex: 4,
      columnCount: 2,
      style: headerStyle,
    );

    _appendSummaryNumberRow(
      summarySheet,
      'Entries',
      entries.length,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Total Credit',
      summary.totalCredit,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Total Debit',
      summary.totalDebit,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Total Borrowed',
      summary.totalBorrowed,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Total Lent',
      summary.totalLent,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Net Flow',
      summary.netFlow,
      numberStyle,
    );

    entriesSheet.appendRow(<CellValue?>[
      TextCellValue('Entry ID'),
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Bank'),
      TextCellValue('Amount'),
      TextCellValue('Payment Mode'),
      TextCellValue('Counterparty'),
      TextCellValue('Notes'),
      TextCellValue('Split Record ID'),
      TextCellValue('Split Pending Amount'),
      TextCellValue('Managed Lent Entry'),
      TextCellValue('Resolution Income'),
    ]);
    _applyRowStyle(
      entriesSheet,
      rowIndex: 0,
      columnCount: 14,
      style: wrappedHeaderStyle,
    );

    for (final entry in entries) {
      final rowIndex = entriesSheet.maxRows;
      entriesSheet.appendRow(<CellValue?>[
        _numericCell(entry.id),
        TextCellValue(AppConstants.shortDateFormat.format(entry.date)),
        TextCellValue(entry.title),
        TextCellValue(_expenseTypeLabel(entry.type)),
        TextCellValue(entry.category.name),
        TextCellValue(entry.bank?.name ?? ''),
        _numericCell(entry.amount),
        TextCellValue(entry.paymentMode),
        TextCellValue(entry.counterparty ?? ''),
        TextCellValue(entry.notes),
        entry.splitSummary == null
            ? TextCellValue('')
            : _numericCell(entry.splitSummary!.recordId),
        entry.splitSummary == null
            ? TextCellValue('')
            : _numericCell(entry.splitSummary!.pendingLentAmount),
        TextCellValue(entry.isManagedLentEntry ? 'Yes' : 'No'),
        TextCellValue(entry.isResolutionIncome ? 'Yes' : 'No'),
      ]);
      _applyCellStyle(
        entriesSheet,
        rowIndex: rowIndex,
        columnIndex: 0,
        style: numberStyle,
      );
      _applyCellStyle(
        entriesSheet,
        rowIndex: rowIndex,
        columnIndex: 6,
        style: numberStyle,
      );
      if (entry.splitSummary != null) {
        _applyCellStyle(
          entriesSheet,
          rowIndex: rowIndex,
          columnIndex: 10,
          style: numberStyle,
        );
        _applyCellStyle(
          entriesSheet,
          rowIndex: rowIndex,
          columnIndex: 11,
          style: numberStyle,
        );
      }
    }

    if (splitBundle.records.isNotEmpty) {
      final splitRecordsSheet = excel['Split Records'];
      splitRecordsSheet.appendRow(<CellValue?>[
        TextCellValue('Split Record ID'),
        TextCellValue('Expense Entry ID'),
        TextCellValue('Lent Entry ID'),
        TextCellValue('Total Amount'),
        TextCellValue('Created At'),
      ]);
      _applyRowStyle(
        splitRecordsSheet,
        rowIndex: 0,
        columnCount: 5,
        style: wrappedHeaderStyle,
      );
      for (final record in splitBundle.records) {
        final rowIndex = splitRecordsSheet.maxRows;
        splitRecordsSheet.appendRow(<CellValue?>[
          _numericCell(record.id),
          record.expenseEntryId == null
              ? TextCellValue('')
              : _numericCell(record.expenseEntryId!),
          record.lentEntryId == null
              ? TextCellValue('')
              : _numericCell(record.lentEntryId!),
          _numericCell(record.totalAmount),
          TextCellValue(record.createdAt.toIso8601String()),
        ]);
        for (final columnIndex in <int>[0, 1, 2, 3]) {
          _applyCellStyle(
            splitRecordsSheet,
            rowIndex: rowIndex,
            columnIndex: columnIndex,
            style: numberStyle,
          );
        }
      }
      _setColumnWidths(splitRecordsSheet, <double>[16, 16, 16, 16, 24]);
    }

    if (splitBundle.participants.isNotEmpty) {
      final splitParticipantsSheet = excel['Split Participants'];
      splitParticipantsSheet.appendRow(<CellValue?>[
        TextCellValue('Participant ID'),
        TextCellValue('Split Record ID'),
        TextCellValue('Participant Name'),
        TextCellValue('Amount'),
        TextCellValue('Percentage'),
        TextCellValue('Is Self'),
        TextCellValue('Settled Amount'),
        TextCellValue('Sort Order'),
        TextCellValue('Created At'),
      ]);
      _applyRowStyle(
        splitParticipantsSheet,
        rowIndex: 0,
        columnCount: 9,
        style: wrappedHeaderStyle,
      );
      for (final participant in splitBundle.participants) {
        final rowIndex = splitParticipantsSheet.maxRows;
        splitParticipantsSheet.appendRow(<CellValue?>[
          _numericCell(participant.id),
          _numericCell(participant.splitRecordId),
          TextCellValue(participant.participantName),
          _numericCell(participant.amount),
          _numericCell(participant.percentage),
          TextCellValue(participant.isSelf ? 'Yes' : 'No'),
          _numericCell(participant.settledAmount),
          _numericCell(participant.sortOrder),
          TextCellValue(participant.createdAt.toIso8601String()),
        ]);
        for (final columnIndex in <int>[0, 1, 3, 4, 6, 7]) {
          _applyCellStyle(
            splitParticipantsSheet,
            rowIndex: rowIndex,
            columnIndex: columnIndex,
            style: numberStyle,
          );
        }
      }
      _setColumnWidths(
        splitParticipantsSheet,
        <double>[16, 16, 24, 14, 14, 12, 16, 12, 24],
      );
    }

    if (splitBundle.settlements.isNotEmpty) {
      final settlementsSheet = excel['Lent Settlements'];
      settlementsSheet.appendRow(<CellValue?>[
        TextCellValue('Settlement ID'),
        TextCellValue('Split Record ID'),
        TextCellValue('Split Participant ID'),
        TextCellValue('Income Entry ID'),
        TextCellValue('Settled Amount'),
        TextCellValue('Created At'),
      ]);
      _applyRowStyle(
        settlementsSheet,
        rowIndex: 0,
        columnCount: 6,
        style: wrappedHeaderStyle,
      );
      for (final settlement in splitBundle.settlements) {
        final rowIndex = settlementsSheet.maxRows;
        settlementsSheet.appendRow(<CellValue?>[
          _numericCell(settlement.id),
          _numericCell(settlement.splitRecordId),
          _numericCell(settlement.splitParticipantId),
          _numericCell(settlement.incomeEntryId),
          _numericCell(settlement.settledAmount),
          TextCellValue(settlement.createdAt.toIso8601String()),
        ]);
        for (final columnIndex in <int>[0, 1, 2, 3, 4]) {
          _applyCellStyle(
            settlementsSheet,
            rowIndex: rowIndex,
            columnIndex: columnIndex,
            style: numberStyle,
          );
        }
      }
      _setColumnWidths(settlementsSheet, <double>[16, 16, 18, 16, 16, 24]);
    }

    _setColumnWidths(summarySheet, <double>[26, 22]);
    _setColumnWidths(entriesSheet, <double>[
      12,
      14,
      24,
      14,
      18,
      16,
      16,
      18,
      18,
      28,
      14,
      16,
      14,
      14,
    ]);

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Unable to generate the expense Excel export.');
    }
    await file.writeAsBytes(Uint8List.fromList(bytes));
    return file.path;
  }

  Future<String> _exportTaskPdf({
    required DateTimeRange range,
    required List<TaskItem> tasks,
  }) async {
    final file = await _buildExportFile(
      moduleFolder: 'task',
      fileNameLabel: 'task',
      extension: 'pdf',
    );
    final timestamp = DateTime.now();
    final summary = _TaskExportSummary.fromTasks(tasks);
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => <pw.Widget>[
          pw.Text(
            'Task Export',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Range: ${_formatRange(range)}'),
          pw.Text(
            'Exported At: ${AppConstants.longDateFormat.format(timestamp)}',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const <String>['Metric', 'Value'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: <List<String>>[
              <String>[
                'Tasks',
                IndianNumberFormatter.formatFull(summary.totalTasks),
              ],
              <String>[
                'Completed',
                IndianNumberFormatter.formatFull(summary.completedCount),
              ],
              <String>[
                'Pending',
                IndianNumberFormatter.formatFull(summary.pendingCount),
              ],
              <String>[
                'Daily Tasks',
                IndianNumberFormatter.formatFull(summary.dailyTaskCount),
              ],
              <String>[
                'Categories',
                IndianNumberFormatter.formatFull(summary.categoryCount),
              ],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Tasks',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            headers: const <String>[
              'Date',
              'Title',
              'Category',
              'Priority',
              'Daily',
              'Completed',
              'Checklist',
              'Description',
            ],
            data: tasks
                .map(
                  (task) => <String>[
                    AppConstants.shortDateFormat.format(task.date),
                    task.title,
                    task.category,
                    IndianNumberFormatter.formatFull(task.priority),
                    task.isDaily ? 'Yes' : 'No',
                    task.isCompleted ? 'Yes' : 'No',
                    _formatTaskChecklist(task),
                    task.description.trim().isNotEmpty
                        ? task.description.trim()
                        : '-',
                  ],
                )
                .toList(growable: false),
          ),
        ],
      ),
    );

    await file.writeAsBytes(await document.save());
    return file.path;
  }

  Future<String> _exportTaskExcel({
    required DateTimeRange range,
    required List<TaskItem> tasks,
  }) async {
    final file = await _buildExportFile(
      moduleFolder: 'task',
      fileNameLabel: 'task',
      extension: 'xlsx',
    );
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Summary') {
      excel.rename(defaultSheet, 'Summary');
    }

    final summarySheet = excel['Summary'];
    final tasksSheet = excel['Tasks'];
    final summary = _TaskExportSummary.fromTasks(tasks);
    final headerStyle = CellStyle(bold: true);
    final numberStyle = CellStyle(
      numberFormat: const CustomNumericNumFormat(formatCode: '#,##,##0'),
    );

    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Task Export'),
      TextCellValue(''),
    ]);
    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Range'),
      TextCellValue(_formatRange(range)),
    ]);
    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Exported At'),
      TextCellValue(AppConstants.longDateFormat.format(DateTime.now())),
    ]);
    summarySheet.appendRow(const <CellValue?>[]);
    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Metric'),
      TextCellValue('Value'),
    ]);
    _applyRowStyle(
      summarySheet,
      rowIndex: 0,
      columnCount: 2,
      style: headerStyle,
    );
    _applyRowStyle(
      summarySheet,
      rowIndex: 4,
      columnCount: 2,
      style: headerStyle,
    );

    _appendSummaryNumberRow(
      summarySheet,
      'Tasks',
      summary.totalTasks,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Completed',
      summary.completedCount,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Pending',
      summary.pendingCount,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Daily Tasks',
      summary.dailyTaskCount,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Categories',
      summary.categoryCount,
      numberStyle,
    );

    tasksSheet.appendRow(<CellValue?>[
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Priority'),
      TextCellValue('Daily'),
      TextCellValue('Completed'),
      TextCellValue('Checklist'),
      TextCellValue('Description'),
    ]);
    _applyRowStyle(tasksSheet, rowIndex: 0, columnCount: 8, style: headerStyle);

    for (final task in tasks) {
      final rowIndex = tasksSheet.maxRows;
      tasksSheet.appendRow(<CellValue?>[
        TextCellValue(AppConstants.shortDateFormat.format(task.date)),
        TextCellValue(task.title),
        TextCellValue(task.category),
        _numericCell(task.priority),
        TextCellValue(task.isDaily ? 'Yes' : 'No'),
        TextCellValue(task.isCompleted ? 'Yes' : 'No'),
        TextCellValue(_formatTaskChecklist(task)),
        TextCellValue(task.description),
      ]);
      _applyCellStyle(
        tasksSheet,
        rowIndex: rowIndex,
        columnIndex: 3,
        style: numberStyle,
      );
    }

    _setColumnWidths(summarySheet, <double>[26, 22]);
    _setColumnWidths(tasksSheet, <double>[14, 26, 18, 12, 12, 14, 24, 32]);

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Unable to generate the task Excel export.');
    }
    await file.writeAsBytes(Uint8List.fromList(bytes));
    return file.path;
  }

  Future<String> _exportCredentialPdf({
    required List<DecryptedCredential> credentials,
  }) async {
    final file = await _buildExportFile(
      moduleFolder: 'credential',
      fileNameLabel: 'credential',
      extension: 'pdf',
    );
    final timestamp = DateTime.now();
    final summary = _CredentialExportSummary.fromCredentials(credentials);
    final rows = _credentialRows(credentials);
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => <pw.Widget>[
          pw.Text(
            'Credential Export',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Exported At: ${AppConstants.longDateFormat.format(timestamp)}',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const <String>['Metric', 'Value'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: <List<String>>[
              <String>[
                'Credentials',
                IndianNumberFormatter.formatFull(summary.totalCredentials),
              ],
              <String>[
                'Fields',
                IndianNumberFormatter.formatFull(summary.totalFields),
              ],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Credential Data',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            headers: const <String>[
              'Title',
              'Expiry',
              'Field',
              'Value',
              'Created',
              'Updated',
            ],
            data: rows
                .map(
                  (row) => <String>[
                    row.title,
                    row.expiryLabel,
                    row.fieldLabel,
                    row.fieldValue,
                    AppConstants.shortDateFormat.format(row.createdAt),
                    AppConstants.shortDateFormat.format(row.updatedAt),
                  ],
                )
                .toList(growable: false),
          ),
        ],
      ),
    );

    await file.writeAsBytes(await document.save());
    return file.path;
  }

  Future<String> _exportCredentialExcel({
    required List<DecryptedCredential> credentials,
  }) async {
    final file = await _buildExportFile(
      moduleFolder: 'credential',
      fileNameLabel: 'credential',
      extension: 'xlsx',
    );
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Summary') {
      excel.rename(defaultSheet, 'Summary');
    }

    final summarySheet = excel['Summary'];
    final credentialsSheet = excel['Credentials'];
    final summary = _CredentialExportSummary.fromCredentials(credentials);
    final rows = _credentialRows(credentials);
    final headerStyle = CellStyle(bold: true);
    final numberStyle = CellStyle(
      numberFormat: const CustomNumericNumFormat(formatCode: '#,##,##0'),
    );

    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Credential Export'),
      TextCellValue(''),
    ]);
    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Exported At'),
      TextCellValue(AppConstants.longDateFormat.format(DateTime.now())),
    ]);
    summarySheet.appendRow(const <CellValue?>[]);
    summarySheet.appendRow(<CellValue?>[
      TextCellValue('Metric'),
      TextCellValue('Value'),
    ]);
    _applyRowStyle(
      summarySheet,
      rowIndex: 0,
      columnCount: 2,
      style: headerStyle,
    );
    _applyRowStyle(
      summarySheet,
      rowIndex: 3,
      columnCount: 2,
      style: headerStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Credentials',
      summary.totalCredentials,
      numberStyle,
    );
    _appendSummaryNumberRow(
      summarySheet,
      'Fields',
      summary.totalFields,
      numberStyle,
    );

    credentialsSheet.appendRow(<CellValue?>[
      TextCellValue('Title'),
      TextCellValue('Expiry'),
      TextCellValue('Field'),
      TextCellValue('Value'),
      TextCellValue('Created'),
      TextCellValue('Updated'),
    ]);
    _applyRowStyle(
      credentialsSheet,
      rowIndex: 0,
      columnCount: 6,
      style: headerStyle,
    );

    for (final row in rows) {
      credentialsSheet.appendRow(<CellValue?>[
        TextCellValue(row.title),
        TextCellValue(row.expiryLabel),
        TextCellValue(row.fieldLabel),
        TextCellValue(row.fieldValue),
        TextCellValue(AppConstants.shortDateFormat.format(row.createdAt)),
        TextCellValue(AppConstants.shortDateFormat.format(row.updatedAt)),
      ]);
    }

    _setColumnWidths(summarySheet, <double>[24, 18]);
    _setColumnWidths(credentialsSheet, <double>[26, 16, 22, 34, 16, 16]);

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Unable to generate the credential Excel export.');
    }
    await file.writeAsBytes(Uint8List.fromList(bytes));
    return file.path;
  }

  Future<_ExpenseSplitExportBundle> _loadExpenseSplitExportBundle(
    List<ExpenseRecord> entries,
  ) async {
    final entryIds = entries.map((entry) => entry.id).toSet().toList(growable: false);
    if (entryIds.isEmpty) {
      return const _ExpenseSplitExportBundle();
    }

    final directlyLinkedSplitRecords =
        await (_database.select(_database.dbSplitRecords)..where(
          (table) =>
              table.expenseEntryId.isIn(entryIds) | table.lentEntryId.isIn(entryIds),
        ))
            .get();
    final settlementsByIncomeEntry =
        await (_database.select(_database.dbLentSettlements)
              ..where((table) => table.incomeEntryId.isIn(entryIds)))
            .get();
    final splitRecordIds = <int>{
      ...directlyLinkedSplitRecords.map((record) => record.id),
      ...settlementsByIncomeEntry.map((settlement) => settlement.splitRecordId),
    }.toList(growable: false);
    final splitRecords = splitRecordIds.isEmpty
        ? <DbSplitRecord>[]
        : await (_database.select(_database.dbSplitRecords)
              ..where((table) => table.id.isIn(splitRecordIds))
              ..orderBy(<OrderingTerm Function($DbSplitRecordsTable)>[
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();
    final splitParticipants = splitRecordIds.isEmpty
        ? <DbSplitParticipant>[]
        : await (_database.select(_database.dbSplitParticipants)
              ..where((table) => table.splitRecordId.isIn(splitRecordIds))
              ..orderBy(<OrderingTerm Function($DbSplitParticipantsTable)>[
                (table) => OrderingTerm.asc(table.splitRecordId),
                (table) => OrderingTerm.asc(table.sortOrder),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();
    final settlements = splitRecordIds.isEmpty
        ? <DbLentSettlement>[]
        : await (_database.select(_database.dbLentSettlements)
              ..where((table) => table.splitRecordId.isIn(splitRecordIds))
              ..orderBy(<OrderingTerm Function($DbLentSettlementsTable)>[
                (table) => OrderingTerm.asc(table.splitRecordId),
                (table) => OrderingTerm.asc(table.id),
              ]))
            .get();

    final pendingAmountByRecordId = <int, double>{};
    final participantCountByRecordId = <int, int>{};
    for (final participant in splitParticipants) {
      participantCountByRecordId.update(
        participant.splitRecordId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (!participant.isSelf) {
        pendingAmountByRecordId.update(
          participant.splitRecordId,
          (value) => value + (participant.amount - participant.settledAmount),
          ifAbsent: () => participant.amount - participant.settledAmount,
        );
      }
    }

    return _ExpenseSplitExportBundle(
      records: splitRecords,
      participants: splitParticipants,
      settlements: settlements,
      pendingAmountByRecordId: pendingAmountByRecordId.map(
        (key, value) => MapEntry(key, double.parse(value.toStringAsFixed(2))),
      ),
      participantCountByRecordId: participantCountByRecordId,
    );
  }

  void _appendSummaryNumberRow(
    Sheet sheet,
    String label,
    num value,
    CellStyle numberStyle,
  ) {
    final rowIndex = sheet.maxRows;
    sheet.appendRow(<CellValue?>[TextCellValue(label), _numericCell(value)]);
    _applyCellStyle(
      sheet,
      rowIndex: rowIndex,
      columnIndex: 1,
      style: numberStyle,
    );
  }

  CellValue _numericCell(num value) {
    if (value is int) {
      return IntCellValue(value);
    }

    final normalizedValue = value.toDouble();
    if (normalizedValue == normalizedValue.roundToDouble()) {
      return IntCellValue(normalizedValue.toInt());
    }

    return DoubleCellValue(normalizedValue);
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
      _applyCellStyle(
        sheet,
        rowIndex: rowIndex,
        columnIndex: columnIndex,
        style: style,
      );
    }
  }

  void _applyCellStyle(
    Sheet sheet, {
    required int rowIndex,
    required int columnIndex,
    required CellStyle style,
  }) {
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

  Future<File> _buildExportFile({
    required String moduleFolder,
    required String fileNameLabel,
    required String extension,
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
    final exportDirectory = Directory(
      path.join(baseDirectory.path, moduleFolder),
    );
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final dateLabel = AppConstants.exportFileDateFormat.format(DateTime.now());
    var suffix = 1;
    var fileName = '$dateLabel-$fileNameLabel.$extension';
    var file = File(path.join(exportDirectory.path, fileName));

    while (await file.exists()) {
      suffix += 1;
      fileName = '$dateLabel-$fileNameLabel-$suffix.$extension';
      file = File(path.join(exportDirectory.path, fileName));
    }

    return file;
  }

  String _formatRange(DateTimeRange range) {
    return '${AppConstants.shortDateFormat.format(range.start)} - ${AppConstants.shortDateFormat.format(range.end)}';
  }

  String _expenseTypeLabel(String type) {
    return switch (type) {
      'income' => 'Income',
      'lent' => 'Lent',
      'borrowed' => 'Borrowed',
      _ => 'Expense',
    };
  }

  String _formatTaskChecklist(TaskItem task) {
    if (task.checklist.isEmpty) {
      return '-';
    }

    return task.checklist
        .map(
          (item) => '${item.isCompleted ? '[x]' : '[ ]'} ${item.title}',
        )
        .join(' | ');
  }

  List<_CredentialExportRow> _credentialRows(
    List<DecryptedCredential> credentials,
  ) {
    return credentials
        .expand(
          (credential) => credential.fields.isEmpty
              ? <_CredentialExportRow>[
                  _CredentialExportRow(
                    title: credential.title,
                    expiryLabel: credential.expiryDate == null
                        ? '-'
                        : AppConstants.shortDateFormat.format(
                            credential.expiryDate!,
                          ),
                    fieldLabel: '-',
                    fieldValue: '-',
                    createdAt: credential.createdAt,
                    updatedAt: credential.updatedAt,
                  ),
                ]
              : credential.fields.map(
                  (field) => _CredentialExportRow(
                    title: credential.title,
                    expiryLabel: credential.expiryDate == null
                        ? '-'
                        : AppConstants.shortDateFormat.format(
                            credential.expiryDate!,
                          ),
                    fieldLabel: field.keyLabel,
                    fieldValue: field.value,
                    createdAt: credential.createdAt,
                    updatedAt: credential.updatedAt,
                  ),
                ),
        )
        .toList(growable: false);
  }
}

class _ExpenseExportSummary {
  const _ExpenseExportSummary({
    required this.totalCredit,
    required this.totalDebit,
    required this.totalBorrowed,
    required this.totalLent,
  });

  factory _ExpenseExportSummary.fromEntries(List<ExpenseRecord> entries) {
    double sumWhere(bool Function(ExpenseRecord entry) predicate) {
      return entries
          .where(predicate)
          .fold<double>(0, (sum, entry) => sum + entry.amount);
    }

    return _ExpenseExportSummary(
      totalCredit: sumWhere((entry) => entry.isCredit),
      totalDebit: sumWhere((entry) => entry.isDebit),
      totalBorrowed: sumWhere((entry) => entry.type == 'borrowed'),
      totalLent: sumWhere((entry) => entry.type == 'lent'),
    );
  }

  final double totalCredit;
  final double totalDebit;
  final double totalBorrowed;
  final double totalLent;

  double get netFlow => totalCredit - totalDebit;
}

class _ExpenseSplitExportBundle {
  const _ExpenseSplitExportBundle({
    this.records = const <DbSplitRecord>[],
    this.participants = const <DbSplitParticipant>[],
    this.settlements = const <DbLentSettlement>[],
    this.pendingAmountByRecordId = const <int, double>{},
    this.participantCountByRecordId = const <int, int>{},
  });

  final List<DbSplitRecord> records;
  final List<DbSplitParticipant> participants;
  final List<DbLentSettlement> settlements;
  final Map<int, double> pendingAmountByRecordId;
  final Map<int, int> participantCountByRecordId;
}

class _TaskExportSummary {
  const _TaskExportSummary({
    required this.totalTasks,
    required this.completedCount,
    required this.pendingCount,
    required this.dailyTaskCount,
    required this.categoryCount,
  });

  factory _TaskExportSummary.fromTasks(List<TaskItem> tasks) {
    final categoryCount = tasks.map((task) => task.category).toSet().length;
    final completedCount = tasks.where((task) => task.isCompleted).length;
    final totalTasks = tasks.length;

    return _TaskExportSummary(
      totalTasks: totalTasks,
      completedCount: completedCount,
      pendingCount: totalTasks - completedCount,
      dailyTaskCount: tasks.where((task) => task.isDaily).length,
      categoryCount: categoryCount,
    );
  }

  final int totalTasks;
  final int completedCount;
  final int pendingCount;
  final int dailyTaskCount;
  final int categoryCount;
}

class _CredentialExportSummary {
  const _CredentialExportSummary({
    required this.totalCredentials,
    required this.totalFields,
  });

  factory _CredentialExportSummary.fromCredentials(
    List<DecryptedCredential> credentials,
  ) {
    return _CredentialExportSummary(
      totalCredentials: credentials.length,
      totalFields: credentials.fold<int>(
        0,
        (sum, credential) => sum + credential.fields.length,
      ),
    );
  }

  final int totalCredentials;
  final int totalFields;
}

class _CredentialExportRow {
  const _CredentialExportRow({
    required this.title,
    required this.expiryLabel,
    required this.fieldLabel,
    required this.fieldValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String title;
  final String expiryLabel;
  final String fieldLabel;
  final String fieldValue;
  final DateTime createdAt;
  final DateTime updatedAt;
}
