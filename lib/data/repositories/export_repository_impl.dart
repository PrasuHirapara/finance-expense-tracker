import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/export_payload.dart';
import '../../domain/repositories/export_repository.dart';
import '../services/export/csv_export_service.dart';
import '../services/export/pdf_export_service.dart';

class ExportRepositoryImpl implements ExportRepository {
  ExportRepositoryImpl({
    required CsvExportService csvExportService,
    required PdfExportService pdfExportService,
  }) : _csvExportService = csvExportService,
       _pdfExportService = pdfExportService;

  final CsvExportService _csvExportService;
  final PdfExportService _pdfExportService;

  @override
  Future<String> exportCsv({
    required AnalyticsWindow window,
    required AnalyticsReport report,
  }) {
    return _csvExportService.export(window: window, report: report);
  }

  @override
  Future<String> exportPdf({
    required AnalyticsWindow window,
    required AnalyticsReport report,
    required ExportChartSnapshots snapshots,
  }) {
    return _pdfExportService.export(
      window: window,
      report: report,
      snapshots: snapshots,
    );
  }
}
