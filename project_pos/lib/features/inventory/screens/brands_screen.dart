import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/templates/list_screen_template.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  String Function(String) get t => i18nOf(ref);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _filteredBrands = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoading = true);

    try {
      final response = await ref.read(brandServiceProvider).getAllBrands();
      setState(() {
        _brands = (response as List).map<Map<String, dynamic>>((b) => {
          'id': b['id'],
          'name': b['name'],
          'code': b['code'],
          'description': b['description'],
          'active': b['isActive'] == true,
        }).toList();
        _filteredBrands = List.from(_brands);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, '${t('inventory.brand_load_error')}: $e');
      }
    }
  }

  void _filterBrands(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBrands = List.from(_brands);
      } else {
        _filteredBrands = _brands.where((brand) {
          final name = brand['name'].toString().toLowerCase();
          final code = (brand['code'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || code.contains(searchLower);
        }).toList();
      }
    });
  }

  void _showAddBrandDialog() => _showBrandDialog(null);

  void _showEditBrandDialog(Map<String, dynamic> brand) => _showBrandDialog(brand);

  void _showBrandDialog(Map<String, dynamic>? brand) {
    final isEdit = brand != null;
    final nameController = TextEditingController(text: brand?['name'] ?? '');
    final codeController = TextEditingController(text: brand?['code'] ?? '');
    final descriptionController =
        TextEditingController(text: brand?['description'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isEdit
                                    ? AppColors.info
                                    : AppColors.primary)
                                .withValues(alpha: 0.12),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit
                                : Icons.branding_watermark,
                            color: isEdit
                                ? AppColors.info
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit
                                ? t('inventory.edit_brand')
                                : t('inventory.new_brand'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    AppInput(
                      controller: nameController,
                      label: '${t('inventory.brand_name')} *',
                      hint: t('inventory.brand_name_hint'),
                      prefixIcon: Icons.label,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? t('inventory.brand_name')
                              : null,
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      controller: codeController,
                      label: t('inventory.brand_code'),
                      hint: t('inventory.brand_code_hint'),
                      prefixIcon: Icons.code,
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      controller: descriptionController,
                      label: t('inventory.brand_description'),
                      hint: t('inventory.brand_description_hint'),
                      prefixIcon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton.outline(
                          text: t('common.cancel'),
                          onPressed: submitting
                              ? null
                              : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        AppButton.primary(
                          text: isEdit
                              ? t('common.update')
                              : t('common.save'),
                          isLoading: submitting,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => submitting = true);
                            final name = nameController.text.trim();
                            final code = codeController.text.trim();
                            final description =
                                descriptionController.text.trim();
                            final payload = {
                              'name': name,
                              'code': code,
                              'description': description,
                              'isActive':
                                  isEdit ? brand['active'] : true,
                            };
                            final navigator = Navigator.of(context);
                            try {
                              if (isEdit) {
                                await ref
                                    .read(brandServiceProvider)
                                    .updateBrand(brand['id'], payload);
                              } else {
                                await ref
                                    .read(brandServiceProvider)
                                    .createBrand(payload);
                              }
                              navigator.pop();
                              if (!mounted) return;
                              AppToast.success(
                                this.context,
                                isEdit
                                    ? t('inventory.brand_updated')
                                    : '$name ${t('inventory.brand_added')}',
                              );
                              _loadBrands();
                            } catch (e) {
                              if (!mounted) return;
                              AppToast.error(
                                this.context,
                                '${t('inventory.brand_save_error')}: $e',
                              );
                              setDialogState(() => submitting = false);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> brand) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('inventory.delete_brand'),
      message:
          '${brand['name']} ${t('inventory.brand_delete_confirm')}',
      itemName: brand['name'] ?? '',
    );

    if (!confirmed) return;

    try {
      await ref.read(brandServiceProvider).deleteBrand(brand['id']);
      if (mounted) {
        AppToast.success(
          context,
          '${brand['name']} ${t('inventory.brand_deleted')}',
        );
      }
      _loadBrands();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> brand) async {
    try {
      await ref.read(brandServiceProvider).toggleStatus(brand['id']);
      if (mounted) {
        AppToast.success(
          context,
          brand['active']
              ? '${brand['name']} ${t('inventory.brand_deactivated_msg')}'
              : '${brand['name']} ${t('inventory.brand_activated_msg')}',
        );
      }
      _loadBrands();
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          '${t('inventory.brand_status_changed')}: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sprint 16-B: ListScreenTemplate migration.
    // - searchSlot + statsSlot beyaz panel'e sarıldı (önceki bg uyumlu).
    // - FAB yerine search satırındaki AppButton.primary korundu (davranış aynı).
    // - listPadding default → AppConstants.pagePadding.
    return ListScreenTemplate<Map<String, dynamic>>(
      title: t('menu.brands'),
      items: _filteredBrands,
      isLoading: _isLoading,
      onRefresh: _loadBrands,
      emptyState: _buildEmptyState(),
      searchSlot: Container(
        color: Colors.white,
        padding: AppConstants.pagePadding,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppSearchInput(
                    controller: _searchController,
                    hint: '${t('common.search')}...',
                    onChanged: _filterBrands,
                    onClear: () {
                      _searchController.clear();
                      _filterBrands('');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                AppButton.primary(
                  text: t('inventory.new_brand'),
                  icon: Icons.add,
                  onPressed: _showAddBrandDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(t('common.total'), '${_brands.length}', Icons.branding_watermark),
                  Container(width: 1, height: 30, color: AppColors.border),
                  _buildStatItem(t('common.active'), '${_brands.where((b) => b['active'] == true).length}', Icons.check_circle),
                  Container(width: 1, height: 30, color: AppColors.border),
                  _buildStatItem(t('common.passive'), '${_brands.where((b) => b['active'] != true).length}', Icons.cancel),
                ],
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context, brand, index) => _buildBrandCard(brand),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.branding_watermark_outlined,
      title: t('inventory.no_brands'),
      description: t('inventory.add_brand_hint'),
    );
  }

  Widget _buildBrandCard(Map<String, dynamic> brand) {
    final isActive = brand['active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppConstants.borderRadiusMedium,
          onTap: () => _showEditBrandDialog(brand),
          child: Padding(
            padding: AppConstants.pagePadding,
            child: Row(
              children: [
                // Logo placeholder
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppConstants.borderRadiusMedium,
                  ),
                  child: const Center(
                    child: Icon(Icons.branding_watermark, color: AppColors.primary, size: 28),
                  ),
                ),
                const SizedBox(width: 16),

                // Brand Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            brand['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.textMuted.withValues(alpha: 0.1),
                              borderRadius: AppConstants.borderRadiusSmall,
                            ),
                            child: Text(
                              isActive ? t('common.active') : t('common.passive'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive ? AppColors.success : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((brand['code'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.code, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              brand['code'].toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((brand['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          brand['description'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusSmall),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBrandDialog(brand);
                    } else if (value == 'delete') {
                      _showDeleteDialog(brand);
                    } else if (value == 'toggle') {
                      _toggleStatus(brand);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18, color: AppColors.info),
                          const SizedBox(width: 12),
                          Text(t('common.edit')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.toggle_off : Icons.toggle_on,
                            size: 18,
                            color: isActive ? AppColors.warning : AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Text(isActive ? t('inventory.deactivate') : t('inventory.activate')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: AppColors.danger),
                          const SizedBox(width: 12),
                          Text(t('common.delete')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}