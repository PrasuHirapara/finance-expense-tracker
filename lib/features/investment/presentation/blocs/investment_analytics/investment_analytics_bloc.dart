import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/investment_repository.dart';
import '../../../domain/models/investment_models.dart';

class InvestmentAnalyticsState extends Equatable {
  const InvestmentAnalyticsState({
    this.status = InvestmentAnalyticsStatus.initial,
    this.window = InvestmentAnalyticsWindow.all,
    this.selectedCategoryId,
    this.customStartDate,
    this.customEndDate,
    this.analytics,
    this.errorMessage,
  });

  final InvestmentAnalyticsStatus status;
  final InvestmentAnalyticsWindow window;
  final int? selectedCategoryId;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final InvestmentAnalyticsData? analytics;
  final String? errorMessage;

  InvestmentAnalyticsState copyWith({
    InvestmentAnalyticsStatus? status,
    InvestmentAnalyticsWindow? window,
    int? selectedCategoryId,
    bool clearCategory = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
    InvestmentAnalyticsData? analytics,
    String? errorMessage,
  }) {
    return InvestmentAnalyticsState(
      status: status ?? this.status,
      window: window ?? this.window,
      selectedCategoryId: clearCategory ? null : selectedCategoryId ?? this.selectedCategoryId,
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
        selectedCategoryId,
        customStartDate,
        customEndDate,
        analytics,
        errorMessage,
      ];
}

enum InvestmentAnalyticsStatus { initial, loading, success, failure }

sealed class InvestmentAnalyticsEvent extends Equatable {
  const InvestmentAnalyticsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class InvestmentAnalyticsRequested extends InvestmentAnalyticsEvent {
  const InvestmentAnalyticsRequested();
}

class InvestmentAnalyticsWindowChanged extends InvestmentAnalyticsEvent {
  const InvestmentAnalyticsWindowChanged(this.window);

  final InvestmentAnalyticsWindow window;

  @override
  List<Object?> get props => <Object?>[window];
}

class InvestmentAnalyticsCategoryChanged extends InvestmentAnalyticsEvent {
  const InvestmentAnalyticsCategoryChanged(this.categoryId);

  final int? categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

class InvestmentAnalyticsCustomRangeChanged extends InvestmentAnalyticsEvent {
  const InvestmentAnalyticsCustomRangeChanged({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => <Object?>[startDate, endDate];
}

class InvestmentAnalyticsBloc
    extends Bloc<InvestmentAnalyticsEvent, InvestmentAnalyticsState> {
  InvestmentAnalyticsBloc(this._repository)
      : super(const InvestmentAnalyticsState()) {
    on<InvestmentAnalyticsRequested>(_onRequested);
    on<InvestmentAnalyticsWindowChanged>(_onWindowChanged);
    on<InvestmentAnalyticsCategoryChanged>(_onCategoryChanged);
    on<InvestmentAnalyticsCustomRangeChanged>(_onCustomRangeChanged);
  }

  final InvestmentRepository _repository;

  Future<void> _onRequested(
    InvestmentAnalyticsRequested event,
    Emitter<InvestmentAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: InvestmentAnalyticsStatus.loading));
    try {
      final analytics = await _repository.loadAnalytics(
        window: state.window,
        categoryId: state.selectedCategoryId,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
      );
      emit(
        state.copyWith(
          status: InvestmentAnalyticsStatus.success,
          analytics: analytics,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: InvestmentAnalyticsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onWindowChanged(
    InvestmentAnalyticsWindowChanged event,
    Emitter<InvestmentAnalyticsState> emit,
  ) {
    emit(state.copyWith(window: event.window));
    add(const InvestmentAnalyticsRequested());
  }

  void _onCustomRangeChanged(
    InvestmentAnalyticsCustomRangeChanged event,
    Emitter<InvestmentAnalyticsState> emit,
  ) {
    final startDate = event.startDate.isAfter(event.endDate)
        ? event.endDate
        : event.startDate;
    final endDate = event.startDate.isAfter(event.endDate)
        ? event.startDate
        : event.endDate;
    emit(
      state.copyWith(
        window: InvestmentAnalyticsWindow.custom,
        customStartDate: startDate,
        customEndDate: endDate,
      ),
    );
    add(const InvestmentAnalyticsRequested());
  }

  void _onCategoryChanged(
    InvestmentAnalyticsCategoryChanged event,
    Emitter<InvestmentAnalyticsState> emit,
  ) {
    emit(
      event.categoryId == null
          ? state.copyWith(clearCategory: true)
          : state.copyWith(selectedCategoryId: event.categoryId),
    );
    add(const InvestmentAnalyticsRequested());
  }
}
