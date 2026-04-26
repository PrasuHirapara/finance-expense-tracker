import 'package:intl/intl.dart';

final DateFormat _singleDigitSlashDateFormat = DateFormat('d/M/yyyy');
final DateFormat _doubleDigitSlashDateFormat = DateFormat('dd/MM/yyyy');
final DateFormat _singleDigitDashDateFormat = DateFormat('d-M-yyyy');
final DateFormat _doubleDigitDashDateFormat = DateFormat('dd-MM-yyyy');

final RegExp _dateQueryPattern = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$');

bool matchesEquivalentDateQuery(DateTime date, String query) {
  final normalizedQuery = query.trim();
  if (normalizedQuery.isEmpty) {
    return false;
  }

  final match = _dateQueryPattern.firstMatch(normalizedQuery);
  if (match == null) {
    return false;
  }

  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) {
    return false;
  }

  return date.day == day && date.month == month && date.year == year;
}

Iterable<String> equivalentDateSearchTerms(DateTime date) {
  return <String>[
    _singleDigitSlashDateFormat.format(date),
    _doubleDigitSlashDateFormat.format(date),
    _singleDigitDashDateFormat.format(date),
    _doubleDigitDashDateFormat.format(date),
  ];
}
