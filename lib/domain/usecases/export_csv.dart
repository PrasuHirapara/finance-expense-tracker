import '../entities/analytics_models.dart';
import '../repositories/export_repository.dart';

class ExportCsv {
  ExportCsv(this._repository);

  final ExportRepository _repository;

  Future<String> call({
    required AnalyticsWindow window,
    required AnalyticsReport report,
  }) {
    return _repository.exportCsv(window: window, report: report);
  }
}
