import 'package:freezed_annotation/freezed_annotation.dart';

import 'finance_entry.dart';

part 'dashboard_snapshot.freezed.dart';

@freezed
abstract class DashboardSnapshot with _$DashboardSnapshot {
  const DashboardSnapshot._();

  const factory DashboardSnapshot({
    required double todaysExpense,
    required double weeklyExpense,
    required double weeklyCredit,
    required double weeklyDebit,
    required double weeklyBorrowed,
    required double weeklyLent,
    required int categoryCount,
    required List<FinanceEntry> recentEntries,
  }) = _DashboardSnapshot;

  double get weeklyNet => weeklyCredit - weeklyDebit;
}
