import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/formatters/indian_number_formatter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_models.dart';

class ExpenseEntryDetailPage extends StatelessWidget {
  const ExpenseEntryDetailPage({required this.args, super.key});

  final ExpenseDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ExpenseRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('View Entry')),
      body: FutureBuilder<ExpenseEntryDetails?>(
        future: repository.loadEntryDetails(args.entryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final details = snapshot.data;
          if (details == null) {
            return const Center(child: Text('Entry not found.'));
          }

          final entry = details.entry;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: <Widget>[
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${entry.isCredit ? '+' : '-'}${IndianNumberFormatter.formatCompactCurrency(entry.amount)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: entry.isCredit
                            ? const Color(0xFF1F8B4C)
                            : const Color(0xFFC0392B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailLine(label: 'Type', value: _typeLabel(entry)),
                    _DetailLine(label: 'Category', value: entry.category.name),
                    _DetailLine(
                      label: 'Date',
                      value: AppConstants.shortDateFormat.format(entry.date),
                    ),
                    _DetailLine(label: 'Payment', value: entry.paymentMode),
                    if (entry.bank != null)
                      _DetailLine(label: 'Bank', value: entry.bank!.name),
                    if (entry.counterparty?.trim().isNotEmpty == true)
                      _DetailLine(
                        label: 'Counterparty',
                        value: entry.counterparty!.trim(),
                      ),
                    if (entry.notes.trim().isNotEmpty)
                      _DetailLine(label: 'Notes', value: entry.notes.trim()),
                  ],
                ),
              ),
              if (entry.borrowedSummary != null) ...<Widget>[
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Borrowed Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _DetailLine(
                        label: 'Original',
                        value: AppConstants.currency(
                          entry.borrowedSummary!.originalAmount,
                        ),
                      ),
                      _DetailLine(
                        label: 'Resolved',
                        value: AppConstants.currency(
                          entry.borrowedSummary!.settledAmount,
                        ),
                      ),
                      _DetailLine(
                        label: 'Pending',
                        value: AppConstants.currency(
                          entry.borrowedSummary!.pendingAmount,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (details.splitDraft != null) ...<Widget>[
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Split Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _DetailLine(
                        label: 'Total spent',
                        value: AppConstants.currency(
                          details.splitDraft!.totalAmount,
                        ),
                      ),
                      _DetailLine(
                        label: 'My share',
                        value: AppConstants.currency(
                          details.splitDraft!.selfAmount,
                        ),
                      ),
                      _DetailLine(
                        label: 'Pending lent',
                        value: AppConstants.currency(
                          details.splitDraft!.pendingLentAmount,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Participants',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...details.splitDraft!.participants.map(
                        (participant) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ParticipantCard(
                            participant: participant,
                            showSettledBreakdown: !participant.isSelf,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Resolution History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (details.resolutionEntries.isEmpty)
                        const Text('No lent resolutions recorded yet.')
                      else
                        ...details.resolutionEntries.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ResolutionCard(item: item),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (details.borrowedResolutionEntries.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Borrowed Resolution History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...details.borrowedResolutionEntries.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BorrowedResolutionCard(item: item),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (details.isLentResolutionEntry) ...<Widget>[
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Resolved Against',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (details.sourceEntry == null)
                        const Text('Original split entry was not found.')
                      else ...<Widget>[
                        _DetailLine(
                          label: 'Entry',
                          value: details.sourceEntry!.title,
                        ),
                        _DetailLine(
                          label: 'Current lent',
                          value: AppConstants.currency(
                            details.sourceEntry!.effectiveLentAmount,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Settled Participants',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...details.resolvedParticipants.map(
                        (participant) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ParticipantCard(
                            participant: participant,
                            showSettledBreakdown: false,
                            forcedStatusLabel: 'Settled',
                            amountLabel: 'Settled amount',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (details.isBorrowedResolutionEntry) ...<Widget>[
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Resolved Against',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (details.sourceBorrowedEntry == null)
                        const Text('Original borrowed entry was not found.')
                      else ...<Widget>[
                        _DetailLine(
                          label: 'Entry',
                          value: details.sourceBorrowedEntry!.title,
                        ),
                        _DetailLine(
                          label: 'Resolved',
                          value: AppConstants.currency(
                            details.borrowedResolvedAmount ?? entry.amount,
                          ),
                        ),
                        _DetailLine(
                          label: 'Current pending',
                          value: AppConstants.currency(
                            details
                                    .sourceBorrowedEntry!
                                    .borrowedSummary
                                    ?.pendingAmount ??
                                details.sourceBorrowedEntry!.amount,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _typeLabel(ExpenseRecord entry) {
    if (entry.isResolutionIncome) {
      return 'Lent Resolution Income';
    }
    if (entry.isBorrowedResolutionExpense) {
      return 'Borrowed Resolution Expense';
    }
    switch (entry.type) {
      case 'income':
        return 'Income';
      case 'lent':
        return 'Lent';
      case 'borrowed':
        return 'Borrowed';
      default:
        return 'Expense';
    }
  }
}

class _BorrowedResolutionCard extends StatelessWidget {
  const _BorrowedResolutionCard({required this.item});

  final BorrowedResolutionDetail item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _DetailLine(
            label: 'Expense',
            value: AppConstants.currency(item.amount),
          ),
          _DetailLine(
            label: 'Resolved',
            value: AppConstants.currency(item.settledAmount),
          ),
          _DetailLine(
            label: 'Date',
            value: AppConstants.shortDateFormat.format(item.date),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.participant,
    required this.showSettledBreakdown,
    this.forcedStatusLabel,
    this.amountLabel = 'Share',
  });

  final ExpenseSplitParticipant participant;
  final bool showSettledBreakdown;
  final String? forcedStatusLabel;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        forcedStatusLabel ??
        (participant.isSelf || participant.isSettled ? 'Settled' : 'Pending');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            participant.isSelf ? '${participant.name} (Me)' : participant.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _DetailLine(
            label: amountLabel,
            value: AppConstants.currency(participant.amount),
          ),
          _DetailLine(label: 'Status', value: statusLabel),
          if (showSettledBreakdown) ...<Widget>[
            _DetailLine(
              label: 'Settled',
              value: AppConstants.currency(participant.settledAmount),
            ),
            _DetailLine(
              label: 'Pending',
              value: AppConstants.currency(participant.pendingAmount),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({required this.item});

  final ExpenseResolutionDetail item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _DetailLine(
            label: 'Amount',
            value: AppConstants.currency(item.amount),
          ),
          _DetailLine(
            label: 'Date',
            value: AppConstants.shortDateFormat.format(item.date),
          ),
          const SizedBox(height: 4),
          ...item.participants.map(
            (participant) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ParticipantCard(
                participant: participant,
                showSettledBreakdown: false,
                forcedStatusLabel: 'Settled',
                amountLabel: 'Settled amount',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
