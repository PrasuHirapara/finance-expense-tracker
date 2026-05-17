import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/app_settings_repository.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../domain/models/expense_models.dart';

class ExpenseState extends Equatable {
  const ExpenseState({
    this.status = ExpenseStatus.initial,
    this.selectedBankId,
    this.dashboard,
    this.errorMessage,
  });

  final ExpenseStatus status;
  final int? selectedBankId;
  final ExpenseDashboardData? dashboard;
  final String? errorMessage;

  ExpenseState copyWith({
    ExpenseStatus? status,
    int? selectedBankId,
    bool clearBankId = false,
    ExpenseDashboardData? dashboard,
    String? errorMessage,
  }) {
    return ExpenseState(
      status: status ?? this.status,
      selectedBankId: clearBankId
          ? null
          : selectedBankId ?? this.selectedBankId,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    selectedBankId,
    dashboard,
    errorMessage,
  ];
}

enum ExpenseStatus { initial, loading, success, failure }

sealed class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ExpenseSubscriptionRequested extends ExpenseEvent {
  const ExpenseSubscriptionRequested({this.bankId});

  final int? bankId;

  @override
  List<Object?> get props => <Object?>[bankId];
}

class ExpenseBankFilterChanged extends ExpenseEvent {
  const ExpenseBankFilterChanged(this.bankId);

  final int? bankId;

  @override
  List<Object?> get props => <Object?>[bankId];
}

class ExpenseRestoreRequested extends ExpenseEvent {
  const ExpenseRestoreRequested();
}

class _ExpenseDashboardUpdated extends ExpenseEvent {
  const _ExpenseDashboardUpdated(this.dashboard);

  final ExpenseDashboardData dashboard;

  @override
  List<Object?> get props => <Object?>[dashboard];
}

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc(this._repository, this._settingsRepository)
    : super(const ExpenseState()) {
    on<ExpenseSubscriptionRequested>(_onSubscriptionRequested);
    on<ExpenseBankFilterChanged>(_onBankFilterChanged);
    on<ExpenseRestoreRequested>(_onRestoreRequested);
    on<_ExpenseDashboardUpdated>(_onDashboardUpdated);
  }

  final ExpenseRepository _repository;
  final AppSettingsRepository _settingsRepository;
  StreamSubscription<ExpenseDashboardData>? _subscription;

  Future<void> _onSubscriptionRequested(
    ExpenseSubscriptionRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ExpenseStatus.loading,
        selectedBankId: event.bankId,
        clearBankId: event.bankId == null,
        errorMessage: null,
      ),
    );

    await _subscription?.cancel();
    _subscription = _repository
        .watchDashboard(bankId: event.bankId)
        .listen((dashboard) => add(_ExpenseDashboardUpdated(dashboard)));
  }

  Future<void> _onBankFilterChanged(
    ExpenseBankFilterChanged event,
    Emitter<ExpenseState> emit,
  ) async {
    await _settingsRepository.updateSelectedExpenseBankId(event.bankId);
    add(ExpenseSubscriptionRequested(bankId: event.bankId));
  }

  Future<void> _onRestoreRequested(
    ExpenseRestoreRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final settings = await _settingsRepository.getSettings();
    final savedBankId = settings.selectedExpenseBankId;
    final banks = await _repository.watchBanks().first;
    final restoredBankId = banks.any((bank) => bank.id == savedBankId)
        ? savedBankId
        : banks.isEmpty
        ? null
        : banks.first.id;
    if (savedBankId != restoredBankId) {
      await _settingsRepository.updateSelectedExpenseBankId(restoredBankId);
    }
    add(ExpenseSubscriptionRequested(bankId: restoredBankId));
  }

  void _onDashboardUpdated(
    _ExpenseDashboardUpdated event,
    Emitter<ExpenseState> emit,
  ) {
    emit(
      state.copyWith(
        status: ExpenseStatus.success,
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
