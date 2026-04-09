import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
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
        AppToast.error(context, 'Markalar yüklenirken hata oluştu: $e');
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

  void _showAddBrandDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.branding_watermark, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(t('inventory.new_brand')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Marka Adı *',
                  hintText: 'Örn: Nike, Apple, Samsung',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kod',
                  hintText: 'Örn: NIKE, APPLE',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Marka hakkında kısa açıklama',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common.cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              final description = descriptionController.text.trim();

              if (name.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ref.read(brandServiceProvider).createBrand({
                    'name': name,
                    'code': code,
                    'description': description,
                    'isActive': true,
                  });
                  if (mounted) {
                    AppToast.success(context, '$name markası eklendi');
                  }
                  _loadBrands();
                } catch (e) {
                  if (mounted) {
                    AppToast.error(context, 'Marka eklenirken hata oluştu: $e');
                  }
                }
              }
            },
            icon: const Icon(Icons.save),
            label: Text(t('common.save')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBrandDialog(Map<String, dynamic> brand) {
    final nameController = TextEditingController(text: brand['name']);
    final codeController = TextEditingController(text: brand['code'] ?? '');
    final descriptionController = TextEditingController(text: brand['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.info),
            const SizedBox(width: 12),
            Text(t('inventory.edit_brand')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Marka Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kod',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('common.cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              final description = descriptionController.text.trim();

              if (name.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ref.read(brandServiceProvider).updateBrand(
                    brand['id'],
                    {
                      'name': name,
                      'code': code,
                      'description': description,
                      'isActive': brand['active'],
                    },
                  );
                  if (mounted) {
                    AppToast.success(context, 'Marka güncellendi');
                  }
                  _loadBrands();
                } catch (e) {
                  if (mounted) {
                    AppToast.error(context, 'Marka güncellenirken hata oluştu: $e');
                  }
                }
              }
            },
            icon: const Icon(Icons.save),
            label: Text(t('common.update')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> brand) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('inventory.delete_brand'),
      message: '${brand['name']} markasını silmek istediğinizden emin misiniz?',
      itemName: brand['name'] ?? '',
    );

    if (!confirmed) return;

    try {
      await ref.read(brandServiceProvider).deleteBrand(brand['id']);
      if (mounted) {
        AppToast.success(context, '${brand['name']} silindi');
      }
      _loadBrands();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Marka silinirken hata oluştu: $e');
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
              ? '${brand['name']} pasife alındı'
              : '${brand['name']} aktife alındı',
        );
      }
      _loadBrands();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Durum değiştirilirken hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        title: t('menu.brands'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search & Add Section
          Container(
            color: Colors.white,
            padding: AppConstants.pagePadding,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterBrands,
                        decoration: InputDecoration(
                          hintText: '${t('common.search')}...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: AppColors.bgLight,
                          border: OutlineInputBorder(
                            borderRadius: AppConstants.borderRadiusMedium,
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showAddBrandDialog,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(t('inventory.new_brand')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppConstants.borderRadiusMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
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

          // Brands List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBrands.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: AppConstants.pagePadding,
                        itemCount: _filteredBrands.length,
                        itemBuilder: (context, index) {
                          final brand = _filteredBrands[index];
                          return _buildBrandCard(brand);
                        },
                      ),
          ),
        ],
      ),
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
    return AppEmptyState.noData(
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
                    color: AppColors.primary.withOpacity(0.1),
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
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.textMuted.withOpacity(0.1),
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
