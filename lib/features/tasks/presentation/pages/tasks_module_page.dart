import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
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
                    child: Text(
                      'Tasks Module',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.taskAnalytics),
                    icon: const Icon(Icons.insights_rounded),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.taskSettings),
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
              TaskDateSelector(
                selectedDate: state.selectedDate,
                onDateSelected: (date) {
                  context.read<TaskBloc>().add(TasksDateSelected(date));
                },
              ),
              const SizedBox(height: 18),
              if (state.tasks.isEmpty)
                const AppPanel(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: Text('No tasks for the selected date.')),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    _TaskBadge(label: task.category),
                                    _TaskBadge(label: task.priority.toString()),
                                    if (task.isDaily)
                                      const _TaskBadge(label: 'Daily'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              context.read<TaskBloc>().add(
                                TaskCompletionChanged(
                                  id: task.id,
                                  isCompleted: !task.isCompleted,
                                ),
                              );
                            },
                            child: Row(
                              children: <Widget>[
                                Checkbox.adaptive(
                                  value: task.isCompleted,
                                  onChanged: (value) {
                                    context.read<TaskBloc>().add(
                                      TaskCompletionChanged(
                                        id: task.id,
                                        isCompleted: value ?? false,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  task.isCompleted ? 'Completed' : 'Complete',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).pushNamed(
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
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
