import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../domain/models/expense_models.dart';

class ExpenseFormState extends Equatable {
  const ExpenseFormState({
    this.status = ExpenseFormStatus.initial,
    this.expenseId,
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
    this.splitDraft,
    this.lentResolutionDraft,
    this.showValidation = false,
    this.errorMessage,
  });

  final ExpenseFormStatus status;
  final int? expenseId;
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
  final ExpenseSplitDraft? splitDraft;
  final LentResolutionDraft? lentResolutionDraft;
  final bool showValidation;
  final String? errorMessage;

  double? get parsedAmount => double.tryParse(amount);
  ExpenseCategory? get selectedCategory {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  bool get isLentIncome =>
      type == 'income' && selectedCategory?.name.toLowerCase() == 'lent';

  bool get canConfigureSplit => type == 'expense' && (parsedAmount ?? 0) > 0;
  bool get canResolveLent => isLentIncome && (parsedAmount ?? 0) > 0;
  bool get isValid =>
      title.trim().isNotEmpty &&
      (parsedAmount ?? 0) > 0 &&
      categoryId != null &&
      date != null;
  bool get isEditing => expenseId != null;

  ExpenseFormState copyWith({
    ExpenseFormStatus? status,
    int? expenseId,
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
    ExpenseSplitDraft? splitDraft,
    bool clearSplitDraft = false,
    LentResolutionDraft? lentResolutionDraft,
    bool clearLentResolutionDraft = false,
    bool? showValidation,
    String? errorMessage,
  }) {
    return ExpenseFormState(
      status: status ?? this.status,
      expenseId: expenseId ?? this.expenseId,
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
      splitDraft: clearSplitDraft ? null : splitDraft ?? this.splitDraft,
      lentResolutionDraft: clearLentResolutionDraft
          ? null
          : lentResolutionDraft ?? this.lentResolutionDraft,
      showValidation: showValidation ?? this.showValidation,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    expenseId,
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
    splitDraft,
    lentResolutionDraft,
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
  const ExpenseFormInitialized({this.existingExpense});

  final ExpenseRecord? existingExpense;

  @override
  List<Object?> get props => <Object?>[existingExpense];
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

class ExpenseSplitDraftChanged extends ExpenseFormEvent {
  const ExpenseSplitDraftChanged(this.value);

  final ExpenseSplitDraft? value;

  @override
  List<Object?> get props => <Object?>[value];
}

class ExpenseLentResolutionChanged extends ExpenseFormEvent {
  const ExpenseLentResolutionChanged(this.value);

  final LentResolutionDraft? value;

  @override
  List<Object?> get props => <Object?>[value];
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
      (event, emit) => emit(
        state.copyWith(
          type: event.value,
          clearSplitDraft:
              event.value != 'expense' && state.splitDraft != null,
          clearLentResolutionDraft:
              event.value != 'income' && state.lentResolutionDraft != null,
        ),
      ),
    );
    on<ExpenseTitleChanged>(
      (event, emit) => emit(state.copyWith(title: event.value)),
    );
    on<ExpenseAmountChanged>(_onAmountChanged);
    on<ExpenseCategoryChanged>(_onCategoryChanged);
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
    on<ExpenseSplitDraftChanged>(
      (event, emit) => emit(
        event.value == null
            ? state.copyWith(clearSplitDraft: true)
            : state.copyWith(splitDraft: event.value),
      ),
    );
    on<ExpenseLentResolutionChanged>(
      (event, emit) => emit(
        event.value == null
            ? state.copyWith(clearLentResolutionDraft: true)
            : state.copyWith(lentResolutionDraft: event.value),
      ),
    );
    on<ExpenseSubmitted>(_onSubmitted);
  }

  final ExpenseRepository _repository;

  Future<void> _onInitialized(
    ExpenseFormInitialized event,
    Emitter<ExpenseFormState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseFormStatus.loading));
    await _repository.ensureLentCategory();
    final categories = await _repository.watchCategories().first;
    final banks = await _repository.watchBanks().first;
    final splitDraft = event.existingExpense == null
        ? null
        : await _repository.loadSplitDraftForEntry(event.existingExpense!.id);
    emit(
      state.copyWith(
        status: ExpenseFormStatus.ready,
        expenseId: event.existingExpense?.id,
        categories: categories,
        banks: banks,
        type: event.existingExpense?.type ?? state.type,
        title: event.existingExpense?.title ?? state.title,
        amount: _formatAmount(splitDraft?.totalAmount ?? event.existingExpense?.amount),
        categoryId:
            event.existingExpense?.category.id ??
            (categories.isEmpty ? null : categories.first.id),
        bankId: event.existingExpense?.bank?.id,
        paymentMode:
            event.existingExpense?.paymentMode ?? state.paymentMode,
        date: event.existingExpense?.date ?? state.date,
        notes: event.existingExpense?.notes ?? state.notes,
        counterparty:
            event.existingExpense?.counterparty ?? state.counterparty,
        splitDraft: splitDraft,
        clearLentResolutionDraft: true,
      ),
    );
  }

  void _onAmountChanged(
    ExpenseAmountChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    final nextAmount = double.tryParse(event.value);
    final shouldClearSplit =
        state.splitDraft != null &&
        nextAmount != null &&
        !_matchesAmount(state.splitDraft!.totalAmount, nextAmount);
    emit(
      state.copyWith(
        amount: event.value,
        clearSplitDraft: shouldClearSplit,
        clearLentResolutionDraft: state.lentResolutionDraft != null,
      ),
    );
  }

  void _onCategoryChanged(
    ExpenseCategoryChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    ExpenseCategory? category;
    for (final item in state.categories) {
      if (item.id == event.value) {
        category = item;
        break;
      }
    }
    final shouldClearResolution =
        category?.name.toLowerCase() != 'lent' && state.lentResolutionDraft != null;
    emit(
      state.copyWith(
        categoryId: event.value,
        clearLentResolutionDraft: shouldClearResolution,
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
      final splitDraft = state.splitDraft == null || !state.canConfigureSplit
          ? null
          : state.splitDraft!.copyWith(totalAmount: state.parsedAmount!);
      final draft = ExpenseDraft(
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
        splitDraft: splitDraft,
        lentResolutionDraft: state.canResolveLent
            ? state.lentResolutionDraft
            : null,
      );
      if (state.isEditing) {
        await _repository.updateExpense(id: state.expenseId!, draft: draft);
      } else {
        await _repository.addExpense(draft);
      }
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

  String _formatAmount(double? amount) {
    if (amount == null) {
      return state.amount;
    }
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toString();
  }

  bool _matchesAmount(double left, double right) => (left - right).abs() <= 0.01;
}
