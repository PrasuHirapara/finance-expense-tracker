// ignore_for_file: file_names

import 'package:finance_analytics_app/data/database/app_database.dart';
import 'package:finance_analytics_app/features/expense/data/repositories/expense_repository.dart';
import 'package:finance_analytics_app/features/expense/domain/models/expense_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/testHelpers.dart';

void main() {
  initializeProductionTestEnvironment();

  group('Expense production scenarios', () {
    late AppDatabase database;
    late ExpenseRepository repository;

    setUp(() {
      database = createTestDatabase();
      repository = ExpenseRepository(database);
    });

    tearDown(() => database.close());

    test(
      'persists finance entries and ignores invalid category writes',
      () async {
        await repository.seedDefaults();
        final categoriesBefore = await database.getCategories();
        final category = categoriesBefore.firstWhere(
          (item) => item.name == 'Food',
        );
        final bank = (await database.getBanks()).first;
        final date = DateTime(2026, 5, 20, 16, 30);

        await repository.addExpense(
          ExpenseDraft(
            title: '  Salary  ',
            amount: 50000,
            type: 'income',
            categoryId: category.id,
            bankId: bank.id,
            date: date,
            paymentMode: 'Bank Transfer',
            notes: 'May payroll',
          ),
        );
        await repository.addExpense(
          ExpenseDraft(
            title: 'Groceries',
            amount: 1240.456,
            type: 'expense',
            categoryId: category.id,
            bankId: bank.id,
            date: date,
            paymentMode: 'UPI',
            notes: 'Weekly run',
          ),
        );

        final analytics = await repository.loadAnalytics(
          window: ExpenseAnalyticsWindow.monthly,
          anchorDate: date,
        );
        expect(analytics.totalIncome, 50000);
        expect(analytics.totalExpense, 1240.46);
        expect(analytics.netFlow, 48759.54);

        await repository.createCategory(
          name: ' food ',
          colorValue: 0xFF000000,
          iconCodePoint: 1,
        );
        await repository.createCategory(
          name: '   ',
          colorValue: 0xFF000000,
          iconCodePoint: 1,
        );

        expect(await database.countCategories(), categoriesBefore.length);
      },
    );

    test('filters entries by date, bank, category, and cash flow', () async {
      await repository.seedDefaults();
      final food = (await database.getCategories()).firstWhere(
        (item) => item.name == 'Food',
      );
      final travel = (await database.getCategories()).firstWhere(
        (item) => item.name == 'Travel',
      );
      final banks = await database.getBanks();
      final hdfc = banks.firstWhere((bank) => bank.name == 'HDFC');
      final sbi = banks.firstWhere((bank) => bank.name == 'SBI');
      final may20 = DateTime(2026, 5, 20, 10);
      final may21 = DateTime(2026, 5, 21, 10);

      await repository.addExpense(
        ExpenseDraft(
          title: 'Breakfast',
          amount: 220,
          type: 'expense',
          categoryId: food.id,
          bankId: hdfc.id,
          date: may20,
          paymentMode: 'UPI',
          notes: '',
        ),
      );
      await repository.addExpense(
        ExpenseDraft(
          title: 'Salary',
          amount: 40000,
          type: 'income',
          categoryId: food.id,
          bankId: hdfc.id,
          date: may20,
          paymentMode: 'Bank Transfer',
          notes: '',
        ),
      );
      await repository.addExpense(
        ExpenseDraft(
          title: 'Cab',
          amount: 350,
          type: 'expense',
          categoryId: travel.id,
          bankId: sbi.id,
          date: may21,
          paymentMode: 'Debit Card',
          notes: '',
        ),
      );

      expect(
        await repository.loadEntries(
          filter: ExpenseEntryFilter(fromDate: may20, toDate: may20),
        ),
        hasLength(2),
      );
      expect(
        await repository.loadEntries(
          filter: ExpenseEntryFilter(
            bankId: hdfc.id,
            categoryId: food.id,
            flow: ExpenseFlowFilter.credit,
          ),
        ),
        hasLength(1),
      );
      expect(
        (await repository.loadEntries(
          filter: const ExpenseEntryFilter(flow: ExpenseFlowFilter.debit),
        )).map((entry) => entry.title),
        containsAll(<String>['Breakfast', 'Cab']),
      );
    });

    test(
      'prevents duplicate banks and reassigns entries on category delete',
      () async {
        await repository.seedDefaults();
        final categories = await database.getCategories();
        final food = categories.firstWhere((item) => item.name == 'Food');
        final fallback = categories.firstWhere((item) => item.id != food.id);
        final initialBankCount = await database.countBanks();

        await repository.createBank('  HDFC  ');
        await repository.createBank('   ');
        expect(await database.countBanks(), initialBankCount);

        await repository.addExpense(
          ExpenseDraft(
            title: 'Snacks',
            amount: 90,
            type: 'expense',
            categoryId: food.id,
            date: DateTime(2026, 5, 22),
            paymentMode: 'Cash',
            notes: '',
          ),
        );

        await repository.deleteCategory(food.id);

        final entries = await repository.loadEntries();
        expect(entries.single.category.id, fallback.id);
        expect(
          (await database.getCategories()).map((category) => category.id),
          isNot(contains(food.id)),
        );
      },
    );

    test(
      'rejects unsupported self-transfer updates without mutating entry',
      () async {
        await repository.seedDefaults();
        final category = (await database.getCategories()).first;
        await repository.addExpense(
          ExpenseDraft(
            title: 'Original',
            amount: 100,
            type: 'expense',
            categoryId: category.id,
            date: DateTime(2026, 5, 23),
            paymentMode: 'Cash',
            notes: '',
          ),
        );
        final entry = (await repository.loadEntries()).single;

        await expectLater(
          repository.updateExpense(
            id: entry.id,
            draft: ExpenseDraft(
              title: 'Transfer',
              amount: 100,
              type: 'expense',
              categoryId: category.id,
              date: DateTime(2026, 5, 23),
              paymentMode: 'Cash',
              notes: '',
              selfTransferDraft: const SelfTransferDraft(
                sourcePaymentMode: 'Cash',
              ),
            ),
          ),
          throwsA(isA<StateError>()),
        );

        final reloaded = await repository.loadEntryById(entry.id);
        expect(reloaded?.title, 'Original');
        expect(reloaded?.amount, 100);
      },
    );
  });
}
