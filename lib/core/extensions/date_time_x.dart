extension DateTimeX on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);

  DateTime get startOfWeek {
    final delta = weekday - DateTime.monday;
    return subtract(Duration(days: delta)).startOfDay;
  }

  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6)).endOfDay;

  DateTime get startOfMonth => DateTime(year, month);

  DateTime get endOfMonth => DateTime(year, month + 1, 0).endOfDay;

  DateTime get startOfYear => DateTime(year);

  DateTime get endOfYear => DateTime(year, 12, 31).endOfDay;

  bool isSameDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
