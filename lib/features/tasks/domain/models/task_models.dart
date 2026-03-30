import 'package:equatable/equatable.dart';

class TaskItem extends Equatable {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.priority,
    required this.isDaily,
    required this.isCompleted,
    this.sourceTaskId,
  });

  final int id;
  final int? sourceTaskId;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final int priority;
  final bool isDaily;
  final bool isCompleted;

  @override
  List<Object?> get props => <Object?>[
    id,
    sourceTaskId,
    title,
    description,
    category,
    date,
    priority,
    isDaily,
    isCompleted,
  ];
}

class TaskDraft extends Equatable {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.priority,
    required this.isDaily,
    required this.isCompleted,
  });

  final String title;
  final String description;
  final String category;
  final DateTime date;
  final int priority;
  final bool isDaily;
  final bool isCompleted;

  @override
  List<Object?> get props => <Object?>[
    title,
    description,
    category,
    date,
    priority,
    isDaily,
    isCompleted,
  ];
}

class TaskPriorityStat extends Equatable {
  const TaskPriorityStat({required this.priority, required this.count});

  final int priority;
  final int count;

  @override
  List<Object?> get props => <Object?>[priority, count];
}

class TaskCategoryStat extends Equatable {
  const TaskCategoryStat({required this.category, required this.count});

  final String category;
  final int count;

  @override
  List<Object?> get props => <Object?>[category, count];
}

class TaskConsistencyPoint extends Equatable {
  const TaskConsistencyPoint({
    required this.date,
    required this.completedCount,
    required this.label,
  });

  final DateTime date;
  final int completedCount;
  final String label;

  @override
  List<Object?> get props => <Object?>[date, completedCount, label];
}

class TaskAnalyticsData extends Equatable {
  const TaskAnalyticsData({
    required this.completedCount,
    required this.pendingCount,
    required this.dailyTaskStreak,
    required this.priorityDistribution,
    required this.categoryBreakdown,
    required this.consistencyTrend,
  });

  final int completedCount;
  final int pendingCount;
  final int dailyTaskStreak;
  final List<TaskPriorityStat> priorityDistribution;
  final List<TaskCategoryStat> categoryBreakdown;
  final List<TaskConsistencyPoint> consistencyTrend;

  @override
  List<Object?> get props => <Object?>[
    completedCount,
    pendingCount,
    dailyTaskStreak,
    priorityDistribution,
    categoryBreakdown,
    consistencyTrend,
  ];
}
