import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/store_service.dart';
import '../../core/api/api_client.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  final _searchController = TextEditingController();
  late StoreService _storeService;

  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _filteredStores = [];
  bool _isLoading = true;
  String? _selectedType;

  final List<String> _types = ['Tümü', 'Merkez', 'Şube', 'Outlet'];
  final Map<String, String> _typeMap = {
    'Merkez': 'flagship',
    'Şube': 'branch',
    'Outlet': 'outlet',
  };

  @override
  void initState() {
    super.initState();
    _storeService = StoreService(ApiClient());
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
      if (mounted) AppToast.error(context, 'Mağazalar yüklenirken hata oluştu');
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.warning_amber_rounded, color: AppColors.warning), SizedBox(width: 12), Text('Mağaza Sil')],
        ),
        content: Text('$name mağazasını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          AppButton.danger(text: 'Sil', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _storeService.deleteStore(id);
        if (mounted) {
          AppToast.success(context, 'Mağaza başarıyla silindi');
          _loadStores();
        }
      } catch (e) {
        if (mounted) AppToast.error(context, 'Mağaza silinirken hata oluştu');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Mağaza Yönetimi',
        actions: [IconButton(onPressed: _loadStores, icon: const Icon(Icons.refresh), tooltip: 'Yenile')],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatsSection(),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: _filterStores,
                        decoration: InputDecoration(
                          hintText: 'Mağaza ara...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () {_searchController.clear(); _filterStores('');}) : null,
                          border: OutlineInputBorder(borderRadius: AppConstants.borderRadiusMedium),
                          filled: true,
                          fillColor: AppColors.bgLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _types.map((type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(type),
                              selected: type == 'Tümü' ? _selectedType == null : _selectedType == _typeMap[type],
                              onSelected: (selected) {
                                setState(() {_selectedType = type == 'Tümü' ? null : _typeMap[type];});
                                _loadStores();
                              },
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _filteredStores.isEmpty
                      ? AppEmptyState(icon: Icons.store, title: 'Mağaza bulunamadı', actionText: 'Yeni Mağaza Ekle', onAction: () => context.push('/stores/add'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStores.length,
                          itemBuilder: (context, index) => _buildStoreCard(_filteredStores[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        
        onPressed: () => context.push('/stores/add'),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Mağaza'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStatsSection() {
    final total = _stores.length;
    final active = _stores.where((s) => s['isActive'] == true).length;
    final totalEmployees = _stores.fold<int>(0, (sum, s) => sum + (s['employeeCount'] as int? ?? 0));

    return Row(
      children: [
        Expanded(child: _buildStatCard('🏪 Toplam', total.toString(), 'Mağaza', AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('✅ Aktif', active.toString(), 'Mağaza', AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('👥 Çalışan', totalEmployees.toString(), 'Kişi', AppColors.info)),
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
    final typeLabels = {'flagship': '🏢 Merkez', 'branch': '🏪 Şube', 'outlet': '🏬 Outlet'};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusMedium),
      child: InkWell(
        onTap: () => context.push('/stores/${store['id']}'),
        borderRadius: AppConstants.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                            AppBadge(text: isActive ? 'Aktif' : 'Pasif', variant: isActive ? BadgeVariant.success : BadgeVariant.danger),
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
                  _buildInfoChip(Icons.people, '${store['employeeCount']} Çalışan', AppColors.success),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary), const SizedBox(width: 4), Expanded(child: Text('${store['district']}, ${store['city']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)))]),
              const SizedBox(height: 4),
              Row(children: [const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary), const SizedBox(width: 4), Text(store['openingHours'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: AppButton.outline(text: 'Düzenle', icon: Icons.edit, onPressed: () => context.push('/stores/edit/${store['id']}'))),
                  const SizedBox(width: 8),
                  AppIconButton(icon: Icons.delete, variant: ButtonVariant.danger, onPressed: () => _deleteStore(store['id'], store['name']), tooltip: 'Sil'),
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
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}