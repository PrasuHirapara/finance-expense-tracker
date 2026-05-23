import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/date_time_x.dart';
import 'app_select_field.dart';

class HistoryDatePickerDialog extends StatefulWidget {
  const HistoryDatePickerDialog({
    super.key,
    required this.title,
    required this.dataDates,
  });

  final String title;
  final Set<DateTime> dataDates;

  static Future<DateTime?> pick({
    required BuildContext context,
    required String title,
    required Set<DateTime> dataDates,
  }) {
    final normalizedDates = dataDates.map((date) => date.startOfDay).toSet();
    return showDialog<DateTime>(
      context: context,
      builder: (context) =>
          HistoryDatePickerDialog(title: title, dataDates: normalizedDates),
    );
  }

  @override
  State<HistoryDatePickerDialog> createState() =>
      _HistoryDatePickerDialogState();
}

class _HistoryDatePickerDialogState extends State<HistoryDatePickerDialog> {
  late DateTime _visibleMonth;
  late PageController _pageController;

  DateTime get _today => DateTime.now().startOfDay;

  DateTime get _firstMonth {
    if (widget.dataDates.isEmpty) {
      return DateTime(_today.year, _today.month);
    }
    final firstDate = widget.dataDates.reduce(
      (left, right) => left.isBefore(right) ? left : right,
    );
    return DateTime(firstDate.year, firstDate.month);
  }

  DateTime get _lastMonth => DateTime(_today.year, _today.month);

  @override
  void initState() {
    super.initState();
    _visibleMonth = _lastMonth;
    final initialPage = _monthDelta(_firstMonth, _visibleMonth);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yearOptions = _yearOptions;
    final monthOptions = _monthOptionsForYear(_visibleMonth.year);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: <Widget>[
          Expanded(child: Text(widget.title)),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: AppSelectField<int>(
                    label: 'Year',
                    value: _visibleMonth.year,
                    options: yearOptions
                        .map(
                          (year) => AppSelectOption<int>(
                            value: year,
                            label: year.toString(),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _selectYear,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppSelectField<int>(
                    label: 'Month',
                    value: _visibleMonth.month,
                    options: monthOptions
                        .map(
                          (month) => AppSelectOption<int>(
                            value: month,
                            label: _monthOptionLabel(
                              year: _visibleMonth.year,
                              month: month,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _selectMonth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _monthDelta(_firstMonth, _lastMonth) + 1,
                onPageChanged: (page) {
                  final newMonth = DateTime(
                    _firstMonth.year,
                    _firstMonth.month + page,
                  );
                  setState(() {
                    _visibleMonth = newMonth;
                  });
                },
                itemBuilder: (context, page) {
                  final pageMonth = DateTime(
                    _firstMonth.year,
                    _firstMonth.month + page,
                  );
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${AppConstants.monthLabelFormat.format(pageMonth)} ${pageMonth.year}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children:
                              const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                  .map(
                                    (label) => Expanded(
                                      child: Center(child: Text(label)),
                                    ),
                                  )
                                  .toList(growable: false),
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 7,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          children: _buildMonthCellsFor(pageMonth)
                              .map(
                                (date) => _HistoryDateCell(
                                  date: date,
                                  visibleMonth: pageMonth,
                                  hasData: widget.dataDates.contains(
                                    date?.startOfDay,
                                  ),
                                  isToday: date?.isSameDate(_today) ?? false,
                                  onSelected: date == null
                                      ? null
                                      : () => Navigator.of(
                                          context,
                                        ).pop(date.startOfDay),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<int> get _yearOptions {
    return <int>[
      for (var year = _lastMonth.year; year >= _firstMonth.year; year--) year,
    ];
  }

  List<int> _monthOptionsForYear(int year) {
    final firstMonth = year == _firstMonth.year ? _firstMonth.month : 1;
    final lastMonth = year == _lastMonth.year ? _lastMonth.month : 12;
    return <int>[
      for (var month = firstMonth; month <= lastMonth; month++) month,
    ];
  }

  int _monthDelta(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  void _selectYear(int year) {
    setState(() {
      final allowedMonths = _monthOptionsForYear(year);
      final month = _visibleMonth.month.clamp(
        allowedMonths.first,
        allowedMonths.last,
      );
      _visibleMonth = DateTime(year, month);
    });
  }

  void _selectMonth(int month) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, month);
    });
  }

  String _monthLabel(int month) {
    return AppConstants.monthLabelFormat.format(DateTime(2000, month));
  }

  String _monthOptionLabel({required int year, required int month}) {
    final dataCount = _monthDataCount(year: year, month: month);
    if (dataCount == 0) {
      return _monthLabel(month);
    }
    return '${_monthLabel(month)} ($dataCount)';
  }

  int _monthDataCount({required int year, required int month}) {
    return widget.dataDates
        .where((date) => date.year == year && date.month == month)
        .length;
  }

  List<DateTime?> _buildMonthCellsFor(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = firstDay.weekday - DateTime.monday;
    final cells = <DateTime?>[
      for (var index = 0; index < leadingEmptyCells; index++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(month.year, month.month, day),
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return cells;
  }
}

class _HistoryDateCell extends StatelessWidget {
  const _HistoryDateCell({
    required this.date,
    required this.visibleMonth,
    required this.hasData,
    required this.isToday,
    required this.onSelected,
  });

  final DateTime? date;
  final DateTime visibleMonth;
  final bool hasData;
  final bool isToday;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = this.date;
    final inMonth =
        date != null &&
        date.year == visibleMonth.year &&
        date.month == visibleMonth.month;
    final enabled = date != null && hasData && !date.isAfter(DateTime.now());
    final colorScheme = theme.colorScheme;

    if (date == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: enabled ? onSelected : null,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasData ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hasData
                ? colorScheme.primary
                : isToday
                ? colorScheme.outline
                : Colors.transparent,
          ),
        ),
        child: Text(
          date.day.toString(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: enabled
                ? colorScheme.onPrimaryContainer
                : inMonth
                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.52)
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
            fontWeight: hasData ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
