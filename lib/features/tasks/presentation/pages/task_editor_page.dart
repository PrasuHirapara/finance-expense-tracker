import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../blocs/task_editor/task_editor_bloc.dart';

class TaskEditorPage extends StatelessWidget {
  const TaskEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskEditorBloc, TaskEditorState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == TaskEditorStatus.success) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Task Editor')),
        body: BlocBuilder<TaskEditorBloc, TaskEditorState>(
          builder: (context, state) {
            final categoryOptions = <String>{
              ...AppConstants.taskCategoryChoices,
              if (state.category.trim().isNotEmpty) state.category.trim(),
            }.toList(growable: false);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    errorText:
                        state.showValidation && state.title.trim().isEmpty
                        ? 'Enter a title'
                        : null,
                  ),
                  onChanged: (value) => context.read<TaskEditorBloc>().add(
                    TaskTitleChanged(value),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) => context.read<TaskEditorBloc>().add(
                    TaskDescriptionChanged(value),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: state.category.trim().isEmpty
                      ? categoryOptions.first
                      : state.category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    errorText:
                        state.showValidation && state.category.trim().isEmpty
                        ? 'Select a category'
                        : null,
                  ),
                  items: categoryOptions
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<TaskEditorBloc>().add(
                        TaskCategoryChanged(value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.date,
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && context.mounted) {
                      context.read<TaskEditorBloc>().add(
                        TaskDateChanged(picked),
                      );
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(
                      AppConstants.shortDateFormat.format(state.date),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: state.priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: List<int>.generate(5, (index) => index + 1)
                      .map(
                        (priority) => DropdownMenuItem<int>(
                          value: priority,
                          child: Text('Priority $priority'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<TaskEditorBloc>().add(
                        TaskPriorityChanged(value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: state.isDaily,
                  title: const Text('Daily Task'),
                  onChanged: (value) => context.read<TaskEditorBloc>().add(
                    TaskDailyChanged(value),
                  ),
                ),
                CheckboxListTile(
                  value: state.isCompleted,
                  title: const Text('Completed'),
                  onChanged: (value) => context.read<TaskEditorBloc>().add(
                    TaskCompletionStatusChanged(value ?? false),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: state.status == TaskEditorStatus.submitting
                      ? null
                      : () {
                          context.read<TaskEditorBloc>().add(
                            const TaskSubmitted(),
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      state.status == TaskEditorStatus.submitting
                          ? 'Saving...'
                          : 'Save Task',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
