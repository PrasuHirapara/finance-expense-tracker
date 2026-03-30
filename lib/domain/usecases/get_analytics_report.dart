import '../entities/analytics_models.dart';
import '../repositories/finance_repository.dart';

class GetAnalyticsReport {
  GetAnalyticsReport(this._repository);

  final FinanceRepository _repository;

  Future<AnalyticsReport> call({
    required AnalyticsWindow window,
    required DateTime anchorDate,
  }) {
    return _repository.getAnalyticsReport(
      window: window,
      anchorDate: anchorDate,
    );
  }
}
