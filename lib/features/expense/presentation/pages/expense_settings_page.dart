import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_panel.dart';
import '../blocs/bank/bank_bloc.dart';

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
    return BlocBuilder<BankBloc, BankState>(
      builder: (context, state) {
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
                          'Expense Settings',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bank configuration',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
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
                              style: Theme.of(context).textTheme.titleMedium,
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
                              context.read<BankBloc>().add(BankDeleted(bank.id));
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
        );
      },
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
