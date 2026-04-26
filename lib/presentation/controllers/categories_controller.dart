import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/finance_category.dart';
import '../../domain/repositories/finance_repository.dart';

const Object _categoriesUnset = Object();

enum CategoriesStatus { loading, ready, saving, failure }

class CategoriesState extends Equatable {
  const CategoriesState({
    this.status = CategoriesStatus.loading,
    this.categories = const <FinanceCategory>[],
    this.errorMessage,
  });

  final CategoriesStatus status;
  final List<FinanceCategory> categories;
  final String? errorMessage;

  bool get isLoading => status == CategoriesStatus.loading;
  bool get isSaving => status == CategoriesStatus.saving;

  CategoriesState copyWith({
    CategoriesStatus? status,
    List<FinanceCategory>? categories,
    Object? errorMessage = _categoriesUnset,
  }) {
    return CategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: identical(errorMessage, _categoriesUnset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, categories, errorMessage];
}

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState());

  final FinanceRepository _repository;
  StreamSubscription<List<FinanceCategory>>? _categoriesSubscription;

  void initialize() {
    _categoriesSubscription ??= _repository.watchCategories().listen(
      (categories) {
        emit(
          state.copyWith(
            status: CategoriesStatus.ready,
            categories: categories,
            errorMessage: null,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(
          state.copyWith(
            status: CategoriesStatus.failure,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  Future<void> addCategory({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    emit(state.copyWith(status: CategoriesStatus.saving, errorMessage: null));
    try {
      await _repository.addCategory(
        name: name,
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
      );
      emit(state.copyWith(status: CategoriesStatus.ready, errorMessage: null));
    } catch (error) {
      emit(
        state.copyWith(
          status: CategoriesStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _categoriesSubscription?.cancel();
    return super.close();
  }
}
