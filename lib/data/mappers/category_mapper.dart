import '../../domain/entities/finance_category.dart';
import '../models/finance_category_model.dart';

extension FinanceCategoryModelX on FinanceCategoryModel {
  FinanceCategory toDomain() {
    return FinanceCategory(
      id: id,
      name: name,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
    );
  }
}
