import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/export_payload.dart';
import '../../domain/repositories/export_repository.dart';

const Object _exportUnset = Object();

enum ExportStatus { initial, loading, success, failure }

class ExportState extends Equatable {
  const ExportState({this.status = ExportStatus.initial, this.errorMessage});

  final ExportStatus status;
  final String? errorMessage;

  bool get isLoading => status == ExportStatus.loading;

  ExportState copyWith({
    ExportStatus? status,
    Object? errorMessage = _exportUnset,
  }) {
    return ExportState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _exportUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, errorMessage];
}

class ExportCubit extends Cubit<ExportState> {
  ExportCubit(this._repository) : super(const ExportState());

  final ExportRepository _repository;

  Future<String> exportCsv({
    required AnalyticsWindow window,
    required AnalyticsReport report,
  }) async {
    emit(state.copyWith(status: ExportStatus.loading, errorMessage: null));
    try {
      final path = await _repository.exportCsv(window: window, report: report);
      emit(state.copyWith(status: ExportStatus.success, errorMessage: null));
      return path;
    } catch (error) {
      emit(
        state.copyWith(
          status: ExportStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<String> exportPdf({
    required AnalyticsWindow window,
    required AnalyticsReport report,
    required ExportChartSnapshots snapshots,
  }) async {
    emit(state.copyWith(status: ExportStatus.loading, errorMessage: null));
    try {
      final path = await _repository.exportPdf(
        window: window,
        report: report,
        snapshots: snapshots,
      );
      emit(state.copyWith(status: ExportStatus.success, errorMessage: null));
      return path;
    } catch (error) {
      emit(
        state.copyWith(
          status: ExportStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }
}
