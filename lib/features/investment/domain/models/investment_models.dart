import 'package:equatable/equatable.dart';

double _roundInvestmentValue(double value) =>
    double.parse(value.toStringAsFixed(2));

extension RoundedDoubleValue on double {
  double letRound() => _roundInvestmentValue(this);
}

class InvestmentCategory extends Equatable {
  const InvestmentCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
  });

  final int id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, iconCodePoint, colorValue, createdAt];
}

class TaxProfile extends Equatable {
  const TaxProfile({
    required this.id,
    required this.brokerName,
    required this.sttBuyPct,
    required this.sttSellPct,
    required this.exchangeChargePct,
    required this.sebiChargePct,
    required this.stampDutyPct,
    required this.gstPct,
    required this.brokeragePct,
    required this.brokerageFlat,
    required this.brokerageMinOfBoth,
    required this.dpChargePerScrip,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String brokerName;
  final double sttBuyPct;
  final double sttSellPct;
  final double exchangeChargePct;
  final double sebiChargePct;
  final double stampDutyPct;
  final double gstPct;
  final double brokeragePct;
  final double brokerageFlat;
  final bool brokerageMinOfBoth;
  final double dpChargePerScrip;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    brokerName,
    sttBuyPct,
    sttSellPct,
    exchangeChargePct,
    sebiChargePct,
    stampDutyPct,
    gstPct,
    brokeragePct,
    brokerageFlat,
    brokerageMinOfBoth,
    dpChargePerScrip,
    createdAt,
    updatedAt,
  ];

  TaxProfile copyWith({
    int? id,
    String? brokerName,
    double? sttBuyPct,
    double? sttSellPct,
    double? exchangeChargePct,
    double? sebiChargePct,
    double? stampDutyPct,
    double? gstPct,
    double? brokeragePct,
    double? brokerageFlat,
    bool? brokerageMinOfBoth,
    double? dpChargePerScrip,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaxProfile(
      id: id ?? this.id,
      brokerName: brokerName ?? this.brokerName,
      sttBuyPct: sttBuyPct ?? this.sttBuyPct,
      sttSellPct: sttSellPct ?? this.sttSellPct,
      exchangeChargePct: exchangeChargePct ?? this.exchangeChargePct,
      sebiChargePct: sebiChargePct ?? this.sebiChargePct,
      stampDutyPct: stampDutyPct ?? this.stampDutyPct,
      gstPct: gstPct ?? this.gstPct,
      brokeragePct: brokeragePct ?? this.brokeragePct,
      brokerageFlat: brokerageFlat ?? this.brokerageFlat,
      brokerageMinOfBoth: brokerageMinOfBoth ?? this.brokerageMinOfBoth,
      dpChargePerScrip: dpChargePerScrip ?? this.dpChargePerScrip,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InvestmentEntry extends Equatable {
  const InvestmentEntry({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconCodePoint,
    required this.categoryColorValue,
    required this.symbol,
    required this.qty,
    required this.buyDate,
    required this.buyRate,
    required this.buyAmt,
    this.taxProfileId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.taxProfile,
  });

  final int id;
  final int categoryId;
  final String categoryName;
  final int categoryIconCodePoint;
  final int categoryColorValue;
  final String symbol;
  final double qty;
  final DateTime buyDate;
  final double buyRate;
  final double buyAmt;
  final int? taxProfileId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TaxProfile? taxProfile;

  @override
  List<Object?> get props => [
    id,
    categoryId,
    categoryName,
    categoryIconCodePoint,
    categoryColorValue,
    symbol,
    qty,
    buyDate,
    buyRate,
    buyAmt,
    taxProfileId,
    notes,
    createdAt,
    updatedAt,
    taxProfile,
  ];

  InvestmentEntry copyWith({
    int? id,
    int? categoryId,
    String? categoryName,
    int? categoryIconCodePoint,
    int? categoryColorValue,
    String? symbol,
    double? qty,
    DateTime? buyDate,
    double? buyRate,
    double? buyAmt,
    int? taxProfileId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaxProfile? taxProfile,
  }) {
    return InvestmentEntry(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIconCodePoint:
          categoryIconCodePoint ?? this.categoryIconCodePoint,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
      symbol: symbol ?? this.symbol,
      qty: qty ?? this.qty,
      buyDate: buyDate ?? this.buyDate,
      buyRate: buyRate ?? this.buyRate,
      buyAmt: buyAmt ?? this.buyAmt,
      taxProfileId: taxProfileId ?? this.taxProfileId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      taxProfile: taxProfile ?? this.taxProfile,
    );
  }
}

class SellEntry extends Equatable {
  const SellEntry({
    required this.id,
    required this.buyEntryId,
    required this.symbol,
    required this.sellQty,
    required this.sellDate,
    required this.sellRate,
    required this.sellAmt,
    required this.createdAt,
  });

  final int id;
  final int buyEntryId;
  final String symbol;
  final double sellQty;
  final DateTime sellDate;
  final double sellRate;
  final double sellAmt;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    buyEntryId,
    symbol,
    sellQty,
    sellDate,
    sellRate,
    sellAmt,
    createdAt,
  ];
}

enum InvestmentStatusBadge { open, partial, sold }

class SymbolGroup extends Equatable {
  const SymbolGroup({
    required this.symbol,
    required this.buyEntries,
    required this.sellEntries,
  });

  final String symbol;
  final List<InvestmentEntry> buyEntries;
  final List<SellEntry> sellEntries;

  double get totalBoughtQty =>
      buyEntries.fold<double>(0, (sum, entry) => sum + entry.qty);

  double get totalSoldQty =>
      sellEntries.fold<double>(0, (sum, entry) => sum + entry.sellQty);

  double get totalInvested =>
      buyEntries.fold<double>(0, (sum, entry) => sum + entry.buyAmt);

  double get totalSellValue =>
      sellEntries.fold<double>(0, (sum, entry) => sum + entry.sellAmt);

  double get averageBuyRate {
    final qty = totalBoughtQty;
    if (qty == 0) return 0;
    return totalInvested / qty;
  }

  double get remainingInvested {
    double sum = 0.0;
    for (final buy in buyEntries) {
      final soldForThisBuy = sellEntries
          .where((s) => s.buyEntryId == buy.id)
          .fold<double>(0, (sum, sell) => sum + sell.sellQty);
      final remainingQty = buy.qty - soldForThisBuy;
      if (remainingQty > 0) {
        sum += remainingQty * buy.buyRate;
      }
    }
    return sum.letRound();
  }

  InvestmentStatusBadge get statusBadge {
    final bought = totalBoughtQty;
    final sold = totalSoldQty;
    if (sold == 0) return InvestmentStatusBadge.open;
    if (sold < bought) return InvestmentStatusBadge.partial;
    return InvestmentStatusBadge.sold;
  }

  @override
  List<Object?> get props => [symbol, buyEntries, sellEntries];
}

class InvestmentDashboardData extends Equatable {
  const InvestmentDashboardData({
    required this.totalInvested,
    required this.totalSellValue,
    required this.totalPL,
    required this.totalPLPct,
    required this.openPositionsCount,
    required this.totalActiveInvested,
    required this.symbolGroups,
  });

  final double totalInvested;
  final double totalSellValue;
  final double totalPL;
  final double totalPLPct;
  final int openPositionsCount;
  final double totalActiveInvested;
  final List<SymbolGroup> symbolGroups;

  @override
  List<Object?> get props => [
    totalInvested,
    totalSellValue,
    totalPL,
    totalPLPct,
    openPositionsCount,
    totalActiveInvested,
    symbolGroups,
  ];
}

enum InvestmentAnalyticsWindow { all, month, year, threeYears, custom }

class InvestmentCategoryAnalysis extends Equatable {
  const InvestmentCategoryAnalysis({
    required this.name,
    required this.amount,
    required this.colorValue,
  });

  final String name;
  final double amount;
  final int colorValue;

  @override
  List<Object?> get props => [name, amount, colorValue];
}

class InvestmentAnalyticsPoint extends Equatable {
  const InvestmentAnalyticsPoint({
    required this.period,
    required this.label,
    required this.amount,
  });

  final DateTime period;
  final String label;
  final double amount;

  @override
  List<Object?> get props => [period, label, amount];
}

class InvestmentSymbolPLAnalysis extends Equatable {
  const InvestmentSymbolPLAnalysis({
    required this.symbol,
    required this.plPct,
    required this.pl,
  });

  final String symbol;
  final double plPct;
  final double pl;

  @override
  List<Object?> get props => [symbol, plPct, pl];
}

class InvestmentCategoryPLSummary extends Equatable {
  const InvestmentCategoryPLSummary({
    required this.categoryName,
    required this.totalInvested,
    required this.totalSellValue,
    required this.pl,
    required this.plPct,
  });

  final String categoryName;
  final double totalInvested;
  final double totalSellValue;
  final double pl;
  final double plPct;

  @override
  List<Object?> get props => [
    categoryName,
    totalInvested,
    totalSellValue,
    pl,
    plPct,
  ];
}

class InvestmentAnalyticsData extends Equatable {
  const InvestmentAnalyticsData({
    required this.window,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalInvested,
    required this.totalSellValue,
    required this.totalPL,
    required this.totalPLPct,
    required this.categoryBreakdown,
    required this.trend,
    required this.symbolPLBreakdown,
    required this.categoryPLSummary,
  });

  final InvestmentAnalyticsWindow window;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalInvested;
  final double totalSellValue;
  final double totalPL;
  final double totalPLPct;
  final List<InvestmentCategoryAnalysis> categoryBreakdown;
  final List<InvestmentAnalyticsPoint> trend;
  final List<InvestmentSymbolPLAnalysis> symbolPLBreakdown;
  final List<InvestmentCategoryPLSummary> categoryPLSummary;

  @override
  List<Object?> get props => [
    window,
    rangeStart,
    rangeEnd,
    totalInvested,
    totalSellValue,
    totalPL,
    totalPLPct,
    categoryBreakdown,
    trend,
    symbolPLBreakdown,
    categoryPLSummary,
  ];
}
