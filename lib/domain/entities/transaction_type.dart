import 'package:equatable/equatable.dart';

sealed class TransactionType extends Equatable {
  const TransactionType();

  const factory TransactionType.expense() = ExpenseTransactionType;
  const factory TransactionType.income() = IncomeTransactionType;
  const factory TransactionType.borrowed() = BorrowedTransactionType;
  const factory TransactionType.lent() = LentTransactionType;

  String get storageKey;
  String get label;
  bool get isCredit;

  bool get isDebit => !isCredit;
  bool get isLiability => false;
  bool get isReceivable => false;

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

  @override
  List<Object?> get props => <Object?>[storageKey];
}

final class ExpenseTransactionType extends TransactionType {
  const ExpenseTransactionType();

  @override
  String get storageKey => 'expense';

  @override
  String get label => 'Expense';

  @override
  bool get isCredit => false;
}

final class IncomeTransactionType extends TransactionType {
  const IncomeTransactionType();

  @override
  String get storageKey => 'income';

  @override
  String get label => 'Income';

  @override
  bool get isCredit => true;
}

final class BorrowedTransactionType extends TransactionType {
  const BorrowedTransactionType();

  @override
  String get storageKey => 'borrowed';

  @override
  String get label => 'Borrowed';

  @override
  bool get isCredit => true;

  @override
  bool get isLiability => true;
}

final class LentTransactionType extends TransactionType {
  const LentTransactionType();

  @override
  String get storageKey => 'lent';

  @override
  String get label => 'Lent';

  @override
  bool get isCredit => false;

  @override
  bool get isReceivable => true;
}
