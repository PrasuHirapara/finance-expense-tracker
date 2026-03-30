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
      body: const ExpenseSettingsBody(),
    );
  }
}

class ExpenseSettingsBody extends StatelessWidget {
  const ExpenseSettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BankBloc, BankState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Bank Name Management',
                      style: Theme.of(context).textTheme.titleLarge,
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
              ...state.banks.map(
                (bank) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppPanel(
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
      builder: (context) {
        return AlertDialog(
          title: Text(bankId == null ? 'Add Bank' : 'Edit Bank'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Bank name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
