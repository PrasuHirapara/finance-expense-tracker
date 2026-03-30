import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppModule { expense, tasks, settings }

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
    on<ModuleSelected>((event, emit) {
      emit(ModuleNavigationState(module: event.module));
    });
  }
}
