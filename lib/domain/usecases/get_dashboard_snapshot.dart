import '../entities/dashboard_snapshot.dart';
import '../repositories/finance_repository.dart';

class GetDashboardSnapshot {
  GetDashboardSnapshot(this._repository);

  final FinanceRepository _repository;

  Stream<DashboardSnapshot> call(DateTime anchorDate) {
    return _repository.watchDashboardSnapshot(anchorDate);
  }
}
