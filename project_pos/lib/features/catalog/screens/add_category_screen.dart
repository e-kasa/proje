import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// Yeni kategori ekleme / mevcut kategori düzenleme ekranı.
/// Backend API ile çalışır (SQLite yok).
/// 3 seviyeli hiyerarşi: level 0 (kök) → level 1 (alt) → level 2 (torun)
class AddCategoryScreen extends ConsumerStatefulWidget {
  /// Düzenleme modunda mevcut kategori verisi (Map from API).
  /// null ise oluşturma modu.
  final Map<String, dynamic>? category;

  const AddCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  String Function(String) get t => i18nOf(ref);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _sortOrderController;

  String _selectedIcon = 'category';
  bool _isActive = true;
  String? _parentId;
  bool _isLoading = false;
  bool _loadingParents = true;

  List<Map<String, dynamic>> _parentCandidates = [];

  List<_CategoryIcon> _availableIcons(String Function(String) t) => [
        _CategoryIcon('category', Icons.category, t('categories.icon_general')),
        _CategoryIcon('devices', Icons.devices, t('categories.icon_electronics')),
        _CategoryIcon('checkroom', Icons.checkroom, t('categories.icon_clothing')),
        _CategoryIcon('sports_tennis', Icons.sports_tennis, t('categories.icon_footwear')),
        _CategoryIcon('shopping_bag', Icons.shopping_bag, t('categories.icon_accessories')),
        _CategoryIcon('home', Icons.home, t('categories.icon_home')),
        _CategoryIcon('fitness_center', Icons.fitness_center, t('categories.icon_sport')),
        _CategoryIcon('restaurant', Icons.restaurant, t('categories.icon_food')),
        _CategoryIcon('toys', Icons.toys, t('categories.icon_toys')),
        _CategoryIcon('local_florist', Icons.local_florist, t('categories.icon_cosmetics')),
        _CategoryIcon('inventory_2', Icons.inventory_2, t('categories.icon_warehouse')),
        _CategoryIcon('storefront', Icons.storefront, t('categories.icon_store')),
      ];

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?['name'] ?? '');
    _descriptionController =
        TextEditingController(text: cat?['description'] ?? '');
    _sortOrderController =
        TextEditingController(text: (cat?['sortOrder'] ?? 0).toString());

    if (cat != null) {
      _selectedIcon = cat['icon'] ?? 'category';
      _isActive = (cat['status'] == 'ACTIVE');
      _parentId = cat['parentId']?.toString();
    }

    _loadParentCandidates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  /// Üst kategori olabilecek kategorileri yükle.
  /// Kural: sadece level 0 ve level 1 kategoriler üst olabilir
  /// (level 2 zaten 3. seviye = maksimum derinlik).
  Future<void> _loadParentCandidates() async {
    setState(() => _loadingParents = true);
    try {
      final cats =
          await ref.read(categoryServiceProvider).getCategories();

      final editId = widget.category?['id']?.toString();

      setState(() {
        _parentCandidates = cats.where((c) {
          final level = (c['level'] as int?) ?? 0;
          final id = c['id']?.toString() ?? '';
          return level < 2 && id != editId;
        }).toList();
        _loadingParents = false;
      });
    } catch (e) {
      setState(() => _loadingParents = false);
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'parentId': (_parentId?.isNotEmpty == true) ? _parentId : null,
      'status': _isActive ? 'ACTIVE' : 'INACTIVE',
      'sortOrder': int.tryParse(_sortOrderController.text) ?? 0,
      'icon': _selectedIcon,
    };

    try {
      final service = ref.read(categoryServiceProvider);
      final editId = widget.category?['id']?.toString();

      if (editId != null && editId.isNotEmpty) {
        await service.updateCategory(editId, payload);
      } else {
        await service.createCategory(payload);
      }

      if (mounted) {
        AppToast.success(context, t('common.saved'));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Üst kategori dropdown için görüntü metni (girinti ile hiyerarşi)
  String _parentLabel(Map<String, dynamic> cat) {
    final level = (cat['level'] as int?) ?? 0;
    final prefix = level == 0 ? '📁' : '   └─';
    return '$prefix ${cat['name']}';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return AppScaffold(
      appBar: AppAppBar.primary(
        title: isEdit ? t('categories.edit') : t('categories.add'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.pagePadding,
          children: [
            AppSectionCard(
              title: t('categories.basic_info'),
              icon: Icons.info_outline,
              children: [
                AppInput(
                  controller: _nameController,
                  label: '${t('categories.title')} *',
                  hint: t('categories.name_hint'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? t('categories.name_required')
                      : null,
                ),
                const SizedBox(height: 16),
                AppInput(
                  controller: _descriptionController,
                  label: t('categories.description'),
                  hint: t('categories.description_hint'),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: t('categories.icon_selection'),
              icon: Icons.widgets_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableIcons(t).map(_buildIconTile).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: t('categories.advanced_settings'),
              icon: Icons.settings_outlined,
              children: [
                _loadingParents
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<String?>(
                        initialValue: _parentId,
                        decoration: InputDecoration(
                          labelText: t('categories.parent_category'),
                          hintText: t('categories.parent_hint'),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: AppConstants.borderRadiusMedium,
                            borderSide:
                                const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppConstants.borderRadiusMedium,
                            borderSide:
                                const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppConstants.borderRadiusMedium,
                            borderSide:
                                const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('─ ${t('categories.parent_root')}'),
                          ),
                          ..._parentCandidates.map((cat) {
                            return DropdownMenuItem<String?>(
                              value: cat['id']?.toString(),
                              child: Text(
                                _parentLabel(cat),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _parentId = v),
                      ),
                const SizedBox(height: 16),
                AppInput(
                  controller: _sortOrderController,
                  label: t('categories.sort_order'),
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    t('categories.sort_order_help'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('categories.status')),
                  subtitle: Text(
                    _isActive ? t('common.active') : t('common.passive'),
                    style: TextStyle(
                      color:
                          _isActive ? AppColors.success : AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: AppColors.success,
                ),
              ],
            ),
            if (isEdit) ...[
              const SizedBox(height: 12),
              _buildLevelBadge(widget.category!),
            ],
            const SizedBox(height: 24),
            AppButton.primary(
              text: isEdit ? t('common.edit') : t('common.save'),
              onPressed: _isLoading ? null : _saveCategory,
              isLoading: _isLoading,
              fullWidth: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIconTile(_CategoryIcon data) {
    final sel = _selectedIcon == data.name;
    return InkWell(
      onTap: () => setState(() => _selectedIcon = data.name),
      borderRadius: AppConstants.borderRadiusMedium,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: sel
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.bgLight,
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.border,
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              color: sel ? AppColors.primary : AppColors.textMuted,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 9,
                color: sel ? AppColors.primary : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Edit modunda mevcut seviyeyi gösteren bilgi etiketi
  Widget _buildLevelBadge(Map<String, dynamic> cat) {
    final level = (cat['level'] as int?) ?? 0;
    final labels = [
      t('categories.level_root'),
      t('categories.level_sub'),
      t('categories.level_sub2'),
    ];
    const colors = [AppColors.info, AppColors.warning, AppColors.purple];
    final label = level < labels.length ? labels[level] : 'L$level';
    final color = level < colors.length ? colors[level] : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (level >= 2) ...[
            const SizedBox(width: 8),
            Text(
              '(${t('categories.level_max_depth')})',
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryIcon {
  final String name;
  final IconData icon;
  final String label;
  const _CategoryIcon(this.name, this.icon, this.label);
}
