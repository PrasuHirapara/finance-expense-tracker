import 'package:equatable/equatable.dart';

class ExpenseCategory extends Equatable {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final int id;
  final String name;
  final int iconCodePoint;
  final int colorValue;

  @override
  List<Object?> get props => <Object?>[id, name, iconCodePoint, colorValue];
}

class BankName extends Equatable {
  const BankName({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => <Object?>[id, name];
}

class ExpenseRecord extends Equatable {
  const ExpenseRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.paymentMode,
    required this.notes,
    this.counterparty,
    this.bank,
  });

  final int id;
  final String title;
  final double amount;
  final String type;
  final ExpenseCategory category;
  final DateTime date;
  final String paymentMode;
  final String notes;
  final String? counterparty;
  final BankName? bank;

  bool get isCredit => type == 'income' || type == 'borrowed';
  bool get isDebit => !isCredit;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    amount,
    type,
    category,
    date,
    paymentMode,
    notes,
    counterparty,
    bank,
  ];
}

class ExpenseDraft extends Equatable {
  const ExpenseDraft({
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.paymentMode,
    required this.notes,
    this.counterparty,
    this.bankId,
  });

  final String title;
  final double amount;
  final String type;
  final int categoryId;
  final DateTime date;
  final String paymentMode;
  final String notes;
  final String? counterparty;
  final int? bankId;

  @override
  List<Object?> get props => <Object?>[
    title,
    amount,
    type,
    categoryId,
    date,
    paymentMode,
    notes,
    counterparty,
    bankId,
  ];
}

enum ExpenseFlowFilter { all, credit, debit }

class ExpenseEntryFilter extends Equatable {
  const ExpenseEntryFilter({
    this.fromDate,
    this.toDate,
    this.bankId,
    this.categoryId,
    this.flow = ExpenseFlowFilter.all,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final int? bankId;
  final int? categoryId;
  final ExpenseFlowFilter flow;

  ExpenseEntryFilter copyWith({
    Object? fromDate = _expenseFilterUnset,
    Object? toDate = _expenseFilterUnset,
    Object? bankId = _expenseFilterUnset,
    Object? categoryId = _expenseFilterUnset,
    ExpenseFlowFilter? flow,
  }) {
    return ExpenseEntryFilter(
      fromDate: identical(fromDate, _expenseFilterUnset)
          ? this.fromDate
          : fromDate as DateTime?,
      toDate: identical(toDate, _expenseFilterUnset)
          ? this.toDate
          : toDate as DateTime?,
      bankId: identical(bankId, _expenseFilterUnset)
          ? this.bankId
          : bankId as int?,
      categoryId: identical(categoryId, _expenseFilterUnset)
          ? this.categoryId
          : categoryId as int?,
      flow: flow ?? this.flow,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    fromDate,
    toDate,
    bankId,
    categoryId,
    flow,
  ];
}

class ExpenseDashboardData extends Equatable {
  const ExpenseDashboardData({
    required this.todaysExpense,
    required this.totalExpense,
    required this.totalCredit,
    required this.totalDebit,
    required this.recentEntries,
  });

  final double todaysExpense;
  final double totalExpense;
  final double totalCredit;
  final double totalDebit;
  final List<ExpenseRecord> recentEntries;

  double get totalNet => totalCredit - totalDebit;

  @override
  List<Object?> get props => <Object?>[
    todaysExpense,
    totalExpense,
    totalCredit,
    totalDebit,
    recentEntries,
  ];
}

enum ExpenseAnalyticsWindow { weekly, monthly, yearly }

class ExpenseAnalyticsPoint extends Equatable {
  const ExpenseAnalyticsPoint({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  List<Object?> get props => <Object?>[label, amount];
}

class ExpenseCategoryAnalysis extends Equatable {
  const ExpenseCategoryAnalysis({
    required this.name,
    required this.amount,
    required this.colorValue,
  });

  final String name;
  final double amount;
  final int colorValue;

  @override
  List<Object?> get props => <Object?>[name, amount, colorValue];
}

class ExpenseAnalyticsData extends Equatable {
  const ExpenseAnalyticsData({
    required this.window,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalCredit,
    required this.totalDebit,
    required this.totalBorrowed,
    required this.totalLent,
    required this.totalExpense,
    required this.totalIncome,
    required this.categoryBreakdown,
    required this.trend,
  });

  final ExpenseAnalyticsWindow window;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalCredit;
  final double totalDebit;
  final double totalBorrowed;
  final double totalLent;
  final double totalExpense;
  final double totalIncome;
  final List<ExpenseCategoryAnalysis> categoryBreakdown;
  final List<ExpenseAnalyticsPoint> trend;

  double get netFlow => totalCredit - totalDebit;

  @override
  List<Object?> get props => <Object?>[
    window,
    rangeStart,
    rangeEnd,
    totalCredit,
    totalDebit,
    totalBorrowed,
    totalLent,
    totalExpense,
    totalIncome,
    categoryBreakdown,
    trend,
  ];
}

const Object _expenseFilterUnset = Object();
