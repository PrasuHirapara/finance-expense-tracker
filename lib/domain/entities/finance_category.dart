import 'package:freezed_annotation/freezed_annotation.dart';

part 'finance_category.freezed.dart';

@freezed
abstract class FinanceCategory with _$FinanceCategory {
  const factory FinanceCategory({
    required int id,
    required String name,
    required int iconCodePoint,
    required int colorValue,
  }) = _FinanceCategory;
}
