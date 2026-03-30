import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_type.freezed.dart';

@freezed
sealed class TransactionType with _$TransactionType {
  const TransactionType._();

  const factory TransactionType.expense() = ExpenseTransactionType;
  const factory TransactionType.income() = IncomeTransactionType;
  const factory TransactionType.borrowed() = BorrowedTransactionType;
  const factory TransactionType.lent() = LentTransactionType;

  String get storageKey => when(
    expense: () => 'expense',
    income: () => 'income',
    borrowed: () => 'borrowed',
    lent: () => 'lent',
  );

  String get label => when(
    expense: () => 'Expense',
    income: () => 'Income',
    borrowed: () => 'Borrowed',
    lent: () => 'Lent',
  );

  bool get isCredit => when(
    expense: () => false,
    income: () => true,
    borrowed: () => true,
    lent: () => false,
  );

  bool get isDebit => !isCredit;

  bool get isLiability => maybeWhen(borrowed: () => true, orElse: () => false);

  bool get isReceivable => maybeWhen(lent: () => true, orElse: () => false);

  static TransactionType fromStorageKey(String raw) {
    switch (raw) {
      case 'expense':
        return const TransactionType.expense();
      case 'income':
        return const TransactionType.income();
      case 'borrowed':
        return const TransactionType.borrowed();
      case 'lent':
        return const TransactionType.lent();
      default:
        return const TransactionType.expense();
    }
  }
}
