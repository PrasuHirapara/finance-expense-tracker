class FinanceEntryModel {
  const FinanceEntryModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.typeKey,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconCodePoint,
    required this.categoryColorValue,
    required this.entryDate,
    required this.paymentMode,
    required this.notes,
    this.counterparty,
  });

  final int id;
  final String title;
  final double amount;
  final String typeKey;
  final int categoryId;
  final String categoryName;
  final int categoryIconCodePoint;
  final int categoryColorValue;
  final DateTime entryDate;
  final String paymentMode;
  final String notes;
  final String? counterparty;
}
