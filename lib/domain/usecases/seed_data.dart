import '../repositories/finance_repository.dart';

class SeedData {
  SeedData(this._repository);

  final FinanceRepository _repository;

  Future<void> call() => _repository.seedIfNeeded();
}
