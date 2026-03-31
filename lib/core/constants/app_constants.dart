import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../formatters/indian_number_formatter.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Daily Use';

  static const List<String> paymentModes = <String>[
    'Cash',
    'UPI',
    'Debit Card',
    'Credit Card',
    'Bank Transfer',
    'Wallet',
  ];

  static final DateFormat shortDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat longDateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat monthLabelFormat = DateFormat('MMM');
  static final DateFormat dayLabelFormat = DateFormat('dd MMM');
  static final DateFormat exportFileFormat = DateFormat('yyyyMMdd_HHmmss');

  static final List<DefaultCategorySeed> defaultCategories =
      <DefaultCategorySeed>[
        DefaultCategorySeed(
          name: 'Food',
          iconCodePoint: Icons.restaurant_rounded.codePoint,
          colorValue: 0xFFE67E22,
        ),
        DefaultCategorySeed(
          name: 'College',
          iconCodePoint: Icons.school_rounded.codePoint,
          colorValue: 0xFF2E86DE,
        ),
        DefaultCategorySeed(
          name: 'Travel',
          iconCodePoint: Icons.directions_bus_rounded.codePoint,
          colorValue: 0xFF16A085,
        ),
        DefaultCategorySeed(
          name: 'Health',
          iconCodePoint: Icons.health_and_safety_rounded.codePoint,
          colorValue: 0xFFE74C3C,
        ),
        DefaultCategorySeed(
          name: 'Shopping',
          iconCodePoint: Icons.shopping_bag_rounded.codePoint,
          colorValue: 0xFF9B59B6,
        ),
        DefaultCategorySeed(
          name: 'Bills',
          iconCodePoint: Icons.receipt_long_rounded.codePoint,
          colorValue: 0xFF34495E,
        ),
        DefaultCategorySeed(
          name: 'Entertainment',
          iconCodePoint: Icons.movie_creation_rounded.codePoint,
          colorValue: 0xFFF39C12,
        ),
        DefaultCategorySeed(
          name: 'Rent',
          iconCodePoint: Icons.home_rounded.codePoint,
          colorValue: 0xFF27AE60,
        ),
        DefaultCategorySeed(
          name: 'Investment',
          iconCodePoint: Icons.trending_up_rounded.codePoint,
          colorValue: 0xFF2980B9,
        ),
        DefaultCategorySeed(
          name: 'Miscellaneous',
          iconCodePoint: Icons.category_rounded.codePoint,
          colorValue: 0xFF7F8C8D,
        ),
      ];

  static const List<IconData> categoryIconChoices = <IconData>[
    Icons.restaurant_rounded,
    Icons.school_rounded,
    Icons.directions_bus_rounded,
    Icons.health_and_safety_rounded,
    Icons.shopping_bag_rounded,
    Icons.receipt_long_rounded,
    Icons.movie_creation_rounded,
    Icons.home_rounded,
    Icons.trending_up_rounded,
    Icons.category_rounded,
    Icons.pets_rounded,
    Icons.savings_rounded,
  ];

  static const List<int> categoryColorChoices = <int>[
    0xFFE67E22,
    0xFF2E86DE,
    0xFF16A085,
    0xFFE74C3C,
    0xFF9B59B6,
    0xFFF39C12,
    0xFF27AE60,
    0xFF34495E,
    0xFF2980B9,
    0xFF7F8C8D,
    0xFFD35400,
    0xFF1ABC9C,
  ];

  static const List<String> taskCategoryChoices = <String>[
    'Work',
    'Study',
    'Health',
    'Finance',
    'Home',
    'Shopping',
    'Fitness',
    'Reading',
    'Family',
    'Travel',
    'Calls',
    'Personal',
  ];

  static IconData categoryIconFromCodePoint(int codePoint) {
    if (codePoint == Icons.restaurant_rounded.codePoint) {
      return Icons.restaurant_rounded;
    }
    if (codePoint == Icons.school_rounded.codePoint) {
      return Icons.school_rounded;
    }
    if (codePoint == Icons.directions_bus_rounded.codePoint) {
      return Icons.directions_bus_rounded;
    }
    if (codePoint == Icons.health_and_safety_rounded.codePoint) {
      return Icons.health_and_safety_rounded;
    }
    if (codePoint == Icons.shopping_bag_rounded.codePoint) {
      return Icons.shopping_bag_rounded;
    }
    if (codePoint == Icons.receipt_long_rounded.codePoint) {
      return Icons.receipt_long_rounded;
    }
    if (codePoint == Icons.movie_creation_rounded.codePoint) {
      return Icons.movie_creation_rounded;
    }
    if (codePoint == Icons.home_rounded.codePoint) {
      return Icons.home_rounded;
    }
    if (codePoint == Icons.trending_up_rounded.codePoint) {
      return Icons.trending_up_rounded;
    }
    if (codePoint == Icons.category_rounded.codePoint) {
      return Icons.category_rounded;
    }
    if (codePoint == Icons.pets_rounded.codePoint) {
      return Icons.pets_rounded;
    }
    if (codePoint == Icons.savings_rounded.codePoint) {
      return Icons.savings_rounded;
    }
    return Icons.category_rounded;
  }

  static String currency(double value) =>
      IndianNumberFormatter.formatFullCurrency(value);
}

class DefaultCategorySeed {
  const DefaultCategorySeed({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final String name;
  final int iconCodePoint;
  final int colorValue;
}
