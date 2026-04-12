import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/services/company_category_service.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/providers/navigation_provider.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

// ============================================================
// Provider
// ============================================================

final companyCategoryProvider =
    StateNotifierProvider<CompanyCategoryNotifier, CompanyCategoryState>(
  (ref) => CompanyCategoryNotifier(ref.read(companyCategoryServiceProvider)),
);

class CompanyCategoryState {
  final List<Map<String, dynamic>> allCategories; // Global havuz (isSelected dahil)
  final Set<String> selectedIds;                  // Seçili kategori ID'leri
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

      // Zaten seçili olanları set'e ekle
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
      // Seçim kaldırılıyor → bu kategoriyi ve tüm alt torunlarını kaldır
      newSet.remove(categoryId);
      _collectDescendantIds(categoryId, state.allCategories, newSet, remove: true);
    } else {
      newSet.add(categoryId);
    }
    state = state.copyWith(selectedIds: newSet);
  }

  /// [parentId] kategorisinin tüm torun ID'lerini bulur.
  /// [remove] = true ise [ids] set'inden çıkarır, false ise ekler.
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
        // Bulundu — tüm torunları işle
        _applyToAllDescendants(children, ids, remove: remove);
        return;
      }
      // Bulunamadı — alt ağaçta aramaya devam et
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

// ============================================================
// Ekran
// ============================================================

class CompanyCategoryScreen extends ConsumerStatefulWidget {
  const CompanyCategoryScreen({super.key});

  @override
  ConsumerState<CompanyCategoryScreen> createState() =>
      _CompanyCategoryScreenState();
}

class _CompanyCategoryScreenState extends ConsumerState<CompanyCategoryScreen> {
  String Function(String) get t => i18nOf(ref);

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ekrana her dönüşte (navigate-back dahil) yeniden yükle.
    // Provider non-autoDispose olduğu için constructor tetiklenmez.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(companyCategoryProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Aynı menüye ikinci tıklamada da yenile
    ref.listen(navigationRefreshProvider, (prev, next) {
      if (next.route == '/categories/company-setup') {
        ref.read(companyCategoryProvider.notifier).loadCategories();
      }
    });

    final state = ref.watch(companyCategoryProvider);
    final notifier = ref.read(companyCategoryProvider.notifier);

    return AppScaffold(
      appBar: _buildAppBar(state, notifier),
      body: _buildBody(state, notifier),
      bottomNavigationBar: _buildBottomBar(state, notifier),
    );
  }

  // ----------------------------------------------------------
  // AppBar
  // ----------------------------------------------------------
  AppBar _buildAppBar(CompanyCategoryState state, CompanyCategoryNotifier notifier) {
    return AppBar(
      title: Text(t('categories.title'), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        )),
      ),
      actions: [
        if (!state.isLoading) ...[
          TextButton.icon(
            onPressed: () => notifier.toggleAll(true),
            icon: const Icon(Icons.select_all, color: Colors.white, size: 18),
            label: Text(t('common.all'), style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          TextButton.icon(
            onPressed: () => notifier.toggleAll(false),
            icon: const Icon(Icons.deselect, color: Colors.white70, size: 18),
            label: const Text('Temizle', style: TextStyle(color: Colors.white70, fontSize: 12)), // TODO: i18n
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  // ----------------------------------------------------------
  // Body
  // ----------------------------------------------------------
  Widget _buildBody(CompanyCategoryState state, CompanyCategoryNotifier notifier) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(t('common.loading'), style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 16),
            AppButton.primary(

              text: t('common.refresh'),

              icon: Icons.refresh,

              onPressed: () => notifier.loadCategories(),

            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(state),
        _buildSearchBar(notifier),
        Expanded(
          child: _buildCategoryTree(state, notifier),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Header — Seçim özeti
  // ----------------------------------------------------------
  Widget _buildHeader(CompanyCategoryState state) {
    final totalCount = _countAll(state.allCategories);
    final selectedCount = state.selectedIds.length;

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _statChip(Icons.category_outlined, 'Toplam', '$totalCount', Colors.white70), // TODO: i18n
          const SizedBox(width: 12),
          _statChip(Icons.check_circle_outline, 'Seçili', '$selectedCount', Colors.white), // TODO: i18n
          const Spacer(),
          if (totalCount > 0)
            Text(
              '%${(selectedCount / totalCount * 100).round()} seçildi',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  int _countAll(List<Map<String, dynamic>> categories) {
    int count = categories.length;
    for (final cat in categories) {
      final children = cat['children'] as List<dynamic>? ?? [];
      count += _countAll(children.cast<Map<String, dynamic>>());
    }
    return count;
  }

  // ----------------------------------------------------------
  // Arama çubuğu
  // ----------------------------------------------------------
  Widget _buildSearchBar(CompanyCategoryNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: t('common.search'),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    notifier.setSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.bgLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => notifier.setSearch(value),
      ),
    );
  }

  // ----------------------------------------------------------
  // Kategori ağacı
  // ----------------------------------------------------------
  Widget _buildCategoryTree(CompanyCategoryState state, CompanyCategoryNotifier notifier) {
    final filtered = _filterCategories(state.allCategories, state.searchQuery);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              state.searchQuery.isNotEmpty
                  ? t('common.no_records')
                  : t('common.no_data'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _CategoryTreeItem(
          category: filtered[index],
          selectedIds: state.selectedIds,
          onToggle: notifier.toggleCategory,
          depth: 0,
          searchQuery: state.searchQuery,
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterCategories(
    List<Map<String, dynamic>> categories,
    String query,
  ) {
    if (query.isEmpty) return categories;

    final result = <Map<String, dynamic>>[];
    for (final cat in categories) {
      final name = (cat['name'] as String? ?? '').toLowerCase();
      final children = cat['children'] as List<dynamic>? ?? [];
      final filteredChildren =
          _filterCategories(children.cast<Map<String, dynamic>>(), query);

      if (name.contains(query.toLowerCase()) || filteredChildren.isNotEmpty) {
        result.add({...cat, 'children': filteredChildren});
      }
    }
    return result;
  }

  // ----------------------------------------------------------
  // Alt bar — Kaydet butonu
  // ----------------------------------------------------------
  Widget _buildBottomBar(CompanyCategoryState state, CompanyCategoryNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: AppButton.success(
            text: state.isSaving
                  ? t('common.loading')
                  : '${state.selectedIds.length} ${t('categories.title')} ${t('common.save')}',
            icon: Icons.check,
            onPressed: state.isSaving ? null : () {},
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Tek bir kategori satırı (recursive — alt kategorileri gösterir)
// ============================================================

class _CategoryTreeItem extends StatefulWidget {
  final Map<String, dynamic> category;
  final Set<String> selectedIds;
  final void Function(String) onToggle;
  final int depth;
  final String searchQuery;

  const _CategoryTreeItem({
    required this.category,
    required this.selectedIds,
    required this.onToggle,
    required this.depth,
    required this.searchQuery,
  });

  @override
  State<_CategoryTreeItem> createState() => _CategoryTreeItemState();
}

class _CategoryTreeItemState extends State<_CategoryTreeItem> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final id = cat['id'].toString();
    final name = cat['name'] as String? ?? 'Kategori';
    final icon = cat['icon'] as String? ?? '';
    final children = (cat['children'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final hasChildren = children.isNotEmpty;
    final isSelected = widget.selectedIds.contains(id);
    final level = cat['level'] as int? ?? widget.depth;

    // Derinliğe göre girinti ve renk
    final indent = widget.depth * 20.0;
    final levelColors = [
      AppColors.primary,
      AppColors.purple,
      AppColors.teal,
      AppColors.orange,
    ];
    final levelColor = levelColors[widget.depth % levelColors.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Kategori satırı ──
        Container(
          margin: EdgeInsets.only(left: indent, bottom: 4),
          decoration: BoxDecoration(
            color: isSelected ? levelColor.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? levelColor.withValues(alpha: 0.4) : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => widget.onToggle(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? levelColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? levelColor : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Kategori simgesi veya level göstergesi
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: icon.isNotEmpty
                          ? Text(icon, style: const TextStyle(fontSize: 16))
                          : Icon(
                              level == 0 ? Icons.folder_outlined : Icons.subdirectory_arrow_right,
                              color: levelColor,
                              size: 18,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Kategori adı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? levelColor : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        if (cat['path'] != null)
                          Text(
                            cat['path'] as String,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Alt kategori sayısı badge
                  if (hasChildren)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${children.length}',
                        style: TextStyle(
                          color: levelColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (hasChildren) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Alt kategoriler ──
        if (hasChildren && _expanded)
          ...children.map(
            (child) => _CategoryTreeItem(
              category: child,
              selectedIds: widget.selectedIds,
              onToggle: widget.onToggle,
              depth: widget.depth + 1,
              searchQuery: widget.searchQuery,
            ),
          ),

        if (widget.depth == 0) const SizedBox(height: 4),
      ],
    );
  }
}