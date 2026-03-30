import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/expense_repository.dart';
import '../../../domain/models/expense_models.dart';

class BankState extends Equatable {
  const BankState({
    this.status = BankStatus.initial,
    this.banks = const <BankName>[],
    this.errorMessage,
  });

  final BankStatus status;
  final List<BankName> banks;
  final String? errorMessage;

  BankState copyWith({
    BankStatus? status,
    List<BankName>? banks,
    String? errorMessage,
  }) {
    return BankState(
      status: status ?? this.status,
      banks: banks ?? this.banks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, banks, errorMessage];
}

enum BankStatus { initial, loading, success, failure }

sealed class BankEvent extends Equatable {
  const BankEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class BanksSubscriptionRequested extends BankEvent {
  const BanksSubscriptionRequested();
}

class _BanksUpdated extends BankEvent {
  const _BanksUpdated(this.banks);

  final List<BankName> banks;

  @override
  List<Object?> get props => <Object?>[banks];
}

class BankAdded extends BankEvent {
  const BankAdded(this.name);

  final String name;

  @override
  List<Object?> get props => <Object?>[name];
}

class BankUpdated extends BankEvent {
  const BankUpdated({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => <Object?>[id, name];
}

class BankDeleted extends BankEvent {
  const BankDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => <Object?>[id];
}

class BankBloc extends Bloc<BankEvent, BankState> {
  BankBloc(this._repository) : super(const BankState()) {
    on<BanksSubscriptionRequested>(_onSubscriptionRequested);
    on<_BanksUpdated>(_onBanksUpdated);
    on<BankAdded>(_onBankAdded);
    on<BankUpdated>(_onBankUpdated);
    on<BankDeleted>(_onBankDeleted);
  }

  final ExpenseRepository _repository;
  StreamSubscription<List<BankName>>? _subscription;

  Future<void> _onSubscriptionRequested(
    BanksSubscriptionRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(state.copyWith(status: BankStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchBanks().listen(
      (banks) => add(_BanksUpdated(banks)),
    );
  }

  void _onBanksUpdated(_BanksUpdated event, Emitter<BankState> emit) {
    emit(
      state.copyWith(
        status: BankStatus.success,
        banks: event.banks,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onBankAdded(BankAdded event, Emitter<BankState> emit) async {
    await _performMutation(emit, () => _repository.createBank(event.name));
  }

  Future<void> _onBankUpdated(
    BankUpdated event,
    Emitter<BankState> emit,
  ) async {
    await _performMutation(
      emit,
      () => _repository.updateBank(id: event.id, name: event.name),
    );
  }

  Future<void> _onBankDeleted(
    BankDeleted event,
    Emitter<BankState> emit,
  ) async {
    await _performMutation(emit, () => _repository.deleteBank(event.id));
  }

  Future<void> _performMutation(
    Emitter<BankState> emit,
    Future<void> Function() action,
  ) async {
    try {
      emit(state.copyWith(status: BankStatus.loading, errorMessage: null));
      await action();
    } catch (error) {
      emit(
        state.copyWith(
          status: BankStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
