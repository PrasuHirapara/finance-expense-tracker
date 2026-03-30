import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/transaction_type.dart';
import 'app_providers.dart';

part 'add_entry_form_controller.freezed.dart';

@freezed
abstract class AddEntryFormState with _$AddEntryFormState {
  const AddEntryFormState._();

  const factory AddEntryFormState({
    required TransactionType type,
    required String title,
    required String amountInput,
    int? selectedCategoryId,
    required String paymentMode,
    required DateTime date,
    required String notes,
    required String counterparty,
    required bool isSaving,
    required bool showValidation,
  }) = _AddEntryFormState;

  factory AddEntryFormState.initial() => AddEntryFormState(
    type: const TransactionType.expense(),
    title: '',
    amountInput: '',
    selectedCategoryId: null,
    paymentMode: AppConstants.paymentModes.first,
    date: DateTime.now(),
    notes: '',
    counterparty: '',
    isSaving: false,
    showValidation: false,
  );

  double? get parsedAmount => double.tryParse(amountInput);

  bool get hasValidAmount => (parsedAmount ?? 0) > 0;
  bool get hasValidTitle => title.trim().isNotEmpty;
  bool get canSubmit =>
      hasValidTitle &&
      hasValidAmount &&
      selectedCategoryId != null &&
      !isSaving;
}

class AddEntryFormController extends StateNotifier<AddEntryFormState> {
  AddEntryFormController(this._ref) : super(AddEntryFormState.initial());

  final Ref _ref;

  void setType(TransactionType value) => state = state.copyWith(type: value);
  void setTitle(String value) => state = state.copyWith(title: value);
  void setAmount(String value) => state = state.copyWith(amountInput: value);
  void setCategory(int? value) =>
      state = state.copyWith(selectedCategoryId: value);
  void setPaymentMode(String value) =>
      state = state.copyWith(paymentMode: value);
  void setDate(DateTime value) => state = state.copyWith(date: value);
  void setNotes(String value) => state = state.copyWith(notes: value);
  void setCounterparty(String value) =>
      state = state.copyWith(counterparty: value);

  void setDefaultCategoryIfMissing(List<FinanceCategory> categories) {
    if (state.selectedCategoryId == null && categories.isNotEmpty) {
      state = state.copyWith(selectedCategoryId: categories.first.id);
    }
  }

  Future<bool> submit() async {
    if (!state.canSubmit) {
      state = state.copyWith(showValidation: true);
      return false;
    }

    state = state.copyWith(isSaving: true, showValidation: true);

    await _ref
        .read(addFinanceEntryUseCaseProvider)
        .call(
          FinanceEntryDraft(
            title: state.title,
            amount: state.parsedAmount!,
            type: state.type,
            categoryId: state.selectedCategoryId!,
            date: state.date,
            paymentMode: state.paymentMode,
            notes: state.notes,
            counterparty: state.counterparty.trim().isEmpty
                ? null
                : state.counterparty.trim(),
          ),
        );

    _ref.invalidate(dashboardSnapshotProvider);
    _ref.invalidate(analyticsReportProvider);
    state = AddEntryFormState.initial();
    return true;
  }
}

final addEntryFormControllerProvider =
    StateNotifierProvider.autoDispose<
      AddEntryFormController,
      AddEntryFormState
    >((ref) => AddEntryFormController(ref));
