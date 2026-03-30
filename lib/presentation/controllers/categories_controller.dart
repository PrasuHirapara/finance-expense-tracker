import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

class CategoriesController extends StateNotifier<AsyncValue<void>> {
  CategoriesController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> addCategory({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref
          .read(addCategoryUseCaseProvider)
          .call(
            name: name,
            colorValue: colorValue,
            iconCodePoint: iconCodePoint,
          );
      _ref.invalidate(categoriesProvider);
    });
  }
}

final categoriesControllerProvider =
    StateNotifierProvider<CategoriesController, AsyncValue<void>>(
      (ref) => CategoriesController(ref),
    );
