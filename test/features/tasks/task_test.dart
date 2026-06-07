// ignore_for_file: file_names

import 'package:finance_analytics_app/data/database/app_database.dart';
import 'package:finance_analytics_app/features/tasks/data/repositories/task_repository.dart';
import 'package:finance_analytics_app/features/tasks/domain/models/task_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/testHelpers.dart';

void main() {
  initializeProductionTestEnvironment();

  group('Task production scenarios', () {
    late AppDatabase database;
    late TaskRepository repository;

    setUp(() {
      database = createTestDatabase();
      repository = TaskRepository(database);
    });

    tearDown(() => database.close());

    test('clones daily tasks and ignores invalid checklist updates', () async {
      final today = DateTime(2026, 5, 22, 9, 15);
      await repository.addTask(
        TaskDraft(
          title: '  Morning routine  ',
          description: 'Prep the day',
          category: 'Work',
          date: today,
          priority: 5,
          isDaily: true,
          isCompleted: true,
          checklist: const <TaskChecklistItem>[
            TaskChecklistItem(title: 'Review calendar'),
            TaskChecklistItem(title: '   '),
          ],
        ),
      );

      final todayTasks = await repository.loadTasksBetween(today, today);
      expect(todayTasks, hasLength(1));
      expect(todayTasks.single.title, 'Morning routine');
      expect(todayTasks.single.date, DateTime(2026, 5, 22));
      expect(todayTasks.single.checklist, hasLength(1));

      final tomorrow = today.add(const Duration(days: 1));
      final tomorrowTasks = await repository.loadTasksBetween(
        tomorrow,
        tomorrow,
      );
      expect(tomorrowTasks, hasLength(1));
      expect(tomorrowTasks.single.sourceTaskId, todayTasks.single.id);
      expect(tomorrowTasks.single.isCompleted, isFalse);

      await repository.setChecklistItemCompletion(
        taskId: todayTasks.single.id,
        index: 99,
        isCompleted: true,
      );
      await repository.setChecklistItemTitle(
        taskId: todayTasks.single.id,
        index: 0,
        title: 'Review today calendar',
      );
      final reloadedToday = await repository.loadTasksBetween(today, today);
      expect(
        reloadedToday.single.checklist.single.title,
        'Review today calendar',
      );
      expect(reloadedToday.single.checklist.single.isCompleted, isFalse);
    });

    test(
      'updates daily task to one-off and removes future daily clones',
      () async {
        final dayOne = DateTime(2026, 5, 20, 9);
        final dayTwo = dayOne.add(const Duration(days: 1));
        await repository.addTask(
          TaskDraft(
            title: 'Daily review',
            description: 'Original daily item',
            category: 'Work',
            date: dayOne,
            priority: 4,
            isDaily: true,
            isCompleted: false,
          ),
        );

        final dayTwoClone = (await repository.loadTasksBetween(
          dayTwo,
          dayTwo,
        )).single;
        expect(dayTwoClone.sourceTaskId, isNotNull);

        await repository.updateTask(
          id: dayOneCloneSourceId(dayTwoClone),
          draft: TaskDraft(
            title: 'Daily review updated',
            description: 'No longer repeats',
            category: 'Personal',
            date: dayOne,
            priority: 2,
            isDaily: false,
            isCompleted: true,
          ),
        );

        final dayOneTasks = await repository.loadTasksBetween(dayOne, dayOne);
        final futureTasks = await repository.loadTasksBetween(dayTwo, dayTwo);
        expect(dayOneTasks.single.title, 'Daily review updated');
        expect(dayOneTasks.single.isDaily, isFalse);
        expect(dayOneTasks.single.isCompleted, isTrue);
        expect(futureTasks, isEmpty);
      },
    );

    test(
      'computes analytics and completion state for a focused month',
      () async {
        final focusDate = DateTime(2026, 5, 23);
        await repository.addTask(
          TaskDraft(
            title: 'Ship report',
            description: '',
            category: 'Work',
            date: focusDate,
            priority: 5,
            isDaily: false,
            isCompleted: false,
          ),
        );
        await repository.addTask(
          TaskDraft(
            title: 'Pay bill',
            description: '',
            category: 'Finance',
            date: DateTime(2026, 5, 24),
            priority: 3,
            isDaily: false,
            isCompleted: true,
          ),
        );
        final task = (await repository.loadTasksBetween(
          focusDate,
          focusDate,
        )).single;

        await repository.setTaskCompletion(id: task.id, isCompleted: true);
        final analytics = await repository.loadAnalytics(
          focusDate: focusDate,
          window: TaskAnalyticsWindow.monthly,
        );

        expect(analytics.completedCount, 2);
        expect(analytics.pendingCount, 0);
        expect(
          analytics.categoryBreakdown.map((category) => category.category),
          containsAll(<String>['Work', 'Finance']),
        );
        expect(
          analytics.priorityDistribution
              .firstWhere((item) => item.priority == 5)
              .count,
          1,
        );
      },
    );

    test('missing task operations are safe no-ops', () async {
      await repository.addTask(
        TaskDraft(
          title: 'Keep me',
          description: '',
          category: 'Work',
          date: DateTime(2026, 5, 25),
          priority: 3,
          isDaily: false,
          isCompleted: false,
        ),
      );

      await repository.setTaskCompletion(id: 404, isCompleted: true);
      await repository.setChecklistItemCompletion(
        taskId: 404,
        index: 0,
        isCompleted: true,
      );
      await repository.deleteTask(404);

      final tasks = await repository.loadAllTasks();
      expect(tasks, hasLength(1));
      expect(tasks.single.title, 'Keep me');
      expect(tasks.single.isCompleted, isFalse);
    });

    test(
      'does not duplicate daily tasks when importing/adding same daily tasks on consecutive days',
      () async {
        final dayOne = DateTime(2026, 5, 20);
        final dayTwo = dayOne.add(const Duration(days: 1));
        final dayThree = dayTwo.add(const Duration(days: 1));

        // Simulate importing a daily task on Day 1
        await repository.addTask(
          TaskDraft(
            title: 'Daily exercise',
            description: '30 mins run',
            category: 'Health',
            date: dayOne,
            priority: 3,
            isDaily: true,
            isCompleted: false,
          ),
        );

        // Simulate importing the same daily task on Day 2
        await repository.addTask(
          TaskDraft(
            title: 'Daily exercise',
            description: '30 mins run',
            category: 'Health',
            date: dayTwo,
            priority: 3,
            isDaily: true,
            isCompleted: false,
          ),
        );

        // Verify that when loading tasks for Day 2, they don't compound (no duplicates)
        final dayTwoTasks = await repository.loadTasksBetween(dayTwo, dayTwo);
        expect(dayTwoTasks, hasLength(1));

        // Simulate importing the same daily task on Day 3
        await repository.addTask(
          TaskDraft(
            title: 'Daily exercise',
            description: '30 mins run',
            category: 'Health',
            date: dayThree,
            priority: 3,
            isDaily: true,
            isCompleted: false,
          ),
        );

        final dayThreeTasks = await repository.loadTasksBetween(
          dayThree,
          dayThree,
        );
        expect(dayThreeTasks, hasLength(1));
      },
    );
  });
}

int dayOneCloneSourceId(TaskItem clone) => clone.sourceTaskId ?? clone.id;
