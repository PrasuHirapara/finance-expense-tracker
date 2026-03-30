import '../entities/finance_category.dart';
import '../repositories/finance_repository.dart';

class WatchCategories {
  WatchCategories(this._repository);

  final FinanceRepository _repository;

  Stream<List<FinanceCategory>> call() => _repository.watchCategories();
}
