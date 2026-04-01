import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/module_export_models.dart';
import '../../../../core/services/app_settings_repository.dart';
import '../../../../core/services/module_data_export_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_settings_repository.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/module_export_panel.dart';
import '../../data/repositories/task_category_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../blocs/tasks/task_bloc.dart';

class TaskSettingsBody extends StatefulWidget {
  const TaskSettingsBody({super.key});

  @override
  State<TaskSettingsBody> createState() => _TaskSettingsBodyState();
}

class _TaskSettingsBodyState extends State<TaskSettingsBody> {
  bool _showAllCategories = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.read<TaskCategoryRepository>();
    final reminderRepository = context.read<ReminderSettingsRepository>();
    final taskRepository = context.read<TaskRepository>();

    return Column(
      children: <Widget>[
        StreamBuilder<ReminderSettings>(
          stream: reminderRepository.watchSettings(),
          builder: (context, snapshot) {
            final settings = snapshot.data ?? const ReminderSettings();

            return AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Task Reminder', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Choose when the daily task reminder should arrive.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _formatTime(context, settings.taskReminder),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Default is 8:00 AM.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _pickReminderTime(
                            context,
                            initialTime: settings.taskReminder,
                          ),
                          icon: const Icon(Icons.schedule_rounded),
                          label: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        ModuleExportPanel(
          title: 'Task Export',
          onExport: (range, format) =>
              _exportTaskData(context, range: range, format: format),
        ),
        const SizedBox(height: 18),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Task Settings',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage task categories and defaults',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCategoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<String>>(
                stream: repository.watchCategories(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? const <String>[];
                  final visibleCategories =
                      _showAllCategories || categories.length <= 1
                      ? categories
                      : categories.take(1).toList(growable: false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Categories',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          if (categories.length > 1)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showAllCategories = !_showAllCategories;
                                });
                              },
                              child: Text(
                                _showAllCategories
                                    ? 'Hide category'
                                    : 'View category',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (categories.isEmpty)
                        Text(
                          'No categories available.',
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        ...visibleCategories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                10,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.42),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showCategoryDialog(
                                      context,
                                      initialValue: category,
                                      existingValue: category,
                                    ),
                                    icon: const Icon(Icons.edit_rounded),
                                  ),
                                  IconButton(
                                    onPressed: categories.length == 1
                                        ? null
                                        : () => repository.deleteCategory(
                                            category,
                                          ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      AppPanel(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Task Defaults',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '1 Low   2 Medium-low   3 Medium   4 Medium-high   5 High',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Daily tasks automatically carry forward to the next day until completed.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Delete Task Data', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'This clears all tasks, restores the default task categories, and resets the task reminder to 8:00 AM.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => _deleteTaskSectionData(
                  context,
                  taskRepository: taskRepository,
                  categoryRepository: repository,
                ),
                style: FilledButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete Data'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(BuildContext context, ReminderTime reminderTime) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      reminderTime.toTimeOfDay(),
      alwaysUse24HourFormat:
          MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
    );
  }

  Future<void> _pickReminderTime(
    BuildContext context, {
    required ReminderTime initialTime,
  }) async {
    final reminderSettingsRepository = context
        .read<ReminderSettingsRepository>();
    final notificationService = context.read<NotificationService>();
    final appSettingsRepository = context.read<AppSettingsRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final alwaysUse24HourFormat =
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime.toTimeOfDay(),
    );

    if (selectedTime == null) {
      return;
    }

    final reminderTime = ReminderTime.fromTimeOfDay(selectedTime);
    final formattedTime = materialLocalizations.formatTimeOfDay(
      selectedTime,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );

    await reminderSettingsRepository.updateTaskReminder(reminderTime);
    final appSettings = await appSettingsRepository.getSettings();
    if (appSettings.notificationsEnabled) {
      await notificationService.scheduleDailyReminders();
    } else {
      await notificationService.cancelDailyReminders();
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Task reminder set for $formattedTime.')),
    );
  }

  Future<void> _deleteTaskSectionData(
    BuildContext context, {
    required TaskRepository taskRepository,
    required TaskCategoryRepository categoryRepository,
  }) async {
    final reminderSettingsRepository = context
        .read<ReminderSettingsRepository>();
    final notificationService = context.read<NotificationService>();
    final appSettingsRepository = context.read<AppSettingsRepository>();
    final taskBloc = context.read<TaskBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task Data'),
        content: const Text('Are you sure you want to delete data for Tasks?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await taskRepository.clearSectionData();
    await categoryRepository.resetToDefaults();
    await reminderSettingsRepository.resetTaskReminder();
    final appSettings = await appSettingsRepository.getSettings();
    if (appSettings.notificationsEnabled) {
      await notificationService.scheduleDailyReminders();
    } else {
      await notificationService.cancelDailyReminders();
    }

    taskBloc.add(const TasksSubscriptionRequested());
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Task data deleted.')),
    );
  }

  Future<String> _exportTaskData(
    BuildContext context, {
    required DateTimeRange range,
    required ModuleExportFormat format,
  }) async {
    final repository = context.read<TaskRepository>();
    final exportService = context.read<ModuleDataExportService>();
    final tasks = await repository.loadTasksBetween(range.start, range.end);

    return exportService.exportTaskData(
      range: range,
      format: format,
      tasks: tasks,
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    String initialValue = '',
    String? existingValue,
  }) async {
    final repository = context.read<TaskCategoryRepository>();
    final controller = TextEditingController(text: initialValue);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existingValue == null ? 'Add Category' : 'Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (existingValue == null) {
                await repository.addCategory(controller.text);
              } else {
                await repository.updateCategory(
                  oldName: existingValue,
                  newName: controller.text,
                );
              }
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
