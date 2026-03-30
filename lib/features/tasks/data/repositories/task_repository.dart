import 'package:drift/drift.dart';

import '../../../../core/extensions/date_time_x.dart';
import '../../../../data/database/app_database.dart';
import '../../domain/models/task_models.dart';

class TaskRepository {
  TaskRepository(this._database);

  final AppDatabase _database;

  Stream<List<TaskItem>> watchTasksForDate(DateTime date) async* {
    await ensureDailyTasksForDate(date);
    yield* (_database.select(_database.dbTasks)
          ..where(
            (table) =>
                table.taskDate.isBiggerOrEqualValue(date.startOfDay) &
                table.taskDate.isSmallerOrEqualValue(date.endOfDay),
          )
          ..orderBy([
            (table) => OrderingTerm.asc(table.isCompleted),
            (table) => OrderingTerm.desc(table.priority),
            (table) => OrderingTerm.asc(table.createdAt),
          ]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => TaskItem(
                  id: row.id,
                  sourceTaskId: row.sourceTaskId,
                  title: row.title,
                  description: row.description,
                  category: row.category,
                  date: row.taskDate,
                  priority: row.priority,
                  isDaily: row.isDaily,
                  isCompleted: row.isCompleted,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<void> addTask(TaskDraft draft) async {
    await _database
        .into(_database.dbTasks)
        .insert(
          DbTasksCompanion.insert(
            title: draft.title.trim(),
            description: Value(draft.description.trim()),
            category: draft.category.trim(),
            taskDate: draft.date.startOfDay,
            priority: Value(draft.priority),
            isDaily: Value(draft.isDaily),
            isCompleted: Value(draft.isCompleted),
          ),
        );
  }

  Future<void> updateTask({required int id, required TaskDraft draft}) async {
    await (_database.update(
      _database.dbTasks,
    )..where((table) => table.id.equals(id))).write(
      DbTasksCompanion(
        title: Value(draft.title.trim()),
        description: Value(draft.description.trim()),
        category: Value(draft.category.trim()),
        taskDate: Value(draft.date.startOfDay),
        priority: Value(draft.priority),
        isDaily: Value(draft.isDaily),
        isCompleted: Value(draft.isCompleted),
      ),
    );
  }

  Future<void> deleteTask(int id) async {
    await (_database.delete(
      _database.dbTasks,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> setTaskCompletion({
    required int id,
    required bool isCompleted,
  }) async {
    await (_database.update(_database.dbTasks)
          ..where((table) => table.id.equals(id)))
        .write(DbTasksCompanion(isCompleted: Value(isCompleted)));
  }

  Future<void> ensureDailyTasksForDate(DateTime selectedDate) async {
    final targetDate = selectedDate.startOfDay;
    final previousDate = targetDate
        .subtract(const Duration(days: 1))
        .startOfDay;

    final previousDailyTasks =
        await (_database.select(_database.dbTasks)..where(
              (table) =>
                  table.taskDate.isBiggerOrEqualValue(previousDate) &
                  table.taskDate.isSmallerOrEqualValue(previousDate.endOfDay) &
                  table.isDaily.equals(true),
            ))
            .get();

    if (previousDailyTasks.isEmpty) {
      return;
    }

    final currentTasks =
        await (_database.select(_database.dbTasks)..where(
              (table) =>
                  table.taskDate.isBiggerOrEqualValue(targetDate) &
                  table.taskDate.isSmallerOrEqualValue(targetDate.endOfDay),
            ))
            .get();

    final existingSources = currentTasks
        .map((task) => task.sourceTaskId ?? task.id)
        .toSet();

    final clones = <DbTasksCompanion>[];

    for (final task in previousDailyTasks) {
      final sourceId = task.sourceTaskId ?? task.id;
      if (existingSources.contains(sourceId)) {
        continue;
      }
      clones.add(
        DbTasksCompanion.insert(
          sourceTaskId: Value(sourceId),
          title: task.title,
          description: Value(task.description),
          category: task.category,
          taskDate: targetDate,
          priority: Value(task.priority),
          isDaily: const Value(true),
          isCompleted: const Value(false),
        ),
      );
    }

    if (clones.isNotEmpty) {
      await _database.batch(
        (batch) => batch.insertAll(_database.dbTasks, clones),
      );
    }
  }

  Future<TaskAnalyticsData> loadAnalytics(DateTime focusDate) async {
    await ensureDailyTasksForDate(focusDate);
    final tasks = await (_database.select(
      _database.dbTasks,
    )..orderBy([(table) => OrderingTerm.desc(table.taskDate)])).get();

    final completedCount = tasks.where((task) => task.isCompleted).length;
    final pendingCount = tasks.length - completedCount;

    final priorityMap = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
    final categoryMap = <String, int>{};

    for (final task in tasks) {
      priorityMap.update(task.priority, (value) => value + 1);
      categoryMap.update(
        task.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return TaskAnalyticsData(
      completedCount: completedCount,
      pendingCount: pendingCount,
      dailyTaskStreak: _calculateDailyTaskStreak(tasks, focusDate),
      priorityDistribution: priorityMap.entries
          .map(
            (entry) =>
                TaskPriorityStat(priority: entry.key, count: entry.value),
          )
          .toList(growable: false),
      categoryBreakdown:
          categoryMap.entries
              .map(
                (entry) =>
                    TaskCategoryStat(category: entry.key, count: entry.value),
              )
              .toList(growable: false)
            ..sort((a, b) => b.count.compareTo(a.count)),
    );
  }

  int _calculateDailyTaskStreak(List<DbTask> tasks, DateTime focusDate) {
    final completedDailyDates = tasks
        .where((task) => task.isDaily && task.isCompleted)
        .map((task) => task.taskDate.startOfDay)
        .toSet();

    var streak = 0;
    var cursor = focusDate.startOfDay;
    while (completedDailyDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
