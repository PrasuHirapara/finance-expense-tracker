import '../entities/analytics_models.dart';
import '../entities/dashboard_snapshot.dart';
import '../entities/finance_category.dart';
import '../entities/finance_entry.dart';

abstract interface class FinanceRepository {
  Future<void> seedIfNeeded();

  Stream<List<FinanceCategory>> watchCategories();

  Future<void> addCategory({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  });

  Future<void> addEntry(FinanceEntryDraft draft);

  Stream<DashboardSnapshot> watchDashboardSnapshot(DateTime anchorDate);

  Future<AnalyticsReport> getAnalyticsReport({
    required AnalyticsWindow window,
    required DateTime anchorDate,
  });
}
