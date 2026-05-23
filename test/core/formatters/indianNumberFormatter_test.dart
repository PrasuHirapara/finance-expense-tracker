// ignore_for_file: file_names

import 'package:finance_analytics_app/core/formatters/indian_number_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IndianNumberFormatter', () {
    test('shows full values until one crore', () {
      expect(IndianNumberFormatter.formatCompact(9999999), '99,99,999.00');
    });

    test('compacts values from one crore', () {
      expect(IndianNumberFormatter.formatCompact(10000000), '1 Cr.');
      expect(IndianNumberFormatter.formatCompact(12500000), '1.25 Cr.');
    });
  });
}
