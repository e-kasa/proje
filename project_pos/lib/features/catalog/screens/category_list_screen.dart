import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/service_locator.dart';
import 'add_category_screen.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  String Function(String) get t => i18nOf(ref);

  final _searchController = TextEditingController();

  /// Hiyerarşik sırayla düzenlenmiş tam liste
  List<Map<String, dynamic>> _allCategories = [];

  /// Filtre uygulandıktan sonra gösterilen liste
  List<Map<String, dynamic>> _filteredCategories = [];

  Set<String> _selectedCategoryIds = {};

  String _selectedStatus = 'ALL'; // ALL | ACTIVE | INACTIVE
  bool _isLoading = true;
  bool _isSelectionMode = false;

  final List<Map<String, String>> _statusFilters = [
    {'key': 'ALL'},
    {'key': 'ACTIVE'},
    {'key': 'INACTIVE'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categoryService = ref.read(categoryServiceProvider);
      final flat = await categoryService.getCategories();
      final sorted = _sortHierarchically(flat);
      setState(() {
        _allCategories = sorted;
        _filteredCategories = sorted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  /// Düz listeyi kök → alt → torun sırasına koyar
  List<Map<String, dynamic>> _sortHierarchically(
      List<Map<String, dynamic>> flat) {
    final result = <Map<String, dynamic>>[];
    final roots = flat
        .where((c) =>
            c['parentId'] == null || c['parentId'].toString().isEmpty)
        .toList()
      ..sort((a, b) =>
          ((a['sortOrder'] as int?) ?? 0).compareTo((b['sortOrder'] as int?) ?? 0));

    for (final root in roots) {
      result.add(root);
      final rootId = root['id']?.toString() ?? '';

      final level1 = flat
          .where((c) => c['parentId']?.toString() == rootId)
          .toList()
        ..sort((a, b) =>
            ((a['sortOrder'] as int?) ?? 0).compareTo((b['sortOrder'] as int?) ?? 0));

      for (final child in level1) {
        result.add(child);
        final childId = child['id']?.toString() ?? '';

        final level2 = flat
            .where((c) => c['parentId']?.toString() == childId)
            .toList()
          ..sort((a, b) =>
              ((a['sortOrder'] as int?) ?? 0).compareTo((b['sortOrder'] as int?) ?? 0));

        for (final grand in level2) {
          result.add(grand);
        }
      }
    }

    // Listeye giremeyen (orphan) kategorileri sona ekle
    for (final c in flat) {
      if (!result.any((r) => r['id'] == c['id'])) result.add(c);
    }
    return result;
  }

  void _filterCategories() {
    var filtered = _allCategories;

    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      filtered = filtered.where((c) {
        return (c['name']?.toString().toLowerCase() ?? '').contains(q) ||
            (c['description']?.toString().toLowerCase() ?? '').contains(q);
      }).toList();
    }

    if (_selectedStatus == 'ACTIVE') {
      filtered = filtered.where((c) => c['status'] == 'ACTIVE').toList();
    } else if (_selectedStatus == 'INACTIVE') {
      filtered = filtered.where((c) => c['status'] != 'ACTIVE').toList();
    }

    setState(() => _filteredCategories = filtered);
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.delete')),
        content: Text(t('common.are_you_sure')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('common.cancel'))),
          AppButton.danger(
            text: t('common.delete'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(categoryServiceProvider).deleteCategory(id);
        _loadCategories();
        if (mounted) {
          AppToast.success(context, t('common.deleted'));
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, '${t('common.error')}: $e');
        }
      }
    }
  }

  Future<void> _bulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('common.delete')),
        content: Text(t('common.are_you_sure')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('common.cancel'))),
          AppButton.danger(
            text: t('common.delete'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final errors = <String>[];
      for (final id in _selectedCategoryIds) {
        try {
          await ref.read(categoryServiceProvider).deleteCategory(id);
        } catch (_) {
          errors.add(id);
        }
      }
      setState(() {
        _selectedCategoryIds.clear();
        _isSelectionMode = false;
      });
      _loadCategories();
      if (mounted) {
        if (errors.isEmpty) {
          AppToast.success(context, t('common.deleted'));
        } else {
          AppToast.warning(context, '${errors.length} ${t('categories.title')} ${t('common.error')}'); // TODO: i18n full message
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.primary(
        title: t('categories.title'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedCategoryIds.isEmpty ? null : _bulkDelete,
              tooltip: t('common.delete'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedCategoryIds.clear();
              }),
              tooltip: t('common.cancel'),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _isSelectionMode = true),
              tooltip: t('common.filter'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCategories,
              tooltip: t('common.refresh'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories.isEmpty
                    ? _buildEmptyState()
                    : _buildCategoryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const AddCategoryScreen()),
          );
          if (result == true) _loadCategories();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(t('categories.add')),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: t('common.search'),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterCategories();
                      })
                  : null,
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(
                  borderRadius: AppConstants.borderRadiusMedium,
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((entry) {
                final key = entry['key']!;
                final label = key == 'ALL' ? t('common.all') : key == 'ACTIVE' ? t('common.active') : t('common.passive');
                final sel = _selectedStatus == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: sel,
                    onSelected: (_) {
                      setState(() => _selectedStatus = key);
                      _filterCategories();
                    },
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: sel
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: sel
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined,
              size: 80,
              color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ||
                    _selectedStatus != 'ALL'
                ? t('common.no_records')
                : t('common.no_data'),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty ||
                    _selectedStatus != 'ALL'
                ? t('common.filter')
                : t('common.no_records'),
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCategories.length,
      itemBuilder: (ctx, index) {
        final cat = _filteredCategories[index];
        final id = cat['id']?.toString() ?? '';
        final level = (cat['level'] as int?) ?? 0;
        final isActive = cat['status'] == 'ACTIVE';
        final isSelected = _selectedCategoryIds.contains(id);

        return _CategoryTile(
          category: cat,
          id: id,
          level: level,
          isActive: isActive,
          isSelected: isSelected,
          isSelectionMode: _isSelectionMode,
          onSelect: () => setState(() {
            if (isSelected) {
              _selectedCategoryIds.remove(id);
            } else {
              _selectedCategoryIds.add(id);
            }
          }),
          onLongPress: () => setState(() {
            _isSelectionMode = true;
            _selectedCategoryIds.add(id);
          }),
          onEdit: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => AddCategoryScreen(category: cat)),
            );
            if (result == true) _loadCategories();
          },
          onDelete: () => _deleteCategory(id),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Kategori satır widget'ı
// ──────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final Map<String, dynamic> category;
  final String id;
  final int level;
  final bool isActive;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onSelect;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.id,
    required this.level,
    required this.isActive,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onSelect,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  /// Her seviye için görsel ayarlar
  static const _levelColors = [
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];
  static const _levelPrefixes = ['📁', '   └─', '      └─'];
  static const _levelLabels = ['Kök', 'Alt', 'Torun'];

  @override
  Widget build(BuildContext context) {
    final color =
        level < _levelColors.length ? _levelColors[level] : Colors.grey;
    final prefix =
        level < _levelPrefixes.length ? _levelPrefixes[level] : '  ';
    final levelLabel =
        level < _levelLabels.length ? _levelLabels[level] : 'Seviye $level';

    // Girinti genişliği seviyeye göre
    final indent = level * 16.0;

    return Card(
      margin: EdgeInsets.only(bottom: 8, left: indent),
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusMedium,
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
      ),
      child: InkWell(
        onTap: isSelectionMode ? onSelect : onEdit,
        onLongPress: onLongPress,
        borderRadius: AppConstants.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Seçim kutusu
              if (isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                      width: 2,
                    ),
                    color:
                        isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          size: 14, color: Colors.white)
                      : null,
                ),

              // Seviye ikonu / renk
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
                child: Center(
                  child: Text(
                    level == 0
                        ? '📁'
                        : level == 1
                            ? '📂'
                            : '📄',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Bilgi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$prefix ${category['name']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: level == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (category['description'] != null &&
                        category['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        category['description'],
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Seviye etiketi
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: AppConstants.borderRadiusSmall,
                            border: Border.all(
                                color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            levelLabel,
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Durum etiketi
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isActive
                                    ? AppColors.success
                                    : AppColors.textMuted)
                                .withValues(alpha: 0.1),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: Text(
                            isActive ? 'Aktif' : 'Pasif', // TODO: i18n common.active / common.passive
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menü
              if (!isSelectionMode)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textMuted),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Düzenle'), // TODO: i18n common.edit
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete,
                            size: 20, color: AppColors.danger),
                        SizedBox(width: 12),
                        Text('Sil', // TODO: i18n common.delete
                            style: TextStyle(color: AppColors.danger)),
                      ]),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}