import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/services/company_category_service.dart';

class CompanyCategoryState {
  final List<Map<String, dynamic>> allCategories;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String searchQuery;

  const CompanyCategoryState({
    this.allCategories = const [],
    this.selectedIds = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.searchQuery = '',
  });

  CompanyCategoryState copyWith({
    List<Map<String, dynamic>>? allCategories,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? searchQuery,
  }) {
    return CompanyCategoryState(
      allCategories: allCategories ?? this.allCategories,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CompanyCategoryNotifier extends StateNotifier<CompanyCategoryState> {
  final CompanyCategoryService _service;

  CompanyCategoryNotifier(this._service) : super(const CompanyCategoryState()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _service.getAllCategoriesWithSelection();

      final selectedIds = <String>{};
      _collectSelectedIds(categories, selectedIds);

      state = state.copyWith(
        allCategories: categories,
        selectedIds: selectedIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _collectSelectedIds(List<Map<String, dynamic>> categories, Set<String> ids) {
    for (final cat in categories) {
      if (cat['isSelected'] == true) {
        ids.add(cat['id'].toString());
      }
      final children = cat['children'] as List<dynamic>? ?? [];
      _collectSelectedIds(children.cast<Map<String, dynamic>>(), ids);
    }
  }

  void toggleCategory(String categoryId) {
    final newSet = Set<String>.from(state.selectedIds);
    if (newSet.contains(categoryId)) {
      newSet.remove(categoryId);
      _collectDescendantIds(categoryId, state.allCategories, newSet, remove: true);
    } else {
      newSet.add(categoryId);
    }
    state = state.copyWith(selectedIds: newSet);
  }

  void _collectDescendantIds(
    String parentId,
    List<Map<String, dynamic>> categories,
    Set<String> ids, {
    required bool remove,
  }) {
    for (final cat in categories) {
      final id = cat['id'].toString();
      final children = (cat['children'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      if (id == parentId) {
        _applyToAllDescendants(children, ids, remove: remove);
        return;
      }
      _collectDescendantIds(parentId, children, ids, remove: remove);
    }
  }

  void _applyToAllDescendants(
    List<Map<String, dynamic>> categories,
    Set<String> ids, {
    required bool remove,
  }) {
    for (final cat in categories) {
      final id = cat['id'].toString();
      if (remove) {
        ids.remove(id);
      } else {
        ids.add(id);
      }
      final children = (cat['children'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _applyToAllDescendants(children, ids, remove: remove);
    }
  }

  void toggleAll(bool select) {
    if (select) {
      final allIds = <String>{};
      _collectAllIds(state.allCategories, allIds);
      state = state.copyWith(selectedIds: allIds);
    } else {
      state = state.copyWith(selectedIds: {});
    }
  }

  void _collectAllIds(List<Map<String, dynamic>> categories, Set<String> ids) {
    for (final cat in categories) {
      ids.add(cat['id'].toString());
      final children = cat['children'] as List<dynamic>? ?? [];
      _collectAllIds(children.cast<Map<String, dynamic>>(), ids);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> saveSelection() async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _service.bulkSetCategories(state.selectedIds.toList());
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}
