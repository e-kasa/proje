import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/config/sector_config.dart';
import '../models/wizard_state.dart';
import '../widgets/wizard_common_widgets.dart';
import '../widgets/multi_select_chips.dart';
import '../widgets/bulk_dialogs.dart';

class StockBarcodeStep extends ConsumerWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const StockBarcodeStep({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  // ── Sector-aware accent color ──────────────────────────────────────────────
  Color get _accentColor => switch (state.sectorType) {
    SectorType.autoParts => AppColors.orange,
    SectorType.footwear => AppColors.pink,
    SectorType.technology => AppColors.info,
    SectorType.general => AppColors.primary,
  };

  // ── Card wrapper ───────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _header({
    required IconData icon,
    required String title,
    Color? color,
    String? subtitle,
  }) {
    final c = color ?? _accentColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final totalStock = state.variants.fold<int>(0, (sum, v) => sum + (v.inventory?.physicalQuantity ?? 0));
    final totalPurchaseValue = state.variants.fold<double>(0, (sum, v) {
      final qty = v.inventory?.physicalQuantity ?? 0;
      return sum + (qty * v.purchasePrice);
    });
    final totalSaleValue = state.variants.fold<double>(0, (sum, v) {
      final qty = v.inventory?.physicalQuantity ?? 0;
      return sum + (qty * v.salePrice);
    });
    final totalProfit = totalSaleValue - totalPurchaseValue;
    final profitMargin = totalPurchaseValue > 0 ? (totalProfit / totalPurchaseValue) * 100 : 0;
    final variantsWithStock = state.variants.where((v) => (v.inventory?.physicalQuantity ?? 0) > 0).length;

    final statCards = [
      {'label': '${t('common.total')}\n${t('inventory.stock')}', 'value': '$totalStock', 'color': AppColors.success, 'icon': Icons.inventory_2},
      {'label': '${t('product.purchase')}\n${t('product.value')}', 'value': '\u20ba${totalPurchaseValue.toStringAsFixed(2)}', 'color': AppColors.danger, 'icon': Icons.shopping_cart},
      {'label': '${t('product.sale')}\n${t('product.value')}', 'value': '\u20ba${totalSaleValue.toStringAsFixed(2)}', 'color': AppColors.success, 'icon': Icons.point_of_sale},
      {'label': '${t('common.total')}\n${t('product.profit')}', 'value': '\u20ba${totalProfit.toStringAsFixed(2)}', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger, 'icon': totalProfit >= 0 ? Icons.trending_up : Icons.warning_amber},
      {'label': '${t('product.profit')}\n${t('product.margin')}', 'value': '${profitMargin.toStringAsFixed(1)}%', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger, 'icon': Icons.show_chart},
      {'label': '${t('product.stocked')}\n${t('product.variant')}', 'value': '$variantsWithStock/${state.variants.length}', 'color': AppColors.warning, 'icon': Icons.label},
    ];

    return Column(
      children: [
        _buildStoreWarehouseSupplier(context, t),
        const SizedBox(height: 16),
        _buildBulkOperations(context, t),
        const SizedBox(height: 16),
        _buildVariantsList(context, t),
        if (state.isParcaci) ...[
          const SizedBox(height: 16),
          _buildAutoPartsSection(context, t),
        ],
        const SizedBox(height: 16),
        _buildStatCards(statCards, t),
      ],
    );
  }

  // ── Stat cards with icons ──────────────────────────────────────────────────
  Widget _buildStatCards(List<Map<String, dynamic>> statCards, String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(icon: Icons.analytics, title: t('inventory.stock_summary'), color: _accentColor),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isMobile ? 1.6 : 2.0,
            ),
            itemCount: statCards.length,
            itemBuilder: (context, index) {
              final card = statCards[index];
              final color = card['color'] as Color;
              final icon = card['icon'] as IconData;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (card['label'] as String).replaceAll('\n', ' '),
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card['value'] as String,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Store / Warehouse / Supplier ───────────────────────────────────────────
  Widget _buildStoreWarehouseSupplier(BuildContext context, String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: Icons.store,
            title: t('product.warehouse_store_supplier_info'),
            color: AppColors.info,
          ),
          const SizedBox(height: 16),

          buildFormField(
            label: t('product.store'),
            required: true,
            child: MultiSelectChips(
              selectedValues: state.selectedStores,
              allOptions: state.stores,
              hintText: '${t('product.store')} ${t('common.add').toLowerCase()}...',
              icon: Icons.store,
              onChanged: (vals) { state.selectedStores = vals; onChanged(); },
            ),
          ),
          const SizedBox(height: 12),

          buildFormField(
            label: t('product.warehouse'),
            required: true,
            child: MultiSelectChips(
              selectedValues: state.selectedWarehouses,
              allOptions: state.warehouses,
              hintText: '${t('product.warehouse')} ${t('common.add').toLowerCase()}...',
              icon: Icons.warehouse,
              onChanged: (vals) { state.selectedWarehouses = vals; onChanged(); },
            ),
          ),
          const SizedBox(height: 12),

          buildFormField(
            label: t('product.supplier'),
            child: Builder(builder: (context) {
              // Duplicate ID'leri temizle ve güvenli items oluştur
              final supplierItems = state.suppliers
                  .map((sup) => sup['id']?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .map<DropdownMenuItem<String>>((id) {
                    final sup = state.suppliers.firstWhere(
                        (s) => s['id']?.toString() == id);
                    final name = sup['name']?.toString() ??
                        sup['companyName']?.toString() ?? '-';
                    final contact = sup['contactName']?.toString() ?? '';
                    final label = contact.isNotEmpty ? '$name ($contact)' : name;
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    );
                  })
                  .toList();
              final safeValue = supplierItems.any(
                      (item) => item.value == state.selectedSupplier)
                  ? state.selectedSupplier
                  : null;
              return DropdownButtonFormField<String>(
                value: safeValue,
                isExpanded: true,
                decoration: inputDecoration(t('product.select_supplier')).copyWith(
                  prefixIcon: const Icon(Icons.business,
                      color: AppColors.primary, size: 18),
                ),
                items: supplierItems,
                onChanged: (val) {
                  state.selectedSupplier = val;
                  onChanged();
                },
              );
            }),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: t('product.invoice_no'),
                  child: TextField(
                    controller: state.invoiceNumberController,
                    decoration: inputDecoration('FT-2024-001').copyWith(
                      prefixIcon: const Icon(Icons.receipt, color: AppColors.primary, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: t('product.purchase_date'),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.purchaseDateController.text.isNotEmpty
                            ? DateTime.tryParse(state.purchaseDateController.text) ?? DateTime.now()
                            : DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: AppColors.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        state.purchaseDateController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        onChanged();
                      }
                    },
                    child: IgnorePointer(
                      child: TextField(
                        controller: state.purchaseDateController,
                        decoration: inputDecoration(t('common.select_date')).copyWith(
                          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                          suffixIcon: state.purchaseDateController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () { state.purchaseDateController.clear(); onChanged(); },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bulk operations ────────────────────────────────────────────────────────
  Widget _buildBulkOperations(BuildContext context, String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: Icons.bolt,
            title: t('product.quick_bulk_operations'),
            color: AppColors.warning,
            subtitle: t('product.apply_same_value_to_all'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showBulkStockDialog(context: context, state: state, onChanged: onChanged, t: t),
                  icon: Icon(Icons.inventory_2, size: isMobile ? 18 : 20, color: AppColors.info),
                  label: Text(
                    isMobile ? t('inventory.stock') : t('product.apply_stock'),
                    style: TextStyle(fontSize: isMobile ? 11 : 13, color: AppColors.info),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.info.withOpacity(0.5)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 12 : 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showBulkPurchasePriceDialog(context: context, state: state, onChanged: onChanged, t: t),
                  icon: Icon(Icons.attach_money, size: isMobile ? 18 : 20, color: AppColors.danger),
                  label: Text(
                    isMobile ? t('product.purchase') : t('product.purchase_price'),
                    style: TextStyle(fontSize: isMobile ? 11 : 13, color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 12 : 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showBulkSalePriceDialog(context: context, state: state, onChanged: onChanged, t: t),
                  icon: Icon(Icons.sell, size: isMobile ? 18 : 20, color: AppColors.success),
                  label: Text(
                    isMobile ? t('product.sale') : t('product.sale_price'),
                    style: TextStyle(fontSize: isMobile ? 11 : 13, color: AppColors.success),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.success.withOpacity(0.5)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 12 : 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Variants list ──────────────────────────────────────────────────────────
  Widget _buildVariantsList(BuildContext context, String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: Icons.view_list,
            title: '${t('product.variant_stock_info')} (${state.variants.length})',
            color: _accentColor,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.variants.length,
            itemBuilder: (context, index) {
              final variant = state.variants[index];
              final qty = variant.inventory?.physicalQuantity ?? 0;
              final variantProfit = (variant.salePrice - variant.purchasePrice) * qty;
              final isEven = index % 2 == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: EdgeInsets.all(isMobile ? 10 : 14),
                decoration: BoxDecoration(
                  color: isEven ? Colors.transparent : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Index badge
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            variant.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        // Profit badge
                        if (qty > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: variantProfit >= 0
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  variantProfit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 12,
                                  color: variantProfit >= 0 ? AppColors.success : AppColors.danger,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\u20ba${variantProfit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: variantProfit >= 0 ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('stock_${variant.sku}_${variant.inventory?.physicalQuantity}'),
                            initialValue: variant.inventory?.physicalQuantity.toString() ?? '0',
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration('Stok').copyWith(prefixIcon: const Icon(Icons.inventory_2, size: 18)),
                            onChanged: (val) {
                              final parsedQty = int.tryParse(val) ?? 0;
                              if (variant.inventory == null) {
                                variant.inventory = InventoryInfo(
                                  warehouseCode: state.selectedWarehouses.isNotEmpty ? state.selectedWarehouses.first : 'WH-001',
                                  physicalQuantity: parsedQty,
                                );
                              } else {
                                variant.inventory!.physicalQuantity = parsedQty;
                              }
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('purchase_${variant.sku}_${variant.purchasePrice}'),
                            initialValue: variant.purchasePrice.toStringAsFixed(2),
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration('Alis').copyWith(
                              prefixIcon: const Icon(Icons.attach_money, size: 18, color: AppColors.danger),
                              prefixText: '\u20ba',
                            ),
                            onChanged: (val) { variant.purchasePrice = double.tryParse(val) ?? 0; onChanged(); },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('sale_${variant.sku}_${variant.salePrice}'),
                            initialValue: variant.salePrice.toStringAsFixed(2),
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration('Satis').copyWith(
                              prefixIcon: const Icon(Icons.sell, size: 18, color: AppColors.success),
                              prefixText: '\u20ba',
                            ),
                            onChanged: (val) { variant.salePrice = double.tryParse(val) ?? 0; onChanged(); },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: inputDecoration('Barkod').copyWith(prefixIcon: const Icon(Icons.qr_code, size: 18)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Auto parts section (only shown when isParcaci) ─────────────────────────
  Widget _buildAutoPartsSection(BuildContext context, String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: Icons.build_circle,
            title: t('product.auto_parts_info'),
            color: AppColors.orange,
          ),
          const SizedBox(height: 16),

          buildFormField(
            label: t('product.shelf_location'),
            child: TextField(
              controller: state.shelfNumberController,
              decoration: inputDecoration(t('product.hint_shelf')).copyWith(
                prefixIcon: const Icon(Icons.shelves, color: AppColors.primary, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // OEM Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('product.oem_numbers'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              TextButton.icon(
                onPressed: () { state.oemNumbers.add({'oemNumber': '', 'manufacturer': ''}); onChanged(); },
                icon: const Icon(Icons.add, size: 16),
                label: Text(t('common.add'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (state.oemNumbers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(t('product.no_oem_yet'), style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ...state.oemNumbers.asMap().entries.map((entry) {
            final i = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: inputDecoration(t('product.hint_oem_no')).copyWith(
                        prefixIcon: const Icon(Icons.confirmation_number, size: 16),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) => state.oemNumbers[i]['oemNumber'] = val,
                      controller: TextEditingController(text: state.oemNumbers[i]['oemNumber']),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: inputDecoration(t('product.manufacturer')).copyWith(isDense: true),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) => state.oemNumbers[i]['manufacturer'] = val,
                      controller: TextEditingController(text: state.oemNumbers[i]['manufacturer']),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                    onPressed: () { state.oemNumbers.removeAt(i); onChanged(); },
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),

          // Cross References
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('product.cross_references'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              TextButton.icon(
                onPressed: () { state.crossReferences.add({'crossRefNumber': '', 'crossRefBrand': '', 'notes': ''}); onChanged(); },
                icon: const Icon(Icons.add, size: 16),
                label: Text(t('common.add'), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (state.crossReferences.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(t('product.no_cross_ref_yet'), style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ...state.crossReferences.asMap().entries.map((entry) {
            final i = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: inputDecoration(t('product.hint_ref_no')).copyWith(
                        prefixIcon: const Icon(Icons.compare_arrows, size: 16),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) => state.crossReferences[i]['crossRefNumber'] = val,
                      controller: TextEditingController(text: state.crossReferences[i]['crossRefNumber']),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: inputDecoration(t('product.hint_brand_ref')).copyWith(isDense: true),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (val) => state.crossReferences[i]['crossRefBrand'] = val,
                      controller: TextEditingController(text: state.crossReferences[i]['crossRefBrand']),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                    onPressed: () { state.crossReferences.removeAt(i); onChanged(); },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
