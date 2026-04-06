import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../widgets/wizard_common_widgets.dart';
import '../widgets/multi_select_chips.dart';
import '../widgets/bulk_dialogs.dart';
import '../../core/widgets/widgets.dart';

class StockBarcodeStep extends StatelessWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const StockBarcodeStep({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
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
      {'label': '\ud83d\udce6 Toplam\nStok', 'value': '$totalStock', 'color': AppColors.success},
      {'label': '\ud83d\udcb5 Al\u0131\u015f\nDe\u011feri', 'value': '\u20ba${totalPurchaseValue.toStringAsFixed(2)}', 'color': AppColors.danger},
      {'label': '\ud83d\udcb0 Sat\u0131\u015f\nDe\u011feri', 'value': '\u20ba${totalSaleValue.toStringAsFixed(2)}', 'color': AppColors.success},
      {'label': '${totalProfit >= 0 ? "\ud83d\udcb0" : "\u26a0\ufe0f"} Toplam\nK\u00e2r', 'value': '\u20ba${totalProfit.toStringAsFixed(2)}', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger},
      {'label': '\ud83d\udcc8 K\u00e2r\nMarj\u0131', 'value': '${profitMargin.toStringAsFixed(1)}%', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger},
      {'label': '\ud83c\udff7\ufe0f Stoklu\nVaryant', 'value': '$variantsWithStock/${state.variants.length}', 'color': AppColors.warning},
    ];

    return Column(
      children: [
        _buildStoreWarehouseSupplier(context),
        const SizedBox(height: 16),
        _buildBulkOperations(context),
        const SizedBox(height: 16),
        _buildVariantsList(context),
        const SizedBox(height: 16),
        _buildAutoPartsSection(context),
        const SizedBox(height: 16),
        buildResponsiveStatGrid(statCards, isMobile: isMobile),
      ],
    );
  }
  Widget _buildStoreWarehouseSupplier(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: isMobile ? 6 : 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.store, color: AppColors.info),
                SizedBox(width: 12),
                Text('Depo, Ma\u011faza ve Tedarik\u00e7i Bilgileri', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          buildFormField(
            label: 'Ma\u011faza',
            required: true,
            child: MultiSelectChips(
              selectedValues: state.selectedStores,
              allOptions: state.stores,
              hintText: 'Ma\u011faza ekle...',
              icon: Icons.store,
              onChanged: (vals) { state.selectedStores = vals; onChanged(); },
            ),
          ),
          const SizedBox(height: 12),

          buildFormField(
            label: 'Depo',
            required: true,
            child: MultiSelectChips(
              selectedValues: state.selectedWarehouses,
              allOptions: state.warehouses,
              hintText: 'Depo ekle...',
              icon: Icons.warehouse,
              onChanged: (vals) { state.selectedWarehouses = vals; onChanged(); },
            ),
          ),
          const SizedBox(height: 12),

          buildFormField(
            label: 'Tedarik\u00e7i',
            child: DropdownButtonFormField<String>(
              value: state.selectedSupplier,
              decoration: inputDecoration('Tedarik\u00e7i se\u00e7in').copyWith(
                prefixIcon: const Icon(Icons.business, color: AppColors.primary, size: 18),
              ),
              items: state.suppliers.map<DropdownMenuItem<String>>((sup) {
                final name = sup['name']?.toString() ?? sup['companyName']?.toString() ?? '-';
                final contact = sup['contactName']?.toString() ?? '';
                final label = contact.isNotEmpty ? '$name ($contact)' : name;
                return DropdownMenuItem<String>(
                  value: sup['id'].toString(),
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) { state.selectedSupplier = val; onChanged(); },
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'Fatura No',
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
                  label: 'Al\u0131\u015f Tarihi',
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
                        decoration: inputDecoration('Tarih se\u00e7in').copyWith(
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
  Widget _buildBulkOperations(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: isMobile ? 6 : 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('H\u0131zl\u0131 Toplu \u0130\u015flemler', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('T\u00fcm varyantlara ayn\u0131 de\u011feri ata', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showBulkStockDialog(context: context, state: state, onChanged: onChanged),
                  icon: Icon(Icons.inventory_2, size: isMobile ? 18 : 20),
                  label: Text(isMobile ? 'Stok' : 'Stok Uygula', style: TextStyle(fontSize: isMobile ? 11 : 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 12 : 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showBulkPurchasePriceDialog(context: context, state: state, onChanged: onChanged),
                  icon: Icon(Icons.attach_money, size: isMobile ? 18 : 20),
                  label: Text(isMobile ? 'Al\u0131\u015f' : 'Al\u0131\u015f Fiyat\u0131', style: TextStyle(fontSize: isMobile ? 11 : 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 12 : 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showBulkSalePriceDialog(context: context, state: state, onChanged: onChanged),
                  icon: Icon(Icons.sell, size: isMobile ? 18 : 20),
                  label: Text(isMobile ? 'Sat\u0131\u015f' : 'Sat\u0131\u015f Fiyat\u0131', style: TextStyle(fontSize: isMobile ? 11 : 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 12 : 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildVariantsList(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: isMobile ? 6 : 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Varyant Stok Bilgileri (${state.variants.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.variants.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final variant = state.variants[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(variant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('stock_${variant.sku}_${variant.inventory?.physicalQuantity}'),
                          initialValue: variant.inventory?.physicalQuantity.toString() ?? '0',
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration('Stok').copyWith(prefixIcon: const Icon(Icons.inventory_2, size: 18)),
                          onChanged: (val) {
                            final qty = int.tryParse(val) ?? 0;
                            if (variant.inventory == null) {
                              variant.inventory = InventoryInfo(
                                warehouseCode: state.selectedWarehouses.isNotEmpty ? state.selectedWarehouses.first : 'WH-001',
                                physicalQuantity: qty,
                              );
                            } else {
                              variant.inventory!.physicalQuantity = qty;
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
                          decoration: inputDecoration('Al\u0131\u015f').copyWith(
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
                          decoration: inputDecoration('Sat\u0131\u015f').copyWith(
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
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _buildAutoPartsSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: isMobile ? 6 : 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.build_circle, color: AppColors.orange),
                SizedBox(width: 12),
                Text('Oto Parca Bilgileri', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          buildFormField(
            label: 'Raf Konumu',
            child: TextField(
              controller: state.shelfNumberController,
              decoration: inputDecoration('Ornek: A-03-R2').copyWith(
                prefixIcon: const Icon(Icons.shelves, color: AppColors.primary, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // OEM Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('OEM Numaralari', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              TextButton.icon(
                onPressed: () { state.oemNumbers.add({'oemNumber': '', 'manufacturer': ''}); onChanged(); },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ekle', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (state.oemNumbers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Henuz OEM numarasi eklenmedi', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                      decoration: inputDecoration('OEM No (ornek: 04465-02220)').copyWith(
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
                      decoration: inputDecoration('Uretici').copyWith(isDense: true),
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
              const Text('Capraz Referanslar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              TextButton.icon(
                onPressed: () { state.crossReferences.add({'crossRefNumber': '', 'crossRefBrand': '', 'notes': ''}); onChanged(); },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ekle', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (state.crossReferences.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Henuz capraz referans eklenmedi', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                      decoration: inputDecoration('Referans No (ornek: GDB3550)').copyWith(
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
                      decoration: inputDecoration('Marka (ornek: TRW)').copyWith(isDense: true),
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
