import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/customers/providers/customer_vehicles_provider.dart';

/// Sprint 10 — Müşteriye yeni plaka eklemek için inline modal.
///
/// Backend POST /customers/{id}/vehicles **idempotent** — aynı normalized
/// plaka varsa mevcut kayıt döner, çift yaratmaz. Bu nedenle UI'da
/// "zaten kayıtlı" hatası göstermek gereksiz; başarılı response döndürür.
///
/// Kullanım:
/// ```dart
/// final newVehicle = await AddCustomerVehicleModal.show(
///   context, customerId: 'cus-xyz');
/// if (newVehicle != null) {
///   // newVehicle['id'], newVehicle['plateDisplay'], ...
/// }
/// ```
class AddCustomerVehicleModal {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String customerId,
    String? initialPlate,
  }) async {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => _AddVehicleContent(
        customerId: customerId,
        initialPlate: initialPlate,
      ),
    );
  }
}

class _AddVehicleContent extends ConsumerStatefulWidget {
  final String customerId;
  final String? initialPlate;

  const _AddVehicleContent({required this.customerId, this.initialPlate});

  @override
  ConsumerState<_AddVehicleContent> createState() => _AddVehicleContentState();
}

class _AddVehicleContentState extends ConsumerState<_AddVehicleContent> {
  String Function(String) get t => i18nOf(ref);

  late final TextEditingController _plateCtrl;
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plateCtrl = TextEditingController(text: widget.initialPlate ?? '');
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final plate = _plateCtrl.text.trim();
    if (plate.isEmpty) {
      AppToast.warning(context, t('vehicle.plate_required'));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'plateDisplay': plate,
        if (_makeCtrl.text.isNotEmpty) 'make': _makeCtrl.text.trim(),
        if (_modelCtrl.text.isNotEmpty) 'model': _modelCtrl.text.trim(),
        if (_yearCtrl.text.isNotEmpty)
          'yearOfManufacture': int.tryParse(_yearCtrl.text.trim()),
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
        'isActive': true,
      };
      final result = await ref
          .read(customerVehicleServiceProvider)
          .create(widget.customerId, data);
      // Cache invalidate — picker yeniden yükler
      ref.invalidate(customerVehiclesProvider(widget.customerId));
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_car,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t('vehicle.add_new'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _plateCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: t('vehicle.plate'),
                hintText: '34 ABC 123',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _makeCtrl,
              decoration: InputDecoration(
                labelText: t('vehicle.make'),
                hintText: 'Ford',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelCtrl,
              decoration: InputDecoration(
                labelText: t('vehicle.model'),
                hintText: 'Focus',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t('vehicle.year'),
                hintText: '2020',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t('common.notes'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(t('common.cancel')),
        ),
        AppButton.primary(
          text: _saving ? t('common.saving') : t('common.save'),
          icon: Icons.check,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}
