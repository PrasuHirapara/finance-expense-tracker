import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_preferences.dart';

class ModuleNavigationState extends Equatable {
  const ModuleNavigationState({required this.module});

  final AppModule module;

  @override
  List<Object> get props => <Object>[module];
}

sealed class ModuleNavigationEvent extends Equatable {
  const ModuleNavigationEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ModuleSelected extends ModuleNavigationEvent {
  const ModuleSelected(this.module);

  final AppModule module;

  @override
  List<Object?> get props => <Object?>[module];
}

class ModuleNavigationBloc
    extends Bloc<ModuleNavigationEvent, ModuleNavigationState> {
  ModuleNavigationBloc()
    : super(const ModuleNavigationState(module: AppModule.expense)) {
    on<ModuleSelected>(_onModuleSelected);
  }

  void _onModuleSelected(
    ModuleSelected event,
    Emitter<ModuleNavigationState> emit,
  ) {
    if (state.module == event.module) {
      return;
    }

    emit(ModuleNavigationState(module: event.module));
  }
}
