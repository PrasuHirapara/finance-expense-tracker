import 'package:finance_analytics_app/domain/entities/analytics_models.dart';
import 'package:finance_analytics_app/domain/entities/export_payload.dart';
import 'package:finance_analytics_app/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionType', () {
    test('maps credit and debit semantics correctly', () {
      expect(const TransactionType.expense().isDebit, isTrue);
      expect(const TransactionType.expense().isCredit, isFalse);

      expect(const TransactionType.income().isCredit, isTrue);
      expect(const TransactionType.borrowed().isCredit, isTrue);
      expect(const TransactionType.borrowed().isLiability, isTrue);

      expect(const TransactionType.lent().isDebit, isTrue);
      expect(const TransactionType.lent().isReceivable, isTrue);
    });

    test('round trips storage keys', () {
      const borrowed = TransactionType.borrowed();
      expect(TransactionType.fromStorageKey(borrowed.storageKey), borrowed);
    });
  });

  group('Analytics helpers', () {
    test('computes derived balances', () {
      final report = AnalyticsReport(
        window: AnalyticsWindow.monthly,
        rangeStart: DateTime(2026, 3, 1),
        rangeEnd: DateTime(2026, 3, 31),
        totalExpense: 5000,
        totalIncome: 12000,
        totalBorrowed: 2500,
        totalLent: 1000,
        totalCredit: 14500,
        totalDebit: 6000,
        outstandingLiability: 2500,
        outstandingReceivable: 1000,
        categoryDistribution: const <CategorySpend>[],
        trendPoints: const <TrendPoint>[],
        entries: const [],
      );

      expect(report.netCashFlow, 8500);
      expect(report.borrowedVsLentBalance, -1500);
    });

    test('supports nullable chart snapshots', () {
      const snapshots = ExportChartSnapshots();
      expect(snapshots.pieChart, isNull);
      expect(snapshots.lineChart, isNull);
      expect(snapshots.barChart, isNull);
    });
  });
}
