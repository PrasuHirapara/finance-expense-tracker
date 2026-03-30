import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/transaction_type.dart';
import '../database/app_database.dart';

class SeedService {
  SeedService(this._database);

  final AppDatabase _database;

  Future<void> seedIfNeeded() async {
    final categoryCompanions = AppConstants.defaultCategories
        .map(
          (category) => DbCategoriesCompanion.insert(
            name: category.name,
            iconCodePoint: category.iconCodePoint,
            colorValue: category.colorValue,
          ),
        )
        .toList(growable: false);

    await _database.insertCategories(categoryCompanions);

    if (await _database.countEntries() > 0) {
      return;
    }

    final categories = await _database.getCategories();
    final idsByName = <String, int>{
      for (final category in categories) category.name: category.id,
    };
    final now = DateTime.now();

    DbFinanceEntriesCompanion entry({
      required String title,
      required double amount,
      required String type,
      required String categoryName,
      required int daysAgo,
      required String paymentMode,
      required String notes,
      String? counterparty,
    }) {
      return DbFinanceEntriesCompanion.insert(
        title: title,
        amount: amount,
        type: type,
        categoryId: idsByName[categoryName]!,
        entryDate: now.subtract(Duration(days: daysAgo)),
        paymentMode: paymentMode,
        notes: Value(notes),
        counterparty: Value(counterparty),
      );
    }

    await _database.insertEntries(<DbFinanceEntriesCompanion>[
      entry(
        title: 'Monthly Salary',
        amount: 42000,
        type: const TransactionType.income().storageKey,
        categoryName: 'Miscellaneous',
        daysAgo: 24,
        paymentMode: 'Bank Transfer',
        notes: 'Primary salary credit',
      ),
      entry(
        title: 'Apartment Rent',
        amount: 12000,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Rent',
        daysAgo: 3,
        paymentMode: 'Bank Transfer',
        notes: 'April rent payment',
      ),
      entry(
        title: 'Lunch with classmates',
        amount: 240,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Food',
        daysAgo: 0,
        paymentMode: 'UPI',
        notes: 'Cafeteria spend',
      ),
      entry(
        title: 'Groceries',
        amount: 1350,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Food',
        daysAgo: 1,
        paymentMode: 'Debit Card',
        notes: 'Weekly supplies',
      ),
      entry(
        title: 'Cab to campus',
        amount: 560,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Travel',
        daysAgo: 2,
        paymentMode: 'UPI',
        notes: 'Morning ride',
      ),
      entry(
        title: 'Electricity Bill',
        amount: 1800,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Bills',
        daysAgo: 12,
        paymentMode: 'UPI',
        notes: 'Monthly utility',
      ),
      entry(
        title: 'Pharmacy',
        amount: 650,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Health',
        daysAgo: 6,
        paymentMode: 'Cash',
        notes: 'Medicines and supplements',
      ),
      entry(
        title: 'SIP Investment',
        amount: 5000,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Investment',
        daysAgo: 5,
        paymentMode: 'Bank Transfer',
        notes: 'Mutual fund contribution',
      ),
      entry(
        title: 'Freelance Design',
        amount: 3000,
        type: const TransactionType.income().storageKey,
        categoryName: 'Miscellaneous',
        daysAgo: 7,
        paymentMode: 'Bank Transfer',
        notes: 'Weekend freelance project',
      ),
      entry(
        title: 'Borrowed for laptop repair',
        amount: 4000,
        type: const TransactionType.borrowed().storageKey,
        categoryName: 'Miscellaneous',
        daysAgo: 10,
        paymentMode: 'UPI',
        notes: 'Temporary liability',
        counterparty: 'Arun',
      ),
      entry(
        title: 'Lent to cousin',
        amount: 2500,
        type: const TransactionType.lent().storageKey,
        categoryName: 'Miscellaneous',
        daysAgo: 8,
        paymentMode: 'UPI',
        notes: 'Receivable balance',
        counterparty: 'Riya',
      ),
      entry(
        title: 'Movie Night',
        amount: 900,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Entertainment',
        daysAgo: 14,
        paymentMode: 'Credit Card',
        notes: 'Friends outing',
      ),
      entry(
        title: 'Shopping haul',
        amount: 3200,
        type: const TransactionType.expense().storageKey,
        categoryName: 'Shopping',
        daysAgo: 16,
        paymentMode: 'Credit Card',
        notes: 'Clothes and accessories',
      ),
    ]);
  }
}
