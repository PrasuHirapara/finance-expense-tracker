import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_models.dart';

Future<ExpenseSplitDraft?> showExpenseSplitEditor(
  BuildContext context, {
  required double totalAmount,
  ExpenseSplitDraft? initialDraft,
}) {
  return Navigator.of(context).push<ExpenseSplitDraft>(
    MaterialPageRoute<ExpenseSplitDraft>(
      builder: (_) => _ExpenseSplitEditorPage(
        totalAmount: totalAmount,
        initialDraft: initialDraft,
      ),
      fullscreenDialog: true,
    ),
  );
}

Future<LentResolutionDraft?> showLentResolutionEditor(
  BuildContext context, {
  required ExpenseRepository repository,
  required double incomeAmount,
  LentResolutionDraft? initialDraft,
}) {
  return Navigator.of(context).push<LentResolutionDraft>(
    MaterialPageRoute<LentResolutionDraft>(
      builder: (_) => _LentResolutionPage(
        repository: repository,
        incomeAmount: incomeAmount,
        initialDraft: initialDraft,
      ),
      fullscreenDialog: true,
    ),
  );
}

class _ExpenseSplitEditorPage extends StatefulWidget {
  const _ExpenseSplitEditorPage({
    required this.totalAmount,
    this.initialDraft,
  });

  final double totalAmount;
  final ExpenseSplitDraft? initialDraft;

  @override
  State<_ExpenseSplitEditorPage> createState() => _ExpenseSplitEditorPageState();
}

class _ExpenseSplitEditorPageState extends State<_ExpenseSplitEditorPage> {
  static final List<TextInputFormatter> _decimalInputFormatters =
      <TextInputFormatter>[_TwoDecimalTextInputFormatter()];

  final List<_SplitParticipantController> _participants = <_SplitParticipantController>[];
  bool _syncing = false;

  bool get _locked => widget.initialDraft?.hasSettlements ?? false;

  @override
  void initState() {
    super.initState();
    _seedParticipants();
  }

  @override
  void dispose() {
    for (final participant in _participants) {
      participant.dispose();
    }
    super.dispose();
  }

  void _seedParticipants() {
    final source = widget.initialDraft;
    final items = source?.participants ??
        _equalSeed(totalAmount: widget.totalAmount, count: 2);
    for (final participant in items) {
      _participants.add(_SplitParticipantController.fromParticipant(participant));
    }
  }

  List<ExpenseSplitParticipant> _equalSeed({
    required double totalAmount,
    required int count,
  }) {
    final participants = <ExpenseSplitParticipant>[];
    var remaining = totalAmount;
    var remainingPercent = 100.0;
    for (var index = 0; index < count; index++) {
      final isLast = index == count - 1;
      final percentage = isLast ? remainingPercent : 100 / count;
      final amount = isLast ? remaining : (totalAmount * percentage / 100);
      participants.add(
        ExpenseSplitParticipant(
          name: index == 0 ? 'Me' : 'Participant ${index + 1}',
          amount: double.parse(amount.toStringAsFixed(2)),
          percentage: double.parse(percentage.toStringAsFixed(2)),
          isSelf: index == 0,
          settledAmount: index == 0 ? double.parse(amount.toStringAsFixed(2)) : 0,
          sortOrder: index,
        ),
      );
      remaining -= amount;
      remainingPercent -= percentage;
    }
    return participants;
  }

  void _applyEqualSplit() {
    if (_locked) {
      return;
    }
    final next = _equalSeed(totalAmount: widget.totalAmount, count: _participants.length);
    _syncing = true;
    for (var index = 0; index < _participants.length; index++) {
      final controller = _participants[index];
      final participant = next[index];
      controller.nameController.text = index == 0
          ? controller.nameController.text.isEmpty
                ? 'Me'
                : controller.nameController.text
          : controller.nameController.text;
      controller.amountController.text = _formatNumber(participant.amount);
      controller.percentageController.text = _formatNumber(participant.percentage);
    }
    _syncing = false;
    setState(() {});
  }

  void _addParticipant() {
    if (_locked) {
      return;
    }
    setState(() {
      _participants.add(
        _SplitParticipantController(
          isSelf: false,
          settledAmount: 0,
          sortOrder: _participants.length,
          nameController: TextEditingController(
            text: 'Participant ${_participants.length + 1}',
          ),
          amountController: TextEditingController(),
          percentageController: TextEditingController(),
        ),
      );
    });
    _applyEqualSplit();
  }

  void _removeParticipant(int index) {
    if (_locked || _participants[index].isSelf || _participants.length <= 1) {
      return;
    }
    setState(() {
      final removed = _participants.removeAt(index);
      removed.dispose();
    });
    _applyEqualSplit();
  }

  void _onAmountChanged(_SplitParticipantController controller, String value) {
    if (_syncing) {
      return;
    }
    final amount = _parseValue(value);
    final percentage = widget.totalAmount <= 0
        ? 0.0
        : (amount / widget.totalAmount) * 100;
    _syncing = true;
    controller.percentageController.text = _formatNumber(percentage);
    _syncing = false;
    setState(() {});
  }

  void _onPercentageChanged(
    _SplitParticipantController controller,
    String value,
  ) {
    if (_syncing) {
      return;
    }
    final percentage = _parseValue(value);
    final amount = widget.totalAmount * percentage / 100;
    _syncing = true;
    controller.amountController.text = _formatNumber(amount);
    _syncing = false;
    setState(() {});
  }

  ExpenseSplitDraft? _buildDraft() {
    final participants = <ExpenseSplitParticipant>[];
    for (var index = 0; index < _participants.length; index++) {
      final item = _participants[index];
      final name = item.nameController.text.trim();
      final amount = _parseValue(item.amountController.text);
      final percentage = _parseValue(item.percentageController.text);
      if (name.isEmpty) {
        _showError('Enter a name for every participant.');
        return null;
      }
      participants.add(
        ExpenseSplitParticipant(
          id: item.id,
          name: name,
          amount: double.parse(amount.toStringAsFixed(2)),
          percentage: double.parse(percentage.toStringAsFixed(2)),
          isSelf: item.isSelf,
          settledAmount: item.isSelf
              ? double.parse(amount.toStringAsFixed(2))
              : item.settledAmount.clamp(0, amount).toDouble(),
          sortOrder: index,
        ),
      );
    }

    final totalAmount = participants.fold<double>(0, (sum, item) => sum + item.amount);
    final totalPercentage =
        participants.fold<double>(0, (sum, item) => sum + item.percentage);
    if ((totalAmount - widget.totalAmount).abs() > 0.01) {
      _showError('Participant amounts must exactly match the expense amount.');
      return null;
    }
    if ((totalPercentage - 100).abs() > 0.01) {
      _showError('Participant percentages must total 100%.');
      return null;
    }

    return ExpenseSplitDraft(
      recordId: widget.initialDraft?.recordId,
      expenseEntryId: widget.initialDraft?.expenseEntryId,
      lentEntryId: widget.initialDraft?.lentEntryId,
      totalAmount: double.parse(widget.totalAmount.toStringAsFixed(2)),
      participants: participants,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  double _parseValue(String value) => double.tryParse(value) ?? 0;

  String _formatNumber(double value) {
    final rounded = double.parse(value.toStringAsFixed(2));
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final amountTotal = _participants.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item.amountController.text) ?? 0),
    );
    final percentageTotal = _participants.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item.percentageController.text) ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Expense'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              final draft = _buildDraft();
              if (draft != null) {
                Navigator.of(context).pop(draft);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          if (_locked)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'This split already has settlements, so participant shares are locked.',
                ),
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Expense amount'),
            subtitle: Text('Rs ${_formatNumber(widget.totalAmount)}'),
            trailing: !_locked
                ? TextButton(
                    onPressed: _applyEqualSplit,
                    child: const Text('Equal Split'),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          ..._participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: participant.nameController,
                              enabled: !_locked,
                              decoration: const InputDecoration(
                                labelText: 'Participant Name',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (participant.isSelf)
                            const Chip(label: Text('Settled'))
                          else if (!_locked)
                            IconButton(
                              onPressed: () => _removeParticipant(index),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: participant.amountController,
                              enabled: !_locked,
                              inputFormatters: _decimalInputFormatters,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixText: 'Rs ',
                              ),
                              onChanged: (value) => _onAmountChanged(participant, value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: participant.percentageController,
                              enabled: !_locked,
                              inputFormatters: _decimalInputFormatters,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Percentage',
                                suffixText: '%',
                              ),
                              onChanged: (value) =>
                                  _onPercentageChanged(participant, value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (!_locked)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _addParticipant,
                icon: const Icon(Icons.add),
                label: const Text('Add Participant'),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(
                'Amount total: Rs ${_formatNumber(amountTotal)} / ${_formatNumber(widget.totalAmount)}',
              ),
              subtitle: Text(
                'Percentage total: ${_formatNumber(percentageTotal)}%',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LentResolutionPage extends StatefulWidget {
  const _LentResolutionPage({
    required this.repository,
    required this.incomeAmount,
    this.initialDraft,
  });

  final ExpenseRepository repository;
  final double incomeAmount;
  final LentResolutionDraft? initialDraft;

  @override
  State<_LentResolutionPage> createState() => _LentResolutionPageState();
}

class _LentResolutionPageState extends State<_LentResolutionPage> {
  late final Future<List<LentResolutionCandidate>> _future =
      widget.repository.loadResolvableLentEntries();
  final TextEditingController _searchController = TextEditingController();
  LentResolutionCandidate? _selected;
  final Set<String> _selectedKeys = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleParticipant(ExpenseSplitParticipant participant, bool settled) {
    if (participant.isSelf || participant.isSettled) {
      return;
    }
    final key = _participantKey(participant);
    setState(() {
      if (settled) {
        _selectedKeys.add(key);
      } else {
        _selectedKeys.remove(key);
      }
    });
  }

  String _participantKey(ExpenseSplitParticipant participant) {
    return participant.id?.toString() ??
        '${participant.sortOrder}:${participant.name}:${participant.amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Lent'),
        actions: <Widget>[
          TextButton(
            onPressed: _selected == null
                ? null
                : () {
                    final participants = _selected!.splitDraft.participants
                        .where(
                          (participant) =>
                              _selectedKeys.contains(_participantKey(participant)),
                        )
                        .toList(growable: false);
                    final total = participants.fold<double>(
                      0,
                      (sum, participant) => sum + participant.pendingAmount,
                    );
                    if ((total - widget.incomeAmount).abs() > 0.01) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Selected shares must exactly match the income amount.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop(
                      LentResolutionDraft(
                        lentEntryId: _selected!.entry.id,
                        participants: participants,
                      ),
                    );
                  },
            child: const Text('Apply'),
          ),
        ],
      ),
      body: FutureBuilder<List<LentResolutionCandidate>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final filtered = all.where((candidate) {
            final query = _searchController.text.trim().toLowerCase();
            if (query.isEmpty) {
              return true;
            }
            return <String>[
              candidate.entry.title,
              candidate.entry.counterparty ?? '',
              ...candidate.splitDraft.participants.map((item) => item.name),
            ].any((value) => value.toLowerCase().contains(query));
          }).toList(growable: false);

          if (_selected == null &&
              widget.initialDraft != null &&
              all.isNotEmpty) {
            for (final candidate in all) {
              if (candidate.entry.id == widget.initialDraft!.lentEntryId) {
                _selected = candidate;
                for (final participant in widget.initialDraft!.participants) {
                  _selectedKeys.add(_participantKey(participant));
                }
                break;
              }
            }
          }

          final selectedTotal = _selected?.splitDraft.participants
                  .where(
                    (participant) =>
                        _selectedKeys.contains(_participantKey(participant)),
                  )
                  .fold<double>(0, (sum, participant) => sum + participant.pendingAmount) ??
              0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search lent entries',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text('Income amount: ${AppConstants.currency(widget.incomeAmount)}'),
                  subtitle: Text('Selected total: ${AppConstants.currency(selectedTotal)}'),
                ),
              ),
              const SizedBox(height: 12),
              ...filtered.map((candidate) {
                final isSelected = _selected?.entry.id == candidate.entry.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selected = candidate;
                          _selectedKeys.clear();
                        });
                      },
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                      ),
                      title: Text(candidate.entry.title),
                      subtitle: Text(
                        '${AppConstants.shortDateFormat.format(candidate.entry.date)} | Pending ${AppConstants.currency(candidate.splitDraft.pendingLentAmount)}',
                      ),
                    ),
                  ),
                );
              }),
              if (_selected != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  'Participant Shares',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._selected!.splitDraft.participants.map((participant) {
                  final value = participant.isSelf || participant.isSettled
                      ? 'Settled'
                      : _selectedKeys.contains(_participantKey(participant))
                      ? 'Settled'
                      : 'Unsettled';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(participant.name),
                            const SizedBox(height: 8),
                            Text(
                              participant.isSelf
                                  ? 'My share: ${AppConstants.currency(participant.amount)}'
                                  : 'Pending amount: ${AppConstants.currency(participant.pendingAmount)}',
                            ),
                            const SizedBox(height: 12),
                            AppSelectField<String>(
                              label: 'Settlement Status',
                              value: value,
                              enabled:
                                  !participant.isSelf && !participant.isSettled,
                              options: const <AppSelectOption<String>>[
                                AppSelectOption<String>(
                                  value: 'Unsettled',
                                  label: 'Unsettled',
                                ),
                                AppSelectOption<String>(
                                  value: 'Settled',
                                  label: 'Settled',
                                ),
                              ],
                              onChanged: (next) => _toggleParticipant(
                                participant,
                                next == 'Settled',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SplitParticipantController {
  _SplitParticipantController({
    required this.nameController,
    required this.amountController,
    required this.percentageController,
    required this.isSelf,
    required this.settledAmount,
    required this.sortOrder,
    this.id,
  });

  factory _SplitParticipantController.fromParticipant(
    ExpenseSplitParticipant participant,
  ) {
    return _SplitParticipantController(
      id: participant.id,
      isSelf: participant.isSelf,
      settledAmount: participant.settledAmount,
      sortOrder: participant.sortOrder,
      nameController: TextEditingController(text: participant.name),
      amountController: TextEditingController(
        text: participant.amount == participant.amount.roundToDouble()
            ? participant.amount.toStringAsFixed(0)
            : participant.amount.toStringAsFixed(2),
      ),
      percentageController: TextEditingController(
        text: participant.percentage == participant.percentage.roundToDouble()
            ? participant.percentage.toStringAsFixed(0)
            : participant.percentage.toStringAsFixed(2),
      ),
    );
  }

  final int? id;
  final bool isSelf;
  final double settledAmount;
  final int sortOrder;
  final TextEditingController nameController;
  final TextEditingController amountController;
  final TextEditingController percentageController;

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    percentageController.dispose();
  }
}

class _TwoDecimalTextInputFormatter extends TextInputFormatter {
  static final RegExp _pattern = RegExp(r'^\d*(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }
    if (text == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }
    if (_pattern.hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  }
}
