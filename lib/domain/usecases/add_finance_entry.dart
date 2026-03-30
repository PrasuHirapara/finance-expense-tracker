import '../entities/finance_entry.dart';
import '../repositories/finance_repository.dart';

class AddFinanceEntry {
  AddFinanceEntry(this._repository);

  final FinanceRepository _repository;

  Future<void> call(FinanceEntryDraft draft) => _repository.addEntry(draft);
}
