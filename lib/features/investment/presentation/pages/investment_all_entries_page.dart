import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/formatters/indian_number_formatter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../data/repositories/investment_repository.dart';
import '../../domain/models/investment_models.dart';

// ---------------------------------------------------------------------------
// Sort options
// ---------------------------------------------------------------------------

enum _InvestmentSortOrder {
  symbolAZ,
  symbolZA,
  buyDateNewest,
  buyDateOldest,
  buyAmtHigh,
  buyAmtLow,
  plHigh,
  plLow,
  plPctHigh,
  plPctLow,
}

extension _SortLabel on _InvestmentSortOrder {
  String get label => switch (this) {
    _InvestmentSortOrder.symbolAZ => 'Symbol A → Z',
    _InvestmentSortOrder.symbolZA => 'Symbol Z → A',
    _InvestmentSortOrder.buyDateNewest => 'Buy Date: Newest',
    _InvestmentSortOrder.buyDateOldest => 'Buy Date: Oldest',
    _InvestmentSortOrder.buyAmtHigh => 'Buy Amt: High → Low',
    _InvestmentSortOrder.buyAmtLow => 'Buy Amt: Low → High',
    _InvestmentSortOrder.plHigh => 'P/L: High → Low',
    _InvestmentSortOrder.plLow => 'P/L: Low → High',
    _InvestmentSortOrder.plPctHigh => 'P/L %: High → Low',
    _InvestmentSortOrder.plPctLow => 'P/L %: Low → High',
  };
}

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

class _InvFilter {
  const _InvFilter({
    this.fromDate,
    this.toDate,
    this.categoryId,
    this.status,
    this.symbol = '',
    this.sortOrder = _InvestmentSortOrder.symbolAZ,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final int? categoryId;
  final InvestmentStatusBadge? status;
  final String symbol;
  final _InvestmentSortOrder sortOrder;

  _InvFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    Object? categoryId = _sentinel,
    Object? status = _sentinel,
    String? symbol,
    _InvestmentSortOrder? sortOrder,
  }) {
    return _InvFilter(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      categoryId: categoryId == _sentinel
          ? this.categoryId
          : categoryId as int?,
      status: status == _sentinel
          ? this.status
          : status as InvestmentStatusBadge?,
      symbol: symbol ?? this.symbol,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  _InvFilter clearDate() => _InvFilter(
    categoryId: categoryId,
    status: status,
    symbol: symbol,
    sortOrder: sortOrder,
  );

  static const Object _sentinel = Object();

  bool get isActive =>
      fromDate != null ||
      toDate != null ||
      categoryId != null ||
      status != null ||
      symbol.trim().isNotEmpty;
}

// ---------------------------------------------------------------------------
// Row model: one buy lot with its computed P/L
// ---------------------------------------------------------------------------

class _EntryRow {
  const _EntryRow({
    required this.buy,
    required this.totalSoldQty,
    required this.pl,
    required this.plPct,
    required this.statusBadge,
  });

  final InvestmentEntry buy;
  final double totalSoldQty;
  final double pl;
  final double plPct;
  final InvestmentStatusBadge statusBadge;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class InvestmentAllEntriesPage extends StatefulWidget {
  const InvestmentAllEntriesPage({super.key});

  @override
  State<InvestmentAllEntriesPage> createState() =>
      _InvestmentAllEntriesPageState();
}

class _InvestmentAllEntriesPageState extends State<InvestmentAllEntriesPage> {
  static const int _perPage = 15;

  _InvFilter _filter = const _InvFilter();
  int _currentPage = 1;
  bool _filtersExpanded = true;

  final TextEditingController _symbolController = TextEditingController();

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<InvestmentRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Entries'),
        actions: [
          if (_filter.isActive)
            TextButton(
              onPressed: () => setState(() {
                _filter = const _InvFilter();
                _symbolController.clear();
                _currentPage = 1;
              }),
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: StreamBuilder<List<InvestmentCategory>>(
        stream: repo.watchCategories(),
        builder: (context, catSnap) {
          final categories = catSnap.data ?? const [];
          return StreamBuilder<List<InvestmentEntry>>(
            stream: repo.watchBuyEntries(),
            builder: (context, buySnap) {
              return StreamBuilder<List<SellEntry>>(
                stream: repo.watchSellEntries(),
                builder: (context, sellSnap) {
                  if (!buySnap.hasData || !sellSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = _buildRows(buySnap.data!, sellSnap.data!);
                  final paged = _paginate(rows);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      // ── Filters panel ──────────────────────────────────
                      AppPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Filters',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(
                                    () => _filtersExpanded = !_filtersExpanded,
                                  ),
                                  icon: Icon(
                                    _filtersExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                ),
                              ],
                            ),
                            if (_filtersExpanded) ...[
                              const SizedBox(height: 10),
                              // Date row
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _DateChip(
                                    label: 'From',
                                    value: _filter.fromDate,
                                    onTap: () => _pickDate(isFrom: true),
                                    onClear: _filter.fromDate == null
                                        ? null
                                        : () => setState(() {
                                            _filter = _InvFilter(
                                              toDate: _filter.toDate,
                                              categoryId: _filter.categoryId,
                                              status: _filter.status,
                                              symbol: _filter.symbol,
                                              sortOrder: _filter.sortOrder,
                                            );
                                            _currentPage = 1;
                                          }),
                                  ),
                                  _DateChip(
                                    label: 'To',
                                    value: _filter.toDate,
                                    onTap: () => _pickDate(isFrom: false),
                                    onClear: _filter.toDate == null
                                        ? null
                                        : () => setState(() {
                                            _filter = _InvFilter(
                                              fromDate: _filter.fromDate,
                                              categoryId: _filter.categoryId,
                                              status: _filter.status,
                                              symbol: _filter.symbol,
                                              sortOrder: _filter.sortOrder,
                                            );
                                            _currentPage = 1;
                                          }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Symbol search
                              TextField(
                                controller: _symbolController,
                                decoration: InputDecoration(
                                  labelText: 'Search symbol',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _filter.symbol.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _symbolController.clear();
                                            setState(() {
                                              _filter = _filter.copyWith(
                                                symbol: '',
                                              );
                                              _currentPage = 1;
                                            });
                                          },
                                        )
                                      : null,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (v) => setState(() {
                                  _filter = _filter.copyWith(symbol: v.trim());
                                  _currentPage = 1;
                                }),
                              ),
                              const SizedBox(height: 10),
                              // Category
                              AppSelectField<int?>(
                                label: 'Category',
                                value: _filter.categoryId,
                                options: [
                                  const AppSelectOption<int?>(
                                    value: null,
                                    label: 'All Categories',
                                  ),
                                  ...categories.map(
                                    (c) => AppSelectOption<int?>(
                                      value: c.id,
                                      label: c.name,
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() {
                                  _filter = _filter.copyWith(categoryId: v);
                                  _currentPage = 1;
                                }),
                              ),
                              const SizedBox(height: 10),
                              // Status
                              AppSelectField<InvestmentStatusBadge?>(
                                label: 'Status',
                                value: _filter.status,
                                options: const [
                                  AppSelectOption(value: null, label: 'All'),
                                  AppSelectOption(
                                    value: InvestmentStatusBadge.open,
                                    label: 'Open',
                                  ),
                                  AppSelectOption(
                                    value: InvestmentStatusBadge.partial,
                                    label: 'Partial',
                                  ),
                                  AppSelectOption(
                                    value: InvestmentStatusBadge.sold,
                                    label: 'Sold',
                                  ),
                                ],
                                onChanged: (v) => setState(() {
                                  _filter = _filter.copyWith(status: v);
                                  _currentPage = 1;
                                }),
                              ),
                              const SizedBox(height: 10),
                              // Sort
                              AppSelectField<_InvestmentSortOrder>(
                                label: 'Sort by',
                                value: _filter.sortOrder,
                                options: _InvestmentSortOrder.values
                                    .map(
                                      (s) => AppSelectOption(
                                        value: s,
                                        label: s.label,
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _filter = _filter.copyWith(sortOrder: v);
                                  _currentPage = 1;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Summary bar ────────────────────────────────────
                      _SummaryBar(rows: rows),
                      const SizedBox(height: 12),

                      // ── Entry cards ────────────────────────────────────
                      if (rows.isEmpty)
                        const AppPanel(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('No entries match your filters.'),
                            ),
                          ),
                        )
                      else
                        ...paged.map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _EntryCard(
                              row: row,
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.investmentDetail,
                                arguments: InvestmentDetailArgs(
                                  symbol: row.buy.symbol,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // ── Pagination ─────────────────────────────────────
                      if (rows.length > _perPage)
                        _PaginationControls(
                          currentPage: _currentPage,
                          totalPages: _totalPages(rows.length),
                          onPageSelected: (p) =>
                              setState(() => _currentPage = p),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Data helpers ──────────────────────────────────────────────────────────

  List<_EntryRow> _buildRows(
    List<InvestmentEntry> buys,
    List<SellEntry> sells,
  ) {
    // Pre-index sells by buyEntryId
    final sellsByBuyId = <int, List<SellEntry>>{};
    for (final s in sells) {
      sellsByBuyId.putIfAbsent(s.buyEntryId, () => []).add(s);
    }

    // Build row per buy lot, apply filters
    final rows = <_EntryRow>[];
    for (final buy in buys) {
      // Date range filter (on buy date)
      if (_filter.fromDate != null && buy.buyDate.isBefore(_filter.fromDate!)) {
        continue;
      }
      if (_filter.toDate != null &&
          buy.buyDate.isAfter(
            _filter.toDate!.copyWith(hour: 23, minute: 59, second: 59),
          )) {
        continue;
      }
      // Category filter
      if (_filter.categoryId != null && buy.categoryId != _filter.categoryId) {
        continue;
      }
      // Symbol search
      if (_filter.symbol.isNotEmpty &&
          !buy.symbol.toLowerCase().contains(_filter.symbol.toLowerCase())) {
        continue;
      }

      // Compute P/L for this specific buy lot
      final linkedSells = sellsByBuyId[buy.id] ?? [];
      final totalSoldQty = linkedSells.fold<double>(
        0,
        (sum, s) => sum + s.sellQty,
      );
      var pl = 0.0;
      for (final s in linkedSells) {
        pl += s.sellAmt - (buy.buyRate * s.sellQty);
      }
      final plPct = buy.buyAmt == 0 ? 0.0 : (pl / buy.buyAmt) * 100;

      // Status badge for this lot
      final badge = totalSoldQty == 0
          ? InvestmentStatusBadge.open
          : totalSoldQty < buy.qty
          ? InvestmentStatusBadge.partial
          : InvestmentStatusBadge.sold;

      // Status filter
      if (_filter.status != null && _filter.status != badge) continue;

      rows.add(
        _EntryRow(
          buy: buy,
          totalSoldQty: totalSoldQty,
          pl: pl,
          plPct: plPct,
          statusBadge: badge,
        ),
      );
    }

    // Sort
    rows.sort(
      (a, b) => switch (_filter.sortOrder) {
        _InvestmentSortOrder.symbolAZ => a.buy.symbol.compareTo(b.buy.symbol),
        _InvestmentSortOrder.symbolZA => b.buy.symbol.compareTo(a.buy.symbol),
        _InvestmentSortOrder.buyDateNewest => b.buy.buyDate.compareTo(
          a.buy.buyDate,
        ),
        _InvestmentSortOrder.buyDateOldest => a.buy.buyDate.compareTo(
          b.buy.buyDate,
        ),
        _InvestmentSortOrder.buyAmtHigh => b.buy.buyAmt.compareTo(a.buy.buyAmt),
        _InvestmentSortOrder.buyAmtLow => a.buy.buyAmt.compareTo(b.buy.buyAmt),
        _InvestmentSortOrder.plHigh => b.pl.compareTo(a.pl),
        _InvestmentSortOrder.plLow => a.pl.compareTo(b.pl),
        _InvestmentSortOrder.plPctHigh => b.plPct.compareTo(a.plPct),
        _InvestmentSortOrder.plPctLow => a.plPct.compareTo(b.plPct),
      },
    );

    return rows;
  }

  List<_EntryRow> _paginate(List<_EntryRow> rows) {
    final total = _totalPages(rows.length);
    final page = _currentPage.clamp(1, total);
    if (page != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = page);
      });
    }
    final start = (page - 1) * _perPage;
    final end = (start + _perPage).clamp(0, rows.length);
    return rows.sublist(start, end);
  }

  int _totalPages(int count) => count == 0 ? 1 : ((count - 1) ~/ _perPage) + 1;

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_filter.fromDate ?? DateTime.now())
        : (_filter.toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) {
      setState(() {
        _filter = isFrom
            ? _InvFilter(
                fromDate: picked,
                toDate: _filter.toDate,
                categoryId: _filter.categoryId,
                status: _filter.status,
                symbol: _filter.symbol,
                sortOrder: _filter.sortOrder,
              )
            : _InvFilter(
                fromDate: _filter.fromDate,
                toDate: picked,
                categoryId: _filter.categoryId,
                status: _filter.status,
                symbol: _filter.symbol,
                sortOrder: _filter.sortOrder,
              );
        _currentPage = 1;
      });
    }
  }
}

// ---------------------------------------------------------------------------
// Summary bar
// ---------------------------------------------------------------------------

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.rows});
  final List<_EntryRow> rows;

  @override
  Widget build(BuildContext context) {
    final totalInvested = rows.fold<double>(0, (s, r) => s + r.buy.buyAmt);
    final totalPL = rows.fold<double>(0, (s, r) => s + r.pl);
    final plPct = totalInvested == 0 ? 0.0 : (totalPL / totalInvested) * 100;
    final isProfit = totalPL >= 0;

    return AppPanel(
      child: Row(
        children: [
          _SummaryItem(
            label: 'Entries',
            value: '${rows.length}',
            color: Theme.of(context).colorScheme.primary,
          ),
          _SummaryItem(
            label: 'Invested',
            value: IndianNumberFormatter.formatCompactCurrency(totalInvested),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          _SummaryItem(
            label: 'P/L',
            value:
                '${isProfit ? '+' : ''}${IndianNumberFormatter.formatCompactCurrency(totalPL)} (${isProfit ? '+' : ''}${plPct.toStringAsFixed(1)}%)',
            color: isProfit ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry card
// ---------------------------------------------------------------------------

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.row, required this.onTap});
  final _EntryRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buy = row.buy;
    final isProfit = row.pl >= 0;
    final plColor = isProfit ? Colors.green : Colors.red;
    final hasSells = row.totalSoldQty > 0;

    final badgeColor = switch (row.statusBadge) {
      InvestmentStatusBadge.open => Colors.blue,
      InvestmentStatusBadge.partial => Colors.orange,
      InvestmentStatusBadge.sold => Colors.green,
    };
    final badgeLabel = switch (row.statusBadge) {
      InvestmentStatusBadge.open => 'Open',
      InvestmentStatusBadge.partial => 'Partial',
      InvestmentStatusBadge.sold => 'Sold',
    };

    return AppPanel(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: symbol + P/L ──────────────────────────────
              Row(
                children: [
                  // Category colour dot
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(buy.categoryColorValue),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      buy.symbol,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Sub row: category + buy date ───────────────────────
              Text(
                '${buy.categoryName}  •  ${AppConstants.shortDateFormat.format(buy.buyDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // ── Numbers grid ───────────────────────────────────────
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _NumCell(label: 'Qty', value: buy.qty.toStringAsFixed(2)),
                  _NumCell(
                    label: 'Buy Rate',
                    value: IndianNumberFormatter.formatFull(buy.buyRate),
                  ),
                  _NumCell(
                    label: 'Buy Amt',
                    value: IndianNumberFormatter.formatFull(buy.buyAmt),
                  ),
                  if (hasSells) ...[
                    _NumCell(
                      label: 'Sold Qty',
                      value: row.totalSoldQty.toStringAsFixed(2),
                    ),
                    _NumCell(
                      label: 'P/L',
                      value:
                          '${isProfit ? '+' : ''}${IndianNumberFormatter.formatFull(row.pl)}',
                      valueColor: plColor,
                    ),
                    _NumCell(
                      label: 'P/L %',
                      value:
                          '${isProfit ? '+' : ''}${row.plPct.toStringAsFixed(2)}%',
                      valueColor: plColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // ── View button ────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onTap, child: const Text('View')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumCell extends StatelessWidget {
  const _NumCell({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date filter chip
// ---------------------------------------------------------------------------

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_rounded, size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value == null
                ? '$label date'
                : '$label: ${AppConstants.shortDateFormat.format(value!)}',
          ),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination (reused pattern from expense)
// ---------------------------------------------------------------------------

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: currentPage > 1
              ? () => onPageSelected(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Prev'),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(totalPages, (i) {
                final page = i + 1;
                final isSelected = page == currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: TextButton(
                    onPressed: () => onPageSelected(page),
                    style: TextButton.styleFrom(
                      minimumSize: Size(_btnWidth(page), 36),
                      padding: EdgeInsets.symmetric(
                        horizontal: _btnPad(page),
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      foregroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      textStyle: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                    ),
                    child: Text('$page'),
                  ),
                );
              }),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: currentPage < totalPages
              ? () => onPageSelected(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Next'),
        ),
      ],
    );
  }

  double _btnWidth(int page) => 18 + (page.toString().length * 10);
  double _btnPad(int page) {
    final p = 9 - (page.toString().length * 1.5);
    return p < 3 ? 3 : p;
  }
}
