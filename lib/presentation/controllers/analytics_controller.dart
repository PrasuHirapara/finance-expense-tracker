import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/analytics_models.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/repositories/finance_repository.dart';

const Object _analyticsUnset = Object();

enum AnalyticsStatus { loading, ready, failure }

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.status = AnalyticsStatus.loading,
    this.window = AnalyticsWindow.monthly,
    this.report,
    this.errorMessage,
  });

  final AnalyticsStatus status;
  final AnalyticsWindow window;
  final AnalyticsReport? report;
  final String? errorMessage;

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    AnalyticsWindow? window,
    Object? report = _analyticsUnset,
    Object? errorMessage = _analyticsUnset,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      window: window ?? this.window,
      report: identical(report, _analyticsUnset)
          ? this.report
          : report as AnalyticsReport?,
      errorMessage: identical(errorMessage, _analyticsUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, window, report, errorMessage];
}

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit(this._repository) : super(const AnalyticsState());

  final FinanceRepository _repository;
  StreamSubscription<DashboardSnapshot>? _refreshSubscription;
  bool _isRefreshing = false;

  Future<void> initialize() async {
    await refresh(showLoading: true);
    _refreshSubscription ??= _repository
        .watchDashboardSnapshot(DateTime.now())
        .skip(1)
        .listen((_) {
          refresh(showLoading: false);
        });
  }

  Future<void> selectWindow(AnalyticsWindow window) async {
    emit(
      state.copyWith(
        window: window,
        status: AnalyticsStatus.loading,
        report: null,
        errorMessage: null,
      ),
    );
    await refresh(showLoading: false);
  }

  Future<void> refresh({required bool showLoading}) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    if (showLoading && state.report == null) {
      emit(
        state.copyWith(
          status: AnalyticsStatus.loading,
          errorMessage: null,
        ),
      );
    }

    try {
      final report = await _repository.getAnalyticsReport(
        window: state.window,
        anchorDate: DateTime.now(),
      );
      emit(
        state.copyWith(
          status: AnalyticsStatus.ready,
          report: report,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AnalyticsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Future<void> close() async {
    await _refreshSubscription?.cancel();
    return super.close();
  }
}
