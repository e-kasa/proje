import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/customers/providers/customer_vehicles_provider.dart';
import 'package:project_pos/features/customers/widgets/add_customer_vehicle_modal.dart';

/// Sprint 10 — POS Cart Panel'de parçacı sektör plaka picker'ı.
///
/// Davranış:
///   - Müşteri seçili + sektör=autoParts olduğunda görünür (caller koşulla render eder)
///   - Mevcut plakalar dropdown ile seçilir (mevcut müşteri kayıtlarından)
///   - "Yeni plaka ekle" butonu inline modal açar
///   - Seçim değişince [onChanged] callback ile parent'a bildirir
///   - selectedVehicleId null = "plaka yok" (peşin satış / belirsiz)
class CustomerVehiclePicker extends ConsumerStatefulWidget {
  final String customerId;
  final Map<String, dynamic>? selectedVehicle;
  final ValueChanged<Map<String, dynamic>?> onChanged;

  const CustomerVehiclePicker({
    super.key,
    required this.customerId,
    required this.selectedVehicle,
    required this.onChanged,
  });

  @override
  ConsumerState<CustomerVehiclePicker> createState() =>
      _CustomerVehiclePickerState();
}

class _CustomerVehiclePickerState extends ConsumerState<CustomerVehiclePicker> {
  String Function(String) get t => i18nOf(ref);

  Future<void> _addNewVehicle() async {
    final result = await AddCustomerVehicleModal.show(
      context,
      customerId: widget.customerId,
    );
    if (result != null && mounted) {
      // Yeni eklenen plakayı seç
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync =
        ref.watch(customerVehiclesProvider(widget.customerId));

    return vehiclesAsync.when(
      data: (vehicles) => _buildPicker(vehicles),
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text('${t('common.error')}: $e',
            style: const TextStyle(color: AppColors.danger, fontSize: 11)),
      ),
    );
  }

  Widget _buildPicker(List<Map<String, dynamic>> vehicles) {
    final selectedId = widget.selectedVehicle?['id']?.toString();
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: t('vehicle.plate'),
              prefixIcon: const Icon(Icons.directions_car,
                  color: AppColors.primary, size: 18),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButton<String?>(
              value: selectedId,
              isExpanded: true,
              underline: const SizedBox(),
              hint: Text(
                vehicles.isEmpty
                    ? t('vehicle.no_vehicles')
                    : t('vehicle.select'),
                style: const TextStyle(fontSize: 13),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(t('vehicle.none'),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted)),
                ),
                ...vehicles.map((v) {
                  final id = v['id']?.toString() ?? '';
                  final display =
                      v['plateDisplay']?.toString() ?? v['plateNormalized']?.toString() ?? '';
                  final make = v['make']?.toString() ?? '';
                  final model = v['model']?.toString() ?? '';
                  final detail = (make.isNotEmpty || model.isNotEmpty)
                      ? '  ·  $make $model'.trimRight()
                      : '';
                  return DropdownMenuItem<String?>(
                    value: id,
                    child: Text('$display$detail',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (id) {
                if (id == null) {
                  widget.onChanged(null);
                } else {
                  final v = vehicles.firstWhere((x) => x['id']?.toString() == id,
                      orElse: () => <String, dynamic>{});
                  widget.onChanged(v.isEmpty ? null : v);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _addNewVehicle,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
