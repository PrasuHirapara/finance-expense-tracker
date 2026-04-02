import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import 'task_repository.dart';

class TaskCategoryRepository {
  TaskCategoryRepository(this._taskRepository);

  final TaskRepository _taskRepository;
  final StreamController<List<String>> _controller =
      StreamController<List<String>>.broadcast();

  List<String>? _cachedCategories;

  Stream<List<String>> watchCategories() async* {
    final categories = await getCategories();
    yield categories;
    yield* _controller.stream;
  }

  Future<List<String>> getCategories() async {
    if (_cachedCategories != null) {
      return List<String>.from(_cachedCategories!);
    }

    final file = await _categoriesFile();
    if (!await file.exists()) {
      _cachedCategories = List<String>.from(AppConstants.taskCategoryChoices);
      await _writeCategories(_cachedCategories!);
      return List<String>.from(_cachedCategories!);
    }

    final content = await file.readAsString();
    final decoded = (jsonDecode(content) as List<dynamic>)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    _cachedCategories = decoded.isEmpty
        ? List<String>.from(AppConstants.taskCategoryChoices)
        : decoded;

    return List<String>.from(_cachedCategories!);
  }

  Future<void> ensureSeeded() async {
    await getCategories();
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final categories = await getCategories();
    if (_containsIgnoreCase(categories, trimmed)) {
      return;
    }

    categories.add(trimmed);
    await _commit(categories);
  }

  Future<void> updateCategory({
    required String oldName,
    required String newName,
  }) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final categories = await getCategories();
    final index = categories.indexWhere(
      (category) => category.toLowerCase() == oldName.toLowerCase(),
    );
    if (index == -1) {
      return;
    }

    final hasDuplicate = categories.any(
      (category) =>
          category.toLowerCase() == trimmed.toLowerCase() &&
          category.toLowerCase() != oldName.toLowerCase(),
    );
    if (hasDuplicate) {
      return;
    }

    categories[index] = trimmed;
    await _taskRepository.renameCategory(oldName: oldName, newName: trimmed);
    await _commit(categories);
  }

  Future<void> deleteCategory(String name) async {
    final categories = await getCategories();
    if (categories.length <= 1) {
      return;
    }

    final remaining = categories
        .where((category) => category.toLowerCase() != name.toLowerCase())
        .toList(growable: false);
    if (remaining.length == categories.length) {
      return;
    }

    final fallbackCategory = remaining.first;
    await _taskRepository.replaceCategory(
      oldName: name,
      replacement: fallbackCategory,
    );
    await _commit(remaining);
  }

  Future<void> resetToDefaults() async {
    await _commit(List<String>.from(AppConstants.taskCategoryChoices));
  }

  Future<void> replaceAll(List<String> categories) async {
    final sanitized = categories
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    await _commit(
      sanitized.isEmpty
          ? List<String>.from(AppConstants.taskCategoryChoices)
          : sanitized,
    );
  }

  Future<DateTime?> lastModifiedAt() async {
    final file = await _categoriesFile();
    if (!await file.exists()) {
      return null;
    }
    return file.lastModified();
  }

  Future<void> _commit(List<String> categories) async {
    _cachedCategories = categories.toSet().toList(growable: false);
    await _writeCategories(_cachedCategories!);
    _controller.add(List<String>.from(_cachedCategories!));
  }

  Future<void> _writeCategories(List<String> categories) async {
    final file = await _categoriesFile();
    await file.writeAsString(jsonEncode(categories));
  }

  Future<File> _categoriesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, 'task_categories.json'));
  }

  bool _containsIgnoreCase(List<String> categories, String target) {
    return categories.any(
      (category) => category.toLowerCase() == target.toLowerCase(),
    );
  }
}
