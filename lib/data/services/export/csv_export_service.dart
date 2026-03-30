import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/analytics_models.dart';

class CsvExportService {
  Future<String> export({
    required AnalyticsWindow window,
    required AnalyticsReport report,
  }) async {
    final exportDirectory = await _ensureExportDirectory();
    final timestamp = DateTime.now();
    final file = File(
      path.join(
        exportDirectory.path,
        'finance_${window.name}_${AppConstants.exportFileFormat.format(timestamp)}.csv',
      ),
    );

    final rows = <List<dynamic>>[
      <dynamic>['Exported At', AppConstants.longDateFormat.format(timestamp)],
      <dynamic>['Window', window.label],
      <dynamic>[
        'Range',
        '${AppConstants.shortDateFormat.format(report.rangeStart)} - ${AppConstants.shortDateFormat.format(report.rangeEnd)}',
      ],
      <dynamic>['Total Expense', report.totalExpense],
      <dynamic>['Total Income', report.totalIncome],
      <dynamic>['Total Borrowed', report.totalBorrowed],
      <dynamic>['Total Lent', report.totalLent],
      <dynamic>['Total Credit', report.totalCredit],
      <dynamic>['Total Debit', report.totalDebit],
      <dynamic>['Outstanding Liability', report.outstandingLiability],
      <dynamic>['Outstanding Receivable', report.outstandingReceivable],
      <dynamic>[],
      <dynamic>[
        'Title',
        'Type',
        'Category',
        'Amount',
        'Date',
        'Payment Mode',
        'Notes',
        'Counterparty',
      ],
      ...report.entries.map(
        (entry) => <dynamic>[
          entry.title,
          entry.type.label,
          entry.category.name,
          entry.amount,
          AppConstants.shortDateFormat.format(entry.date),
          entry.paymentMode,
          entry.notes,
          entry.counterparty ?? '',
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);
    return file.path;
  }

  Future<Directory> _ensureExportDirectory() async {
    final baseDirectory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(path.join(baseDirectory.path, 'exports'));
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }
    return exportDirectory;
  }
}
