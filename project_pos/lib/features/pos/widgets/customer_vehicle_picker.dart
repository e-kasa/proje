import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/customers/widgets/add_customer_vehicle_modal.dart';
import 'package:project_pos/features/customers/widgets/vehicle_search_field.dart';

/// Sprint 10 — POS Cart Panel'de parçacı sektör plaka picker'ı.
/// Sprint 11d — dropdown yerine [VehicleSearchField] (autocomplete) kullanır.
///
/// Davranış:
///   - Müşteri seçili + sektör=autoParts olduğunda görünür (caller koşulla render eder)
///   - Plaka arama input'u (debounced server-side prefix search)
///   - "Yeni plaka ekle" butonu inline modal açar (trailing slot)
///   - Seçim değişince [onChanged] callback ile parent'a bildirir
///   - Suffix × ile seçim temizlenir (peşin satış / belirsiz)
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
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VehicleSearchField(
      customerId: widget.customerId,
      selectedVehicle: widget.selectedVehicle,
      onSelected: widget.onChanged,
      labelText: t('vehicle.plate'),
      allowClear: true,
      trailing: Material(
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
    );
  }
}
