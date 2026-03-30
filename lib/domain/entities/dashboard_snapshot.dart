import 'package:equatable/equatable.dart';

import 'finance_entry.dart';

class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    required this.todaysExpense,
    required this.weeklyExpense,
    required this.weeklyCredit,
    required this.weeklyDebit,
    required this.weeklyBorrowed,
    required this.weeklyLent,
    required this.categoryCount,
    required this.recentEntries,
  });

  final double todaysExpense;
  final double weeklyExpense;
  final double weeklyCredit;
  final double weeklyDebit;
  final double weeklyBorrowed;
  final double weeklyLent;
  final int categoryCount;
  final List<FinanceEntry> recentEntries;

  double get weeklyNet => weeklyCredit - weeklyDebit;

  @override
  List<Object?> get props => <Object?>[
    todaysExpense,
    weeklyExpense,
    weeklyCredit,
    weeklyDebit,
    weeklyBorrowed,
    weeklyLent,
    categoryCount,
    recentEntries,
  ];
}
