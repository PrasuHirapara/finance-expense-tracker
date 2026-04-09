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

class ExpenseSplitParticipant extends Equatable {
  const ExpenseSplitParticipant({
    this.id,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.isSelf,
    this.settledAmount = 0,
    this.sortOrder = 0,
  });

  final int? id;
  final String name;
  final double amount;
  final double percentage;
  final bool isSelf;
  final double settledAmount;
  final int sortOrder;

  double get pendingAmount => amount - settledAmount;
  bool get isSettled => pendingAmount <= 0.005;
  bool get hasSettlement => settledAmount > 0.005;

  ExpenseSplitParticipant copyWith({
    int? id,
    String? name,
    double? amount,
    double? percentage,
    bool? isSelf,
    double? settledAmount,
    int? sortOrder,
  }) {
    return ExpenseSplitParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      isSelf: isSelf ?? this.isSelf,
      settledAmount: settledAmount ?? this.settledAmount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    amount,
    percentage,
    isSelf,
    settledAmount,
    sortOrder,
  ];
}

class ExpenseSplitDraft extends Equatable {
  const ExpenseSplitDraft({
    this.recordId,
    this.expenseEntryId,
    this.lentEntryId,
    required this.totalAmount,
    required this.participants,
  });

  final int? recordId;
  final int? expenseEntryId;
  final int? lentEntryId;
  final double totalAmount;
  final List<ExpenseSplitParticipant> participants;

  double get selfAmount => participants
      .where((participant) => participant.isSelf)
      .fold<double>(0, (sum, participant) => sum + participant.amount);

  double get othersAmount => participants
      .where((participant) => !participant.isSelf)
      .fold<double>(0, (sum, participant) => sum + participant.amount);

  double get pendingLentAmount => participants
      .where((participant) => !participant.isSelf)
      .fold<double>(0, (sum, participant) => sum + participant.pendingAmount);

  bool get hasLentParticipants =>
      participants.any((participant) => !participant.isSelf);

  bool get hasSettlements => participants.any(
    (participant) => !participant.isSelf && participant.hasSettlement,
  );

  int get settledParticipantCount =>
      participants.where((participant) => participant.isSettled).length;

  ExpenseSplitDraft copyWith({
    int? recordId,
    int? expenseEntryId,
    int? lentEntryId,
    double? totalAmount,
    List<ExpenseSplitParticipant>? participants,
  }) {
    return ExpenseSplitDraft(
      recordId: recordId ?? this.recordId,
      expenseEntryId: expenseEntryId ?? this.expenseEntryId,
      lentEntryId: lentEntryId ?? this.lentEntryId,
      totalAmount: totalAmount ?? this.totalAmount,
      participants: participants ?? this.participants,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    recordId,
    expenseEntryId,
    lentEntryId,
    totalAmount,
    participants,
  ];
}

class ExpenseSplitSummary extends Equatable {
  const ExpenseSplitSummary({
    required this.recordId,
    required this.totalAmount,
    required this.selfAmount,
    required this.pendingLentAmount,
    required this.participantCount,
    required this.settledParticipantCount,
    required this.hasSettlements,
    required this.hasLentParticipants,
    this.expenseEntryId,
    this.lentEntryId,
  });

  final int recordId;
  final double totalAmount;
  final double selfAmount;
  final double pendingLentAmount;
  final int participantCount;
  final int settledParticipantCount;
  final bool hasSettlements;
  final bool hasLentParticipants;
  final int? expenseEntryId;
  final int? lentEntryId;

  int get pendingParticipantCount => participantCount - settledParticipantCount;
  bool get isFullySettled => hasLentParticipants && pendingLentAmount <= 0.005;

  @override
  List<Object?> get props => <Object?>[
    recordId,
    totalAmount,
    selfAmount,
    pendingLentAmount,
    participantCount,
    settledParticipantCount,
    hasSettlements,
    hasLentParticipants,
    expenseEntryId,
    lentEntryId,
  ];
}

class LentResolutionDraft extends Equatable {
  const LentResolutionDraft({
    required this.lentEntryId,
    required this.participants,
  });

  final int lentEntryId;
  final List<ExpenseSplitParticipant> participants;

  @override
  List<Object?> get props => <Object?>[lentEntryId, participants];
}

class BorrowedResolutionDraft extends Equatable {
  const BorrowedResolutionDraft({
    required this.borrowedEntryId,
    required this.borrowedEntryTitle,
    required this.settledAmount,
  });

  final int borrowedEntryId;
  final String borrowedEntryTitle;
  final double settledAmount;

  @override
  List<Object?> get props => <Object?>[
    borrowedEntryId,
    borrowedEntryTitle,
    settledAmount,
  ];
}

class LentResolutionCandidate extends Equatable {
  const LentResolutionCandidate({
    required this.entry,
    required this.splitDraft,
  });

  final ExpenseRecord entry;
  final ExpenseSplitDraft splitDraft;

  @override
  List<Object?> get props => <Object?>[entry, splitDraft];
}

class BorrowedResolutionCandidate extends Equatable {
  const BorrowedResolutionCandidate({
    required this.entry,
    required this.pendingAmount,
    required this.settledAmount,
  });

  final ExpenseRecord entry;
  final double pendingAmount;
  final double settledAmount;

  @override
  List<Object?> get props => <Object?>[entry, pendingAmount, settledAmount];
}

class BorrowedResolutionSummary extends Equatable {
  const BorrowedResolutionSummary({
    required this.originalAmount,
    required this.settledAmount,
    required this.pendingAmount,
    required this.resolutionCount,
  });

  final double originalAmount;
  final double settledAmount;
  final double pendingAmount;
  final int resolutionCount;

  bool get isFullySettled => pendingAmount <= 0.005;

  @override
  List<Object?> get props => <Object?>[
    originalAmount,
    settledAmount,
    pendingAmount,
    resolutionCount,
  ];
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
    this.splitSummary,
    this.borrowedSummary,
    this.isManagedLentEntry = false,
    this.isResolutionIncome = false,
    this.isBorrowedResolutionExpense = false,
    this.canEdit = true,
    this.canDelete = true,
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
  final ExpenseSplitSummary? splitSummary;
  final BorrowedResolutionSummary? borrowedSummary;
  final bool isManagedLentEntry;
  final bool isResolutionIncome;
  final bool isBorrowedResolutionExpense;
  final bool canEdit;
  final bool canDelete;

  bool get isCredit => type == 'income' || type == 'borrowed';
  bool get isDebit => !isCredit;
  bool get hasTrackedSplitLent => splitSummary?.hasLentParticipants ?? false;
  double get effectiveLentAmount {
    if (isManagedLentEntry) {
      return 0;
    }
    if (type == 'lent') {
      return amount;
    }
    return splitSummary?.pendingLentAmount ?? 0;
  }

  double get effectiveDebitAmount {
    if (isManagedLentEntry || !isDebit) {
      return 0;
    }
    return amount;
  }

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
    splitSummary,
    borrowedSummary,
    isManagedLentEntry,
    isResolutionIncome,
    isBorrowedResolutionExpense,
    canEdit,
    canDelete,
  ];
}

class ExpenseResolutionDetail extends Equatable {
  const ExpenseResolutionDetail({
    required this.incomeEntryId,
    required this.title,
    required this.amount,
    required this.date,
    required this.participants,
  });

  final int incomeEntryId;
  final String title;
  final double amount;
  final DateTime date;
  final List<ExpenseSplitParticipant> participants;

  @override
  List<Object?> get props => <Object?>[
    incomeEntryId,
    title,
    amount,
    date,
    participants,
  ];
}

class BorrowedResolutionDetail extends Equatable {
  const BorrowedResolutionDetail({
    required this.expenseEntryId,
    required this.title,
    required this.amount,
    required this.settledAmount,
    required this.date,
  });

  final int expenseEntryId;
  final String title;
  final double amount;
  final double settledAmount;
  final DateTime date;

  @override
  List<Object?> get props => <Object?>[
    expenseEntryId,
    title,
    amount,
    settledAmount,
    date,
  ];
}

class ExpenseEntryDetails extends Equatable {
  const ExpenseEntryDetails({
    required this.entry,
    this.splitDraft,
    this.sourceEntry,
    this.sourceBorrowedEntry,
    this.borrowedResolvedAmount,
    this.resolvedParticipants = const <ExpenseSplitParticipant>[],
    this.resolutionEntries = const <ExpenseResolutionDetail>[],
    this.borrowedResolutionEntries = const <BorrowedResolutionDetail>[],
  });

  final ExpenseRecord entry;
  final ExpenseSplitDraft? splitDraft;
  final ExpenseRecord? sourceEntry;
  final ExpenseRecord? sourceBorrowedEntry;
  final double? borrowedResolvedAmount;
  final List<ExpenseSplitParticipant> resolvedParticipants;
  final List<ExpenseResolutionDetail> resolutionEntries;
  final List<BorrowedResolutionDetail> borrowedResolutionEntries;

  bool get isSplitTracked => splitDraft != null;
  bool get isLentResolutionEntry =>
      resolvedParticipants.isNotEmpty || sourceEntry != null;
  bool get isBorrowedResolutionEntry => sourceBorrowedEntry != null;
  bool get isResolutionEntry =>
      isLentResolutionEntry || isBorrowedResolutionEntry;

  @override
  List<Object?> get props => <Object?>[
    entry,
    splitDraft,
    sourceEntry,
    sourceBorrowedEntry,
    borrowedResolvedAmount,
    resolvedParticipants,
    resolutionEntries,
    borrowedResolutionEntries,
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
    this.splitDraft,
    this.lentResolutionDraft,
    this.borrowedResolutionDraft,
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
  final ExpenseSplitDraft? splitDraft;
  final LentResolutionDraft? lentResolutionDraft;
  final BorrowedResolutionDraft? borrowedResolutionDraft;

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
    splitDraft,
    lentResolutionDraft,
    borrowedResolutionDraft,
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
    required this.totalCredit,
    required this.totalDebit,
    required this.totalLent,
    required this.totalBorrowed,
    required this.entries,
  });

  final double totalCredit;
  final double totalDebit;
  final double totalLent;
  final double totalBorrowed;
  final List<ExpenseRecord> entries;

  double get totalNet => totalCredit - totalDebit;

  @override
  List<Object?> get props => <Object?>[
    totalCredit,
    totalDebit,
    totalLent,
    totalBorrowed,
    entries,
  ];
}

enum ExpenseAnalyticsWindow { weekly, monthly, yearly }

extension ExpenseAnalyticsWindowX on ExpenseAnalyticsWindow {
  String get label {
    switch (this) {
      case ExpenseAnalyticsWindow.weekly:
        return 'Week';
      case ExpenseAnalyticsWindow.monthly:
        return 'Month';
      case ExpenseAnalyticsWindow.yearly:
        return 'Year';
    }
  }
}

class ExpenseAnalyticsPoint extends Equatable {
  const ExpenseAnalyticsPoint({
    required this.period,
    required this.label,
    required this.amount,
  });

  final DateTime period;
  final String label;
  final double amount;

  @override
  List<Object?> get props => <Object?>[period, label, amount];
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
