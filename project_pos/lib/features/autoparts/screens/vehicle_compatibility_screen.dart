import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class VehicleCompatibilityScreen extends ConsumerStatefulWidget {
  final String variantId;
  final String variantName;

  const VehicleCompatibilityScreen({
    super.key,
    required this.variantId,
    this.variantName = '',
  });

  @override
  ConsumerState<VehicleCompatibilityScreen> createState() => _VehicleCompatibilityScreenState();
}

class _VehicleCompatibilityScreenState extends ConsumerState<VehicleCompatibilityScreen> {
  String Function(String) get t => i18nOf(ref);
  List<Map<String, dynamic>> _compatibilities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompatibilities();
  }

  Future<void> _loadCompatibilities() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(vehicleServiceProvider).getActiveVehicles();
      // Uyumluluk listesi icin ozel endpoint kullaniyoruz
      // vehicleCompatibility service uzerinden
      final compatibilities = await _fetchCompatibilities();
      setState(() {
        _compatibilities = compatibilities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCompatibilities() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('product/api/vehicle-compatibility/variant/${widget.variantId}');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      return [];
    }
  }

  void _showAddCompatibilityDialog() async {
    // Marka listesini yukle
    final makes = await ref.read(vehicleServiceProvider).getDistinctMakes();

    if (!mounted) return;

    String? selectedMake;
    List<String> models = [];
    String? selectedModel;
    List<Map<String, dynamic>> matchedVehicles = [];
    Set<String> selectedVehicleIds = {};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.add_circle, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(t('vehicles.add')), // TODO: i18n add_compatibility key
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marka secimi
                  DropdownButtonFormField<String>(
                    value: selectedMake,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Arac Markasi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    items: makes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) async {
                      setDialogState(() {
                        selectedMake = val;
                        selectedModel = null;
                        models = [];
                        matchedVehicles = [];
                        selectedVehicleIds = {};
                      });
                      if (val != null) {
                        final m = await ref.read(vehicleServiceProvider).getModelsByMake(val);
                        setDialogState(() => models = m);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Model secimi
                  DropdownButtonFormField<String>(
                    value: selectedModel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Arac Modeli',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.model_training),
                    ),
                    items: models.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) async {
                      setDialogState(() {
                        selectedModel = val;
                        matchedVehicles = [];
                        selectedVehicleIds = {};
                      });
                      if (val != null && selectedMake != null) {
                        final vehicles = await ref.read(vehicleServiceProvider).searchVehicles(
                          make: selectedMake,
                          model: val,
                        );
                        setDialogState(() => matchedVehicles = vehicles);
                      }
                    },
                  ),

                  // Bulunan araclar
                  if (matchedVehicles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('${matchedVehicles.length} arac bulundu:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...matchedVehicles.map((v) {
                      final id = v['id'] as String;
                      final isSelected = selectedVehicleIds.contains(id);
                      final yearRange = [
                        if (v['yearStart'] != null) v['yearStart'].toString(),
                        if (v['yearEnd'] != null) v['yearEnd'].toString(),
                      ].join('-');

                      return CheckboxListTile(
                        dense: true,
                        value: isSelected,
                        title: Text(
                          '${v['make']} ${v['model']} ($yearRange)',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          [v['engineType'], v['fuelType']].where((s) => s != null && s.toString().isNotEmpty).join(' / '),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedVehicleIds.add(id);
                            } else {
                              selectedVehicleIds.remove(id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
            AppButton.primary(
              text: '${selectedVehicleIds.length} Arac Ekle', // TODO: i18n
              icon: Icons.save,
              onPressed: selectedVehicleIds.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        final apiClient = ref.read(apiClientProvider);
                        await apiClient.post('product/api/vehicle-compatibility/bulk', data: {
                          'variantId': widget.variantId,
                          'vehicleIds': selectedVehicleIds.toList(),
                        });
                        if (mounted) {
                          AppToast.success(context, t('common.saved'));
                        }
                        _loadCompatibilities();
                      } catch (e) {
                        if (mounted) {
                          AppToast.error(context, t('common.error'));
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCompatibility(Map<String, dynamic> compat) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('product/api/vehicle-compatibility/${compat['id']}');
      if (mounted) {
        AppToast.success(context, t('common.saved'));
      }
      _loadCompatibilities();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, t('common.error'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('vehicles.compatibility'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: _showAddCompatibilityDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _compatibilities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off, size: 80, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(t('common.no_data'), style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)), // TODO: i18n no_compatibility key
                      const SizedBox(height: 16),
                      AppButton.primary(
                        text: t('vehicles.add'),
                        icon: Icons.add,
                        onPressed: _showAddCompatibilityDialog,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCompatibilities,
                  child: ListView.builder(
                    padding: AppConstants.pagePadding,
                    itemCount: _compatibilities.length,
                    itemBuilder: (context, index) {
                      final compat = _compatibilities[index];
                      final yearRange = [
                        if (compat['vehicleYearStart'] != null) compat['vehicleYearStart'].toString(),
                        if (compat['vehicleYearEnd'] != null) compat['vehicleYearEnd'].toString(),
                      ].join(' - ');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppConstants.borderRadiusMedium,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: AppConstants.borderRadiusSmall,
                            ),
                            child: const Center(child: Icon(Icons.directions_car, color: AppColors.primary, size: 24)),
                          ),
                          title: Text(
                            '${compat['vehicleMake']} ${compat['vehicleModel']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Row(
                            children: [
                              if (yearRange.isNotEmpty) ...[
                                Text(yearRange, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 8),
                              ],
                              if ((compat['vehicleEngineType'] ?? '').toString().isNotEmpty)
                                Text(compat['vehicleEngineType'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              if (compat['isVerified'] == true) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, size: 14, color: AppColors.success),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                            onPressed: () => _deleteCompatibility(compat),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}