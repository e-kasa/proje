import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/templates/list_screen_template.dart';
import 'package:project_pos/services/store_service.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  String Function(String) get t => i18nOf(ref);

  final _searchController = TextEditingController();
  late StoreService _storeService;

  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _filteredStores = [];
  bool _isLoading = true;
  String? _selectedType;

  final List<String> _typeKeys = ['all', 'flagship', 'branch', 'outlet'];
  final Map<String, String> _backendTypeMap = {
    'flagship': 'flagship',
    'branch': 'branch',
    'outlet': 'outlet',
  };

  @override
  void initState() {
    super.initState();
    _storeService = ref.read(storeServiceProvider);
    _loadStores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    try {
      final stores = await _storeService.getStores(type: _selectedType);
      setState(() {
        _stores = stores;
        _filteredStores = stores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AppToast.error(context, t('stores.load_error'));
    }
  }

  void _filterStores(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStores = _stores;
      } else {
        _filteredStores = _stores.where((store) {
          final name = store['name'].toString().toLowerCase();
          final code = store['code'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || code.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteStore(String id, String name) async {
    final confirm = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('stores.delete_title'),
      message: t('stores.delete_confirm'),
      itemName: name,
      confirmText: t('common.delete'),
      cancelText: t('common.cancel'),
    );

    if (confirm) {
      try {
        await _storeService.deleteStore(id);
        if (mounted) {
          AppToast.success(context, t('stores.deleted_success'));
          _loadStores();
        }
      } catch (e) {
        if (mounted) AppToast.error(context, t('stores.delete_error'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sprint 21 W1: AppScaffold + Column + manual switcher → ListScreenTemplate.
    return ListScreenTemplate<Map<String, dynamic>>(
      title: t('stores.title'),
      actions: [
        IconButton(
          onPressed: _loadStores,
          icon: const Icon(Icons.refresh),
          tooltip: t('common.refresh'),
        ),
      ],
      items: _filteredStores,
      isLoading: _isLoading,
      onRefresh: _loadStores,
      statsSlot: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: _buildStatsSection(),
      ),
      searchSlot: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: AppSearchInput(
          controller: _searchController,
          hint: t('stores.search_hint'),
          onChanged: _filterStores,
          onClear: () {
            _searchController.clear();
            _filterStores('');
          },
        ),
      ),
      filterSlot: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _typeKeys.map((key) {
              final label = key == 'all'
                  ? t('common.all')
                  : key == 'flagship'
                      ? t('stores.type_flagship')
                      : key == 'branch'
                          ? t('stores.type_branch')
                          : t('stores.type_outlet');
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: key == 'all'
                      ? _selectedType == null
                      : _selectedType == _backendTypeMap[key],
                  onSelected: (selected) {
                    setState(() {
                      _selectedType =
                          key == 'all' ? null : _backendTypeMap[key];
                    });
                    _loadStores();
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      emptyState: AppEmptyState(
        icon: Icons.store,
        title: t('stores.empty_title'),
        actionText: t('stores.add'),
        onAction: () => context.push('/stores/add'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/stores/add'),
        icon: const Icon(Icons.add),
        label: Text(t('stores.add')),
        backgroundColor: AppColors.primary,
      ),
      itemBuilder: (ctx, store, idx) => _buildStoreCard(store),
    );
  }

  Widget _buildStatsSection() {
    final total = _stores.length;
    final active = _stores.where((s) => s['isActive'] == true).length;
    final totalEmployees = _stores.fold<int>(0, (sum, s) => sum + (s['employeeCount'] as int? ?? 0));

    return Row(
      children: [
        Expanded(child: _buildStatCard(t('stores.stat_total'), total.toString(), t('stores.store_suffix'), AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(t('stores.stat_active'), active.toString(), t('stores.store_suffix'), AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(t('stores.stat_employees'), totalEmployees.toString(), t('stores.person_suffix'), AppColors.info)),
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
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(suffix, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final isActive = store['isActive'] as bool? ?? true;
    final typeLabels = {
      'flagship': t('stores.type_flagship'),
      'branch': t('stores.type_branch'),
      'outlet': t('stores.type_outlet'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => context.push('/stores/${store['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: AppConstants.borderRadiusMedium,
                  ),
                  child: Icon(Icons.store, color: isActive ? AppColors.primary : AppColors.textMuted, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(store['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          AppBadge(text: isActive ? t('common.active') : t('common.passive'), variant: isActive ? BadgeVariant.success : BadgeVariant.danger),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(store['code'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.category, typeLabels[store['type']] ?? '', AppColors.info),
                _buildInfoChip(Icons.person, store['managerName'] ?? '', AppColors.purple),
                _buildInfoChip(Icons.people, '${store['employeeCount']} ${t('stores.employee_suffix')}', AppColors.success),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary), const SizedBox(width: 4), Expanded(child: Text('${store['district']}, ${store['city']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)))]),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary), const SizedBox(width: 4), Text(store['openingHours'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))]),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppButton.outline(text: t('common.edit'), icon: Icons.edit, onPressed: () => context.push('/stores/edit/${store['id']}'))),
                const SizedBox(width: 8),
                AppIconButton(icon: Icons.delete, variant: ButtonVariant.danger, onPressed: () => _deleteStore(store['id'], store['name']), tooltip: t('common.delete')),
              ],
            ),
          ],
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
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}