import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/task_repository.dart';
import '../../../domain/models/task_models.dart';

class TaskAnalyticsState extends Equatable {
  const TaskAnalyticsState({
    required this.focusDate,
    this.status = TaskAnalyticsStatus.initial,
    this.window = TaskAnalyticsWindow.monthly,
    this.customStartDate,
    this.customEndDate,
    this.analytics,
    this.errorMessage,
  });

  final DateTime focusDate;
  final TaskAnalyticsStatus status;
  final TaskAnalyticsWindow window;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final TaskAnalyticsData? analytics;
  final String? errorMessage;

  TaskAnalyticsState copyWith({
    DateTime? focusDate,
    TaskAnalyticsStatus? status,
    TaskAnalyticsWindow? window,
    DateTime? customStartDate,
    DateTime? customEndDate,
    TaskAnalyticsData? analytics,
    String? errorMessage,
  }) {
    return TaskAnalyticsState(
      focusDate: focusDate ?? this.focusDate,
      status: status ?? this.status,
      window: window ?? this.window,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      analytics: analytics ?? this.analytics,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    focusDate,
    status,
    window,
    customStartDate,
    customEndDate,
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

class TaskAnalyticsWindowChanged extends TaskAnalyticsEvent {
  const TaskAnalyticsWindowChanged(this.window);

  final TaskAnalyticsWindow window;

  @override
  List<Object?> get props => <Object?>[window];
}

class TaskAnalyticsCustomRangeChanged extends TaskAnalyticsEvent {
  const TaskAnalyticsCustomRangeChanged({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => <Object?>[startDate, endDate];
}

class TaskAnalyticsBloc extends Bloc<TaskAnalyticsEvent, TaskAnalyticsState> {
  TaskAnalyticsBloc(this._repository)
    : super(TaskAnalyticsState(focusDate: DateTime.now())) {
    on<TaskAnalyticsRequested>(_onRequested);
    on<TaskAnalyticsFocusDateChanged>(_onDateChanged);
    on<TaskAnalyticsWindowChanged>(_onWindowChanged);
    on<TaskAnalyticsCustomRangeChanged>(_onCustomRangeChanged);
  }

  final TaskRepository _repository;

  Future<void> _onRequested(
    TaskAnalyticsRequested event,
    Emitter<TaskAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: TaskAnalyticsStatus.loading));
    try {
      final analytics = await _repository.loadAnalytics(
        focusDate: state.focusDate,
        window: state.window,
        customStartDate: state.customStartDate,
        customEndDate: state.customEndDate,
      );
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

  void _onWindowChanged(
    TaskAnalyticsWindowChanged event,
    Emitter<TaskAnalyticsState> emit,
  ) {
    emit(state.copyWith(window: event.window));
    add(const TaskAnalyticsRequested());
  }

  void _onCustomRangeChanged(
    TaskAnalyticsCustomRangeChanged event,
    Emitter<TaskAnalyticsState> emit,
  ) {
    final startDate = event.startDate.isAfter(event.endDate)
        ? event.endDate
        : event.startDate;
    final endDate = event.startDate.isAfter(event.endDate)
        ? event.startDate
        : event.endDate;
    emit(
      state.copyWith(
        focusDate: endDate,
        window: TaskAnalyticsWindow.custom,
        customStartDate: startDate,
        customEndDate: endDate,
      ),
    );
    add(const TaskAnalyticsRequested());
  }
}
