import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../data/repositories/task_category_repository.dart';
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
        appBar: AppBar(
          title: BlocBuilder<TaskEditorBloc, TaskEditorState>(
            buildWhen: (previous, current) => previous.taskId != current.taskId,
            builder: (context, state) =>
                Text(state.taskId == null ? 'Add Task' : 'Edit Task'),
          ),
        ),
        body: StreamBuilder<List<String>>(
          stream: context.read<TaskCategoryRepository>().watchCategories(),
          builder: (context, snapshot) {
            final categories = (snapshot.data == null || snapshot.data!.isEmpty)
                ? AppConstants.taskCategoryChoices
                : snapshot.data!;

            return BlocBuilder<TaskEditorBloc, TaskEditorState>(
              builder: (context, state) {
                final effectiveCategory = state.category.trim().isEmpty
                    ? categories.first
                    : state.category;
                if (!categories.contains(effectiveCategory) &&
                    categories.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context.read<TaskEditorBloc>().add(
                        TaskCategoryChanged(categories.first),
                      );
                    }
                  });
                }

                final categoryOptions = <String>{
                  ...categories,
                  if (state.category.trim().isNotEmpty) state.category.trim(),
                }
                    .map(
                      (category) => AppSelectOption<String>(
                        value: category,
                        label: category,
                      ),
                    )
                    .toList(growable: false);

                final priorityOptions = List<int>.generate(
                  5,
                  (index) => index + 1,
                )
                    .map(
                      (priority) => AppSelectOption<int>(
                        value: priority,
                        label: priority.toString(),
                      ),
                    )
                    .toList(growable: false);

                return ListView(
                  key: ValueKey<int?>(state.taskId),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: <Widget>[
                    TextFormField(
                      initialValue: state.title,
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
                    TextFormField(
                      initialValue: state.description,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description'),
                      onChanged: (value) => context.read<TaskEditorBloc>().add(
                        TaskDescriptionChanged(value),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppSelectField<String>(
                      label: 'Category',
                      value: categories.contains(effectiveCategory)
                          ? effectiveCategory
                          : categoryOptions.first.value,
                      options: categoryOptions,
                      errorText:
                          state.showValidation && state.category.trim().isEmpty
                          ? 'Select a category'
                          : null,
                      onChanged: (value) {
                        context.read<TaskEditorBloc>().add(
                          TaskCategoryChanged(value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.date,
                          firstDate: DateTime(2022),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
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
                    AppSelectField<int>(
                      label: 'Priority',
                      value: state.priority,
                      options: priorityOptions,
                      onChanged: (value) => context.read<TaskEditorBloc>().add(
                        TaskPriorityChanged(value),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
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
                              : state.taskId == null
                              ? 'Save Task'
                              : 'Update Task',
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
