import '../repositories/finance_repository.dart';

class AddCategory {
  AddCategory(this._repository);

  final FinanceRepository _repository;

  Future<void> call({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) {
    return _repository.addCategory(
      name: name,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
    );
  }
}
