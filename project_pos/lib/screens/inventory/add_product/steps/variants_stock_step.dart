import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../widgets/wizard_common_widgets.dart';
import '../widgets/multi_select_chips.dart';
import '../widgets/variant_dialogs.dart';
import '../widgets/bulk_dialogs.dart';

class VariantsStockStep extends StatelessWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const VariantsStockStep({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProductTypeCard(context),
        const SizedBox(height: 16),
        if (state.productType == 'variant') ...[
          _buildAttributesCard(context),
          const SizedBox(height: 16),
          if (state.variants.isNotEmpty &&
              state.variants.first.attributes.isNotEmpty) ...[
            _buildVariantPreview(context),
            const SizedBox(height: 16),
          ],
        ],
        _buildLocationCard(context),
        const SizedBox(height: 16),
        _buildStockCard(context),
      ],
    );
  }

  // ─── Product Type ─────────────────────────────────────────────────────────

  Widget _buildProductTypeCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.layers_rounded, 'Ürün Tipi'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _typeOption(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  label: 'Basit Ürün',
                  subtitle: 'Tek varyant',
                  selected: state.productType == 'simple',
                  onTap: () {
                    state.productType = 'simple';
                    state.generateVariants(context);
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _typeOption(
                  context: context,
                  icon: Icons.layers_rounded,
                  label: 'Varyantlı',
                  subtitle: state.isParcaci
                      ? 'Marka, araç grubu'
                      : state.isGiyim
                          ? 'Renk, beden'
                          : 'Farklı özellikler',
                  selected: state.productType == 'variant',
                  onTap: () {
                    state.productType = 'variant';
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          if (state.productType == 'simple') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Basit ürün olarak oluşturulacak — SKU: ${state.variants.isNotEmpty ? state.variants[0].sku : "-"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 36,
                color:
                    selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── Attributes ───────────────────────────────────────────────────────────

  Widget _buildAttributesCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.tune_rounded, 'Özellikler & Varyantlar'),
          const SizedBox(height: 14),

          // Preset buttons
          _buildPresetRow(context),
          const SizedBox(height: 14),

          // Attribute list
          if (state.attributes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.border, style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Şablon seçin veya "Yeni Özellik" ile özel özellik ekleyin',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...state.attributes.asMap().entries.map((entry) {
              return _buildAttributeRow(context, entry.key, entry.value);
            }),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  state.generateVariants(context);
                  onChanged();
                },
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(
                    'Varyantları Oluştur (${state.calculateTotalVariants()})'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetRow(BuildContext context) {
    final presetLabels = {
      'auto_parts': ('Oto Parça', Icons.build_circle_rounded),
      'clothing': ('Giyim', Icons.checkroom_rounded),
      'electronics': ('Elektronik', Icons.computer_rounded),
      'shoes': ('Ayakkabı', Icons.ice_skating_rounded),
      'custom': ('Özel', Icons.add_circle_outline_rounded),
    };

    final visiblePresets = state.getSectorPresets();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visiblePresets.map((key) {
          final info = presetLabels[key];
          if (info == null) return const SizedBox();
          final isSelected = state.selectedPreset == key;
          return ActionChip(
            avatar: Icon(info.$2,
                size: 16,
                color:
                    isSelected ? AppColors.primary : AppColors.textMuted),
            label: Text(info.$1,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary)),
            backgroundColor: isSelected
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.bgLight,
            side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border),
            onPressed: () {
              if (key == 'custom') {
                state.selectedPreset = 'custom';
                state.attributes = [];
              } else {
                state.applyPreset(key);
              }
              onChanged();
            },
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add_rounded,
              size: 16, color: AppColors.success),
          label: const Text('Yeni Özellik',
              style: TextStyle(fontSize: 12, color: AppColors.success)),
          backgroundColor: AppColors.success.withOpacity(0.06),
          side: BorderSide(color: AppColors.success.withOpacity(0.3)),
          onPressed: () => showAddAttributeDialog(
              context: context, state: state, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildAttributeRow(
      BuildContext context, int index, ProductAttribute attr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(attr.icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(attr.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              InkWell(
                onTap: () {
                  state.removeAttribute(index);
                  onChanged();
                },
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...attr.values.asMap().entries.map((entry) {
                return Chip(
                  label:
                      Text(entry.value, style: const TextStyle(fontSize: 11)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  onDeleted: () {
                    state.removeValueFromAttribute(index, entry.key);
                    onChanged();
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.primary.withOpacity(0.06),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                );
              }),
              ActionChip(
                label:
                    const Text('+ Ekle', style: TextStyle(fontSize: 11)),
                onPressed: () => showAddValueDialog(
                    context: context,
                    state: state,
                    attrIndex: index,
                    attrName: attr.name,
                    onChanged: onChanged),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColors.success.withOpacity(0.06),
                side:
                    BorderSide(color: AppColors.success.withOpacity(0.2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Variant Preview ──────────────────────────────────────────────────────

  Widget _buildVariantPreview(BuildContext context) {
    final displayLimit = state.showAllVariants ? state.variants.length : 5;
    final displayed = state.variants.take(displayLimit).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _header(Icons.preview_rounded, 'Varyant Önizleme'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.variants.length} varyant',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...displayed.asMap().entries.map((entry) {
            final v = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text('${entry.key + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('SKU: ${v.sku}',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: v.attributes.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${e.key}: ${e.value}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          if (state.variants.length > 5)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  state.showAllVariants = !state.showAllVariants;
                  onChanged();
                },
                icon: Icon(
                    state.showAllVariants
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18),
                label: Text(
                  state.showAllVariants
                      ? 'Daha az göster'
                      : 'Tümünü göster (+${state.variants.length - 5})',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Location (Store / Warehouse / Supplier) ──────────────────────────────

  Widget _buildLocationCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.location_on_rounded, 'Konum & Tedarikçi'),
          const SizedBox(height: 14),
          buildFormField(
            label: 'Mağaza',
            required: true,
            child: MultiSelectChips(
              selectedValues: state.selectedStores,
              allOptions: state.stores,
              hintText: 'Mağaza ekle...',
              icon: Icons.store_rounded,
              onChanged: (vals) {
                state.selectedStores = vals;
                onChanged();
              },
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
              icon: Icons.warehouse_rounded,
              onChanged: (vals) {
                state.selectedWarehouses = vals;
                onChanged();
              },
            ),
          ),
          const SizedBox(height: 12),
          buildFormField(
            label: 'Tedarikçi',
            child: DropdownButtonFormField<String>(
              value: state.selectedSupplier,
              decoration: inputDecoration('Tedarikçi seçin').copyWith(
                prefixIcon: const Icon(Icons.business_rounded,
                    color: AppColors.primary, size: 18),
              ),
              items: state.suppliers.map<DropdownMenuItem<String>>((sup) {
                final name = sup['name']?.toString() ??
                    sup['companyName']?.toString() ??
                    '-';
                return DropdownMenuItem<String>(
                  value: sup['id'].toString(),
                  child: Text(name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                state.selectedSupplier = val;
                onChanged();
              },
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
                    decoration: inputDecoration('FT-2024-001'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Alış Tarihi',
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            state.purchaseDateController.text.isNotEmpty
                                ? DateTime.tryParse(
                                        state.purchaseDateController.text) ??
                                    DateTime.now()
                                : DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
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
                        decoration:
                            inputDecoration('Tarih seçin').copyWith(
                          prefixIcon: const Icon(Icons.calendar_today_rounded,
                              color: AppColors.primary, size: 18),
                          suffixIcon:
                              state.purchaseDateController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 16),
                                      onPressed: () {
                                        state.purchaseDateController.clear();
                                        onChanged();
                                      },
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

  // ─── Stock ────────────────────────────────────────────────────────────────

  Widget _buildStockCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.inventory_rounded, 'Stok & Barkod'),
          const SizedBox(height: 10),

          // Bulk operations row
          if (state.variants.length > 1) ...[
            Row(
              children: [
                Text('Toplu İşlem:',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                _bulkButton(
                  label: 'Stok',
                  color: AppColors.info,
                  onTap: () => showBulkStockDialog(
                      context: context, state: state, onChanged: onChanged),
                ),
                const SizedBox(width: 6),
                _bulkButton(
                  label: 'Alış',
                  color: AppColors.danger,
                  onTap: () => showBulkPurchasePriceDialog(
                      context: context, state: state, onChanged: onChanged),
                ),
                const SizedBox(width: 6),
                _bulkButton(
                  label: 'Satış',
                  color: AppColors.success,
                  onTap: () => showBulkSalePriceDialog(
                      context: context, state: state, onChanged: onChanged),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Variant stock list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.variants.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final variant = state.variants[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(variant.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(
                              'stock_${variant.sku}_${variant.inventory?.physicalQuantity}'),
                          initialValue:
                              variant.inventory?.physicalQuantity.toString() ??
                                  '0',
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration('Stok').copyWith(
                              prefixIcon: const Icon(
                                  Icons.inventory_2_rounded,
                                  size: 18)),
                          onChanged: (val) {
                            final qty = int.tryParse(val) ?? 0;
                            if (variant.inventory == null) {
                              variant.inventory = InventoryInfo(
                                warehouseCode:
                                    state.selectedWarehouses.isNotEmpty
                                        ? state.selectedWarehouses.first
                                        : 'WH-001',
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
                          key: ValueKey(
                              'purchase_${variant.sku}_${variant.purchasePrice}'),
                          initialValue:
                              variant.purchasePrice.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration('Alış ₺').copyWith(
                              prefixIcon: const Icon(Icons.arrow_downward_rounded,
                                  size: 18, color: AppColors.danger)),
                          onChanged: (val) {
                            variant.purchasePrice =
                                double.tryParse(val) ?? 0;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(
                              'sale_${variant.sku}_${variant.salePrice}'),
                          initialValue:
                              variant.salePrice.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration('Satış ₺').copyWith(
                              prefixIcon: const Icon(Icons.arrow_upward_rounded,
                                  size: 18, color: AppColors.success)),
                          onChanged: (val) {
                            variant.salePrice =
                                double.tryParse(val) ?? 0;
                            onChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bulkButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: child,
    );
  }

  Widget _header(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ],
    );
  }
}
