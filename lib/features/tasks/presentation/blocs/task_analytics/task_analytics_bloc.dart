import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/task_repository.dart';
import '../../../domain/models/task_models.dart';

class TaskAnalyticsState extends Equatable {
  const TaskAnalyticsState({
    required this.focusDate,
    this.status = TaskAnalyticsStatus.initial,
    this.analytics,
    this.errorMessage,
  });

  final DateTime focusDate;
  final TaskAnalyticsStatus status;
  final TaskAnalyticsData? analytics;
  final String? errorMessage;

  TaskAnalyticsState copyWith({
    DateTime? focusDate,
    TaskAnalyticsStatus? status,
    TaskAnalyticsData? analytics,
    String? errorMessage,
  }) {
    return TaskAnalyticsState(
      focusDate: focusDate ?? this.focusDate,
      status: status ?? this.status,
      analytics: analytics ?? this.analytics,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    focusDate,
    status,
    analytics,
    errorMessage,
  ];
}

enum TaskAnalyticsStatus { initial, loading, success, failure }

sealed class TaskAnalyticsEvent extends Equatable {
  const TaskAnalyticsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class TaskAnalyticsRequested extends TaskAnalyticsEvent {
  const TaskAnalyticsRequested();
}

class TaskAnalyticsFocusDateChanged extends TaskAnalyticsEvent {
  const TaskAnalyticsFocusDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => <Object?>[date];
}

class TaskAnalyticsBloc extends Bloc<TaskAnalyticsEvent, TaskAnalyticsState> {
  TaskAnalyticsBloc(this._repository)
    : super(TaskAnalyticsState(focusDate: DateTime.now())) {
    on<TaskAnalyticsRequested>(_onRequested);
    on<TaskAnalyticsFocusDateChanged>(_onDateChanged);
  }

  final TaskRepository _repository;

  Future<void> _onRequested(
    TaskAnalyticsRequested event,
    Emitter<TaskAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: TaskAnalyticsStatus.loading));
    try {
      final analytics = await _repository.loadAnalytics(state.focusDate);
      emit(
        state.copyWith(
          status: TaskAnalyticsStatus.success,
          analytics: analytics,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TaskAnalyticsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onDateChanged(
    TaskAnalyticsFocusDateChanged event,
    Emitter<TaskAnalyticsState> emit,
  ) {
    emit(state.copyWith(focusDate: event.date));
    add(const TaskAnalyticsRequested());
  }
}
