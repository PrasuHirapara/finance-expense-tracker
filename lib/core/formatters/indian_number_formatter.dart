import 'package:intl/intl.dart';

class IndianNumberFormatter {
  IndianNumberFormatter._();

  static final NumberFormat _fullNumberFormatter = NumberFormat(
    '#,##,##0.################',
    'en_IN',
  );

  static final NumberFormat _compactDecimalFormatter = NumberFormat(
    '0.00',
    'en_IN',
  );

  static String formatCompact(num value) {
    final absoluteValue = value.abs().toDouble();
    final prefix = value < 0 ? '-' : '';

    if (absoluteValue >= 10000000) {
      return '$prefix${_compactDecimalFormatter.format(absoluteValue / 10000000)} Cr';
    }

    if (absoluteValue >= 100000) {
      return '$prefix${_compactDecimalFormatter.format(absoluteValue / 100000)} Lakh';
    }

    return '$prefix${formatFull(absoluteValue)}';
  }

  static String formatCompactCurrency(num value) {
    return 'Rs ${formatCompact(value)}';
  }

  static String formatFull(num value) {
    return _fullNumberFormatter.format(value);
  }

  static String formatFullCurrency(num value) {
    return 'Rs ${formatFull(value)}';
  }
}
