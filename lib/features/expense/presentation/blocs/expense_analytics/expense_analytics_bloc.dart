import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/expense_repository.dart';
import '../../../domain/models/expense_models.dart';

class ExpenseAnalyticsState extends Equatable {
  const ExpenseAnalyticsState({
    this.status = ExpenseAnalyticsStatus.initial,
    this.window = ExpenseAnalyticsWindow.monthly,
    this.selectedBankId,
    this.customStartDate,
    this.customEndDate,
    this.analytics,
    this.errorMessage,
  });

  final ExpenseAnalyticsStatus status;
  final ExpenseAnalyticsWindow window;
  final int? selectedBankId;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final ExpenseAnalyticsData? analytics;
  final String? errorMessage;

  ExpenseAnalyticsState copyWith({
    ExpenseAnalyticsStatus? status,
    ExpenseAnalyticsWindow? window,
    int? selectedBankId,
    bool clearBank = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
    ExpenseAnalyticsData? analytics,
    String? errorMessage,
  }) {
    return ExpenseAnalyticsState(
      status: status ?? this.status,
      window: window ?? this.window,
      selectedBankId: clearBank ? null : selectedBankId ?? this.selectedBankId,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      analytics: analytics ?? this.analytics,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    window,
    selectedBankId,
    customStartDate,
    customEndDate,
    analytics,
    errorMessage,
  ];
}

enum ExpenseAnalyticsStatus { initial, loading, success, failure }

sealed class ExpenseAnalyticsEvent extends Equatable {
  const ExpenseAnalyticsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ExpenseAnalyticsRequested extends ExpenseAnalyticsEvent {
  const ExpenseAnalyticsRequested();
}

class ExpenseAnalyticsWindowChanged extends ExpenseAnalyticsEvent {
  const ExpenseAnalyticsWindowChanged(this.window);

  final ExpenseAnalyticsWindow window;

  @override
  List<Object?> get props => <Object?>[window];
}

class ExpenseAnalyticsBankChanged extends ExpenseAnalyticsEvent {
  const ExpenseAnalyticsBankChanged(this.bankId);

  final int? bankId;

  @override
  List<Object?> get props => <Object?>[bankId];
}

class ExpenseAnalyticsCustomRangeChanged extends ExpenseAnalyticsEvent {
  const ExpenseAnalyticsCustomRangeChanged({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => <Object?>[startDate, endDate];
}

class ExpenseAnalyticsBloc
    extends Bloc<ExpenseAnalyticsEvent, ExpenseAnalyticsState> {
  ExpenseAnalyticsBloc(this._repository)
    : super(const ExpenseAnalyticsState()) {
    on<ExpenseAnalyticsRequested>(_onRequested);
    on<ExpenseAnalyticsWindowChanged>(_onWindowChanged);
    on<ExpenseAnalyticsBankChanged>(_onBankChanged);
    on<ExpenseAnalyticsCustomRangeChanged>(_onCustomRangeChanged);
  }

  final ExpenseRepository _repository;

  Future<void> _onRequested(
    ExpenseAnalyticsRequested event,
    Emitter<ExpenseAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseAnalyticsStatus.loading));
    try {
      final analytics = await _repository.loadAnalytics(
        window: state.window,
        bankId: state.selectedBankId,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
      );
      emit(
        state.copyWith(
          status: ExpenseAnalyticsStatus.success,
          analytics: analytics,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ExpenseAnalyticsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onWindowChanged(
    ExpenseAnalyticsWindowChanged event,
    Emitter<ExpenseAnalyticsState> emit,
  ) {
    emit(state.copyWith(window: event.window));
    add(const ExpenseAnalyticsRequested());
  }

  void _onCustomRangeChanged(
    ExpenseAnalyticsCustomRangeChanged event,
    Emitter<ExpenseAnalyticsState> emit,
  ) {
    final startDate = event.startDate.isAfter(event.endDate)
        ? event.endDate
        : event.startDate;
    final endDate = event.startDate.isAfter(event.endDate)
        ? event.startDate
        : event.endDate;
    emit(
      state.copyWith(
        window: ExpenseAnalyticsWindow.custom,
        customStartDate: startDate,
        customEndDate: endDate,
      ),
    );
    add(const ExpenseAnalyticsRequested());
  }

  void _onBankChanged(
    ExpenseAnalyticsBankChanged event,
    Emitter<ExpenseAnalyticsState> emit,
  ) {
    emit(
      event.bankId == null
          ? state.copyWith(clearBank: true)
          : state.copyWith(selectedBankId: event.bankId),
    );
    add(const ExpenseAnalyticsRequested());
  }
}
