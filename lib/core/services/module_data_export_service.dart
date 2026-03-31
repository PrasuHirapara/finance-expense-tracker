import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/expense/domain/models/expense_models.dart';
import '../../features/tasks/domain/models/task_models.dart';
import '../constants/app_constants.dart';
import '../formatters/indian_number_formatter.dart';
import '../models/module_export_models.dart';
import 'app_settings_repository.dart';

class ModuleDataExportService {
  ModuleDataExportService(this._appSettingsRepository);

  final AppSettingsRepository _appSettingsRepository;

  Future<String> exportExpenseData({
    required DateTimeRange range,
    required ModuleExportFormat format,
    required List<ExpenseRecord> entries,
  }) {
    return switch (format) {
      ModuleExportFormat.pdf => _exportExpensePdf(range: range, entries: entries),
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

  Future<String> _exportExpensePdf({
    required DateTimeRange range,
    required List<ExpenseRecord> entries,
  }) async {
    final file = await _buildExportFile(
      moduleFolder: 'expense',
      fileNamePrefix: 'expense_export',
      extension: 'pdf',
    );
    final timestamp = DateTime.now();
    final summary = _ExpenseExportSummary.fromEntries(entries);
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
              <String>['Entries', IndianNumberFormatter.formatFull(entries.length)],
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
              <String>['Net Flow', IndianNumberFormatter.formatFull(summary.netFlow)],
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
              'Date',
              'Title',
              'Type',
              'Category',
              'Bank',
              'Amount',
              'Mode',
              'Counterparty',
              'Notes',
            ],
            data: entries
                .map(
                  (entry) => <String>[
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

  Future<String> _exportExpenseExcel({
    required DateTimeRange range,
    required List<ExpenseRecord> entries,
  }) async {
    final file = await _buildExportFile(
      moduleFolder: 'expense',
      fileNamePrefix: 'expense_export',
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
    _applyRowStyle(summarySheet, rowIndex: 0, columnCount: 2, style: headerStyle);
    _applyRowStyle(summarySheet, rowIndex: 4, columnCount: 2, style: headerStyle);

    _appendSummaryNumberRow(summarySheet, 'Entries', entries.length, numberStyle);
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
      TextCellValue('Date'),
      TextCellValue('Title'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Bank'),
      TextCellValue('Amount'),
      TextCellValue('Payment Mode'),
      TextCellValue('Counterparty'),
      TextCellValue('Notes'),
    ]);
    _applyRowStyle(
      entriesSheet,
      rowIndex: 0,
      columnCount: 9,
      style: wrappedHeaderStyle,
    );

    for (final entry in entries) {
      final rowIndex = entriesSheet.maxRows;
      entriesSheet.appendRow(<CellValue?>[
        TextCellValue(AppConstants.shortDateFormat.format(entry.date)),
        TextCellValue(entry.title),
        TextCellValue(_expenseTypeLabel(entry.type)),
        TextCellValue(entry.category.name),
        TextCellValue(entry.bank?.name ?? ''),
        _numericCell(entry.amount),
        TextCellValue(entry.paymentMode),
        TextCellValue(entry.counterparty ?? ''),
        TextCellValue(entry.notes),
      ]);
      _applyCellStyle(
        entriesSheet,
        rowIndex: rowIndex,
        columnIndex: 5,
        style: numberStyle,
      );
    }

    _setColumnWidths(
      summarySheet,
      <double>[26, 22],
    );
    _setColumnWidths(
      entriesSheet,
      <double>[14, 24, 14, 18, 16, 16, 18, 18, 28],
    );

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
      moduleFolder: 'tasks',
      fileNamePrefix: 'task_export',
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
              <String>['Tasks', IndianNumberFormatter.formatFull(summary.totalTasks)],
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
      moduleFolder: 'tasks',
      fileNamePrefix: 'task_export',
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
    _applyRowStyle(summarySheet, rowIndex: 0, columnCount: 2, style: headerStyle);
    _applyRowStyle(summarySheet, rowIndex: 4, columnCount: 2, style: headerStyle);

    _appendSummaryNumberRow(summarySheet, 'Tasks', summary.totalTasks, numberStyle);
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
      TextCellValue('Description'),
    ]);
    _applyRowStyle(tasksSheet, rowIndex: 0, columnCount: 7, style: headerStyle);

    for (final task in tasks) {
      final rowIndex = tasksSheet.maxRows;
      tasksSheet.appendRow(<CellValue?>[
        TextCellValue(AppConstants.shortDateFormat.format(task.date)),
        TextCellValue(task.title),
        TextCellValue(task.category),
        _numericCell(task.priority),
        TextCellValue(task.isDaily ? 'Yes' : 'No'),
        TextCellValue(task.isCompleted ? 'Yes' : 'No'),
        TextCellValue(task.description),
      ]);
      _applyCellStyle(
        tasksSheet,
        rowIndex: rowIndex,
        columnIndex: 3,
        style: numberStyle,
      );
    }

    _setColumnWidths(
      summarySheet,
      <double>[26, 22],
    );
    _setColumnWidths(
      tasksSheet,
      <double>[14, 26, 18, 12, 12, 14, 32],
    );

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Unable to generate the task Excel export.');
    }
    await file.writeAsBytes(Uint8List.fromList(bytes));
    return file.path;
  }

  void _appendSummaryNumberRow(
    Sheet sheet,
    String label,
    num value,
    CellStyle numberStyle,
  ) {
    final rowIndex = sheet.maxRows;
    sheet.appendRow(<CellValue?>[
      TextCellValue(label),
      _numericCell(value),
    ]);
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
        .cellStyle = style;
  }

  Future<File> _buildExportFile({
    required String moduleFolder,
    required String fileNamePrefix,
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

    final timestamp = AppConstants.exportFileFormat.format(DateTime.now());
    return File(
      path.join(exportDirectory.path, '${fileNamePrefix}_$timestamp.$extension'),
    );
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
