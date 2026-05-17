import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/module_export_models.dart';
import '../../../../core/services/app_settings_repository.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/services/module_data_export_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_settings_repository.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/module_export_panel.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_models.dart';
import '../blocs/bank/bank_bloc.dart';
import '../blocs/expense/expense_bloc.dart';
import '../widgets/expense_import_section.dart';

class ExpenseSettingsPage extends StatelessWidget {
  const ExpenseSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: const ExpenseSettingsBody(),
      ),
    );
  }
}

class ExpenseSettingsBody extends StatefulWidget {
  const ExpenseSettingsBody({super.key});

  @override
  State<ExpenseSettingsBody> createState() => _ExpenseSettingsBodyState();
}

class _ExpenseSettingsBodyState extends State<ExpenseSettingsBody> {
  bool _showAllBanks = false;
  bool _showAllCategories = false;

  @override
  Widget build(BuildContext context) {
    final reminderRepository = context.read<ReminderSettingsRepository>();
    final expenseRepository = context.read<ExpenseRepository>();
    final theme = Theme.of(context);

    return BlocBuilder<BankBloc, BankState>(
      builder: (context, bankState) {
        return StreamBuilder<List<ExpenseCategory>>(
          stream: expenseRepository.watchCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? const <ExpenseCategory>[];
            final banks = bankState.banks;
            final visibleCategories = _showAllCategories
                ? categories
                : const <ExpenseCategory>[];
            final visibleBanks = _showAllBanks ? banks : const <BankName>[];

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
                          Text(
                            'Expense Reminder',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose when the daily expense reminder should arrive.',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _formatTime(
                                          context,
                                          settings.expenseReminder,
                                        ),
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Default is 8:00 PM.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => _pickReminderTime(
                                    context,
                                    initialTime: settings.expenseReminder,
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
                  title: 'Expense Export',
                  onExport: (range, format) =>
                      _exportExpenseData(context, range: range, format: format),
                ),
                const SizedBox(height: 18),
                const ExpenseImportSection(),
                const SizedBox(height: 18),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Expense Settings',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage expense categories and banks.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Categories', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          if (categories.isNotEmpty)
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
                          FilledButton.tonalIcon(
                            onPressed: () => _showCategoryDialog(
                              context,
                              existingCategories: categories,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add category'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (categories.isEmpty)
                        _buildEmptyCard(context, 'No categories added yet.')
                      else
                        ...visibleCategories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCategoryCard(
                              context,
                              category: category,
                              canDelete: categories.length > 1,
                              existingCategories: categories,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 14),
                      Text('Banks', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          if (banks.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showAllBanks = !_showAllBanks;
                                });
                              },
                              child: Text(
                                _showAllBanks ? 'Hide banks' : 'View banks',
                              ),
                            ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _showBankDialog(context, existingBanks: banks),
                            icon: const Icon(Icons.add),
                            label: const Text('Add bank'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (banks.isEmpty)
                        _buildEmptyCard(context, 'No banks added yet.')
                      else
                        ...visibleBanks.map(
                          (bank) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildBankCard(
                              context,
                              bank: bank,
                              existingBanks: banks,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Delete Expense Data',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This clears expense entries, restores the default banks and categories, and resets the expense reminder to 8:00 PM.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: () => _deleteExpenseSectionData(context),
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
          },
        );
      },
    );
  }

  Widget _buildEmptyCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required ExpenseCategory category,
    required bool canDelete,
    required List<ExpenseCategory> existingCategories,
  }) {
    final theme = Theme.of(context);
    final color = Color(category.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(
              AppConstants.categoryIconFromCodePoint(category.iconCodePoint),
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(category.name, style: theme.textTheme.titleMedium),
          ),
          IconButton(
            onPressed: () => _showCategoryDialog(
              context,
              category: category,
              existingCategories: existingCategories,
            ),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: canDelete
                ? () async {
                    await context.read<ExpenseRepository>().deleteCategory(
                      category.id,
                    );
                  }
                : null,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(
    BuildContext context, {
    required BankName bank,
    required List<BankName> existingBanks,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(bank.name, style: theme.textTheme.titleMedium)),
          IconButton(
            onPressed: () => _showBankDialog(
              context,
              bankId: bank.id,
              initialName: bank.name,
              existingBanks: existingBanks,
            ),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () {
              context.read<BankBloc>().add(BankDeleted(bank.id));
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
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

    await reminderSettingsRepository.updateExpenseReminder(reminderTime);
    final appSettings = await appSettingsRepository.getSettings();
    if (appSettings.notificationsEnabled) {
      await notificationService.scheduleDailyReminders();
    } else {
      await notificationService.cancelDailyReminders();
    }

    if (!context.mounted) {
      return;
    }
    scaffoldMessenger.showSnackBar(
      buildAppSnackBar(context, message: 'Expense reminder set for $formattedTime.'),
    );
  }

  Future<void> _deleteExpenseSectionData(BuildContext context) async {
    final expenseRepository = context.read<ExpenseRepository>();
    final reminderSettingsRepository = context
        .read<ReminderSettingsRepository>();
    final notificationService = context.read<NotificationService>();
    final appSettingsRepository = context.read<AppSettingsRepository>();
    final expenseBloc = context.read<ExpenseBloc>();
    final cloudSyncService = context.read<CloudSyncService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense Data'),
        content: const Text(
          'Are you sure you want to delete data for Expense?',
        ),
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

    await expenseRepository.clearSectionData();
    String? cloudCleanupWarning;
    try {
      await cloudSyncService.deleteCloudData('Expense');
    } catch (error) {
      cloudCleanupWarning = ' Cloud backup cleanup failed: $error';
    }
    await reminderSettingsRepository.resetExpenseReminder();
    final appSettings = await appSettingsRepository.getSettings();
    if (appSettings.notificationsEnabled) {
      await notificationService.scheduleDailyReminders();
    } else {
      await notificationService.cancelDailyReminders();
    }

    if (!context.mounted) {
      return;
    }
    expenseBloc.add(const ExpenseSubscriptionRequested());
    scaffoldMessenger.showSnackBar(
      buildAppSnackBar(
        context,
        message: 'Expense data deleted.${cloudCleanupWarning ?? ''}',
        type: cloudCleanupWarning == null
            ? AppSnackBarType.info
            : AppSnackBarType.warning,
      ),
    );
  }

  Future<String> _exportExpenseData(
    BuildContext context, {
    required DateTimeRange range,
    required ModuleExportFormat format,
  }) async {
    final repository = context.read<ExpenseRepository>();
    final exportService = context.read<ModuleDataExportService>();
    final entries = await repository.loadEntries(
      filter: ExpenseEntryFilter(fromDate: range.start, toDate: range.end),
    );

    return exportService.exportExpenseData(
      range: range,
      format: format,
      entries: entries,
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    ExpenseCategory? category,
    required List<ExpenseCategory> existingCategories,
  }) async {
    final repository = context.read<ExpenseRepository>();
    final nameController = TextEditingController(text: category?.name ?? '');
    var selectedIcon = category == null
        ? AppConstants.categoryIconChoices.first
        : AppConstants.categoryIconFromCodePoint(category.iconCodePoint);
    var selectedColor =
        category?.colorValue ?? AppConstants.categoryColorChoices.first;

    if (!AppConstants.categoryIconChoices.contains(selectedIcon)) {
      selectedIcon = AppConstants.categoryIconChoices.first;
    }
    if (!AppConstants.categoryColorChoices.contains(selectedColor)) {
      selectedColor = AppConstants.categoryColorChoices.first;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                    category == null ? 'Add Category' : 'Edit Category',
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
                            onTap: () =>
                                setSheetState(() => selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surface,
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
                                setSheetState(() => selectedColor = colorValue),
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
                      onPressed: () async {
                        final trimmedName = nameController.text.trim();
                        if (trimmedName.isEmpty) {
                          return;
                        }

                        final hasDuplicate = existingCategories.any(
                          (existingCategory) =>
                              existingCategory.id != category?.id &&
                              existingCategory.name.toLowerCase() ==
                                  trimmedName.toLowerCase(),
                        );
                        if (hasDuplicate) {
                          showAppSnackBar(
                            context,
                            message: 'Category already exists.',
                            type: AppSnackBarType.warning,
                          );
                          return;
                        }

                        if (category == null) {
                          await repository.createCategory(
                            name: trimmedName,
                            colorValue: selectedColor,
                            iconCodePoint: selectedIcon.codePoint,
                          );
                        } else {
                          await repository.updateCategory(
                            id: category.id,
                            name: trimmedName,
                            colorValue: selectedColor,
                            iconCodePoint: selectedIcon.codePoint,
                          );
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          category == null
                              ? 'Save Category'
                              : 'Update Category',
                        ),
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

  Future<void> _showBankDialog(
    BuildContext context, {
    int? bankId,
    String initialName = '',
    required List<BankName> existingBanks,
  }) async {
    final controller = TextEditingController(text: initialName);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(bankId == null ? 'Add Bank' : 'Edit Bank'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Bank name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  return;
                }
                final hasDuplicate = existingBanks.any(
                  (bank) =>
                      bank.id != bankId &&
                      bank.name.toLowerCase() == name.toLowerCase(),
                );
                if (hasDuplicate) {
                  showAppSnackBar(
                    dialogContext,
                    message: 'Bank already exists.',
                    type: AppSnackBarType.warning,
                  );
                  return;
                }
                if (bankId == null) {
                  context.read<BankBloc>().add(BankAdded(name));
                } else {
                  context.read<BankBloc>().add(
                    BankUpdated(id: bankId, name: name),
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
