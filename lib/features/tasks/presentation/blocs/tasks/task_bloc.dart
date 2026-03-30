import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/task_repository.dart';
import '../../../domain/models/task_models.dart';

class TaskState extends Equatable {
  const TaskState({
    required this.selectedDate,
    this.status = TaskStatus.initial,
    this.tasks = const <TaskItem>[],
    this.errorMessage,
  });

  final DateTime selectedDate;
  final TaskStatus status;
  final List<TaskItem> tasks;
  final String? errorMessage;

  TaskState copyWith({
    DateTime? selectedDate,
    TaskStatus? status,
    List<TaskItem>? tasks,
    String? errorMessage,
  }) {
    return TaskState(
      selectedDate: selectedDate ?? this.selectedDate,
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedDate,
    status,
    tasks,
    errorMessage,
  ];
}

enum TaskStatus { initial, loading, success, failure }

sealed class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class TasksSubscriptionRequested extends TaskEvent {
  const TasksSubscriptionRequested();
}

class TasksDateSelected extends TaskEvent {
  const TasksDateSelected(this.date);

  final DateTime date;

  @override
  List<Object?> get props => <Object?>[date];
}

class TaskCompletionChanged extends TaskEvent {
  const TaskCompletionChanged({required this.id, required this.isCompleted});

  final int id;
  final bool isCompleted;

  @override
  List<Object?> get props => <Object?>[id, isCompleted];
}

class TaskDeleted extends TaskEvent {
  const TaskDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => <Object?>[id];
}

class _TasksUpdated extends TaskEvent {
  const _TasksUpdated(this.tasks);

  final List<TaskItem> tasks;

  @override
  List<Object?> get props => <Object?>[tasks];
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc(this._repository) : super(TaskState(selectedDate: DateTime.now())) {
    on<TasksSubscriptionRequested>(_onSubscriptionRequested);
    on<TasksDateSelected>(_onDateSelected);
    on<TaskCompletionChanged>(_onCompletionChanged);
    on<TaskDeleted>(_onDeleted);
    on<_TasksUpdated>(_onTasksUpdated);
  }

  final TaskRepository _repository;
  StreamSubscription<List<TaskItem>>? _subscription;

  Future<void> _onSubscriptionRequested(
    TasksSubscriptionRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskStatus.loading));
    await _subscription?.cancel();
    _subscription = _repository
        .watchTasksForDate(state.selectedDate)
        .listen((tasks) => add(_TasksUpdated(tasks)));
  }

  Future<void> _onDateSelected(
    TasksDateSelected event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(selectedDate: event.date));
    add(const TasksSubscriptionRequested());
  }

  Future<void> _onCompletionChanged(
    TaskCompletionChanged event,
    Emitter<TaskState> emit,
  ) async {
    await _repository.setTaskCompletion(
      id: event.id,
      isCompleted: event.isCompleted,
    );
  }

  Future<void> _onDeleted(TaskDeleted event, Emitter<TaskState> emit) async {
    await _repository.deleteTask(event.id);
  }

  void _onTasksUpdated(_TasksUpdated event, Emitter<TaskState> emit) {
    emit(
      state.copyWith(
        status: TaskStatus.success,
        tasks: event.tasks,
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
