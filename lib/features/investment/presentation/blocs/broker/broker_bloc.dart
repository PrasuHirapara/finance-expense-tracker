import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/investment_repository.dart';
import '../../../domain/models/investment_models.dart';

class BrokerState extends Equatable {
  const BrokerState({
    this.status = BrokerStatus.initial,
    this.profiles = const <TaxProfile>[],
    this.errorMessage,
  });

  final BrokerStatus status;
  final List<TaxProfile> profiles;
  final String? errorMessage;

  BrokerState copyWith({
    BrokerStatus? status,
    List<TaxProfile>? profiles,
    String? errorMessage,
  }) {
    return BrokerState(
      status: status ?? this.status,
      profiles: profiles ?? this.profiles,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, profiles, errorMessage];
}

enum BrokerStatus { initial, loading, success, failure }

sealed class BrokerEvent extends Equatable {
  const BrokerEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class BrokersSubscriptionRequested extends BrokerEvent {
  const BrokersSubscriptionRequested();
}

class _BrokersUpdated extends BrokerEvent {
  const _BrokersUpdated(this.profiles);

  final List<TaxProfile> profiles;

  @override
  List<Object?> get props => <Object?>[profiles];
}

class BrokerAdded extends BrokerEvent {
  const BrokerAdded(this.profile);

  final TaxProfile profile;

  @override
  List<Object?> get props => <Object?>[profile];
}

class BrokerUpdated extends BrokerEvent {
  const BrokerUpdated(this.profile);

  final TaxProfile profile;

  @override
  List<Object?> get props => <Object?>[profile];
}

class BrokerDeleted extends BrokerEvent {
  const BrokerDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => <Object?>[id];
}

class BrokerBloc extends Bloc<BrokerEvent, BrokerState> {
  BrokerBloc(this._repository) : super(const BrokerState()) {
    on<BrokersSubscriptionRequested>(_onSubscriptionRequested);
    on<_BrokersUpdated>(_onBrokersUpdated);
    on<BrokerAdded>(_onBrokerAdded);
    on<BrokerUpdated>(_onBrokerUpdated);
    on<BrokerDeleted>(_onBrokerDeleted);
  }

  final InvestmentRepository _repository;
  StreamSubscription<List<TaxProfile>>? _subscription;

  Future<void> _onSubscriptionRequested(
    BrokersSubscriptionRequested event,
    Emitter<BrokerState> emit,
  ) async {
    emit(state.copyWith(status: BrokerStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository.watchTaxProfiles().listen(
      (profiles) => add(_BrokersUpdated(profiles)),
    );
  }

  void _onBrokersUpdated(_BrokersUpdated event, Emitter<BrokerState> emit) {
    emit(
      state.copyWith(
        status: BrokerStatus.success,
        profiles: event.profiles,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onBrokerAdded(BrokerAdded event, Emitter<BrokerState> emit) async {
    await _performMutation(emit, () => _repository.insertTaxProfile(event.profile));
  }

  Future<void> _onBrokerUpdated(
    BrokerUpdated event,
    Emitter<BrokerState> emit,
  ) async {
    await _performMutation(
      emit,
      () => _repository.updateTaxProfile(event.profile),
    );
  }

  Future<void> _onBrokerDeleted(
    BrokerDeleted event,
    Emitter<BrokerState> emit,
  ) async {
    await _performMutation(emit, () => _repository.deleteTaxProfile(event.id));
  }

  Future<void> _performMutation(
    Emitter<BrokerState> emit,
    Future<void> Function() action,
  ) async {
    try {
      emit(state.copyWith(status: BrokerStatus.loading, errorMessage: null));
      await action();
    } catch (error) {
      emit(
        state.copyWith(
          status: BrokerStatus.failure,
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
