import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/app_settings_repository.dart';
import '../../../data/repositories/investment_repository.dart';
import '../../../domain/models/investment_models.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class InvestmentState extends Equatable {
  const InvestmentState({
    this.status = InvestmentStatus.initial,
    this.selectedCategoryId,
    this.selectedDateRange,
    this.selectedWindow = InvestmentAnalyticsWindow.all,
    this.dashboard,
    this.errorMessage,
  });

  final InvestmentStatus status;
  final int? selectedCategoryId;
  final DateTimeRange? selectedDateRange;
  final InvestmentAnalyticsWindow selectedWindow;
  final InvestmentDashboardData? dashboard;
  final String? errorMessage;

  InvestmentState copyWith({
    InvestmentStatus? status,
    int? selectedCategoryId,
    bool clearCategory = false,
    DateTimeRange? selectedDateRange,
    bool clearDateRange = false,
    InvestmentAnalyticsWindow? selectedWindow,
    InvestmentDashboardData? dashboard,
    String? errorMessage,
  }) {
    return InvestmentState(
      status: status ?? this.status,
      selectedCategoryId: clearCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      selectedDateRange: clearDateRange
          ? null
          : selectedDateRange ?? this.selectedDateRange,
      selectedWindow: selectedWindow ?? this.selectedWindow,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    selectedCategoryId,
    selectedDateRange,
    selectedWindow,
    dashboard,
    errorMessage,
  ];
}

enum InvestmentStatus { initial, loading, success, failure }

// ─── Events ──────────────────────────────────────────────────────────────────

sealed class InvestmentEvent extends Equatable {
  const InvestmentEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Fired on screen open to restore persisted filter from settings.
class InvestmentRestoreRequested extends InvestmentEvent {
  const InvestmentRestoreRequested();
}

class InvestmentSubscriptionRequested extends InvestmentEvent {
  const InvestmentSubscriptionRequested({this.categoryId, this.dateRange});

  final int? categoryId;
  final DateTimeRange? dateRange;

  @override
  List<Object?> get props => <Object?>[categoryId, dateRange];
}

class InvestmentCategoryFilterChanged extends InvestmentEvent {
  const InvestmentCategoryFilterChanged(this.categoryId);

  final int? categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

class InvestmentDateFilterChanged extends InvestmentEvent {
  const InvestmentDateFilterChanged({required this.window, this.dateRange});

  final InvestmentAnalyticsWindow window;
  final DateTimeRange? dateRange;

  @override
  List<Object?> get props => <Object?>[window, dateRange];
}

class InvestmentDeleted extends InvestmentEvent {
  const InvestmentDeleted(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

class _InvestmentDashboardUpdated extends InvestmentEvent {
  const _InvestmentDashboardUpdated(this.dashboard);

  final InvestmentDashboardData dashboard;

  @override
  List<Object?> get props => <Object?>[dashboard];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class InvestmentBloc extends Bloc<InvestmentEvent, InvestmentState> {
  InvestmentBloc(this._repository, this._settingsRepository)
    : super(const InvestmentState()) {
    on<InvestmentRestoreRequested>(_onRestoreRequested);
    on<InvestmentSubscriptionRequested>(_onSubscriptionRequested);
    on<InvestmentCategoryFilterChanged>(_onCategoryFilterChanged);
    on<InvestmentDateFilterChanged>(_onDateFilterChanged);
    on<InvestmentDeleted>(_onDeleted);
    on<_InvestmentDashboardUpdated>(_onDashboardUpdated);
  }

  final InvestmentRepository _repository;
  final AppSettingsRepository _settingsRepository;
  StreamSubscription<InvestmentDashboardData>? _subscription;

  // Restore persisted category filter from settings then start subscription.
  Future<void> _onRestoreRequested(
    InvestmentRestoreRequested event,
    Emitter<InvestmentState> emit,
  ) async {
    final settings = await _settingsRepository.getSettings();
    final savedCategoryId = settings.selectedInvestmentCategoryId;

    // Validate that saved category still exists in DB.
    int? resolvedCategoryId;
    if (savedCategoryId != null) {
      final categories = await _repository.getCategories();
      if (categories.any((c) => c.id == savedCategoryId)) {
        resolvedCategoryId = savedCategoryId;
      }
    }
    add(InvestmentSubscriptionRequested(categoryId: resolvedCategoryId));
  }

  Future<void> _onSubscriptionRequested(
    InvestmentSubscriptionRequested event,
    Emitter<InvestmentState> emit,
  ) async {
    emit(
      state.copyWith(
        status: InvestmentStatus.loading,
        selectedCategoryId: event.categoryId,
        clearCategory: event.categoryId == null,
        selectedDateRange: event.dateRange,
        clearDateRange: event.dateRange == null,
        errorMessage: null,
      ),
    );

    await _subscription?.cancel();
    _subscription = _repository
        .watchDashboard(
          categoryId: event.categoryId,
          dateRange: event.dateRange,
        )
        .listen((dashboard) => add(_InvestmentDashboardUpdated(dashboard)));
  }

  // Persist then reload.
  Future<void> _onCategoryFilterChanged(
    InvestmentCategoryFilterChanged event,
    Emitter<InvestmentState> emit,
  ) async {
    await _settingsRepository.updateSelectedInvestmentCategoryId(
      event.categoryId,
    );
    add(
      InvestmentSubscriptionRequested(
        categoryId: event.categoryId,
        dateRange: state.selectedDateRange,
      ),
    );
  }

  void _onDateFilterChanged(
    InvestmentDateFilterChanged event,
    Emitter<InvestmentState> emit,
  ) {
    emit(state.copyWith(selectedWindow: event.window));
    add(
      InvestmentSubscriptionRequested(
        categoryId: state.selectedCategoryId,
        dateRange: event.dateRange,
      ),
    );
  }

  Future<void> _onDeleted(
    InvestmentDeleted event,
    Emitter<InvestmentState> emit,
  ) async {
    try {
      await _repository.deleteBuyEntry(event.id);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onDashboardUpdated(
    _InvestmentDashboardUpdated event,
    Emitter<InvestmentState> emit,
  ) {
    emit(
      state.copyWith(
        status: InvestmentStatus.success,
        dashboard: event.dashboard,
        errorMessage: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
