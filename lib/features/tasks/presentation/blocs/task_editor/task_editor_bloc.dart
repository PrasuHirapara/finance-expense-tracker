import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../domain/models/task_models.dart';

class TaskEditorState extends Equatable {
  const TaskEditorState({
    required this.date,
    this.status = TaskEditorStatus.ready,
    this.taskId,
    this.title = '',
    this.description = '',
    this.category = '',
    this.priority = 3,
    this.isDaily = false,
    this.isCompleted = false,
    this.showValidation = false,
    this.errorMessage,
  });

  final DateTime date;
  final TaskEditorStatus status;
  final int? taskId;
  final String title;
  final String description;
  final String category;
  final int priority;
  final bool isDaily;
  final bool isCompleted;
  final bool showValidation;
  final String? errorMessage;

  bool get isValid => title.trim().isNotEmpty && category.trim().isNotEmpty;

  TaskEditorState copyWith({
    DateTime? date,
    TaskEditorStatus? status,
    int? taskId,
    String? title,
    String? description,
    String? category,
    int? priority,
    bool? isDaily,
    bool? isCompleted,
    bool? showValidation,
    String? errorMessage,
  }) {
    return TaskEditorState(
      date: date ?? this.date,
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isDaily: isDaily ?? this.isDaily,
      isCompleted: isCompleted ?? this.isCompleted,
      showValidation: showValidation ?? this.showValidation,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    date,
    status,
    taskId,
    title,
    description,
    category,
    priority,
    isDaily,
    isCompleted,
    showValidation,
    errorMessage,
  ];
}

enum TaskEditorStatus { ready, submitting, success, failure }

sealed class TaskEditorEvent extends Equatable {
  const TaskEditorEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class TaskEditorInitialized extends TaskEditorEvent {
  const TaskEditorInitialized({required this.selectedDate, this.existingTask});

  final DateTime selectedDate;
  final TaskItem? existingTask;

  @override
  List<Object?> get props => <Object?>[selectedDate, existingTask];
}

class TaskTitleChanged extends TaskEditorEvent {
  const TaskTitleChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class TaskDescriptionChanged extends TaskEditorEvent {
  const TaskDescriptionChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class TaskCategoryChanged extends TaskEditorEvent {
  const TaskCategoryChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class TaskDateChanged extends TaskEditorEvent {
  const TaskDateChanged(this.value);
  final DateTime value;
  @override
  List<Object?> get props => <Object?>[value];
}

class TaskPriorityChanged extends TaskEditorEvent {
  const TaskPriorityChanged(this.value);
  final int value;
  @override
  List<Object?> get props => <Object?>[value];
}

class TaskDailyChanged extends TaskEditorEvent {
  const TaskDailyChanged(this.value);
  final bool value;
  @override
  List<Object?> get props => <Object?>[value];
}

class TaskCompletionStatusChanged extends TaskEditorEvent {
  const TaskCompletionStatusChanged(this.value);
  final bool value;
  @override
  List<Object?> get props => <Object?>[value];
}

class TaskSubmitted extends TaskEditorEvent {
  const TaskSubmitted();
}

class TaskEditorBloc extends Bloc<TaskEditorEvent, TaskEditorState> {
  TaskEditorBloc(this._repository)
    : super(TaskEditorState(date: DateTime.now())) {
    on<TaskEditorInitialized>(_onInitialized);
    on<TaskTitleChanged>(
      (event, emit) => emit(state.copyWith(title: event.value)),
    );
    on<TaskDescriptionChanged>(
      (event, emit) => emit(state.copyWith(description: event.value)),
    );
    on<TaskCategoryChanged>(
      (event, emit) => emit(state.copyWith(category: event.value)),
    );
    on<TaskDateChanged>(
      (event, emit) => emit(state.copyWith(date: event.value)),
    );
    on<TaskPriorityChanged>(
      (event, emit) => emit(state.copyWith(priority: event.value)),
    );
    on<TaskDailyChanged>(
      (event, emit) => emit(state.copyWith(isDaily: event.value)),
    );
    on<TaskCompletionStatusChanged>(
      (event, emit) => emit(state.copyWith(isCompleted: event.value)),
    );
    on<TaskSubmitted>(_onSubmitted);
  }

  final TaskRepository _repository;

  void _onInitialized(
    TaskEditorInitialized event,
    Emitter<TaskEditorState> emit,
  ) {
    final task = event.existingTask;
    if (task == null) {
      emit(
        state.copyWith(
          date: event.selectedDate,
          category: AppConstants.taskCategoryChoices.first,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        taskId: task.id,
        title: task.title,
        description: task.description,
        category: task.category,
        date: task.date,
        priority: task.priority,
        isDaily: task.isDaily,
        isCompleted: task.isCompleted,
      ),
    );
  }

  Future<void> _onSubmitted(
    TaskSubmitted event,
    Emitter<TaskEditorState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(showValidation: true));
      return;
    }

    emit(
      state.copyWith(
        status: TaskEditorStatus.submitting,
        showValidation: true,
        errorMessage: null,
      ),
    );

    final draft = TaskDraft(
      title: state.title,
      description: state.description,
      category: state.category,
      date: state.date,
      priority: state.priority,
      isDaily: state.isDaily,
      isCompleted: state.isCompleted,
    );

    try {
      if (state.taskId == null) {
        await _repository.addTask(draft);
      } else {
        await _repository.updateTask(id: state.taskId!, draft: draft);
      }
      emit(state.copyWith(status: TaskEditorStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: TaskEditorStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
