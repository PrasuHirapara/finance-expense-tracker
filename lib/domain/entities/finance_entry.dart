import 'package:equatable/equatable.dart';

import 'finance_category.dart';
import 'transaction_type.dart';

class FinanceEntry extends Equatable {
  const FinanceEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.paymentMode,
    required this.notes,
    this.counterparty,
  });

  final int id;
  final String title;
  final double amount;
  final TransactionType type;
  final FinanceCategory category;
  final DateTime date;
  final String paymentMode;
  final String notes;
  final String? counterparty;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    amount,
    type,
    category,
    date,
    paymentMode,
    notes,
    counterparty,
  ];
}

class FinanceEntryDraft extends Equatable {
  const FinanceEntryDraft({
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.paymentMode,
    required this.notes,
    this.counterparty,
  });

  final String title;
  final double amount;
  final TransactionType type;
  final int categoryId;
  final DateTime date;
  final String paymentMode;
  final String notes;
  final String? counterparty;

  @override
  List<Object?> get props => <Object?>[
    title,
    amount,
    type,
    categoryId,
    date,
    paymentMode,
    notes,
    counterparty,
  ];
}
