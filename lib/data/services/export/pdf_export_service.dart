import 'dart:typed_data';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/analytics_models.dart';
import '../../../domain/entities/export_payload.dart';

class PdfExportService {
  Future<String> export({
    required AnalyticsWindow window,
    required AnalyticsReport report,
    required ExportChartSnapshots snapshots,
  }) async {
    final exportDirectory = await _ensureExportDirectory();
    final timestamp = DateTime.now();
    final file = File(
      path.join(
        exportDirectory.path,
        'finance_${window.name}_${AppConstants.exportFileFormat.format(timestamp)}.pdf',
      ),
    );
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'INR ',
      decimalDigits: 0,
    );

    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(28)),
        build: (context) => <pw.Widget>[
          pw.Text(
            'Daily Use Analytics Export',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Window: ${window.label}'),
          pw.Text(
            'Range: ${AppConstants.shortDateFormat.format(report.rangeStart)} - ${AppConstants.shortDateFormat.format(report.rangeEnd)}',
          ),
          pw.Text(
            'Exported At: ${AppConstants.longDateFormat.format(timestamp)}',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: const <String>['Metric', 'Value'],
            data: <List<String>>[
              <String>['Total Expense', currency.format(report.totalExpense)],
              <String>['Total Income', currency.format(report.totalIncome)],
              <String>['Total Borrowed', currency.format(report.totalBorrowed)],
              <String>['Total Lent', currency.format(report.totalLent)],
              <String>['Total Credit', currency.format(report.totalCredit)],
              <String>['Total Debit', currency.format(report.totalDebit)],
              <String>[
                'Outstanding Liability',
                currency.format(report.outstandingLiability),
              ],
              <String>[
                'Outstanding Receivable',
                currency.format(report.outstandingReceivable),
              ],
              <String>['Net Cash Flow', currency.format(report.netCashFlow)],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Transactions',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: const <String>[
              'Date',
              'Title',
              'Type',
              'Category',
              'Amount',
              'Mode',
            ],
            data: report.entries
                .map(
                  (entry) => <String>[
                    AppConstants.shortDateFormat.format(entry.date),
                    entry.title,
                    entry.type.label,
                    entry.category.name,
                    currency.format(entry.amount),
                    entry.paymentMode,
                  ],
                )
                .toList(growable: false),
          ),
          if (snapshots.pieChart != null ||
              snapshots.lineChart != null ||
              snapshots.barChart != null) ...<pw.Widget>[
            pw.SizedBox(height: 20),
            pw.Text(
              'Chart Snapshots',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            if (snapshots.pieChart != null)
              _buildChartBlock(
                title: 'Category Distribution',
                imageBytes: snapshots.pieChart!,
              ),
            if (snapshots.lineChart != null)
              _buildChartBlock(
                title: 'Expense Trendline',
                imageBytes: snapshots.lineChart!,
              ),
            if (snapshots.barChart != null)
              _buildChartBlock(
                title: 'Borrowed vs Lent',
                imageBytes: snapshots.barChart!,
              ),
          ],
        ],
      ),
    );

    await file.writeAsBytes(await document.save());
    return file.path;
  }

  pw.Widget _buildChartBlock({
    required String title,
    required Uint8List imageBytes,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Image(
              pw.MemoryImage(imageBytes),
              fit: pw.BoxFit.contain,
              height: 180,
            ),
          ),
        ],
      ),
    );
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
