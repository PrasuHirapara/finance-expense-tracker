import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../data/database/app_database.dart';
import '../../domain/models/task_models.dart';

class TaskRepository {
  TaskRepository(this._database);

  final AppDatabase _database;

  Stream<List<TaskItem>> watchTasksForDate(DateTime date) async* {
    await ensureDailyTasksThroughDate(date);
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

  Future<List<TaskItem>> loadTasksBetween(DateTime start, DateTime end) async {
    await ensureDailyTasksThroughDate(end);
    final rows =
        await (_database.select(_database.dbTasks)..where(
              (table) =>
                  table.taskDate.isBiggerOrEqualValue(start.startOfDay) &
                  table.taskDate.isSmallerOrEqualValue(end.endOfDay),
            )..orderBy([
              (table) => OrderingTerm.desc(table.taskDate),
              (table) => OrderingTerm.asc(table.isCompleted),
              (table) => OrderingTerm.desc(table.priority),
              (table) => OrderingTerm.asc(table.createdAt),
            ]))
            .get();

    return rows
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
        .toList(growable: false);
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

  Future<void> clearSectionData() async {
    await _database.delete(_database.dbTasks).go();
  }

  Future<void> renameCategory({
    required String oldName,
    required String newName,
  }) async {
    await (_database.update(_database.dbTasks)
          ..where((table) => table.category.equals(oldName)))
        .write(DbTasksCompanion(category: Value(newName.trim())));
  }

  Future<void> replaceCategory({
    required String oldName,
    required String replacement,
  }) async {
    await (_database.update(_database.dbTasks)
          ..where((table) => table.category.equals(oldName)))
        .write(DbTasksCompanion(category: Value(replacement.trim())));
  }

  Future<void> setTaskCompletion({
    required int id,
    required bool isCompleted,
  }) async {
    await (_database.update(_database.dbTasks)
          ..where((table) => table.id.equals(id)))
        .write(DbTasksCompanion(isCompleted: Value(isCompleted)));
  }

  Future<void> ensureDailyTasksThroughDate(DateTime selectedDate) async {
    await ensureDailyTasksForDate(selectedDate);
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

  Future<TaskAnalyticsData> loadAnalytics({
    required DateTime focusDate,
    required TaskAnalyticsWindow window,
  }) async {
    await ensureDailyTasksThroughDate(focusDate);
    final tasks = await (_database.select(
      _database.dbTasks,
    )..orderBy([(table) => OrderingTerm.desc(table.taskDate)])).get();
    final range = _resolveRange(window, focusDate);
    final tasksInRange = tasks
        .where(
          (task) =>
              !task.taskDate.isBefore(range.start) &&
              !task.taskDate.isAfter(range.end),
        )
        .toList(growable: false);

    final completedCount = tasksInRange.where((task) => task.isCompleted).length;
    final pendingCount = tasksInRange.length - completedCount;

    final priorityMap = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
    final categoryMap = <String, int>{};

    for (final task in tasksInRange) {
      priorityMap.update(task.priority, (value) => value + 1);
      categoryMap.update(
        task.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return TaskAnalyticsData(
      window: window,
      rangeStart: range.start,
      rangeEnd: range.end,
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
      consistencyTrend: _buildConsistencyTrend(
        tasks: tasks,
        range: range,
        window: window,
      ),
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

  List<TaskConsistencyPoint> _buildConsistencyTrend({
    required List<DbTask> tasks,
    required _TaskDateRange range,
    required TaskAnalyticsWindow window,
  }) {
    final completedByPeriod = <DateTime, int>{};

    if (window == TaskAnalyticsWindow.yearly) {
      var cursor = DateTime(range.start.year, range.start.month);
      final endBucket = DateTime(range.end.year, range.end.month);
      while (!cursor.isAfter(endBucket)) {
        completedByPeriod[cursor] = 0;
        cursor = DateTime(cursor.year, cursor.month + 1);
      }

      for (final task in tasks.where((task) => task.isCompleted)) {
        final date = task.taskDate.startOfDay;
        if (date.isBefore(range.start) || date.isAfter(range.end)) {
          continue;
        }
        final bucket = DateTime(date.year, date.month);
        completedByPeriod.update(bucket, (value) => value + 1);
      }

      return completedByPeriod.entries
          .map(
            (entry) => TaskConsistencyPoint(
              date: entry.key,
              completedCount: entry.value,
              label: AppConstants.monthLabelFormat.format(entry.key),
            ),
          )
          .toList(growable: false);
    }

    for (
      var cursor = range.start.startOfDay;
      !cursor.isAfter(range.end);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      completedByPeriod[cursor] = 0;
    }

    for (final task in tasks.where((task) => task.isCompleted)) {
      final date = task.taskDate.startOfDay;
      if (date.isBefore(range.start) || date.isAfter(range.end)) {
        continue;
      }
      completedByPeriod.update(date, (value) => value + 1);
    }

    return completedByPeriod.entries
        .map(
          (entry) => TaskConsistencyPoint(
            date: entry.key,
            completedCount: entry.value,
            label: window == TaskAnalyticsWindow.weekly
                ? DateFormat('E').format(entry.key)
                : DateFormat('d').format(entry.key),
          ),
        )
        .toList(growable: false);
  }

  _TaskDateRange _resolveRange(TaskAnalyticsWindow window, DateTime anchorDate) {
    switch (window) {
      case TaskAnalyticsWindow.weekly:
        return _TaskDateRange(anchorDate.startOfWeek, anchorDate.endOfWeek);
      case TaskAnalyticsWindow.monthly:
        return _TaskDateRange(
          anchorDate.startOfMonth,
          anchorDate.endOfMonth,
        );
      case TaskAnalyticsWindow.yearly:
        return _TaskDateRange(anchorDate.startOfYear, anchorDate.endOfYear);
    }
  }
}

class _TaskDateRange {
  const _TaskDateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
