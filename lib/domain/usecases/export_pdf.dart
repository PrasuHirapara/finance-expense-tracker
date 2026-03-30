import '../entities/analytics_models.dart';
import '../entities/export_payload.dart';
import '../repositories/export_repository.dart';

class ExportPdf {
  ExportPdf(this._repository);

  final ExportRepository _repository;

  Future<String> call({
    required AnalyticsWindow window,
    required AnalyticsReport report,
    required ExportChartSnapshots snapshots,
  }) {
    return _repository.exportPdf(
      window: window,
      report: report,
      snapshots: snapshots,
    );
  }
}
