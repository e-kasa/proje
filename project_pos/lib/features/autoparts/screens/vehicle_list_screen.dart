import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/templates/list_screen_template.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  String Function(String) get t => i18nOf(ref);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _filteredVehicles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(vehicleServiceProvider).getAllVehicles();
      setState(() {
        _vehicles = response;
        _filteredVehicles = List.from(_vehicles);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, t('common.error'));
      }
    }
  }

  void _filterVehicles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVehicles = List.from(_vehicles);
      } else {
        final q = query.toLowerCase();
        _filteredVehicles = _vehicles.where((v) {
          final make = (v['make'] ?? '').toString().toLowerCase();
          final model = (v['model'] ?? '').toString().toLowerCase();
          final platform = (v['platformCode'] ?? '').toString().toLowerCase();
          return make.contains(q) || model.contains(q) || platform.contains(q);
        }).toList();
      }
    });
  }

  void _showAddEditDialog({Map<String, dynamic>? vehicle}) {
    final makeCtl = TextEditingController(text: vehicle?['make'] ?? '');
    final modelCtl = TextEditingController(text: vehicle?['model'] ?? '');
    final yearStartCtl = TextEditingController(text: vehicle?['yearStart']?.toString() ?? '');
    final yearEndCtl = TextEditingController(text: vehicle?['yearEnd']?.toString() ?? '');
    final engineCtl = TextEditingController(text: vehicle?['engineType'] ?? '');
    final platformCtl = TextEditingController(text: vehicle?['platformCode'] ?? '');
    String fuelType = vehicle?['fuelType'] ?? '';
    String bodyType = vehicle?['bodyType'] ?? '';

    final isEdit = vehicle != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit : Icons.directions_car, color: isEdit ? AppColors.info : AppColors.primary),
              const SizedBox(width: 12),
              Text(isEdit ? t('common.edit') : t('vehicles.add')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: makeCtl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Marka *',
                    hintText: 'Toyota, BMW, Mercedes...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelCtl,
                  decoration: const InputDecoration(
                    labelText: 'Model *',
                    hintText: 'Corolla, 3 Serisi...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.model_training),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: yearStartCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Baslangic Yili',
                          hintText: '2015',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: yearEndCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Bitis Yili',
                          hintText: '2020',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: engineCtl,
                  decoration: const InputDecoration(
                    labelText: 'Motor Tipi',
                    hintText: '1.6 TDI, 2.0 TSI...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.settings),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: fuelType.isEmpty ? null : fuelType,
                  decoration: const InputDecoration(
                    labelText: 'Yakit Tipi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_gas_station),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Benzin', child: Text('Benzin')),
                    DropdownMenuItem(value: 'Dizel', child: Text('Dizel')),
                    DropdownMenuItem(value: 'LPG', child: Text('LPG')),
                    DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                    DropdownMenuItem(value: 'Elektrik', child: Text('Elektrik')),
                  ],
                  onChanged: (val) => setDialogState(() => fuelType = val ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: bodyType.isEmpty ? null : bodyType,
                  decoration: const InputDecoration(
                    labelText: 'Kasa Tipi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.car_repair),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Sedan', child: Text('Sedan')),
                    DropdownMenuItem(value: 'Hatchback', child: Text('Hatchback')),
                    DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                    DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
                    DropdownMenuItem(value: 'Van', child: Text('Van')),
                    DropdownMenuItem(value: 'Coupe', child: Text('Coupe')),
                    DropdownMenuItem(value: 'Station', child: Text('Station Wagon')),
                  ],
                  onChanged: (val) => setDialogState(() => bodyType = val ?? ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: platformCtl,
                  decoration: const InputDecoration(
                    labelText: 'Platform Kodu',
                    hintText: 'E90, W205...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
            ElevatedButton.icon(
              onPressed: () async {
                final make = makeCtl.text.trim();
                final model = modelCtl.text.trim();
                if (make.isEmpty || model.isEmpty) return;

                Navigator.pop(ctx);
                try {
                  final data = {
                    'make': make,
                    'model': model,
                    'yearStart': int.tryParse(yearStartCtl.text.trim()),
                    'yearEnd': int.tryParse(yearEndCtl.text.trim()),
                    'engineType': engineCtl.text.trim(),
                    'fuelType': fuelType,
                    'bodyType': bodyType,
                    'platformCode': platformCtl.text.trim(),
                    'isActive': true,
                  };
                  if (isEdit) {
                    await ref.read(vehicleServiceProvider).updateVehicle(vehicle['id'], data);
                  } else {
                    await ref.read(vehicleServiceProvider).createVehicle(data);
                  }
                  if (mounted) {
                    AppToast.success(context, t('common.saved'));
                  }
                  _loadVehicles();
                } catch (e) {
                  if (mounted) {
                    AppToast.error(context, t('common.error'));
                  }
                }
              },
              icon: Icon(isEdit ? Icons.save : Icons.add),
              label: Text(isEdit ? t('common.save') : t('common.save')),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEdit ? AppColors.info : AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.danger),
            const SizedBox(width: 12),
            Text(t('common.delete')), // TODO: i18n delete_vehicle key
          ],
        ),
        content: Text('${vehicle['make']} ${vehicle['model']} aracini silmek istediginizden emin misiniz?'), // TODO: i18n
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(vehicleServiceProvider).deleteVehicle(vehicle['id']);
                if (mounted) {
                  AppToast.success(context, t('common.saved'));
                }
                _loadVehicles();
              } catch (e) {
                if (mounted) {
                  AppToast.error(context, t('common.error'));
                }
              }
            },
            icon: const Icon(Icons.delete),
            label: Text(t('common.delete')),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListScreenTemplate<Map<String, dynamic>>(
      title: t('autoparts.vehicles_title'),
      items: _filteredVehicles,
      isLoading: _isLoading,
      onRefresh: _loadVehicles,
      searchSlot: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _filterVehicles,
                decoration: InputDecoration(
                  hintText: t('common.search'), // TODO: i18n vehicle search hint
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.bgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 20),
              label: Text(t('vehicles.add')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      statsSlot: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Toplam', '${_vehicles.length}', Icons.directions_car), // TODO: i18n
              Container(width: 1, height: 30, color: AppColors.border),
              _buildStatItem('Aktif', '${_vehicles.where((v) => v['isActive'] == true).length}', Icons.check_circle), // TODO: i18n
            ],
          ),
        ),
      ),
      emptyState: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 80, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(t('common.no_data'), style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)), // TODO: i18n no_vehicles key
          ],
        ),
      ),
      itemBuilder: (context, vehicle, index) => _buildVehicleCard(vehicle),
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
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final yearRange = [
      if (vehicle['yearStart'] != null) vehicle['yearStart'].toString(),
      if (vehicle['yearEnd'] != null) vehicle['yearEnd'].toString(),
    ].join(' - ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAddEditDialog(vehicle: vehicle),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.directions_car, color: AppColors.primary, size: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle['make']} ${vehicle['model']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (yearRange.isNotEmpty) ...[
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(yearRange, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(width: 12),
                          ],
                          if ((vehicle['fuelType'] ?? '').toString().isNotEmpty) ...[
                            const Icon(Icons.local_gas_station, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(vehicle['fuelType'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                      if ((vehicle['engineType'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(vehicle['engineType'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (value) {
                    if (value == 'edit') _showAddEditDialog(vehicle: vehicle);
                    if (value == 'delete') _showDeleteDialog(vehicle);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [
                      const Icon(Icons.edit, size: 18, color: AppColors.info), const SizedBox(width: 12), Text(t('common.edit')),
                    ])),
                    PopupMenuItem(value: 'delete', child: Row(children: [
                      const Icon(Icons.delete, size: 18, color: AppColors.danger), const SizedBox(width: 12), Text(t('common.delete')),
                    ])),
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
