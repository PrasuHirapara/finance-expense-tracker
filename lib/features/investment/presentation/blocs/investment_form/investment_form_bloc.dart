import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/services/app_settings_repository.dart';
import '../../../data/repositories/investment_repository.dart';
import '../../../domain/models/investment_models.dart';

enum InvestmentFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

class InvestmentFormState extends Equatable {
  const InvestmentFormState({
    this.status = InvestmentFormStatus.initial,
    this.categories = const [],
    this.profiles = const [],
    this.categoryId,
    this.symbol = '',
    this.qty,
    this.buyDate,
    this.buyRate,
    this.buyAmt,
    this.isBuyAmtOverridden = false,
    this.taxProfileId,
    this.notes,
    this.sellDate,
    this.sellRate,
    this.sellQty,
    this.sellAmt,
    this.isSellAmtOverridden = false,
    this.showValidation = false,
    this.errorMessage,
    this.existingId,
    this.soldQty = 0.0,
  });

  final InvestmentFormStatus status;
  final List<InvestmentCategory> categories;
  final List<TaxProfile> profiles;
  final int? categoryId;
  final String symbol;
  final double? qty;
  final DateTime? buyDate;
  final double? buyRate;
  final double? buyAmt;
  final bool isBuyAmtOverridden;
  final int? taxProfileId;
  final String? notes;
  final int? existingId;
  final double soldQty;

  // Sell form fields
  final DateTime? sellDate;
  final double? sellRate;
  final double? sellQty;
  final double? sellAmt;
  final bool isSellAmtOverridden;

  final bool showValidation;
  final String? errorMessage;

  bool get isBuyValid =>
      categoryId != null &&
      symbol.trim().isNotEmpty &&
      qty != null &&
      qty! > 0 &&
      qty! >= soldQty &&
      buyDate != null &&
      buyRate != null &&
      buyRate! >= 0;

  // Always use qty*rate; override is removed.

  bool get isSellValid =>
      sellDate != null &&
      sellRate != null &&
      sellRate! >= 0 &&
      sellQty != null &&
      sellQty! > 0 &&
      sellAmt != null &&
      sellAmt! >= 0;

  double get computedBuyAmt => (qty ?? 0.0) * (buyRate ?? 0.0);
  double get computedSellAmt => (sellQty ?? 0.0) * (sellRate ?? 0.0);

  InvestmentFormState copyWith({
    InvestmentFormStatus? status,
    List<InvestmentCategory>? categories,
    List<TaxProfile>? profiles,
    int? categoryId,
    bool clearCategory = false,
    String? symbol,
    double? qty,
    bool clearQty = false,
    DateTime? buyDate,
    double? buyRate,
    bool clearBuyRate = false,
    double? buyAmt,
    bool? isBuyAmtOverridden,
    int? taxProfileId,
    bool clearTaxProfile = false,
    String? notes,
    bool clearNotes = false,
    DateTime? sellDate,
    double? sellRate,
    bool clearSellRate = false,
    double? sellQty,
    bool clearSellQty = false,
    double? sellAmt,
    bool? isSellAmtOverridden,
    bool? showValidation,
    String? errorMessage,
    int? existingId,
    bool clearExistingId = false,
    double? soldQty,
  }) {
    return InvestmentFormState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      profiles: profiles ?? this.profiles,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      symbol: symbol ?? this.symbol,
      qty: clearQty ? null : qty ?? this.qty,
      buyDate: buyDate ?? this.buyDate,
      buyRate: clearBuyRate ? null : buyRate ?? this.buyRate,
      buyAmt: buyAmt ?? this.buyAmt,
      isBuyAmtOverridden: isBuyAmtOverridden ?? this.isBuyAmtOverridden,
      taxProfileId: clearTaxProfile ? null : taxProfileId ?? this.taxProfileId,
      notes: clearNotes ? null : notes ?? this.notes,
      sellDate: sellDate ?? this.sellDate,
      sellRate: clearSellRate ? null : sellRate ?? this.sellRate,
      sellQty: clearSellQty ? null : sellQty ?? this.sellQty,
      sellAmt: sellAmt ?? this.sellAmt,
      isSellAmtOverridden: isSellAmtOverridden ?? this.isSellAmtOverridden,
      showValidation: showValidation ?? this.showValidation,
      errorMessage: errorMessage,
      existingId: clearExistingId ? null : existingId ?? this.existingId,
      soldQty: soldQty ?? this.soldQty,
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    profiles,
    categoryId,
    symbol,
    qty,
    buyDate,
    buyRate,
    buyAmt,
    isBuyAmtOverridden,
    taxProfileId,
    notes,
    sellDate,
    sellRate,
    sellQty,
    sellAmt,
    isSellAmtOverridden,
    showValidation,
    errorMessage,
    existingId,
    soldQty,
  ];
}

sealed class InvestmentFormEvent extends Equatable {
  const InvestmentFormEvent();

  @override
  List<Object?> get props => [];
}

class InvestmentFormInit extends InvestmentFormEvent {
  const InvestmentFormInit({this.existingEntry, this.defaultTaxProfileId});

  final InvestmentEntry? existingEntry;
  final int? defaultTaxProfileId;

  @override
  List<Object?> get props => [existingEntry, defaultTaxProfileId];
}

class InvestmentFormCategoryChanged extends InvestmentFormEvent {
  const InvestmentFormCategoryChanged(this.categoryId);
  final int categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class InvestmentFormSymbolChanged extends InvestmentFormEvent {
  const InvestmentFormSymbolChanged(this.symbol);
  final String symbol;

  @override
  List<Object?> get props => [symbol];
}

class InvestmentFormQtyChanged extends InvestmentFormEvent {
  const InvestmentFormQtyChanged(this.qty);
  final double? qty;

  @override
  List<Object?> get props => [qty];
}

class InvestmentFormBuyDateChanged extends InvestmentFormEvent {
  const InvestmentFormBuyDateChanged(this.buyDate);
  final DateTime buyDate;

  @override
  List<Object?> get props => [buyDate];
}

class InvestmentFormBuyRateChanged extends InvestmentFormEvent {
  const InvestmentFormBuyRateChanged(this.buyRate);
  final double? buyRate;

  @override
  List<Object?> get props => [buyRate];
}

class InvestmentFormBuyAmtChanged extends InvestmentFormEvent {
  const InvestmentFormBuyAmtChanged(this.buyAmt);
  final double? buyAmt;

  @override
  List<Object?> get props => [buyAmt];
}

class InvestmentFormBuyAmtOverrideToggled extends InvestmentFormEvent {
  const InvestmentFormBuyAmtOverrideToggled();
}

class InvestmentFormBrokerChanged extends InvestmentFormEvent {
  const InvestmentFormBrokerChanged(this.taxProfileId);
  final int? taxProfileId;

  @override
  List<Object?> get props => [taxProfileId];
}

class InvestmentFormNotesChanged extends InvestmentFormEvent {
  const InvestmentFormNotesChanged(this.notes);
  final String notes;

  @override
  List<Object?> get props => [notes];
}

class InvestmentFormBuySubmitted extends InvestmentFormEvent {
  const InvestmentFormBuySubmitted({this.existingId});
  final int? existingId;

  @override
  List<Object?> get props => [existingId];
}

// Sell entry specific events
class InvestmentFormSellInit extends InvestmentFormEvent {
  const InvestmentFormSellInit({
    required this.buyEntryId,
    required this.symbol,
    required this.remainingUnsoldQty,
  });

  final int buyEntryId;
  final String symbol;
  final double remainingUnsoldQty;

  @override
  List<Object?> get props => [buyEntryId, symbol, remainingUnsoldQty];
}

class InvestmentFormSellDateChanged extends InvestmentFormEvent {
  const InvestmentFormSellDateChanged(this.sellDate);
  final DateTime sellDate;

  @override
  List<Object?> get props => [sellDate];
}

class InvestmentFormSellRateChanged extends InvestmentFormEvent {
  const InvestmentFormSellRateChanged(this.sellRate);
  final double? sellRate;

  @override
  List<Object?> get props => [sellRate];
}

class InvestmentFormSellQtyChanged extends InvestmentFormEvent {
  const InvestmentFormSellQtyChanged(this.sellQty);
  final double? sellQty;

  @override
  List<Object?> get props => [sellQty];
}

class InvestmentFormSellAmtChanged extends InvestmentFormEvent {
  const InvestmentFormSellAmtChanged(this.sellAmt);
  final double? sellAmt;

  @override
  List<Object?> get props => [sellAmt];
}

class InvestmentFormSellAmtOverrideToggled extends InvestmentFormEvent {
  const InvestmentFormSellAmtOverrideToggled();
}

class InvestmentFormSellSubmitted extends InvestmentFormEvent {
  const InvestmentFormSellSubmitted({
    required this.buyEntryId,
    required this.symbol,
  });
  final int buyEntryId;
  final String symbol;

  @override
  List<Object?> get props => [buyEntryId, symbol];
}

class InvestmentFormBloc
    extends Bloc<InvestmentFormEvent, InvestmentFormState> {
  InvestmentFormBloc(this._repository, this._settingsRepository)
    : super(const InvestmentFormState()) {
    on<InvestmentFormInit>(_onInit);
    on<InvestmentFormCategoryChanged>(_onCategoryChanged);
    on<InvestmentFormSymbolChanged>(_onSymbolChanged);
    on<InvestmentFormQtyChanged>(_onQtyChanged);
    on<InvestmentFormBuyDateChanged>(_onBuyDateChanged);
    on<InvestmentFormBuyRateChanged>(_onBuyRateChanged);
    on<InvestmentFormBuyAmtChanged>(_onBuyAmtChanged);
    on<InvestmentFormBuyAmtOverrideToggled>(_onBuyAmtOverrideToggled);
    on<InvestmentFormBrokerChanged>(_onBrokerChanged);
    on<InvestmentFormNotesChanged>(_onNotesChanged);
    on<InvestmentFormBuySubmitted>(_onBuySubmitted);

    on<InvestmentFormSellInit>(_onSellInit);
    on<InvestmentFormSellDateChanged>(_onSellDateChanged);
    on<InvestmentFormSellRateChanged>(_onSellRateChanged);
    on<InvestmentFormSellQtyChanged>(_onSellQtyChanged);
    on<InvestmentFormSellAmtChanged>(_onSellAmtChanged);
    on<InvestmentFormSellAmtOverrideToggled>(_onSellAmtOverrideToggled);
    on<InvestmentFormSellSubmitted>(_onSellSubmitted);
  }

  final InvestmentRepository _repository;
  final AppSettingsRepository _settingsRepository;

  Future<void> _onInit(
    InvestmentFormInit event,
    Emitter<InvestmentFormState> emit,
  ) async {
    emit(state.copyWith(status: InvestmentFormStatus.loading));
    try {
      final categories = await _repository.getCategories();
      final profiles = await _repository.getTaxProfiles();

      if (event.existingEntry != null) {
        final entry = event.existingEntry!;
        final sells = await _repository.getSellEntries();
        final soldQty = sells
            .where((s) => s.buyEntryId == entry.id)
            .fold<double>(0.0, (sum, s) => sum + s.sellQty);
        emit(
          state.copyWith(
            status: InvestmentFormStatus.ready,
            categories: categories,
            profiles: profiles,
            categoryId: entry.categoryId,
            symbol: entry.symbol,
            qty: entry.qty,
            buyDate: entry.buyDate,
            buyRate: entry.buyRate,
            buyAmt: entry.buyAmt,
            isBuyAmtOverridden:
                (entry.buyAmt - (entry.qty * entry.buyRate)).abs() > 0.01,
            taxProfileId: entry.taxProfileId,
            notes: entry.notes,
            existingId: entry.id,
            soldQty: soldQty,
          ),
        );
      } else {
        // Resolve saved default broker from settings.
        final settings = await _settingsRepository.getSettings();
        int? defaultBrokerId =
            event.defaultTaxProfileId ?? settings.selectedInvestmentBrokerId;
        // Validate the saved broker still exists.
        if (defaultBrokerId != null &&
            !profiles.any((p) => p.id == defaultBrokerId)) {
          defaultBrokerId = profiles.isNotEmpty ? profiles.first.id : null;
        }

        // Resolve saved default category from settings.
        int? defaultCategoryId = settings.selectedInvestmentCategoryId;
        if (defaultCategoryId == null ||
            !categories.any((c) => c.id == defaultCategoryId)) {
          defaultCategoryId = categories.isNotEmpty
              ? categories.first.id
              : null;
        }

        emit(
          state.copyWith(
            status: InvestmentFormStatus.ready,
            categories: categories,
            profiles: profiles,
            categoryId: defaultCategoryId,
            buyDate: DateTime.now(),
            buyAmt: 0.0,
            taxProfileId: defaultBrokerId,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: InvestmentFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onCategoryChanged(
    InvestmentFormCategoryChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    _settingsRepository.updateSelectedInvestmentCategoryId(event.categoryId);
    emit(state.copyWith(categoryId: event.categoryId));
  }

  void _onSymbolChanged(
    InvestmentFormSymbolChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    emit(state.copyWith(symbol: event.symbol));
  }

  void _onQtyChanged(
    InvestmentFormQtyChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    final qty = event.qty;
    emit(
      state.copyWith(
        qty: qty,
        clearQty: qty == null,
        buyAmt: state.isBuyAmtOverridden
            ? state.buyAmt
            : (qty ?? 0.0) * (state.buyRate ?? 0.0),
      ),
    );
  }

  void _onBuyDateChanged(
    InvestmentFormBuyDateChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    emit(state.copyWith(buyDate: event.buyDate));
  }

  void _onBuyRateChanged(
    InvestmentFormBuyRateChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    final buyRate = event.buyRate;
    emit(
      state.copyWith(
        buyRate: buyRate,
        clearBuyRate: buyRate == null,
        buyAmt: state.isBuyAmtOverridden
            ? state.buyAmt
            : (state.qty ?? 0.0) * (buyRate ?? 0.0),
      ),
    );
  }

  void _onBuyAmtChanged(
    InvestmentFormBuyAmtChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    emit(state.copyWith(buyAmt: event.buyAmt));
  }

  void _onBuyAmtOverrideToggled(
    InvestmentFormBuyAmtOverrideToggled event,
    Emitter<InvestmentFormState> emit,
  ) {
    final nextOverride = !state.isBuyAmtOverridden;
    emit(
      state.copyWith(
        isBuyAmtOverridden: nextOverride,
        buyAmt: nextOverride
            ? state.buyAmt ?? state.computedBuyAmt
            : state.computedBuyAmt,
      ),
    );
  }

  void _onBrokerChanged(
    InvestmentFormBrokerChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    // Persist broker selection for next time.
    _settingsRepository.updateSelectedInvestmentBrokerId(event.taxProfileId);
    emit(
      state.copyWith(
        taxProfileId: event.taxProfileId,
        clearTaxProfile: event.taxProfileId == null,
      ),
    );
  }

  void _onNotesChanged(
    InvestmentFormNotesChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    emit(state.copyWith(notes: event.notes));
  }

  Future<void> _onBuySubmitted(
    InvestmentFormBuySubmitted event,
    Emitter<InvestmentFormState> emit,
  ) async {
    if (!state.isBuyValid) {
      emit(state.copyWith(showValidation: true));
      return;
    }

    emit(state.copyWith(status: InvestmentFormStatus.submitting));
    try {
      final existingId = event.existingId ?? state.existingId;
      if (existingId != null) {
        await _repository.updateBuyEntry(
          id: existingId,
          categoryId: state.categoryId!,
          symbol: state.symbol,
          qty: state.qty!,
          buyDate: state.buyDate!,
          buyRate: state.buyRate!,
          buyAmt: state.buyAmt ?? state.computedBuyAmt,
          taxProfileId: state.taxProfileId,
          notes: state.notes,
        );
      } else {
        await _repository.insertBuyEntry(
          categoryId: state.categoryId!,
          symbol: state.symbol,
          qty: state.qty!,
          buyDate: state.buyDate!,
          buyRate: state.buyRate!,
          buyAmt: state.computedBuyAmt,
          taxProfileId: state.taxProfileId,
          notes: state.notes,
        );
      }
      emit(state.copyWith(status: InvestmentFormStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: InvestmentFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // Sell implementations
  Future<void> _onSellInit(
    InvestmentFormSellInit event,
    Emitter<InvestmentFormState> emit,
  ) async {
    emit(state.copyWith(status: InvestmentFormStatus.loading));
    try {
      final profiles = await _repository.getTaxProfiles();
      emit(
        state.copyWith(
          status: InvestmentFormStatus.ready,
          profiles: profiles,
          symbol: event.symbol,
          sellQty: event.remainingUnsoldQty,
          sellDate: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InvestmentFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onSellDateChanged(
    InvestmentFormSellDateChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    emit(state.copyWith(sellDate: event.sellDate));
  }

  void _onSellRateChanged(
    InvestmentFormSellRateChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    final rate = event.sellRate;
    emit(
      state.copyWith(
        sellRate: rate,
        clearSellRate: rate == null,
        sellAmt: state.isSellAmtOverridden
            ? state.sellAmt
            : (state.sellQty ?? 0.0) * (rate ?? 0.0),
      ),
    );
  }

  void _onSellQtyChanged(
    InvestmentFormSellQtyChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    final qty = event.sellQty;
    emit(
      state.copyWith(
        sellQty: qty,
        clearSellQty: qty == null,
        sellAmt: state.isSellAmtOverridden
            ? state.sellAmt
            : (qty ?? 0.0) * (state.sellRate ?? 0.0),
      ),
    );
  }

  void _onSellAmtChanged(
    InvestmentFormSellAmtChanged event,
    Emitter<InvestmentFormState> emit,
  ) {
    emit(state.copyWith(sellAmt: event.sellAmt));
  }

  void _onSellAmtOverrideToggled(
    InvestmentFormSellAmtOverrideToggled event,
    Emitter<InvestmentFormState> emit,
  ) {
    final nextOverride = !state.isSellAmtOverridden;
    emit(
      state.copyWith(
        isSellAmtOverridden: nextOverride,
        sellAmt: nextOverride
            ? state.sellAmt ?? state.computedSellAmt
            : state.computedSellAmt,
      ),
    );
  }

  Future<void> _onSellSubmitted(
    InvestmentFormSellSubmitted event,
    Emitter<InvestmentFormState> emit,
  ) async {
    if (!state.isSellValid) {
      emit(state.copyWith(showValidation: true));
      return;
    }

    emit(state.copyWith(status: InvestmentFormStatus.submitting));
    try {
      await _repository.insertSellEntry(
        buyEntryId: event.buyEntryId,
        symbol: event.symbol,
        sellQty: state.sellQty!,
        sellDate: state.sellDate!,
        sellRate: state.sellRate!,
        sellAmt: state.sellAmt ?? state.computedSellAmt,
      );
      emit(state.copyWith(status: InvestmentFormStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: InvestmentFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
