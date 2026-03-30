import 'package:equatable/equatable.dart';

import 'finance_entry.dart';

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

class CategorySpend extends Equatable {
  const CategorySpend({
    required this.categoryName,
    required this.amount,
    required this.colorValue,
  });

  final String categoryName;
  final double amount;
  final int colorValue;

  @override
  List<Object?> get props => <Object?>[categoryName, amount, colorValue];
}

class TrendPoint extends Equatable {
  const TrendPoint({
    required this.period,
    required this.amount,
    required this.label,
  });

  final DateTime period;
  final double amount;
  final String label;

  @override
  List<Object?> get props => <Object?>[period, amount, label];
}

class AnalyticsReport extends Equatable {
  const AnalyticsReport({
    required this.window,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalExpense,
    required this.totalIncome,
    required this.totalBorrowed,
    required this.totalLent,
    required this.totalCredit,
    required this.totalDebit,
    required this.outstandingLiability,
    required this.outstandingReceivable,
    required this.categoryDistribution,
    required this.trendPoints,
    required this.entries,
  });

  final AnalyticsWindow window;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalExpense;
  final double totalIncome;
  final double totalBorrowed;
  final double totalLent;
  final double totalCredit;
  final double totalDebit;
  final double outstandingLiability;
  final double outstandingReceivable;
  final List<CategorySpend> categoryDistribution;
  final List<TrendPoint> trendPoints;
  final List<FinanceEntry> entries;

  double get netCashFlow => totalCredit - totalDebit;
  double get borrowedVsLentBalance =>
      outstandingReceivable - outstandingLiability;

  @override
  List<Object?> get props => <Object?>[
    window,
    rangeStart,
    rangeEnd,
    totalExpense,
    totalIncome,
    totalBorrowed,
    totalLent,
    totalCredit,
    totalDebit,
    outstandingLiability,
    outstandingReceivable,
    categoryDistribution,
    trendPoints,
    entries,
  ];
}
