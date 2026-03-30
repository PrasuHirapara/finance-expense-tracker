import 'package:freezed_annotation/freezed_annotation.dart';

import 'finance_category.dart';
import 'transaction_type.dart';

part 'finance_entry.freezed.dart';

@freezed
abstract class FinanceEntry with _$FinanceEntry {
  const factory FinanceEntry({
    required int id,
    required String title,
    required double amount,
    required TransactionType type,
    required FinanceCategory category,
    required DateTime date,
    required String paymentMode,
    required String notes,
    String? counterparty,
  }) = _FinanceEntry;
}

@freezed
abstract class FinanceEntryDraft with _$FinanceEntryDraft {
  const factory FinanceEntryDraft({
    required String title,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required DateTime date,
    required String paymentMode,
    required String notes,
    String? counterparty,
  }) = _FinanceEntryDraft;
}
