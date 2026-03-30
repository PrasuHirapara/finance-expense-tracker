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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
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
                                  task.isCompleted ? 'Completed' : 'Pending',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(task.description),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              Chip(label: Text(task.category)),
                              Chip(label: Text('Priority ${task.priority}')),
                              if (task.isDaily)
                                const Chip(label: Text('Daily Task')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Completed'),
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
                              ),
                              Expanded(
                                child: CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Not Completed'),
                                  value: !task.isCompleted,
                                  onChanged: (value) {
                                    context.read<TaskBloc>().add(
                                      TaskCompletionChanged(
                                        id: task.id,
                                        isCompleted: !(value ?? false),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
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
