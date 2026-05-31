import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/history_date_picker_dialog.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/task_models.dart';
import '../blocs/tasks/task_bloc.dart';
import '../widgets/task_date_selector.dart';

class TasksModulePage extends StatelessWidget {
  const TasksModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Task', style: theme.textTheme.headlineMedium),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.taskAnalytics),
                    icon: const Icon(Icons.insights_rounded),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.taskSettings),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.taskEditor,
                      arguments: TaskEditorArgs(
                        selectedDate: state.selectedDate,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TaskDateSelector(
                      selectedDate: state.selectedDate,
                      onDateSelected: (date) {
                        context.read<TaskBloc>().add(TasksDateSelected(date));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: IconButton.filledTonal(
                      tooltip: 'Open task history dates',
                      onPressed: () => _openTaskHistoryPicker(context),
                      icon: const Icon(Icons.calendar_month_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (state.tasks.isEmpty)
                const AppPanel(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: Text('No tasks for the selected date.'),
                    ),
                  ),
                )
              else
                ...state.tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppPanel(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _TaskBadge(label: task.category),
                              _TaskBadge(label: 'Priority ${task.priority}'),
                              if (task.isDaily)
                                const _TaskBadge(label: 'Daily'),
                              if (task.checklist.isNotEmpty)
                                _TaskBadge(
                                  label:
                                      '${task.completedChecklistCount}/${task.checklist.length} Done',
                                ),
                            ],
                          ),
                          if (task.description.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 10),
                            Text(
                              task.description.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (task.checklist.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            ...task.checklist.asMap().entries.map(
                              (entry) => _EditableChecklistItemRow(
                                taskId: task.id,
                                index: entry.key,
                                item: entry.value,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  context.read<TaskBloc>().add(
                                    TaskCompletionChanged(
                                      id: task.id,
                                      isCompleted: !task.isCompleted,
                                    ),
                                  );
                                },
                                icon: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                ),
                                label: Text(
                                  task.isCompleted ? 'Completed' : 'Complete',
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.taskEditor,
                                      arguments: TaskEditorArgs(
                                        selectedDate: state.selectedDate,
                                        task: task,
                                      ),
                                    ),
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  context.read<TaskBloc>().add(
                                    TaskDeleted(task.id),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTaskHistoryPicker(BuildContext context) async {
    final repository = context.read<TaskRepository>();
    final today = DateTime.now().startOfDay;
    final tasks = await repository.loadAllTasks();
    final historyDates = tasks
        .map((task) => task.date.startOfDay)
        .where((date) => !date.isAfter(today))
        .toSet();

    if (!context.mounted) {
      return;
    }

    if (historyDates.isEmpty) {
      showAppSnackBar(
        context,
        message: 'No task history dates available.',
        type: AppSnackBarType.warning,
      );
      return;
    }

    final selectedDate = await HistoryDatePickerDialog.pick(
      context: context,
      title: 'Task History',
      dataDates: historyDates,
    );

    if (selectedDate == null || !context.mounted) {
      return;
    }

    context.read<TaskBloc>().add(TasksDateSelected(selectedDate));
  }
}

class _EditableChecklistItemRow extends StatelessWidget {
  const _EditableChecklistItemRow({
    required this.taskId,
    required this.index,
    required this.item,
  });

  final int taskId;
  final int index;
  final TaskChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Checkbox(
            value: item.isCompleted,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) {
              context.read<TaskBloc>().add(
                TaskChecklistItemCompletionChanged(
                  taskId: taskId,
                  index: index,
                  isCompleted: value ?? false,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _EditableChecklistTitleField(
              taskId: taskId,
              index: index,
              item: item,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableChecklistTitleField extends StatefulWidget {
  const _EditableChecklistTitleField({
    required this.taskId,
    required this.index,
    required this.item,
  });

  final int taskId;
  final int index;
  final TaskChecklistItem item;

  @override
  State<_EditableChecklistTitleField> createState() =>
      _EditableChecklistTitleFieldState();
}

class _EditableChecklistTitleFieldState
    extends State<_EditableChecklistTitleField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.title);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _EditableChecklistTitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.item.title != _controller.text) {
      _controller.text = widget.item.title;
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _queueSave(String value) {
    _saveDebounce?.cancel();
    if (value.trim().isEmpty) {
      return;
    }
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      context.read<TaskBloc>().add(
        TaskChecklistItemTitleChanged(
          taskId: widget.taskId,
          index: widget.index,
          title: value,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      minLines: 1,
      maxLines: 2,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Sub-task title',
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(14, 12, 14, 12),
      ),
      style: theme.textTheme.bodyMedium?.copyWith(
        decoration: widget.item.isCompleted ? TextDecoration.lineThrough : null,
        color: widget.item.isCompleted
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurface,
      ),
      onChanged: _queueSave,
    );
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.65,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
