import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_panel.dart';
import '../../data/repositories/task_category_repository.dart';

class TaskSettingsBody extends StatelessWidget {
  const TaskSettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.read<TaskCategoryRepository>();

    return AppPanel(
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Categories',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (categories.isEmpty)
                    Text(
                      'No categories available.',
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    ...categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
                                    : () => repository.deleteCategory(category),
                                icon: const Icon(Icons.delete_outline_rounded),
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
