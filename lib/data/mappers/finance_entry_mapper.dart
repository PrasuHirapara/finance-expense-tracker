import '../../domain/entities/finance_category.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/transaction_type.dart';
import '../models/finance_entry_model.dart';

extension FinanceEntryModelX on FinanceEntryModel {
  FinanceEntry toDomain() {
    return FinanceEntry(
      id: id,
      title: title,
      amount: amount,
      type: TransactionType.fromStorageKey(typeKey),
      category: FinanceCategory(
        id: categoryId,
        name: categoryName,
        iconCodePoint: categoryIconCodePoint,
        colorValue: categoryColorValue,
      ),
      date: entryDate,
      paymentMode: paymentMode,
      notes: notes,
      counterparty: counterparty,
    );
  }
}
