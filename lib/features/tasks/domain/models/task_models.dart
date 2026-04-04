import 'package:equatable/equatable.dart';

enum TaskAnalyticsWindow { weekly, monthly, yearly }

extension TaskAnalyticsWindowX on TaskAnalyticsWindow {
  String get label {
    switch (this) {
      case TaskAnalyticsWindow.weekly:
        return 'Week';
      case TaskAnalyticsWindow.monthly:
        return 'Month';
      case TaskAnalyticsWindow.yearly:
        return 'Year';
    }
  }
}

class TaskChecklistItem extends Equatable {
  const TaskChecklistItem({
    required this.title,
    this.isCompleted = false,
  });

  final String title;
  final bool isCompleted;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'isCompleted': isCompleted,
  };

  factory TaskChecklistItem.fromJson(Map<String, dynamic> json) {
    return TaskChecklistItem(
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  TaskChecklistItem copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return TaskChecklistItem(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => <Object?>[title, isCompleted];
}

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
    this.checklist = const <TaskChecklistItem>[],
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
  final List<TaskChecklistItem> checklist;

  int get completedChecklistCount =>
      checklist.where((item) => item.isCompleted).length;

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
    checklist,
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
    this.checklist = const <TaskChecklistItem>[],
  });

  final String title;
  final String description;
  final String category;
  final DateTime date;
  final int priority;
  final bool isDaily;
  final bool isCompleted;
  final List<TaskChecklistItem> checklist;

  @override
  List<Object?> get props => <Object?>[
    title,
    description,
    category,
    date,
    priority,
    isDaily,
    isCompleted,
    checklist,
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
    required this.window,
    required this.rangeStart,
    required this.rangeEnd,
    required this.completedCount,
    required this.pendingCount,
    required this.dailyTaskStreak,
    required this.priorityDistribution,
    required this.categoryBreakdown,
    required this.consistencyTrend,
  });

  final TaskAnalyticsWindow window;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final int completedCount;
  final int pendingCount;
  final int dailyTaskStreak;
  final List<TaskPriorityStat> priorityDistribution;
  final List<TaskCategoryStat> categoryBreakdown;
  final List<TaskConsistencyPoint> consistencyTrend;

  @override
  List<Object?> get props => <Object?>[
    window,
    rangeStart,
    rangeEnd,
    completedCount,
    pendingCount,
    dailyTaskStreak,
    priorityDistribution,
    categoryBreakdown,
    consistencyTrend,
  ];
}
