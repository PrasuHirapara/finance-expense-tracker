import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_panel.dart';
import '../../../../shared/widgets/app_select_field.dart';
import '../../../../core/formatters/indian_number_formatter.dart';
import '../../domain/models/investment_models.dart';
import '../../data/repositories/investment_repository.dart';
import '../blocs/investment/investment_bloc.dart';

class InvestmentModulePage extends StatefulWidget {
  const InvestmentModulePage({super.key});

  @override
  State<InvestmentModulePage> createState() => _InvestmentModulePageState();
}

class _InvestmentModulePageState extends State<InvestmentModulePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  InvestmentStatusBadge? _selectedStatusFilter;
  int _visibleGroupCount = 10;
  static const int _initialVisibleGroups = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _visibleGroupCount = _initialVisibleGroups;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<InvestmentBloc, InvestmentState>(
      builder: (context, investmentState) {
        final dashboard = investmentState.dashboard;

        if (dashboard == null) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // 1. Get all buy entries
        final allBuyEntries = dashboard.symbolGroups
            .expand((group) => group.buyEntries)
            .toList();

        // 2. Filter buy entries
        final filteredEntries = allBuyEntries.where((entry) {
          // Status filter
          // Let's compute entry status
          final entrySells = dashboard.symbolGroups
              .firstWhere((g) => g.symbol == entry.symbol)
              .sellEntries
              .where((s) => s.buyEntryId == entry.id)
              .toList();
          final soldQty = entrySells.fold<double>(
            0.0,
            (sum, s) => sum + s.sellQty,
          );
          final entryStatus = soldQty == 0
              ? InvestmentStatusBadge.open
              : (soldQty < entry.qty
                    ? InvestmentStatusBadge.partial
                    : InvestmentStatusBadge.sold);

          if (_selectedStatusFilter != null) {
            if (_selectedStatusFilter == InvestmentStatusBadge.open) {
              if (entryStatus == InvestmentStatusBadge.sold) return false;
            } else {
              if (entryStatus != _selectedStatusFilter) return false;
            }
          }

          // Search query filter
          if (_searchController.text.trim().isNotEmpty) {
            final query = _searchController.text.trim().toLowerCase();
            if (!entry.symbol.toLowerCase().contains(query)) return false;
          }

          return true;
        }).toList()..sort((a, b) => b.buyDate.compareTo(a.buyDate));

        final groupedEntries = _groupBuyEntries(
          filteredEntries,
          dashboard.symbolGroups,
        );
        final visibleGroupedEntries =
            Map<String, List<InvestmentEntry>>.fromEntries(
              groupedEntries.entries.take(_visibleGroupCount),
            );

        final summaryCards = <_SummaryCardData>[
          _SummaryCardData(
            label: 'Total Sell Value',
            value: IndianNumberFormatter.formatFull(dashboard.totalSellValue),
            color: const Color(0xFFC0392B),
            statusFilter: null,
          ),
          _SummaryCardData(
            label: 'Total P/L',
            value:
                '${dashboard.totalPL >= 0 ? "+" : ""}${IndianNumberFormatter.formatFull(dashboard.totalPL)}',
            color: dashboard.totalPL >= 0
                ? const Color(0xFF1F8B4C)
                : const Color(0xFFC0392B),
            statusFilter: null,
          ),
          _SummaryCardData(
            label: 'Total P/L %',
            value:
                '${dashboard.totalPLPct >= 0 ? "+" : ""}${dashboard.totalPLPct.toStringAsFixed(2)}%',
            color: dashboard.totalPLPct >= 0
                ? const Color(0xFF1F8B4C)
                : const Color(0xFFC0392B),
            statusFilter: null,
          ),
          _SummaryCardData(
            label: 'Invested',
            value: IndianNumberFormatter.formatFull(
              dashboard.totalActiveInvested,
            ),
            color: const Color(0xFF16A085),
            statusFilter: InvestmentStatusBadge.open,
          ),
        ];

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<InvestmentBloc>().add(
                  InvestmentSubscriptionRequested(
                    categoryId: investmentState.selectedCategoryId,
                    dateRange: investmentState.selectedDateRange,
                  ),
                );
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Investment',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.investmentAnalytics),
                        icon: const Icon(Icons.insights_rounded),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.investmentSettings),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StreamBuilder<List<InvestmentCategory>>(
                          stream: context
                              .read<InvestmentRepository>()
                              .watchCategories(),
                          builder: (context, categoriesSnapshot) {
                            final categories =
                                categoriesSnapshot.data ??
                                const <InvestmentCategory>[];
                            return BlocBuilder<InvestmentBloc, InvestmentState>(
                              builder: (context, state) {
                                return AppSelectField<int?>(
                                  label: 'Filter by category',
                                  value: state.selectedCategoryId,
                                  options: <AppSelectOption<int?>>[
                                    const AppSelectOption<int?>(
                                      value: null,
                                      label: 'All',
                                    ),
                                    ...categories.map(
                                      (c) => AppSelectOption<int?>(
                                        value: c.id,
                                        label: c.name,
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    context.read<InvestmentBloc>().add(
                                      InvestmentCategoryFilterChanged(value),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.investmentAdd),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Investment'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Summary',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStatusFilter = null;
                                  _visibleGroupCount = _initialVisibleGroups;
                                });
                              },
                              child: const Text('All transactions'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _NetSummaryRow(
                          value: IndianNumberFormatter.formatFull(
                            dashboard.totalInvested,
                          ),
                          selected: _selectedStatusFilter == null,
                          onTap: () {
                            setState(() {
                              _selectedStatusFilter = null;
                              _visibleGroupCount = _initialVisibleGroups;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 1.45,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: summaryCards
                              .map(
                                (item) => _SummaryMetricCard(
                                  data: item,
                                  selected:
                                      item.statusFilter != null &&
                                      _selectedStatusFilter ==
                                          item.statusFilter,
                                  onTap: item.statusFilter == null
                                      ? () {}
                                      : () {
                                          setState(() {
                                            if (_selectedStatusFilter ==
                                                item.statusFilter) {
                                              // Toggle off
                                              _selectedStatusFilter = null;
                                            } else {
                                              _selectedStatusFilter =
                                                  item.statusFilter;
                                            }
                                            _visibleGroupCount =
                                                _initialVisibleGroups;
                                          });
                                        },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Search investments',
                            hintText: 'Search by symbol',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchFocusNode.unfocus();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: IconButton.filledTonal(
                          tooltip: 'Filter by date range',
                          onPressed: () => _openDateFilterDialog(context),
                          icon: const Icon(Icons.calendar_month_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'History',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.investmentAllEntries),
                              child: const Text('All Entries'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (filteredEntries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No transactions match the current filter.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ...visibleGroupedEntries.entries.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _SymbolInvestmentGroup(
                                symbol: group.key,
                                entries: group.value,
                                dashboard: dashboard,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.investmentDetail,
                                    arguments: InvestmentDetailArgs(
                                      symbol: group.key,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (groupedEntries.length >
                            visibleGroupedEntries.length)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleGroupCount += 10;
                                  });
                                },
                                child: const Text('Load More'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDateFilterDialog(BuildContext context) async {
    final result = await showDialog<InvestmentDateFilterResult>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Filter by Date'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(
                context,
                const InvestmentDateFilterResult(
                  window: InvestmentAnalyticsWindow.all,
                ),
              ),
              child: const Text('All Time'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(
                context,
                const InvestmentDateFilterResult(
                  window: InvestmentAnalyticsWindow.year,
                ),
              ),
              child: const Text('This Year'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(
                context,
                const InvestmentDateFilterResult(
                  window: InvestmentAnalyticsWindow.threeYears,
                ),
              ),
              child: const Text('Past 3 Years'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  if (context.mounted) {
                    Navigator.pop(
                      context,
                      InvestmentDateFilterResult(
                        window: InvestmentAnalyticsWindow.custom,
                        range: DateTimeRange(
                          start: picked.start,
                          end: picked.end,
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Custom Range'),
            ),
          ],
        );
      },
    );

    if (result != null && context.mounted) {
      DateTimeRange? resolvedRange;
      final now = DateTime.now();
      switch (result.window) {
        case InvestmentAnalyticsWindow.all:
          resolvedRange = null;
          break;
        case InvestmentAnalyticsWindow.month:
          resolvedRange = DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          );
          break;
        case InvestmentAnalyticsWindow.year:
          resolvedRange = DateTimeRange(
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year, 12, 31, 23, 59, 59),
          );
          break;
        case InvestmentAnalyticsWindow.threeYears:
          resolvedRange = DateTimeRange(
            start: DateTime(now.year - 3, now.month, now.day),
            end: now,
          );
          break;
        case InvestmentAnalyticsWindow.custom:
          resolvedRange = result.range;
          break;
      }

      context.read<InvestmentBloc>().add(
        InvestmentDateFilterChanged(
          window: result.window,
          dateRange: resolvedRange,
        ),
      );
    }
  }

  Map<String, List<InvestmentEntry>> _groupBuyEntries(
    List<InvestmentEntry> entries,
    List<SymbolGroup> symbolGroups,
  ) {
    final Map<String, List<InvestmentEntry>> grouped = {};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.symbol, () => <InvestmentEntry>[]).add(entry);
    }

    // Sort buy lots within each symbol by date desc
    for (final symbol in grouped.keys) {
      grouped[symbol]!.sort((a, b) => b.buyDate.compareTo(a.buyDate));
    }

    // Sort symbols A → Z
    final sortedSymbols = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    final Map<String, List<InvestmentEntry>> sortedGrouped = {};
    for (final symbol in sortedSymbols) {
      sortedGrouped[symbol] = grouped[symbol]!;
    }
    return sortedGrouped;
  }
}

class InvestmentDateFilterResult {
  const InvestmentDateFilterResult({required this.window, this.range});
  final InvestmentAnalyticsWindow window;
  final DateTimeRange? range;
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.color,
    this.statusFilter,
  });

  final String label;
  final String value;
  final Color color;

  /// If non-null, tapping this card will filter the list by this status.
  final InvestmentStatusBadge? statusFilter;
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _SummaryCardData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: selected
              ? data.color.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.42,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? data.color : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              data.value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NetSummaryRow extends StatelessWidget {
  const _NetSummaryRow({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2E86DE).withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.42,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E86DE)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Total Invested',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolInvestmentGroup extends StatelessWidget {
  const _SymbolInvestmentGroup({
    required this.symbol,
    required this.entries,
    required this.dashboard,
    required this.onTap,
  });

  final String symbol;
  final List<InvestmentEntry> entries;
  final InvestmentDashboardData dashboard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final group = dashboard.symbolGroups.firstWhere(
      (g) => g.symbol == symbol,
      orElse: () => SymbolGroup(
        symbol: symbol,
        buyEntries: entries,
        sellEntries: const [],
      ),
    );

    final buyRates = {for (final buy in group.buyEntries) buy.id: buy.buyRate};
    final totalPL = group.sellEntries.fold<double>(
      0.0,
      (sum, s) =>
          sum + (s.sellAmt - ((buyRates[s.buyEntryId] ?? 0.0) * s.sellQty)),
    );
    final isPositive = totalPL >= 0;

    final latestDate = entries.isNotEmpty
        ? entries.first.buyDate
        : DateTime.now();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      symbol,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isPositive ? "+" : ""}${IndianNumberFormatter.formatFull(totalPL)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Qty: ${group.totalBoughtQty.toStringAsFixed(2)} | Date: ${AppConstants.shortDateFormat.format(latestDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'P/L',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(onPressed: onTap, child: const Text('View')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
