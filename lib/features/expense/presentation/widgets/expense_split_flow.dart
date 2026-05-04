import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_models.dart';
import '../utils/expense_search_utils.dart';

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

Future<BorrowedResolutionDraft?> showBorrowedResolutionEditor(
  BuildContext context, {
  required ExpenseRepository repository,
  required double expenseAmount,
  BorrowedResolutionDraft? initialDraft,
}) {
  return Navigator.of(context).push<BorrowedResolutionDraft>(
    MaterialPageRoute<BorrowedResolutionDraft>(
      builder: (_) => _BorrowedResolutionPage(
        repository: repository,
        expenseAmount: expenseAmount,
        initialDraft: initialDraft,
      ),
      fullscreenDialog: true,
    ),
  );
}

class _ExpenseSplitEditorPage extends StatefulWidget {
  const _ExpenseSplitEditorPage({required this.totalAmount, this.initialDraft});

  final double totalAmount;
  final ExpenseSplitDraft? initialDraft;

  @override
  State<_ExpenseSplitEditorPage> createState() =>
      _ExpenseSplitEditorPageState();
}

class _ExpenseSplitEditorPageState extends State<_ExpenseSplitEditorPage> {
  static final List<TextInputFormatter> _decimalInputFormatters =
      <TextInputFormatter>[_TwoDecimalTextInputFormatter()];

  final List<_SplitParticipantController> _participants =
      <_SplitParticipantController>[];
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
    final items =
        source?.participants ??
        _equalSeed(totalAmount: widget.totalAmount, count: 2);
    for (final participant in items) {
      _participants.add(
        _SplitParticipantController.fromParticipant(participant),
      );
    }
  }

  List<ExpenseSplitParticipant> _equalSeed({
    required double totalAmount,
    required int count,
  }) {
    final participants = <ExpenseSplitParticipant>[];
    final normalizedTotal = _roundValue(totalAmount);
    final totalMinorUnits = _toMinorUnits(normalizedTotal);
    final baseMinorUnits = count == 0 ? 0 : totalMinorUnits ~/ count;
    final remainderMinorUnits = count == 0 ? 0 : totalMinorUnits % count;
    var assignedPercentage = 0.0;
    for (var index = 0; index < count; index++) {
      final isLast = index == count - 1;
      final amount = _fromMinorUnits(
        baseMinorUnits + (index >= count - remainderMinorUnits ? 1 : 0),
      );
      final percentage = isLast
          ? _roundValue(100 - assignedPercentage)
          : _roundValue((amount / normalizedTotal) * 100);
      assignedPercentage = _roundValue(assignedPercentage + percentage);
      participants.add(
        ExpenseSplitParticipant(
          name: index == 0 ? 'Me' : 'Participant ${index + 1}',
          amount: amount,
          percentage: percentage,
          isSelf: index == 0,
          settledAmount: index == 0 ? amount : 0,
          sortOrder: index,
        ),
      );
    }
    return participants;
  }

  void _applyEqualSplit() {
    if (_locked) {
      return;
    }
    final next = _equalSeed(
      totalAmount: widget.totalAmount,
      count: _participants.length,
    );
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
      controller.percentageController.text = _formatNumber(
        participant.percentage,
      );
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
    controller.percentageController.text = _formatNumber(
      _roundValue(percentage),
    );
    _syncing = false;
    setState(() {});
  }

  ExpenseSplitDraft? _buildDraft() {
    final participants = <ExpenseSplitParticipant>[];
    for (var index = 0; index < _participants.length; index++) {
      final item = _participants[index];
      final name = item.nameController.text.trim();
      final amount = _parseValue(item.amountController.text);
      final percentage = widget.totalAmount <= 0
          ? 0.0
          : _roundValue((amount / widget.totalAmount) * 100);
      if (name.isEmpty) {
        _showError('Enter a name for every participant.');
        return null;
      }
      participants.add(
        ExpenseSplitParticipant(
          id: item.id,
          name: name,
          amount: _roundValue(amount),
          percentage: _roundValue(percentage),
          isSelf: item.isSelf,
          settledAmount: item.isSelf
              ? _roundValue(amount)
              : _roundValue(item.settledAmount.clamp(0, amount).toDouble()),
          sortOrder: index,
        ),
      );
    }

    final totalAmount = participants.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalPercentage = participants.fold<double>(
      0,
      (sum, item) => sum + item.percentage,
    );
    if ((totalAmount - widget.totalAmount).abs() > 0.01) {
      _showError('Participant amounts must exactly match the expense amount.');
      return null;
    }
    if ((totalPercentage - 100).abs() > 0.01) {
      _showError('Participant amounts must exactly match the expense amount.');
      return null;
    }

    return ExpenseSplitDraft(
      recordId: widget.initialDraft?.recordId,
      expenseEntryId: widget.initialDraft?.expenseEntryId,
      lentEntryId: widget.initialDraft?.lentEntryId,
      totalAmount: _roundValue(widget.totalAmount),
      participants: participants,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  double _parseValue(String value) =>
      double.tryParse(value.replaceAll('%', '').trim()) ?? 0;

  String _formatNumber(double value) => _roundValue(value).toStringAsFixed(2);

  double _roundValue(double value) => double.parse(value.toStringAsFixed(2));

  int _toMinorUnits(double value) => (_roundValue(value) * 100).round();

  double _fromMinorUnits(int value) => value / 100;

  @override
  Widget build(BuildContext context) {
    final amountTotal = _participants.fold<double>(
      0,
      (sum, item) => sum + (double.tryParse(item.amountController.text) ?? 0),
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
                      TextField(
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
                        onChanged: (value) =>
                            _onAmountChanged(participant, value),
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
  static const int _initialVisibleCandidates = 5;

  late final Future<List<LentResolutionCandidate>> _future = widget.repository
      .loadResolvableLentEntries();
  final TextEditingController _searchController = TextEditingController();
  int _visibleCandidateCount = _initialVisibleCandidates;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _participantKey(ExpenseSplitParticipant participant) {
    return participant.id?.toString() ??
        '${participant.sortOrder}:${participant.name}:${participant.amount.toStringAsFixed(2)}';
  }

  Future<void> _openCandidate(LentResolutionCandidate candidate) async {
    final initialSelectedKeys =
        widget.initialDraft?.lentEntryId == candidate.entry.id
        ? widget.initialDraft!.participants.map(_participantKey).toSet()
        : const <String>{};
    final draft = await Navigator.of(context).push<LentResolutionDraft>(
      MaterialPageRoute<LentResolutionDraft>(
        builder: (_) => _LentParticipantSelectionPage(
          candidate: candidate,
          incomeAmount: widget.incomeAmount,
          initialSelectedKeys: initialSelectedKeys,
        ),
        fullscreenDialog: true,
      ),
    );
    if (draft != null && mounted) {
      Navigator.of(context).pop(draft);
    }
  }

  Future<void> _openSummaryPage(
    List<LentResolutionCandidate> candidates,
  ) async {
    final summaries = _buildLentSummaries(candidates);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _NameAmountSummaryPage(
          title: 'Lent Data',
          amountLabel: 'Total Lent',
          emptyMessage: 'No pending lent data found.',
          summaries: summaries,
        ),
      ),
    );
  }

  List<_NameAmountSummary> _buildLentSummaries(
    List<LentResolutionCandidate> candidates,
  ) {
    final totals = <String, double>{};
    for (final candidate in candidates) {
      for (final participant in candidate.splitDraft.participants) {
        if (participant.isSelf || participant.pendingAmount <= 0.005) {
          continue;
        }
        final name = participant.name.trim().isEmpty
            ? 'Participant'
            : participant.name.trim();
        totals.update(
          name,
          (value) => value + participant.pendingAmount,
          ifAbsent: () => participant.pendingAmount,
        );
      }
    }
    final summaries = totals.entries
        .map(
          (entry) => _NameAmountSummary(name: entry.key, amount: entry.value),
        )
        .toList(growable: false);
    summaries.sort((a, b) => b.amount.compareTo(a.amount));
    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resolve Lent')),
      body: FutureBuilder<List<LentResolutionCandidate>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final query = _searchController.text.trim().toLowerCase();
          final filtered = all
              .where((candidate) {
                if (query.isEmpty) {
                  return true;
                }
                if (matchesEquivalentDateQuery(candidate.entry.date, query)) {
                  return true;
                }
                return <String>[
                  candidate.entry.title,
                  candidate.entry.counterparty ?? '',
                  ...candidate.splitDraft.participants.map((item) => item.name),
                  ...equivalentDateSearchTerms(candidate.entry.date),
                ].any((value) => value.toLowerCase().contains(query));
              })
              .toList(growable: false);
          final visible = filtered
              .take(_visibleCandidateCount)
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search lent entries',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {
                  _visibleCandidateCount = _initialVisibleCandidates;
                }),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(
                    'Income amount: ${AppConstants.currency(widget.incomeAmount)}',
                  ),
                  subtitle: const Text(
                    'Select a transaction to choose participant shares on the next screen.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('No lent entries match this search.'),
                  ),
                ),
              ...visible.map((candidate) {
                final participantNames = candidate.splitDraft.participants
                    .where((participant) => !participant.isSelf)
                    .map((participant) => participant.name)
                    .join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openCandidate(candidate),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      title: Text(candidate.entry.title),
                      subtitle: Text(
                        '${AppConstants.shortDateFormat.format(candidate.entry.date)} | Pending ${AppConstants.currency(candidate.splitDraft.pendingLentAmount)}${participantNames.isEmpty ? '' : ' | $participantNames'}',
                      ),
                    ),
                  ),
                );
              }),
              if (filtered.isNotEmpty)
                Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: () => _openSummaryPage(filtered),
                      child: const Text('Show Data'),
                    ),
                    const Spacer(),
                    if (filtered.length > visible.length)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _visibleCandidateCount += 5;
                          });
                        },
                        child: const Text('Show more'),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LentParticipantSelectionPage extends StatefulWidget {
  const _LentParticipantSelectionPage({
    required this.candidate,
    required this.incomeAmount,
    required this.initialSelectedKeys,
  });

  final LentResolutionCandidate candidate;
  final double incomeAmount;
  final Set<String> initialSelectedKeys;

  @override
  State<_LentParticipantSelectionPage> createState() =>
      _LentParticipantSelectionPageState();
}

class _LentParticipantSelectionPageState
    extends State<_LentParticipantSelectionPage> {
  late final Set<String> _selectedKeys = <String>{
    ...widget.initialSelectedKeys,
  };

  String _participantKey(ExpenseSplitParticipant participant) {
    return participant.id?.toString() ??
        '${participant.sortOrder}:${participant.name}:${participant.amount.toStringAsFixed(2)}';
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

  String _formatParticipantNames(List<ExpenseSplitParticipant> participants) {
    final names = participants
        .where((participant) => !participant.isSelf)
        .map((participant) => participant.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (names.isEmpty) {
      return '-';
    }
    if (names.length == 1) {
      return names.first;
    }
    if (names.length == 2) {
      return '${names.first} and ${names.last}';
    }
    return '${names.sublist(0, names.length - 1).join(', ')}, and ${names.last}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedParticipants = widget.candidate.splitDraft.participants
        .where(
          (participant) => _selectedKeys.contains(_participantKey(participant)),
        )
        .toList(growable: false);
    final selectedTotal = selectedParticipants.fold<double>(
      0,
      (sum, participant) => sum + participant.pendingAmount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Participant Shares'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if ((selectedTotal - widget.incomeAmount).abs() > 0.01) {
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
                  lentEntryId: widget.candidate.entry.id,
                  participants: selectedParticipants,
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.candidate.entry.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Participants: ${_formatParticipantNames(widget.candidate.splitDraft.participants)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${AppConstants.shortDateFormat.format(widget.candidate.entry.date)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Income amount: ${AppConstants.currency(widget.incomeAmount)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selected total: ${AppConstants.currency(selectedTotal)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...widget.candidate.splitDraft.participants.map((participant) {
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
                        enabled: !participant.isSelf && !participant.isSettled,
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
                        onChanged: (next) =>
                            _toggleParticipant(participant, next == 'Settled'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BorrowedResolutionPage extends StatefulWidget {
  const _BorrowedResolutionPage({
    required this.repository,
    required this.expenseAmount,
    this.initialDraft,
  });

  final ExpenseRepository repository;
  final double expenseAmount;
  final BorrowedResolutionDraft? initialDraft;

  @override
  State<_BorrowedResolutionPage> createState() =>
      _BorrowedResolutionPageState();
}

class _BorrowedResolutionPageState extends State<_BorrowedResolutionPage> {
  static const int _initialVisibleCandidates = 5;

  late final Future<List<BorrowedResolutionCandidate>> _future = widget
      .repository
      .loadResolvableBorrowedEntries();
  final TextEditingController _searchController = TextEditingController();
  int _visibleCandidateCount = _initialVisibleCandidates;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCandidate(BorrowedResolutionCandidate candidate) async {
    final draft = await Navigator.of(context).push<BorrowedResolutionDraft>(
      MaterialPageRoute<BorrowedResolutionDraft>(
        builder: (_) => _BorrowedResolutionSelectionPage(
          candidate: candidate,
          expenseAmount: widget.expenseAmount,
          initialAmount:
              widget.initialDraft?.borrowedEntryId == candidate.entry.id
              ? widget.initialDraft!.settledAmount
              : null,
        ),
        fullscreenDialog: true,
      ),
    );
    if (draft != null && mounted) {
      Navigator.of(context).pop(draft);
    }
  }

  Future<void> _openSummaryPage(
    List<BorrowedResolutionCandidate> candidates,
  ) async {
    final summaries = _buildBorrowedSummaries(candidates);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _NameAmountSummaryPage(
          title: 'Borrowed Data',
          amountLabel: 'Total Borrowed',
          emptyMessage: 'No pending borrowed data found.',
          summaries: summaries,
        ),
      ),
    );
  }

  List<_NameAmountSummary> _buildBorrowedSummaries(
    List<BorrowedResolutionCandidate> candidates,
  ) {
    final totals = <String, double>{};
    for (final candidate in candidates) {
      final name = candidate.entry.counterparty?.trim().isNotEmpty == true
          ? candidate.entry.counterparty!.trim()
          : candidate.entry.title.trim();
      final normalizedName = name.isEmpty ? 'Unknown' : name;
      totals.update(
        normalizedName,
        (value) => value + candidate.pendingAmount,
        ifAbsent: () => candidate.pendingAmount,
      );
    }
    final summaries = totals.entries
        .map(
          (entry) => _NameAmountSummary(name: entry.key, amount: entry.value),
        )
        .toList(growable: false);
    summaries.sort((a, b) => b.amount.compareTo(a.amount));
    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resolve Borrowed')),
      body: FutureBuilder<List<BorrowedResolutionCandidate>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final query = _searchController.text.trim().toLowerCase();
          final filtered = all
              .where((candidate) {
                final matchesAmount =
                    candidate.pendingAmount + 0.005 >= widget.expenseAmount ||
                    candidate.entry.id == widget.initialDraft?.borrowedEntryId;
                if (!matchesAmount) {
                  return false;
                }
                if (query.isEmpty) {
                  return true;
                }
                if (matchesEquivalentDateQuery(candidate.entry.date, query)) {
                  return true;
                }
                return <String>[
                  candidate.entry.title,
                  candidate.entry.counterparty ?? '',
                  candidate.entry.notes,
                  candidate.entry.category.name,
                  ...equivalentDateSearchTerms(candidate.entry.date),
                ].any((value) => value.toLowerCase().contains(query));
              })
              .toList(growable: false);
          final visible = filtered
              .take(_visibleCandidateCount)
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: <Widget>[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search borrowed entries',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {
                  _visibleCandidateCount = _initialVisibleCandidates;
                }),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(
                    'Expense amount: ${AppConstants.currency(widget.expenseAmount)}',
                  ),
                  subtitle: const Text(
                    'Select a borrowed entry to continue on the next screen.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'No borrowed entries have enough pending amount for this expense.',
                    ),
                  ),
                ),
              ...visible.map((candidate) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      onTap: () => _openCandidate(candidate),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      title: Text(candidate.entry.title),
                      subtitle: Text(
                        '${AppConstants.shortDateFormat.format(candidate.entry.date)} | Pending ${AppConstants.currency(candidate.pendingAmount)}',
                      ),
                    ),
                  ),
                );
              }),
              if (filtered.isNotEmpty)
                Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: () => _openSummaryPage(filtered),
                      child: const Text('Show Data'),
                    ),
                    const Spacer(),
                    if (filtered.length > visible.length)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _visibleCandidateCount += 5;
                          });
                        },
                        child: const Text('Show more'),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BorrowedResolutionSelectionPage extends StatefulWidget {
  const _BorrowedResolutionSelectionPage({
    required this.candidate,
    required this.expenseAmount,
    this.initialAmount,
  });

  final BorrowedResolutionCandidate candidate;
  final double expenseAmount;
  final double? initialAmount;

  @override
  State<_BorrowedResolutionSelectionPage> createState() =>
      _BorrowedResolutionSelectionPageState();
}

class _BorrowedResolutionSelectionPageState
    extends State<_BorrowedResolutionSelectionPage> {
  final TextEditingController _settledAmountController =
      TextEditingController();
  bool _syncingSettledAmount = false;

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.initialAmount ?? _maxAllowedAmount;
    _setSettledAmount(
      initialAmount <= _maxAllowedAmount ? initialAmount : _maxAllowedAmount,
    );
  }

  @override
  void dispose() {
    _settledAmountController.dispose();
    super.dispose();
  }

  double get _maxAllowedAmount {
    return widget.expenseAmount <= widget.candidate.pendingAmount
        ? widget.expenseAmount
        : widget.candidate.pendingAmount;
  }

  double _selectedAmount() =>
      double.tryParse(_settledAmountController.text) ?? 0;

  void _setSettledAmount(double amount) {
    _syncingSettledAmount = true;
    _settledAmountController.text = amount.toStringAsFixed(2);
    _settledAmountController.selection = TextSelection.collapsed(
      offset: _settledAmountController.text.length,
    );
    _syncingSettledAmount = false;
  }

  void _handleSettledAmountChanged(String value) {
    if (_syncingSettledAmount) {
      return;
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return;
    }
    if (amount > _maxAllowedAmount + 0.005) {
      _setSettledAmount(_maxAllowedAmount);
    }
  }

  String? _resolveAmountErrorText() {
    if (_settledAmountController.text.trim().isEmpty) {
      return null;
    }
    final amount = _selectedAmount();
    if (amount <= 0) {
      return 'Enter a valid amount.';
    }
    if (amount > widget.expenseAmount + 0.005) {
      return 'Amount cannot exceed the entered expense amount.';
    }
    if (amount > widget.candidate.pendingAmount + 0.005) {
      return 'Amount cannot exceed the pending borrowed amount.';
    }
    if ((amount - widget.expenseAmount).abs() > 0.01) {
      return 'Resolve amount must exactly match the expense amount.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Borrowed'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              final selectedAmount = _selectedAmount();
              if ((selectedAmount - widget.expenseAmount).abs() > 0.01) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Resolved borrowed amount must exactly match the expense amount.',
                    ),
                  ),
                );
                return;
              }
              if (selectedAmount <= 0 ||
                  selectedAmount > widget.candidate.pendingAmount + 0.01) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Resolved borrowed amount cannot exceed the pending amount.',
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).pop(
                BorrowedResolutionDraft(
                  borrowedEntryId: widget.candidate.entry.id,
                  borrowedEntryTitle: widget.candidate.entry.title,
                  settledAmount: double.parse(
                    selectedAmount.toStringAsFixed(2),
                  ),
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.candidate.entry.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${AppConstants.shortDateFormat.format(widget.candidate.entry.date)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pending amount: ${AppConstants.currency(widget.candidate.pendingAmount)}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expense amount: ${AppConstants.currency(widget.expenseAmount)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _settledAmountController,
                inputFormatters:
                    _ExpenseSplitEditorPageState._decimalInputFormatters,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Resolve amount',
                  prefixText: 'Rs ',
                  errorText: _resolveAmountErrorText(),
                ),
                onChanged: (value) {
                  _handleSettledAmountChanged(value);
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameAmountSummary {
  const _NameAmountSummary({required this.name, required this.amount});

  final String name;
  final double amount;
}

class _NameAmountSummaryPage extends StatelessWidget {
  const _NameAmountSummaryPage({
    required this.title,
    required this.amountLabel,
    required this.emptyMessage,
    required this.summaries,
  });

  final String title;
  final String amountLabel;
  final String emptyMessage;
  final List<_NameAmountSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: summaries.isEmpty
          ? Center(child: Text(emptyMessage))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: summaries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return Card(
                  child: ListTile(
                    title: Text(summary.name),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          AppConstants.currency(summary.amount),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          amountLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
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
        text: participant.amount.toStringAsFixed(2),
      ),
      percentageController: TextEditingController(
        text: participant.percentage.toStringAsFixed(2),
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
