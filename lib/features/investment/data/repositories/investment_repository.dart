import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/date_time_x.dart';
import '../../../../data/database/app_database.dart';
import '../../domain/models/investment_models.dart';

class InvestmentRepository {
  InvestmentRepository(this._database);

  final AppDatabase _database;

  static const List<Map<String, dynamic>> _defaultCategories = [
    {
      'name': 'Equity / Stocks',
      'iconCodePoint': 0xe62e, // Icons.trending_up
      'colorValue': 0xFF2196F3, // Colors.blue
    },
    {
      'name': 'IPO (Allocation)',
      'iconCodePoint': 0xe43d, // Icons.new_releases
      'colorValue': 0xFFFF9800, // Colors.orange
    },
    {
      'name': 'Mutual Fund',
      'iconCodePoint': 0xe09f, // Icons.account_balance
      'colorValue': 0xFF9C27B0, // Colors.purple
    },
    {
      'name': 'Gold',
      'iconCodePoint': 0xe5fa, // Icons.star
      'colorValue': 0xFFFFC107, // Colors.amber
    },
    {
      'name': 'Bond / Debt',
      'iconCodePoint': 0xf0140, // Icons.receipt_long
      'colorValue': 0xFF009688, // Colors.teal
    },
    {
      'name': 'Fixed Deposit',
      'iconCodePoint': 0xf016e, // Icons.savings
      'colorValue': 0xFF4CAF50, // Colors.green
    },
  ];

  static const List<Map<String, dynamic>> _defaultTaxProfiles = [
    {
      'brokerName': 'Zerodha',
      'sttBuyPct': 0.001,
      'sttSellPct': 0.001,
      'exchangeChargePct': 0.0000345,
      'sebiChargePct': 0.000001,
      'stampDutyPct': 0.00015,
      'gstPct': 0.18,
      'brokeragePct': 0.0003,
      'brokerageFlat': 20.0,
      'brokerageMinOfBoth': true,
      'dpChargePerScrip': 15.93,
    },
    {
      'brokerName': 'Angel One',
      'sttBuyPct': 0.001,
      'sttSellPct': 0.001,
      'exchangeChargePct': 0.0000345,
      'sebiChargePct': 0.000001,
      'stampDutyPct': 0.00015,
      'gstPct': 0.18,
      'brokeragePct': 0.0,
      'brokerageFlat': 0.0,
      'brokerageMinOfBoth': false,
      'dpChargePerScrip': 20.0,
    },
    {
      'brokerName': 'Motilal Oswal',
      'sttBuyPct': 0.001,
      'sttSellPct': 0.001,
      'exchangeChargePct': 0.0000345,
      'sebiChargePct': 0.000001,
      'stampDutyPct': 0.00015,
      'gstPct': 0.18,
      'brokeragePct': 0.005,
      'brokerageFlat': 20.0,
      'brokerageMinOfBoth': true,
      'dpChargePerScrip': 13.5,
    },
    {
      'brokerName': 'Groww',
      'sttBuyPct': 0.001,
      'sttSellPct': 0.001,
      'exchangeChargePct': 0.0000345,
      'sebiChargePct': 0.000001,
      'stampDutyPct': 0.00015,
      'gstPct': 0.18,
      'brokeragePct': 0.0,
      'brokerageFlat': 20.0,
      'brokerageMinOfBoth': false,
      'dpChargePerScrip': 19.0,
    },
    {
      'brokerName': 'Upstox',
      'sttBuyPct': 0.001,
      'sttSellPct': 0.001,
      'exchangeChargePct': 0.0000345,
      'sebiChargePct': 0.000001,
      'stampDutyPct': 0.00015,
      'gstPct': 0.18,
      'brokeragePct': 0.025,
      'brokerageFlat': 20.0,
      'brokerageMinOfBoth': true,
      'dpChargePerScrip': 18.5,
    },
  ];

  Future<void> seedDefaults() async {
    final categoryCount = await (selectInvestmentCategories().get());
    if (categoryCount.isEmpty) {
      final companions = _defaultCategories.map((c) {
        return DbInvestmentCategoriesCompanion.insert(
          name: c['name'] as String,
          iconCodePoint: c['iconCodePoint'] as int,
          colorValue: c['colorValue'] as int,
        );
      }).toList();
      await _database.batch((batch) {
        batch.insertAll(_database.dbInvestmentCategories, companions,
            mode: InsertMode.insertOrIgnore);
      });
    }

    final taxProfiles = await (selectTaxProfiles().get());
    if (taxProfiles.isEmpty) {
      final companions = _defaultTaxProfiles.map((p) {
        return DbInvestmentTaxProfilesCompanion.insert(
          brokerName: p['brokerName'] as String,
          sttBuyPct: p['sttBuyPct'] as double,
          sttSellPct: p['sttSellPct'] as double,
          exchangeChargePct: p['exchangeChargePct'] as double,
          sebiChargePct: p['sebiChargePct'] as double,
          stampDutyPct: p['stampDutyPct'] as double,
          gstPct: p['gstPct'] as double,
          brokeragePct: p['brokeragePct'] as double,
          brokerageFlat: p['brokerageFlat'] as double,
          brokerageMinOfBoth: p['brokerageMinOfBoth'] as bool,
          dpChargePerScrip: p['dpChargePerScrip'] as double,
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();
      await _database.batch((batch) {
        batch.insertAll(_database.dbInvestmentTaxProfiles, companions,
            mode: InsertMode.insertOrIgnore);
      });
    }
  }

  Future<void> clearSectionData() async {
    await (_database.delete(_database.dbSellEntries)).go();
    await (_database.delete(_database.dbInvestmentEntries)).go();
    await (_database.delete(_database.dbInvestmentTaxProfiles)).go();
    await (_database.delete(_database.dbInvestmentCategories)).go();
    await seedDefaults();
  }

  // --- Categories CRUD ---

  SimpleSelectStatement<$DbInvestmentCategoriesTable, DbInvestmentCategory>
      selectInvestmentCategories() {
    return _database.select(_database.dbInvestmentCategories)
      ..orderBy([
        (table) => OrderingTerm.asc(table.name),
      ]);
  }

  Stream<List<InvestmentCategory>> watchCategories() {
    return selectInvestmentCategories().watch().map(
          (rows) => rows
              .map(
                (row) => InvestmentCategory(
                  id: row.id,
                  name: row.name,
                  iconCodePoint: row.iconCodePoint,
                  colorValue: row.colorValue,
                  createdAt: row.createdAt,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<List<InvestmentCategory>> getCategories() async {
    final rows = await selectInvestmentCategories().get();
    return rows
        .map(
          (row) => InvestmentCategory(
            id: row.id,
            name: row.name,
            iconCodePoint: row.iconCodePoint,
            colorValue: row.colorValue,
            createdAt: row.createdAt,
          ),
        )
        .toList(growable: false);
  }

  Future<int> insertCategory(
      {required String name, required int colorValue, required int iconCodePoint}) async {
    return _database.into(_database.dbInvestmentCategories).insert(
          DbInvestmentCategoriesCompanion.insert(
            name: name,
            colorValue: colorValue,
            iconCodePoint: iconCodePoint,
          ),
        );
  }

  Future<void> updateCategory(
      {required int id,
      required String name,
      required int colorValue,
      required int iconCodePoint}) async {
    await (_database.update(_database.dbInvestmentCategories)
          ..where((t) => t.id.equals(id)))
        .write(
      DbInvestmentCategoriesCompanion(
        name: Value(name),
        colorValue: Value(colorValue),
        iconCodePoint: Value(iconCodePoint),
      ),
    );
  }

  Future<void> deleteCategory(int id, {int? reassignCategoryId}) async {
    await _database.transaction(() async {
      if (reassignCategoryId != null) {
        await (_database.update(_database.dbInvestmentEntries)
              ..where((t) => t.categoryId.equals(id)))
            .write(DbInvestmentEntriesCompanion(categoryId: Value(reassignCategoryId)));
      } else {
        // delete linked buys & sells
        final linkedBuys = await (_database.select(_database.dbInvestmentEntries)
              ..where((t) => t.categoryId.equals(id)))
            .get();
        final buyIds = linkedBuys.map((b) => b.id).toList();
        if (buyIds.isNotEmpty) {
          await (_database.delete(_database.dbSellEntries)
                ..where((t) => t.buyEntryId.isIn(buyIds)))
              .go();
          await (_database.delete(_database.dbInvestmentEntries)
                ..where((t) => t.id.isIn(buyIds)))
              .go();
        }
      }
      await (_database.delete(_database.dbInvestmentCategories)
            ..where((t) => t.id.equals(id)))
          .go();
    });
  }

  // --- Tax Profiles CRUD ---

  SimpleSelectStatement<$DbInvestmentTaxProfilesTable, DbInvestmentTaxProfile>
      selectTaxProfiles() {
    return _database.select(_database.dbInvestmentTaxProfiles)
      ..orderBy([
        (table) => OrderingTerm.asc(table.brokerName),
      ]);
  }

  Stream<List<TaxProfile>> watchTaxProfiles() {
    return selectTaxProfiles().watch().map(
          (rows) => rows
              .map((row) => _mapTaxProfile(row))
              .toList(growable: false),
        );
  }

  Future<List<TaxProfile>> getTaxProfiles() async {
    final rows = await selectTaxProfiles().get();
    return rows.map((row) => _mapTaxProfile(row)).toList(growable: false);
  }

  Future<int> insertTaxProfile(TaxProfile profile) async {
    return _database.into(_database.dbInvestmentTaxProfiles).insert(
          DbInvestmentTaxProfilesCompanion.insert(
            brokerName: profile.brokerName,
            sttBuyPct: profile.sttBuyPct,
            sttSellPct: profile.sttSellPct,
            exchangeChargePct: profile.exchangeChargePct,
            sebiChargePct: profile.sebiChargePct,
            stampDutyPct: profile.stampDutyPct,
            gstPct: profile.gstPct,
            brokeragePct: profile.brokeragePct,
            brokerageFlat: profile.brokerageFlat,
            brokerageMinOfBoth: profile.brokerageMinOfBoth,
            dpChargePerScrip: profile.dpChargePerScrip,
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updateTaxProfile(TaxProfile profile) async {
    await (_database.update(_database.dbInvestmentTaxProfiles)
          ..where((t) => t.id.equals(profile.id)))
        .write(
      DbInvestmentTaxProfilesCompanion(
        brokerName: Value(profile.brokerName),
        sttBuyPct: Value(profile.sttBuyPct),
        sttSellPct: Value(profile.sttSellPct),
        exchangeChargePct: Value(profile.exchangeChargePct),
        sebiChargePct: Value(profile.sebiChargePct),
        stampDutyPct: Value(profile.stampDutyPct),
        gstPct: Value(profile.gstPct),
        brokeragePct: Value(profile.brokeragePct),
        brokerageFlat: Value(profile.brokerageFlat),
        brokerageMinOfBoth: Value(profile.brokerageMinOfBoth),
        dpChargePerScrip: Value(profile.dpChargePerScrip),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTaxProfile(int id) async {
    await _database.transaction(() async {
      await (_database.update(_database.dbInvestmentEntries)
            ..where((t) => t.taxProfileId.equals(id)))
          .write(const DbInvestmentEntriesCompanion(taxProfileId: Value(null)));
      await (_database.delete(_database.dbInvestmentTaxProfiles)
            ..where((t) => t.id.equals(id)))
          .go();
    });
  }

  // --- Investment Entries CRUD ---

  Future<int> insertBuyEntry({
    required int categoryId,
    required String symbol,
    required double qty,
    required DateTime buyDate,
    required double buyRate,
    required double buyAmt,
    int? taxProfileId,
    String? notes,
  }) async {
    return _database.into(_database.dbInvestmentEntries).insert(
          DbInvestmentEntriesCompanion.insert(
            categoryId: categoryId,
            symbol: symbol.trim().toUpperCase(),
            qty: qty,
            buyDate: buyDate,
            buyRate: buyRate,
            buyAmt: buyAmt,
            taxProfileId: Value(taxProfileId),
            notes: Value(notes),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> updateBuyEntry({
    required int id,
    required int categoryId,
    required String symbol,
    required double qty,
    required DateTime buyDate,
    required double buyRate,
    required double buyAmt,
    int? taxProfileId,
    String? notes,
  }) async {
    await (_database.update(_database.dbInvestmentEntries)
          ..where((t) => t.id.equals(id)))
        .write(
      DbInvestmentEntriesCompanion(
        categoryId: Value(categoryId),
        symbol: Value(symbol.trim().toUpperCase()),
        qty: Value(qty),
        buyDate: Value(buyDate),
        buyRate: Value(buyRate),
        buyAmt: Value(buyAmt),
        taxProfileId: Value(taxProfileId),
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteBuyEntry(int id) async {
    await _database.transaction(() async {
      await (_database.delete(_database.dbSellEntries)
            ..where((t) => t.buyEntryId.equals(id)))
          .go();
      await (_database.delete(_database.dbInvestmentEntries)
            ..where((t) => t.id.equals(id)))
          .go();
    });
  }

  // --- Sell Entries CRUD ---

  Future<int> insertSellEntry({
    required int buyEntryId,
    required String symbol,
    required double sellQty,
    required DateTime sellDate,
    required double sellRate,
    required double sellAmt,
  }) async {
    return _database.into(_database.dbSellEntries).insert(
          DbSellEntriesCompanion.insert(
            buyEntryId: buyEntryId,
            symbol: symbol.trim().toUpperCase(),
            sellQty: sellQty,
            sellDate: sellDate,
            sellRate: sellRate,
            sellAmt: sellAmt,
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteSellEntry(int id) async {
    await (_database.delete(_database.dbSellEntries)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // --- Queries & Dashboard/Analytics ---

  Stream<List<InvestmentEntry>> watchBuyEntries() {
    final query = _database.select(_database.dbInvestmentEntries).join([
      innerJoin(
        _database.dbInvestmentCategories,
        _database.dbInvestmentCategories.id.equalsExp(_database.dbInvestmentEntries.categoryId),
      ),
      leftOuterJoin(
        _database.dbInvestmentTaxProfiles,
        _database.dbInvestmentTaxProfiles.id.equalsExp(_database.dbInvestmentEntries.taxProfileId),
      ),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final entry = row.readTable(_database.dbInvestmentEntries);
        final cat = row.readTable(_database.dbInvestmentCategories);
        final taxRow = row.readTableOrNull(_database.dbInvestmentTaxProfiles);
        return _mapInvestmentEntry(entry, cat, taxRow);
      }).toList();
    });
  }

  Future<List<InvestmentEntry>> getBuyEntries() async {
    final query = _database.select(_database.dbInvestmentEntries).join([
      innerJoin(
        _database.dbInvestmentCategories,
        _database.dbInvestmentCategories.id.equalsExp(_database.dbInvestmentEntries.categoryId),
      ),
      leftOuterJoin(
        _database.dbInvestmentTaxProfiles,
        _database.dbInvestmentTaxProfiles.id.equalsExp(_database.dbInvestmentEntries.taxProfileId),
      ),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final entry = row.readTable(_database.dbInvestmentEntries);
      final cat = row.readTable(_database.dbInvestmentCategories);
      final taxRow = row.readTableOrNull(_database.dbInvestmentTaxProfiles);
      return _mapInvestmentEntry(entry, cat, taxRow);
    }).toList();
  }

  Future<List<SellEntry>> getSellEntries() async {
    final rows = await _database.select(_database.dbSellEntries).get();
    return rows.map((row) => _mapSellEntry(row)).toList();
  }

  Stream<List<SellEntry>> watchSellEntries() {
    return _database.select(_database.dbSellEntries).watch().map((rows) {
      return rows.map((row) => _mapSellEntry(row)).toList();
    });
  }

  Stream<InvestmentDashboardData> watchDashboard({
    int? categoryId,
    DateTimeRange? dateRange,
  }) {
    return watchBuyEntries().asyncCombine(watchSellEntries(), (buys, sells) {
      return _compileDashboard(buys, sells, categoryId, dateRange);
    });
  }

  InvestmentDashboardData _compileDashboard(
    List<InvestmentEntry> buys,
    List<SellEntry> sells,
    int? categoryId,
    DateTimeRange? dateRange,
  ) {
    // 1. Filter buy entries by category and date range
    var filteredBuys = buys;
    if (categoryId != null) {
      filteredBuys = filteredBuys.where((b) => b.categoryId == categoryId).toList();
    }
    if (dateRange != null) {
      filteredBuys = filteredBuys
          .where((b) => !b.buyDate.isBefore(dateRange.start) && !b.buyDate.isAfter(dateRange.end))
          .toList();
    }

    final buyIds = filteredBuys.map((b) => b.id).toSet();
    final filteredSells = sells.where((s) => buyIds.contains(s.buyEntryId)).toList();

    // 2. Group by symbol
    final buysBySymbol = <String, List<InvestmentEntry>>{};
    for (final buy in filteredBuys) {
      buysBySymbol.putIfAbsent(buy.symbol, () => []).add(buy);
    }

    final sellsBySymbol = <String, List<SellEntry>>{};
    for (final sell in filteredSells) {
      sellsBySymbol.putIfAbsent(sell.symbol, () => []).add(sell);
    }

    final allSymbols = buysBySymbol.keys.toSet().toList()..sort();
    final groups = allSymbols.map((symbol) {
      return SymbolGroup(
        symbol: symbol,
        buyEntries: buysBySymbol[symbol] ?? [],
        sellEntries: sellsBySymbol[symbol] ?? [],
      );
    }).toList();

    // 3. Totals
    var totalInvested = 0.0;
    var totalSellValue = 0.0;
    var totalPL = 0.0;
    int openPositions = 0;

    for (final g in groups) {
      totalInvested += g.totalInvested;
      totalSellValue += g.totalSellValue;
      if (g.statusBadge == InvestmentStatusBadge.open) {
        openPositions += 1;
      }

      // Live calculation: PL = sellAmt - (buyRate * sellQty)
      // Since sell entries are linked to buyEntryId, we look up the buyRate from the buyEntry
      final buyRates = {for (final buy in g.buyEntries) buy.id: buy.buyRate};
      for (final sell in g.sellEntries) {
        final buyRate = buyRates[sell.buyEntryId] ?? 0.0;
        final pl = sell.sellAmt - (buyRate * sell.sellQty);
        totalPL += pl;
      }
    }

    final totalPLPct = totalInvested == 0 ? 0.0 : (totalPL / totalInvested) * 100;
    final totalActiveInvested = groups.fold<double>(0.0, (sum, g) => sum + g.remainingInvested);

    return InvestmentDashboardData(
      totalInvested: totalInvested.letRound(),
      totalSellValue: totalSellValue.letRound(),
      totalPL: totalPL.letRound(),
      totalPLPct: totalPLPct.letRound(),
      openPositionsCount: openPositions,
      totalActiveInvested: totalActiveInvested.letRound(),
      symbolGroups: groups,
    );
  }

  Future<InvestmentAnalyticsData> loadAnalytics({
    required InvestmentAnalyticsWindow window,
    int? categoryId,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final buys = await getBuyEntries();
    final sells = await getSellEntries();

    final now = DateTime.now();
    DateTime rangeStart;
    DateTime rangeEnd = now.endOfDay;

    switch (window) {
      case InvestmentAnalyticsWindow.month:
        rangeStart = DateTime(now.year, now.month, 1).startOfDay;
        break;
      case InvestmentAnalyticsWindow.year:
        rangeStart = DateTime(now.year, 1, 1).startOfDay;
        break;
      case InvestmentAnalyticsWindow.threeYears:
        rangeStart = DateTime(now.year - 3, now.month, now.day).startOfDay;
        break;
      case InvestmentAnalyticsWindow.custom:
        rangeStart = (customStartDate ?? now.subtract(const Duration(days: 30))).startOfDay;
        rangeEnd = (customEndDate ?? now).endOfDay;
        break;
      case InvestmentAnalyticsWindow.all:
        rangeStart = DateTime(2000, 1, 1).startOfDay;
        break;
    }

    // Filter buys
    var filteredBuys = buys;
    if (categoryId != null) {
      filteredBuys = filteredBuys.where((b) => b.categoryId == categoryId).toList();
    }
    filteredBuys = filteredBuys
        .where((b) => !b.buyDate.isBefore(rangeStart) && !b.buyDate.isAfter(rangeEnd))
        .toList();

    final buyIds = filteredBuys.map((b) => b.id).toSet();
    final filteredSells = sells.where((s) => buyIds.contains(s.buyEntryId)).toList();

    // Summary calculations
    double totalInvested = 0;
    double totalSellValue = 0;
    double totalPL = 0;

    final buyRates = {for (final buy in buys) buy.id: buy.buyRate};
    final buyCategories = {for (final buy in buys) buy.id: buy.categoryName};

    for (final buy in filteredBuys) {
      totalInvested += buy.buyAmt;
    }
    for (final sell in filteredSells) {
      totalSellValue += sell.sellAmt;
      final buyRate = buyRates[sell.buyEntryId] ?? 0.0;
      totalPL += sell.sellAmt - (buyRate * sell.sellQty);
    }

    final totalPLPct = totalInvested == 0 ? 0.0 : (totalPL / totalInvested) * 100;

    // 1. Investment by Category (total buyAmt per category)
    final categoryTotals = <String, double>{};
    final categoryColors = <String, int>{};
    for (final buy in filteredBuys) {
      categoryTotals.update(buy.categoryName, (v) => v + buy.buyAmt, ifAbsent: () => buy.buyAmt);
      categoryColors[buy.categoryName] = buy.categoryColorValue;
    }
    final categoryBreakdown = categoryTotals.entries.map((e) {
      return InvestmentCategoryAnalysis(
        name: e.key,
        amount: e.value.letRound(),
        colorValue: categoryColors[e.key] ?? 0xFFFFFFFF,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // 2. P/L Over Time (Line chart: X = sell date, Y = cumulative P/L)
    final sellsSorted = List<SellEntry>.from(filteredSells)
      ..sort((a, b) => a.sellDate.compareTo(b.sellDate));
    double cumulativePL = 0;
    final trendPoints = sellsSorted.map((sell) {
      final buyRate = buyRates[sell.buyEntryId] ?? 0.0;
      final pl = sell.sellAmt - (buyRate * sell.sellQty);
      cumulativePL += pl;
      return InvestmentAnalyticsPoint(
        period: sell.sellDate,
        label: DateFormat('dd MMM').format(sell.sellDate),
        amount: cumulativePL.letRound(),
      );
    }).toList();

    // 3. P/L % by Symbol (Top symbols by P/L%)
    final symbolPL = <String, double>{};
    final symbolInvested = <String, double>{};
    for (final sell in filteredSells) {
      final buyRate = buyRates[sell.buyEntryId] ?? 0.0;
      final pl = sell.sellAmt - (buyRate * sell.sellQty);
      symbolPL.update(sell.symbol, (v) => v + pl, ifAbsent: () => pl);
    }
    for (final buy in filteredBuys) {
      symbolInvested.update(buy.symbol, (v) => v + buy.buyAmt, ifAbsent: () => buy.buyAmt);
    }

    final symbolPLBreakdown = symbolPL.entries.map((e) {
      final symbol = e.key;
      final pl = e.value;
      final invested = symbolInvested[symbol] ?? 1.0;
      final plPct = (pl / invested) * 100;
      return InvestmentSymbolPLAnalysis(
        symbol: symbol,
        plPct: plPct.letRound(),
        pl: pl.letRound(),
      );
    }).toList()
      ..sort((a, b) => b.plPct.compareTo(a.plPct));

    // 4. Category P/L Summary (Table/Card. Per category: Total Invested, Total Sell, P/L, P/L%)
    final catInvested = <String, double>{};
    final catSellValue = <String, double>{};
    final catPL = <String, double>{};

    for (final buy in filteredBuys) {
      catInvested.update(buy.categoryName, (v) => v + buy.buyAmt, ifAbsent: () => buy.buyAmt);
    }
    for (final sell in filteredSells) {
      final catName = buyCategories[sell.buyEntryId] ?? 'Equity / Stocks';
      catSellValue.update(catName, (v) => v + sell.sellAmt, ifAbsent: () => sell.sellAmt);
      final buyRate = buyRates[sell.buyEntryId] ?? 0.0;
      final pl = sell.sellAmt - (buyRate * sell.sellQty);
      catPL.update(catName, (v) => v + pl, ifAbsent: () => pl);
    }

    final categoryPLSummary = catInvested.entries.map((e) {
      final catName = e.key;
      final invested = e.value;
      final sellVal = catSellValue[catName] ?? 0.0;
      final pl = catPL[catName] ?? 0.0;
      final plPct = invested == 0 ? 0.0 : (pl / invested) * 100;
      return InvestmentCategoryPLSummary(
        categoryName: catName,
        totalInvested: invested.letRound(),
        totalSellValue: sellVal.letRound(),
        pl: pl.letRound(),
        plPct: plPct.letRound(),
      );
    }).toList();

    return InvestmentAnalyticsData(
      window: window,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      totalInvested: totalInvested.letRound(),
      totalSellValue: totalSellValue.letRound(),
      totalPL: totalPL.letRound(),
      totalPLPct: totalPLPct.letRound(),
      categoryBreakdown: categoryBreakdown,
      trend: trendPoints,
      symbolPLBreakdown: symbolPLBreakdown,
      categoryPLSummary: categoryPLSummary,
    );
  }

  // --- Calculations ---

  double computeLiveTax(TaxProfile profile, double buyAmt, double sellAmt) {
    return calculateLiveTax(
      sttBuyPct: profile.sttBuyPct,
      sttSellPct: profile.sttSellPct,
      exchangeChargePct: profile.exchangeChargePct,
      sebiChargePct: profile.sebiChargePct,
      stampDutyPct: profile.stampDutyPct,
      gstPct: profile.gstPct,
      brokeragePct: profile.brokeragePct,
      brokerageFlat: profile.brokerageFlat,
      brokerageMinOfBoth: profile.brokerageMinOfBoth,
      dpChargePerScrip: profile.dpChargePerScrip,
      buyAmt: buyAmt,
      sellAmt: sellAmt,
    );
  }

  static double calculateLiveTax({
    required double sttBuyPct,
    required double sttSellPct,
    required double exchangeChargePct,
    required double sebiChargePct,
    required double stampDutyPct,
    required double gstPct,
    required double brokeragePct,
    required double brokerageFlat,
    required bool brokerageMinOfBoth,
    required double dpChargePerScrip,
    required double buyAmt,
    required double sellAmt,
  }) {
    final turnover = buyAmt + sellAmt;
    final brokerage = brokerageMinOfBoth
        ? math.min(brokerageFlat, turnover * brokeragePct)
        : (brokeragePct > 0 ? turnover * brokeragePct : brokerageFlat);
    final exchangeCharge = turnover * exchangeChargePct;
    final sebiCharge = turnover * sebiChargePct;
    final gst = (exchangeCharge + sebiCharge + brokerage) * gstPct;
    final stt = (buyAmt * sttBuyPct) + (sellAmt * sttSellPct);
    final stampDuty = buyAmt * stampDutyPct;
    final dpCharge = dpChargePerScrip;
    return stt + exchangeCharge + sebiCharge + gst + brokerage + stampDuty + dpCharge;
  }

  // --- Mappings ---

  TaxProfile _mapTaxProfile(DbInvestmentTaxProfile row) {
    return TaxProfile(
      id: row.id,
      brokerName: row.brokerName,
      sttBuyPct: row.sttBuyPct,
      sttSellPct: row.sttSellPct,
      exchangeChargePct: row.exchangeChargePct,
      sebiChargePct: row.sebiChargePct,
      stampDutyPct: row.stampDutyPct,
      gstPct: row.gstPct,
      brokeragePct: row.brokeragePct,
      brokerageFlat: row.brokerageFlat,
      brokerageMinOfBoth: row.brokerageMinOfBoth,
      dpChargePerScrip: row.dpChargePerScrip,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  InvestmentEntry _mapInvestmentEntry(
      DbInvestmentEntry row, DbInvestmentCategory cat, DbInvestmentTaxProfile? taxRow) {
    return InvestmentEntry(
      id: row.id,
      categoryId: row.categoryId,
      categoryName: cat.name,
      categoryIconCodePoint: cat.iconCodePoint,
      categoryColorValue: cat.colorValue,
      symbol: row.symbol,
      qty: row.qty,
      buyDate: row.buyDate,
      buyRate: row.buyRate,
      buyAmt: row.buyAmt,
      taxProfileId: row.taxProfileId,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      taxProfile: taxRow != null ? _mapTaxProfile(taxRow) : null,
    );
  }

  SellEntry _mapSellEntry(DbSellEntry row) {
    return SellEntry(
      id: row.id,
      buyEntryId: row.buyEntryId,
      symbol: row.symbol,
      sellQty: row.sellQty,
      sellDate: row.sellDate,
      sellRate: row.sellRate,
      sellAmt: row.sellAmt,
      createdAt: row.createdAt,
    );
  }
}

// Extension to combine streams async
extension _AsyncStreamCombine<T> on Stream<T> {
  Stream<R> asyncCombine<S, R>(
    Stream<S> other,
    FutureOr<R> Function(T event, S otherEvent) combiner,
  ) {
    T? latestT;
    S? latestS;
    bool hasT = false;
    bool hasS = false;

    final controller = StreamController<R>.broadcast();
    StreamSubscription<T>? subT;
    StreamSubscription<S>? subS;

    void update() async {
      if (hasT && hasS) {
        try {
          final result = await combiner(latestT as T, latestS as S);
          if (!controller.isClosed) {
            controller.add(result);
          }
        } catch (e, s) {
          if (!controller.isClosed) {
            controller.addError(e, s);
          }
        }
      }
    }

    controller.onListen = () {
      subT = listen(
        (val) {
          latestT = val;
          hasT = true;
          update();
        },
        onError: controller.addError,
        onDone: () {
          if (subS == null || controller.isClosed) return;
        },
      );
      subS = other.listen(
        (val) {
          latestS = val;
          hasS = true;
          update();
        },
        onError: controller.addError,
        onDone: () {
          if (subT == null || controller.isClosed) return;
        },
      );
    };

    controller.onCancel = () {
      subT?.cancel();
      subS?.cancel();
    };

    return controller.stream;
  }
}
