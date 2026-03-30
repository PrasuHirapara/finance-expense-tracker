import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/export_repository_impl.dart';
import '../../data/repositories/finance_repository_impl.dart';
import '../../data/services/export/csv_export_service.dart';
import '../../data/services/export/pdf_export_service.dart';
import '../../data/services/seed_service.dart';
import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/repositories/export_repository.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/add_finance_entry.dart';
import '../../domain/usecases/export_csv.dart';
import '../../domain/usecases/export_pdf.dart';
import '../../domain/usecases/get_analytics_report.dart';
import '../../domain/usecases/get_dashboard_snapshot.dart';
import '../../domain/usecases/seed_data.dart';
import '../../domain/usecases/watch_categories.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final seedServiceProvider = Provider<SeedService>((ref) {
  return SeedService(ref.watch(appDatabaseProvider));
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    seedService: ref.watch(seedServiceProvider),
  );
});

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return ExportRepositoryImpl(
    csvExportService: CsvExportService(),
    pdfExportService: PdfExportService(),
  );
});

final seedDataUseCaseProvider = Provider<SeedData>((ref) {
  return SeedData(ref.watch(financeRepositoryProvider));
});

final watchCategoriesUseCaseProvider = Provider<WatchCategories>((ref) {
  return WatchCategories(ref.watch(financeRepositoryProvider));
});

final addCategoryUseCaseProvider = Provider<AddCategory>((ref) {
  return AddCategory(ref.watch(financeRepositoryProvider));
});

final addFinanceEntryUseCaseProvider = Provider<AddFinanceEntry>((ref) {
  return AddFinanceEntry(ref.watch(financeRepositoryProvider));
});

final getDashboardSnapshotUseCaseProvider = Provider<GetDashboardSnapshot>((
  ref,
) {
  return GetDashboardSnapshot(ref.watch(financeRepositoryProvider));
});

final getAnalyticsReportUseCaseProvider = Provider<GetAnalyticsReport>((ref) {
  return GetAnalyticsReport(ref.watch(financeRepositoryProvider));
});

final exportCsvUseCaseProvider = Provider<ExportCsv>((ref) {
  return ExportCsv(ref.watch(exportRepositoryProvider));
});

final exportPdfUseCaseProvider = Provider<ExportPdf>((ref) {
  return ExportPdf(ref.watch(exportRepositoryProvider));
});

final appStartupProvider = FutureProvider<void>((ref) async {
  await ref.watch(seedDataUseCaseProvider).call();
});

final categoriesProvider = StreamProvider<List<FinanceCategory>>((ref) {
  return ref.watch(watchCategoriesUseCaseProvider).call();
});

final dashboardSnapshotProvider = StreamProvider<DashboardSnapshot>((ref) {
  return ref.watch(getDashboardSnapshotUseCaseProvider).call(DateTime.now());
});

final analyticsWindowProvider = StateProvider<AnalyticsWindow>(
  (ref) => AnalyticsWindow.monthly,
);

final analyticsReportProvider = FutureProvider.autoDispose
    .family<AnalyticsReport, AnalyticsWindow>((ref, window) {
      return ref
          .watch(getAnalyticsReportUseCaseProvider)
          .call(window: window, anchorDate: DateTime.now());
    });
