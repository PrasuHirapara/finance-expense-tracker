import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/finance_category.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/finance_repository.dart';

const Object _unset = Object();

enum AddEntryFormStatus { loading, ready, submitting, success, failure }

class AddEntryFormState extends Equatable {
  const AddEntryFormState({
    required this.status,
    required this.categories,
    required this.type,
    required this.title,
    required this.amountInput,
    required this.selectedCategoryId,
    required this.paymentMode,
    required this.date,
    required this.notes,
    required this.counterparty,
    required this.showValidation,
    this.errorMessage,
  });

  factory AddEntryFormState.initial() => AddEntryFormState(
    status: AddEntryFormStatus.loading,
    categories: const <FinanceCategory>[],
    type: const TransactionType.expense(),
    title: '',
    amountInput: '',
    selectedCategoryId: null,
    paymentMode: AppConstants.paymentModes.first,
    date: DateTime.now(),
    notes: '',
    counterparty: '',
    showValidation: false,
  );

  final AddEntryFormStatus status;
  final List<FinanceCategory> categories;
  final TransactionType type;
  final String title;
  final String amountInput;
  final int? selectedCategoryId;
  final String paymentMode;
  final DateTime date;
  final String notes;
  final String counterparty;
  final bool showValidation;
  final String? errorMessage;

  double? get parsedAmount => double.tryParse(amountInput);

  bool get hasValidAmount => (parsedAmount ?? 0) > 0;
  bool get hasValidTitle => title.trim().isNotEmpty;
  bool get isSaving => status == AddEntryFormStatus.submitting;
  bool get isLoading => status == AddEntryFormStatus.loading;
  bool get canSubmit =>
      hasValidTitle &&
      hasValidAmount &&
      selectedCategoryId != null &&
      !isSaving &&
      !isLoading;

  AddEntryFormState copyWith({
    AddEntryFormStatus? status,
    List<FinanceCategory>? categories,
    TransactionType? type,
    String? title,
    String? amountInput,
    Object? selectedCategoryId = _unset,
    String? paymentMode,
    DateTime? date,
    String? notes,
    String? counterparty,
    bool? showValidation,
    Object? errorMessage = _unset,
  }) {
    return AddEntryFormState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      type: type ?? this.type,
      title: title ?? this.title,
      amountInput: amountInput ?? this.amountInput,
      selectedCategoryId: identical(selectedCategoryId, _unset)
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      paymentMode: paymentMode ?? this.paymentMode,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      counterparty: counterparty ?? this.counterparty,
      showValidation: showValidation ?? this.showValidation,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    categories,
    type,
    title,
    amountInput,
    selectedCategoryId,
    paymentMode,
    date,
    notes,
    counterparty,
    showValidation,
    errorMessage,
  ];
}

class AddEntryFormCubit extends Cubit<AddEntryFormState> {
  AddEntryFormCubit(this._repository) : super(AddEntryFormState.initial());

  final FinanceRepository _repository;
  StreamSubscription<List<FinanceCategory>>? _categoriesSubscription;

  void initialize() {
    _categoriesSubscription ??= _repository.watchCategories().listen(
      _onCategoriesChanged,
      onError: (Object error, StackTrace stackTrace) {
        emit(
          state.copyWith(
            status: AddEntryFormStatus.failure,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  void _onCategoriesChanged(List<FinanceCategory> categories) {
    final hasCurrentSelection =
        state.selectedCategoryId != null &&
        categories.any((category) => category.id == state.selectedCategoryId);
    final nextCategoryId = hasCurrentSelection
        ? state.selectedCategoryId
        : categories.isEmpty
        ? null
        : categories.first.id;

    emit(
      state.copyWith(
        status: AddEntryFormStatus.ready,
        categories: categories,
        selectedCategoryId: nextCategoryId,
        errorMessage: null,
      ),
    );
  }

  void setType(TransactionType value) => emit(state.copyWith(type: value));
  void setTitle(String value) => emit(state.copyWith(title: value));
  void setAmount(String value) => emit(state.copyWith(amountInput: value));
  void setCategory(int? value) =>
      emit(state.copyWith(selectedCategoryId: value));
  void setPaymentMode(String value) => emit(state.copyWith(paymentMode: value));
  void setDate(DateTime value) => emit(state.copyWith(date: value));
  void setNotes(String value) => emit(state.copyWith(notes: value));
  void setCounterparty(String value) =>
      emit(state.copyWith(counterparty: value));

  Future<bool> submit() async {
    if (!state.canSubmit) {
      emit(state.copyWith(showValidation: true));
      return false;
    }

    emit(
      state.copyWith(
        status: AddEntryFormStatus.submitting,
        showValidation: true,
        errorMessage: null,
      ),
    );

    try {
      await _repository.addEntry(
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
      emit(state.copyWith(status: AddEntryFormStatus.success));
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          status: AddEntryFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _categoriesSubscription?.cancel();
    return super.close();
  }
}
