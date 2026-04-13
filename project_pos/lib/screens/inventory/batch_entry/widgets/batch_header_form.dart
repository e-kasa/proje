import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/service_locator.dart';
import '../models/batch_entry_models.dart';
import '../providers/batch_entry_provider.dart';

class BatchHeaderForm extends ConsumerStatefulWidget {
  const BatchHeaderForm({super.key});

  @override
  ConsumerState<BatchHeaderForm> createState() => _BatchHeaderFormState();
}

class _BatchHeaderFormState extends ConsumerState<BatchHeaderForm> {
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _locations = []; // stores + warehouses combined
  bool _loading = true;

  final _invoiceCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _deliveryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ref.read(supplierServiceProvider).getSuppliers(status: 'ACTIVE'),
        ref.read(warehouseServiceProvider).getWarehouses(isActive: true),
        ref.read(storeServiceProvider).getStores(isActive: true),
      ]);
      if (mounted) {
        final warehouses = results[1] as List<Map<String, dynamic>>;
        final stores = results[2] as List<Map<String, dynamic>>;
        final combined = [
          ...stores.map((s) => {
            'code': s['code']?.toString() ?? s['id']?.toString() ?? '',
            'name': s['name']?.toString() ?? '',
            'type': 'STORE',
          }),
          ...warehouses.map((w) => {
            'code': w['code']?.toString() ?? w['id']?.toString() ?? '',
            'name': w['name']?.toString() ?? '',
            'type': 'WAREHOUSE',
          }),
        ];
        setState(() {
          _suppliers = results[0];
          _locations = combined;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('BatchHeaderForm veri yüklenemedi: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final st = ref.read(batchEntryProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: st.purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      ref.read(batchEntryProvider.notifier).updateHeader(purchaseDate: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final state = ref.watch(batchEntryProvider);
    final isCollapsed = state.headerCollapsed;
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Toggle header ────────────────────────────────────────────────
          InkWell(
            onTap: () => ref
                .read(batchEntryProvider.notifier)
                .updateHeader(headerCollapsed: !isCollapsed),
            borderRadius: isCollapsed
                ? BorderRadius.circular(16)
                : const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isCollapsed
                        ? _buildCollapsedSummary(state, dateFmt, t)
                        : Text(
                            t('batch.invoice_delivery_info'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                  ),
                  // Validation indicator
                  if (state.supplierId != null &&
                      state.locationId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(t('batch.ready'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 12, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(t('batch.incomplete'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // ── Form ─────────────────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _loading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  )
                : _buildForm(state, dateFmt, t),
            crossFadeState: isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSummary(
      BatchEntryState state, DateFormat dateFmt, Function(String) t) {
    final parts = <String>[];
    if (state.supplierName != null) parts.add(state.supplierName!);
    if (state.invoiceNumber != null)
      parts.add('${t('batch.invoice')}: ${state.invoiceNumber}');
    if (state.locationName != null) parts.add(state.locationName!);
    parts.add(dateFmt.format(state.purchaseDate));

    return Text(
      parts.join('  ·  '),
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildForm(BatchEntryState state, DateFormat dateFmt, Function(String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 14),

          // Supplier
          _DropdownField<String>(
            label: '${t('batch.supplier')} *',
            icon: Icons.local_shipping_outlined,
            value: state.supplierId,
            items: _suppliers.map((s) {
              return DropdownMenuItem<String>(
                value: s['id']?.toString(),
                child: Text(s['name']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              final supplier = _suppliers.firstWhere(
                (s) => s['id']?.toString() == val,
                orElse: () => {},
              );
              ref.read(batchEntryProvider.notifier).updateHeader(
                    supplierId: val,
                    supplierName: supplier['name']?.toString(),
                  );
            },
          ),
          const SizedBox(height: 10),

          // Invoice + Delivery note
          Row(
            children: [
              Expanded(
                child: _TextField(
                  label: t('batch.invoice_no'),
                  icon: Icons.receipt_outlined,
                  ctrl: _invoiceCtrl,
                  hint: 'FTR-2025-001',
                  onChanged: (v) => ref
                      .read(batchEntryProvider.notifier)
                      .updateHeader(invoiceNumber: v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TextField(
                  label: t('batch.delivery_note_no'),
                  icon: Icons.description_outlined,
                  ctrl: _deliveryCtrl,
                  hint: 'IRS-2025-001',
                  onChanged: (v) => ref
                      .read(batchEntryProvider.notifier)
                      .updateHeader(deliveryNoteNumber: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date + Warehouse + Store
          Row(
            children: [
              // Date picker
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFE8E9F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t('batch.date'),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                dateFmt.format(state.purchaseDate),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_calendar_outlined,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Unified Location (Store + Warehouse)
              Expanded(
                flex: 2,
                child: _DropdownField<String>(
                  label: '${t('batch.location')} *',
                  icon: Icons.location_on_outlined,
                  value: state.locationId,
                  items: _locations.map((loc) {
                    final isWarehouse = loc['type'] == 'WAREHOUSE';
                    return DropdownMenuItem<String>(
                      value: loc['code']?.toString(),
                      child: Row(
                        children: [
                          Icon(
                            isWarehouse ? Icons.warehouse_outlined : Icons.store_outlined,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(loc['name']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final loc = _locations.firstWhere(
                      (l) => l['code']?.toString() == val,
                      orElse: () => {},
                    );
                    ref.read(batchEntryProvider.notifier).updateHeader(
                          locationId: val,
                          locationName: loc['name']?.toString(),
                          locationType: loc['type']?.toString() ?? 'STORE',
                        );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── REUSABLE FIELD WIDGETS ────────────────────────────────────────────────────
class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E9F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.textMuted),
          hint: Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          selectedItemBuilder: (ctx) => items
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: item.child,
                  ))
              .toList(),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController ctrl;
  final String hint;
  final ValueChanged<String> onChanged;

  const _TextField({
    required this.label,
    required this.icon,
    required this.ctrl,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontSize: 12, color: AppColors.textMuted),
          hintText: hint,
          hintStyle:
              const TextStyle(fontSize: 12, color: AppColors.textMuted),
          prefixIcon:
              Icon(icon, size: 16, color: AppColors.textMuted),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8E9F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}