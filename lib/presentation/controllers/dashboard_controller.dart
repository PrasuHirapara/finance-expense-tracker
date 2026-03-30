import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/repositories/finance_repository.dart';

const Object _dashboardUnset = Object();

enum DashboardStatus { loading, ready, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.loading,
    this.snapshot,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardSnapshot? snapshot;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    Object? snapshot = _dashboardUnset,
    Object? errorMessage = _dashboardUnset,
  }) {
    return DashboardState(
      status: status ?? this.status,
      snapshot: identical(snapshot, _dashboardUnset)
          ? this.snapshot
          : snapshot as DashboardSnapshot?,
      errorMessage: identical(errorMessage, _dashboardUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, snapshot, errorMessage];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());

  final FinanceRepository _repository;
  StreamSubscription<DashboardSnapshot>? _snapshotSubscription;

  void initialize() {
    _snapshotSubscription ??= _repository.watchDashboardSnapshot(DateTime.now()).listen(
      (snapshot) {
        emit(
          state.copyWith(
            status: DashboardStatus.ready,
            snapshot: snapshot,
            errorMessage: null,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(
          state.copyWith(
            status: DashboardStatus.failure,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    return super.close();
  }
}
