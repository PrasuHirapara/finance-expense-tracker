import 'package:freezed_annotation/freezed_annotation.dart';

import 'finance_entry.dart';

part 'analytics_models.freezed.dart';

enum AnalyticsWindow { weekly, monthly, yearly }

extension AnalyticsWindowX on AnalyticsWindow {
  String get label {
    switch (this) {
      case AnalyticsWindow.weekly:
        return 'Weekly';
      case AnalyticsWindow.monthly:
        return 'Monthly';
      case AnalyticsWindow.yearly:
        return 'Yearly';
    }
  }
}

@freezed
abstract class CategorySpend with _$CategorySpend {
  const factory CategorySpend({
    required String categoryName,
    required double amount,
    required int colorValue,
  }) = _CategorySpend;
}

@freezed
abstract class TrendPoint with _$TrendPoint {
  const factory TrendPoint({
    required DateTime period,
    required double amount,
    required String label,
  }) = _TrendPoint;
}

@freezed
abstract class AnalyticsReport with _$AnalyticsReport {
  const AnalyticsReport._();

  const factory AnalyticsReport({
    required AnalyticsWindow window,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required double totalExpense,
    required double totalIncome,
    required double totalBorrowed,
    required double totalLent,
    required double totalCredit,
    required double totalDebit,
    required double outstandingLiability,
    required double outstandingReceivable,
    required List<CategorySpend> categoryDistribution,
    required List<TrendPoint> trendPoints,
    required List<FinanceEntry> entries,
  }) = _AnalyticsReport;

  double get netCashFlow => totalCredit - totalDebit;
  double get borrowedVsLentBalance =>
      outstandingReceivable - outstandingLiability;
}
