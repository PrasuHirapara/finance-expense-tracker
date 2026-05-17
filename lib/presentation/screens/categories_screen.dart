import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../controllers/categories_controller.dart';
import '../widgets/section_card.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const String routeName = 'categories';
  static const String routePath = '/categories';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoriesCubit>(
      create: (context) =>
          CategoriesCubit(context.read<FinanceRepository>())..initialize(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Categories'),
            actions: <Widget>[
              IconButton(
                onPressed: state.isSaving
                    ? null
                    : () => _showAddCategorySheet(context),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          body: state.isLoading && state.categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.status == CategoriesStatus.failure &&
                    state.categories.isEmpty
              ? Center(
                  child: Text(
                    state.errorMessage ?? 'Unable to load categories.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: state.categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    final color = Color(category.colorValue);
                    return SectionCard(
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.14),
                            child: Icon(
                              AppConstants.categoryIconFromCodePoint(
                                category.iconCodePoint,
                              ),
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              category.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _showAddCategorySheet(BuildContext context) async {
    final nameController = TextEditingController();
    var selectedIcon = AppConstants.categoryIconChoices.first;
    var selectedColor = AppConstants.categoryColorChoices.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Add Category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose an icon',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.categoryIconChoices
                        .map((icon) {
                          final selected = icon == selectedIcon;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setState(() => selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose a color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.categoryColorChoices
                        .map((colorValue) {
                          final selected = colorValue == selectedColor;
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () =>
                                setState(() => selectedColor = colorValue),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(colorValue),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        width: 2,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: context.watch<CategoriesCubit>().state.isSaving
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                return;
                              }

                              try {
                                await context
                                    .read<CategoriesCubit>()
                                    .addCategory(
                                      name: name,
                                      colorValue: selectedColor,
                                      iconCodePoint: selectedIcon.codePoint,
                                    );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  showAppSnackBar(
                                    context,
                                    message: 'Category added.',
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    message:
                                        context
                                            .read<CategoriesCubit>()
                                            .state
                                            .errorMessage ??
                                        'Unable to add category.',
                                    type: AppSnackBarType.error,
                                  );
                                }
                              }
                            },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Save Category'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
