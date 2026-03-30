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
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Tasks Module',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage tasks by date, priority, completion, and daily carry-forward.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.taskAnalytics),
                    icon: const Icon(Icons.insights_rounded),
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
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      task.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        Chip(label: Text(task.category)),
                                        Chip(
                                          label: Text('Priority ${task.priority}'),
                                        ),
                                        if (task.isDaily)
                                          const Chip(label: Text('Daily')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (task.description.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Checkbox(
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
                              const Text('Complete'),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: task.isCompleted
                                      ? const Color(0xFFD8F3E3)
                                      : const Color(0xFFFDE8E6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  task.isCompleted ? 'Complete' : 'Pending',
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.taskEditor,
                                      arguments: TaskEditorArgs(
                                        selectedDate: state.selectedDate,
                                        task: task,
                                      ),
                                    ),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                onPressed: () {
                                  context.read<TaskBloc>().add(
                                    TaskDeleted(task.id),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
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
