import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../domain/models/expense_models.dart';

class ExpenseFormState extends Equatable {
  const ExpenseFormState({
    this.status = ExpenseFormStatus.initial,
    this.type = 'expense',
    this.title = '',
    this.amount = '',
    this.categoryId,
    this.bankId,
    this.paymentMode = 'Cash',
    this.date,
    this.notes = '',
    this.counterparty = '',
    this.categories = const <ExpenseCategory>[],
    this.banks = const <BankName>[],
    this.showValidation = false,
    this.errorMessage,
  });

  final ExpenseFormStatus status;
  final String type;
  final String title;
  final String amount;
  final int? categoryId;
  final int? bankId;
  final String paymentMode;
  final DateTime? date;
  final String notes;
  final String counterparty;
  final List<ExpenseCategory> categories;
  final List<BankName> banks;
  final bool showValidation;
  final String? errorMessage;

  double? get parsedAmount => double.tryParse(amount);
  bool get isValid =>
      title.trim().isNotEmpty &&
      (parsedAmount ?? 0) > 0 &&
      categoryId != null &&
      date != null;

  ExpenseFormState copyWith({
    ExpenseFormStatus? status,
    String? type,
    String? title,
    String? amount,
    int? categoryId,
    bool clearCategory = false,
    int? bankId,
    bool clearBank = false,
    String? paymentMode,
    DateTime? date,
    String? notes,
    String? counterparty,
    List<ExpenseCategory>? categories,
    List<BankName>? banks,
    bool? showValidation,
    String? errorMessage,
  }) {
    return ExpenseFormState(
      status: status ?? this.status,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      bankId: clearBank ? null : bankId ?? this.bankId,
      paymentMode: paymentMode ?? this.paymentMode,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      counterparty: counterparty ?? this.counterparty,
      categories: categories ?? this.categories,
      banks: banks ?? this.banks,
      showValidation: showValidation ?? this.showValidation,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    type,
    title,
    amount,
    categoryId,
    bankId,
    paymentMode,
    date,
    notes,
    counterparty,
    categories,
    banks,
    showValidation,
    errorMessage,
  ];
}

enum ExpenseFormStatus { initial, loading, ready, submitting, success, failure }

sealed class ExpenseFormEvent extends Equatable {
  const ExpenseFormEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ExpenseFormInitialized extends ExpenseFormEvent {
  const ExpenseFormInitialized();
}

class ExpenseTypeChanged extends ExpenseFormEvent {
  const ExpenseTypeChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseTitleChanged extends ExpenseFormEvent {
  const ExpenseTitleChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseAmountChanged extends ExpenseFormEvent {
  const ExpenseAmountChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseCategoryChanged extends ExpenseFormEvent {
  const ExpenseCategoryChanged(this.value);
  final int? value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseBankChanged extends ExpenseFormEvent {
  const ExpenseBankChanged(this.value);
  final int? value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpensePaymentModeChanged extends ExpenseFormEvent {
  const ExpensePaymentModeChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseDateChanged extends ExpenseFormEvent {
  const ExpenseDateChanged(this.value);
  final DateTime value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseNotesChanged extends ExpenseFormEvent {
  const ExpenseNotesChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseCounterpartyChanged extends ExpenseFormEvent {
  const ExpenseCounterpartyChanged(this.value);
  final String value;
  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseSubmitted extends ExpenseFormEvent {
  const ExpenseSubmitted();
}

class ExpenseFormBloc extends Bloc<ExpenseFormEvent, ExpenseFormState> {
  ExpenseFormBloc(this._repository)
    : super(
        ExpenseFormState(
          paymentMode: AppConstants.paymentModes.first,
          date: DateTime.now(),
        ),
      ) {
    on<ExpenseFormInitialized>(_onInitialized);
    on<ExpenseTypeChanged>(
      (event, emit) => emit(state.copyWith(type: event.value)),
    );
    on<ExpenseTitleChanged>(
      (event, emit) => emit(state.copyWith(title: event.value)),
    );
    on<ExpenseAmountChanged>(
      (event, emit) => emit(state.copyWith(amount: event.value)),
    );
    on<ExpenseCategoryChanged>(
      (event, emit) => emit(state.copyWith(categoryId: event.value)),
    );
    on<ExpenseBankChanged>(
      (event, emit) => emit(
        event.value == null
            ? state.copyWith(clearBank: true)
            : state.copyWith(bankId: event.value),
      ),
    );
    on<ExpensePaymentModeChanged>(
      (event, emit) => emit(state.copyWith(paymentMode: event.value)),
    );
    on<ExpenseDateChanged>(
      (event, emit) => emit(state.copyWith(date: event.value)),
    );
    on<ExpenseNotesChanged>(
      (event, emit) => emit(state.copyWith(notes: event.value)),
    );
    on<ExpenseCounterpartyChanged>(
      (event, emit) => emit(state.copyWith(counterparty: event.value)),
    );
    on<ExpenseSubmitted>(_onSubmitted);
  }

  final ExpenseRepository _repository;

  Future<void> _onInitialized(
    ExpenseFormInitialized event,
    Emitter<ExpenseFormState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseFormStatus.loading));
    final categories = await _repository.watchCategories().first;
    final banks = await _repository.watchBanks().first;
    emit(
      state.copyWith(
        status: ExpenseFormStatus.ready,
        categories: categories,
        banks: banks,
        categoryId: categories.isEmpty ? null : categories.first.id,
      ),
    );
  }

  Future<void> _onSubmitted(
    ExpenseSubmitted event,
    Emitter<ExpenseFormState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(showValidation: true));
      return;
    }

    emit(
      state.copyWith(
        status: ExpenseFormStatus.submitting,
        showValidation: true,
        errorMessage: null,
      ),
    );

    try {
      await _repository.addExpense(
        ExpenseDraft(
          title: state.title,
          amount: state.parsedAmount!,
          type: state.type,
          categoryId: state.categoryId!,
          bankId: state.bankId,
          date: state.date!,
          paymentMode: state.paymentMode,
          notes: state.notes,
          counterparty: state.counterparty.trim().isEmpty
              ? null
              : state.counterparty.trim(),
        ),
      );
      emit(state.copyWith(status: ExpenseFormStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: ExpenseFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
