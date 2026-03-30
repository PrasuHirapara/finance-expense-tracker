import '../entities/analytics_models.dart';
import '../entities/export_payload.dart';

abstract interface class ExportRepository {
  Future<String> exportCsv({
    required AnalyticsWindow window,
    required AnalyticsReport report,
  });

  Future<String> exportPdf({
    required AnalyticsWindow window,
    required AnalyticsReport report,
    required ExportChartSnapshots snapshots,
  });
}
