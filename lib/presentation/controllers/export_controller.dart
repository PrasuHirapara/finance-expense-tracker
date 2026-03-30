import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/export_payload.dart';
import 'app_providers.dart';

class ExportController extends StateNotifier<AsyncValue<String?>> {
  ExportController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<String> exportCsv({
    required AnalyticsWindow window,
    required AnalyticsReport report,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _ref
          .read(exportCsvUseCaseProvider)
          .call(window: window, report: report),
    );
    state = result;
    return result.requireValue;
  }

  Future<String> exportPdf({
    required AnalyticsWindow window,
    required AnalyticsReport report,
    required ExportChartSnapshots snapshots,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _ref
          .read(exportPdfUseCaseProvider)
          .call(window: window, report: report, snapshots: snapshots),
    );
    state = result;
    return result.requireValue;
  }
}

final exportControllerProvider =
    StateNotifierProvider<ExportController, AsyncValue<String?>>(
      (ref) => ExportController(ref),
    );
