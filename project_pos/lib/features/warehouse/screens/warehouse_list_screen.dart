import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/warehouse_service.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class WarehouseListScreen extends ConsumerStatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  ConsumerState<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends ConsumerState<WarehouseListScreen> {
  String Function(String) get t => i18nOf(ref);

  final _searchController = TextEditingController();
  late WarehouseService _warehouseService;

  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _filteredWarehouses = [];
  bool _isLoading = true;
  String? _selectedType;
  bool? _selectedStatus;

  // Language-neutral type keys; labels are translated in build()
  final List<String> _typeKeys = ['all', 'main', 'regional', 'backup'];
  final Map<String, String> _backendTypeMap = {
    'main': 'main',
    'regional': 'regional',
    'backup': 'backup',
  };

  @override
  void initState() {
    super.initState();
    _warehouseService = ref.read(warehouseServiceProvider);
    _loadWarehouses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final warehouses = await _warehouseService.getWarehouses(
        type: _selectedType,
        isActive: _selectedStatus,
      );
      setState(() {
        _warehouses = warehouses;
        _filteredWarehouses = warehouses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, t('warehouses.load_error'));
      }
    }
  }

  void _filterWarehouses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredWarehouses = _warehouses;
      } else {
        _filteredWarehouses = _warehouses.where((warehouse) {
          final name = warehouse['name'].toString().toLowerCase();
          final code = warehouse['code'].toString().toLowerCase();
          final city = warehouse['city'].toString().toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
                 code.contains(searchLower) ||
                 city.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteWarehouse(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Text(t('warehouses.delete_title')),
          ],
        ),
        content: Text(t('warehouses.delete_confirm').replaceAll('{name}', name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('common.cancel')),
          ),
          AppButton.danger(
            text: t('common.delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _warehouseService.deleteWarehouse(id);
        if (mounted) {
          AppToast.success(context, t('warehouses.deleted_success'));
          _loadWarehouses();
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, t('warehouses.delete_error'));
        }
      }
    }
  }

  Future<void> _toggleStatus(String id) async {
    try {
      await _warehouseService.toggleWarehouseStatus(id);
      if (mounted) {
        AppToast.success(context, t('common.status_updated'));
        _loadWarehouses();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, t('common.status_update_error'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('warehouses.title'),
        actions: [
          IconButton(
            onPressed: _loadWarehouses,
            icon: const Icon(Icons.refresh),
            tooltip: t('common.refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters & Search Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Statistics Cards
                      _buildStatsSection(),
                      const SizedBox(height: 16),

                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: _filterWarehouses,
                        decoration: InputDecoration(
                          hintText: t('warehouses.search_hint'),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterWarehouses('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: AppConstants.borderRadiusMedium,
                          ),
                          filled: true,
                          fillColor: AppColors.bgLight,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._typeKeys.map((key) {
                              final label = key == 'all'
                                  ? t('common.all')
                                  : key == 'main'
                                      ? t('warehouses.type_main')
                                      : key == 'regional'
                                          ? t('warehouses.type_regional')
                                          : t('warehouses.type_backup');
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(label),
                                  selected: key == 'all' ? _selectedType == null : _selectedType == _backendTypeMap[key],
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedType = key == 'all' ? null : _backendTypeMap[key];
                                    });
                                    _loadWarehouses();
                                  },
                                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                ),
                              );
                            }),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(t('warehouses.active_only')),
                              selected: _selectedStatus == true,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = selected ? true : null;
                                });
                                _loadWarehouses();
                              },
                              selectedColor: AppColors.success.withValues(alpha: 0.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Warehouse List
                Expanded(
                  child: _filteredWarehouses.isEmpty
                      ? AppEmptyState(
                          icon: Icons.warehouse,
                          title: t('warehouses.empty_title'),
                          actionText: t('warehouses.add'),
                          onAction: () => context.push('/warehouses/add'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredWarehouses.length,
                          itemBuilder: (context, index) {
                            final warehouse = _filteredWarehouses[index];
                            return _buildWarehouseCard(warehouse, isMobile);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        
        onPressed: () => context.push('/warehouses/add'),
        icon: const Icon(Icons.add),
        label: Text(t('warehouses.add')),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalWarehouses = _warehouses.length;
    final activeWarehouses = _warehouses.where((w) => w['isActive'] == true).length;
    final totalCapacity = _warehouses.fold<int>(0, (sum, w) => sum + (w['capacity'] as int? ?? 0));
    final totalStock = _warehouses.fold<int>(0, (sum, w) => sum + (w['currentStock'] as int? ?? 0));
    final utilizationRate = totalCapacity > 0 ? (totalStock / totalCapacity * 100).toStringAsFixed(1) : '0';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            t('warehouses.stat_total'),
            totalWarehouses.toString(),
            t('warehouses.warehouse_suffix'),
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            t('warehouses.stat_active'),
            activeWarehouses.toString(),
            t('warehouses.warehouse_suffix'),
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            t('warehouses.stat_utilization'),
            '$utilizationRate%',
            t('warehouses.utilization_suffix'),
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String suffix, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseCard(Map<String, dynamic> warehouse, bool isMobile) {
    final isActive = warehouse['isActive'] as bool? ?? true;
    final capacity = warehouse['capacity'] as int? ?? 0;
    final currentStock = warehouse['currentStock'] as int? ?? 0;
    final utilizationRate = capacity > 0 ? (currentStock / capacity * 100) : 0.0;

    final typeLabels = {
      'main': t('warehouses.type_main'),
      'regional': t('warehouses.type_regional'),
      'backup': t('warehouses.type_backup'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: () => context.push('/warehouses/${warehouse['id']}'),
        borderRadius: AppConstants.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.textMuted.withValues(alpha: 0.1),
                      borderRadius: AppConstants.borderRadiusMedium,
                    ),
                    child: Icon(
                      Icons.warehouse,
                      color: isActive ? AppColors.primary : AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                warehouse['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            AppBadge(
                              text: isActive ? t('common.active') : t('common.passive'),
                              variant: isActive ? BadgeVariant.success : BadgeVariant.danger,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          warehouse['code'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Type & Manager
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.category,
                    typeLabels[warehouse['type']] ?? warehouse['type'] ?? '',
                    AppColors.info,
                  ),
                  _buildInfoChip(
                    Icons.person,
                    warehouse['managerName'] ?? '',
                    AppColors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${warehouse['district']}, ${warehouse['city']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    warehouse['phone'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Capacity Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('warehouses.capacity_usage'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${utilizationRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: utilizationRate > 80
                              ? AppColors.danger
                              : utilizationRate > 60
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppConstants.borderRadiusSmall,
                    child: LinearProgressIndicator(
                      value: utilizationRate / 100,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(
                        utilizationRate > 80
                            ? AppColors.danger
                            : utilizationRate > 60
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentStock / $capacity ${t('warehouses.unit')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      text: t('common.edit'),
                      icon: Icons.edit,
                      onPressed: () => context.push('/warehouses/edit/${warehouse['id']}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppIconButton(
                    icon: isActive ? Icons.toggle_on : Icons.toggle_off,
                    variant: isActive ? ButtonVariant.success : ButtonVariant.secondary,
                    onPressed: () => _toggleStatus(warehouse['id']),
                    tooltip: isActive ? t('common.deactivate') : t('common.activate'),
                  ),
                  const SizedBox(width: 8),
                  AppIconButton(
                    icon: Icons.delete,
                    variant: ButtonVariant.danger,
                    onPressed: () => _deleteWarehouse(warehouse['id'], warehouse['name']),
                    tooltip: t('common.delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}