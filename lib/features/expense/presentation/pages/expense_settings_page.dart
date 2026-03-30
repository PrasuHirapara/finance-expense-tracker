import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_settings_repository.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../data/repositories/expense_repository.dart';
import '../blocs/bank/bank_bloc.dart';
import '../blocs/expense/expense_bloc.dart';

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

class ExpenseSettingsBody extends StatelessWidget {
  const ExpenseSettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final reminderRepository = context.read<ReminderSettingsRepository>();

    return BlocBuilder<BankBloc, BankState>(
      builder: (context, state) {
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
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose when the daily expense reminder should arrive.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
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
                                    _formatTime(
                                      context,
                                      settings.expenseReminder,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Default is 8:00 PM.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
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
                              'Expense Settings',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bank configuration',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showBankDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Bank'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.banks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text('No banks added yet.'),
                    )
                  else
                    ...state.banks.map(
                      (bank) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  bank.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showBankDialog(
                                  context,
                                  bankId: bank.id,
                                  initialName: bank.name,
                                ),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                onPressed: () {
                                  context.read<BankBloc>().add(
                                    BankDeleted(bank.id),
                                  );
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This clears expense entries, restores the default banks, and resets the expense reminder to 8:00 PM.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => _deleteExpenseSectionData(context),
                    style: FilledButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
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
    await notificationService.scheduleDailyReminders();

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Expense reminder set for $formattedTime.')),
    );
  }

  Future<void> _deleteExpenseSectionData(BuildContext context) async {
    final expenseRepository = context.read<ExpenseRepository>();
    final reminderSettingsRepository = context
        .read<ReminderSettingsRepository>();
    final notificationService = context.read<NotificationService>();
    final expenseBloc = context.read<ExpenseBloc>();
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
    await reminderSettingsRepository.resetExpenseReminder();
    await notificationService.scheduleDailyReminders();

    expenseBloc.add(const ExpenseSubscriptionRequested());
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Expense data deleted.')),
    );
  }

  Future<void> _showBankDialog(
    BuildContext context, {
    int? bankId,
    String initialName = '',
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
