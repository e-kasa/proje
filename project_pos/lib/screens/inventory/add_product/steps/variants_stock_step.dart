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

  // ─── Sector Accent Color ─────────────────────────────────────────────────

  Color get _accentColor => switch (state.sectorType) {
    SectorType.autoParts => AppColors.orange,
    SectorType.footwear => AppColors.pink,
    SectorType.technology => AppColors.info,
    SectorType.general => AppColors.primary,
  };

  // ─── Attribute Color Palette ─────────────────────────────────────────────

  static const List<Color> _attrColors = [
    AppColors.primary,
    AppColors.teal,
    AppColors.orange,
    AppColors.pink,
    AppColors.purple,
    AppColors.info,
    AppColors.cyan,
  ];

  Color _colorForAttrIndex(int index) => _attrColors[index % _attrColors.length];

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
          _header(Icons.layers_rounded, 'Urun Tipi'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _typeOption(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  label: 'Basit Urun',
                  subtitle: _simpleDescription,
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
                  label: 'Varyantli',
                  subtitle: _variantDescription,
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
                      'Basit urun olarak olusturulacak -- SKU: ${state.variants.isNotEmpty ? state.variants[0].sku : "-"}',
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

  String get _simpleDescription => switch (state.sectorType) {
    SectorType.autoParts => 'Tek parca, varyant yok',
    SectorType.footwear => 'Tek model, beden/renk yok',
    SectorType.technology => 'Tek konfigürasyon',
    SectorType.general => 'Tek varyant',
  };

  String get _variantDescription => switch (state.sectorType) {
    SectorType.autoParts => 'Marka, arac grubu',
    SectorType.footwear => 'Renk, beden, numara',
    SectorType.technology => 'RAM, depolama, renk',
    SectorType.general => 'Farkli ozellikler',
  };

  Widget _typeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = _accentColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withOpacity(0.12)
                    : AppColors.bgLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 24,
                  color: selected ? accent : AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? accent : AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── Attributes ───────────────────────────────────────────────────────────

  Widget _buildAttributesCard(BuildContext context) {
    final accent = _accentColor;
    final hasValuesForGenerate = state.attributes
        .any((attr) => attr.values.isNotEmpty);
    final totalVariants = state.calculateTotalVariants();

    return _card(
      accentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.tune_rounded, 'Ozellikler & Varyantlar'),
          const SizedBox(height: 14),

          // Preset buttons
          _buildPresetRow(context),
          const SizedBox(height: 14),

          // Attribute list
          if (state.attributes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.border, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.widgets_outlined,
                      color: AppColors.textMuted.withOpacity(0.5), size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Henuz ozellik eklenmedi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sablon secin veya "Yeni Ozellik" ile ozel ozellik ekleyin',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            ...state.attributes.asMap().entries.map((entry) {
              return _buildAttributeRow(context, entry.key, entry.value);
            }),
            const SizedBox(height: 16),

            // Generate variants button
            SizedBox(
              width: double.infinity,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: hasValuesForGenerate
                      ? () {
                          state.generateVariants(context);
                          onChanged();
                        }
                      : null,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: hasValuesForGenerate
                          ? LinearGradient(
                              colors: [accent, accent.withOpacity(0.8)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: hasValuesForGenerate
                          ? null
                          : AppColors.textMuted.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 20,
                              color: hasValuesForGenerate
                                  ? Colors.white
                                  : AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            'Varyantlari Olustur',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: hasValuesForGenerate
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                          ),
                          if (totalVariants > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                    hasValuesForGenerate ? 0.25 : 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$totalVariants',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: hasValuesForGenerate
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetRow(BuildContext context) {
    final accent = _accentColor;
    final presetLabels = {
      'auto_parts': ('Oto Parca', Icons.build_circle_rounded),
      'clothing': ('Giyim', Icons.checkroom_rounded),
      'electronics': ('Elektronik', Icons.computer_rounded),
      'shoes': ('Ayakkabi', Icons.ice_skating_rounded),
      'custom': ('Ozel', Icons.add_circle_outline_rounded),
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
                color: isSelected ? Colors.white : AppColors.textMuted),
            label: Text(info.$1,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary)),
            backgroundColor: isSelected
                ? accent
                : AppColors.bgLight,
            side: BorderSide(
                color: isSelected ? accent : AppColors.border),
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
          label: const Text('Yeni Ozellik',
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
    final attrColor = _colorForAttrIndex(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.drag_handle_rounded,
                  size: 16, color: AppColors.textMuted.withOpacity(0.4)),
              const SizedBox(width: 4),
              Icon(attr.icon, size: 16, color: attrColor),
              const SizedBox(width: 6),
              Text(attr.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: attrColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${attr.values.length} deger',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: attrColor),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  state.removeAttribute(index);
                  onChanged();
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...attr.values.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value,
                      style: TextStyle(
                          fontSize: 11,
                          color: attrColor,
                          fontWeight: FontWeight.w500)),
                  deleteIcon: Icon(Icons.close_rounded,
                      size: 14, color: attrColor.withOpacity(0.6)),
                  onDeleted: () {
                    state.removeValueFromAttribute(index, entry.key);
                    onChanged();
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: attrColor.withOpacity(0.08),
                  side: BorderSide(color: attrColor.withOpacity(0.2)),
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
    final accent = _accentColor;
    final displayLimit = state.showAllVariants ? state.variants.length : 5;
    final displayed = state.variants.take(displayLimit).toList();

    return _card(
      accentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _header(Icons.preview_rounded, 'Varyant Onizleme'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.variants.length} varyant',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...displayed.asMap().entries.map((entry) {
            final v = entry.value;
            final isEven = entry.key.isEven;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 14, vertical: isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: isEven
                    ? AppColors.bgLight
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  // Variant index
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withOpacity(0.15),
                          accent.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('${entry.key + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent)),
                  ),
                  const SizedBox(width: 10),
                  // Name and SKU
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(v.sku,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) const SizedBox(width: 8),
                  // Attribute chips
                  if (!isMobile)
                    Wrap(
                      spacing: 4,
                      children: v.attributes.entries.map((e) {
                        final attrIdx = state.attributes
                            .indexWhere((a) => a.name == e.key);
                        final chipColor =
                            attrIdx >= 0 ? _colorForAttrIndex(attrIdx) : AppColors.info;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: chipColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: chipColor.withOpacity(0.2)),
                          ),
                          child: Text(e.value,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: chipColor)),
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
                    size: 18,
                    color: accent),
                label: Text(
                  state.showAllVariants
                      ? 'Daha az goster'
                      : 'Tumunu goster (+${state.variants.length - 5})',
                  style: TextStyle(fontSize: 12, color: accent),
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
          _header(Icons.location_on_rounded, 'Konum & Tedarikci'),
          const SizedBox(height: 14),
          buildFormField(
            label: 'Magaza',
            required: true,
            child: MultiSelectChips(
              selectedValues: state.selectedStores,
              allOptions: state.stores,
              hintText: 'Magaza ekle...',
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
            label: 'Tedarikci',
            child: Builder(builder: (context) {
              // Tedarikçiler listesinden güvenli items ve value oluştur
              final supplierItems = state.suppliers
                  .map((sup) => sup['id']?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toSet() // duplicate ID'leri temizle
                  .map<DropdownMenuItem<String>>((id) {
                    final sup = state.suppliers.firstWhere(
                        (s) => s['id']?.toString() == id);
                    final name = sup['name']?.toString() ??
                        sup['companyName']?.toString() ??
                        '-';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(name, overflow: TextOverflow.ellipsis),
                    );
                  })
                  .toList();
              // Value sadece items listesinde varsa kullan, yoksa null
              final safeValue = supplierItems.any(
                      (item) => item.value == state.selectedSupplier)
                  ? state.selectedSupplier
                  : null;
              return DropdownButtonFormField<String>(
                value: safeValue,
                isExpanded: true,
                decoration: inputDecoration('Tedarikci secin').copyWith(
                  prefixIcon: const Icon(Icons.business_rounded,
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
                  label: 'Fatura No',
                  child: TextField(
                    controller: state.invoiceNumberController,
                    decoration: inputDecoration('FT-2024-001').copyWith(
                      prefixIcon: const Icon(Icons.receipt_long_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Alis Tarihi',
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
                            inputDecoration('Tarih secin').copyWith(
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
                const Text('Toplu Islem:',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                _bulkButton(
                  label: 'Stok',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.info,
                  onTap: () => showBulkStockDialog(
                      context: context, state: state, onChanged: onChanged),
                ),
                const SizedBox(width: 6),
                _bulkButton(
                  label: 'Alis',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.danger,
                  onTap: () => showBulkPurchasePriceDialog(
                      context: context, state: state, onChanged: onChanged),
                ),
                const SizedBox(width: 6),
                _bulkButton(
                  label: 'Satis',
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.success,
                  onTap: () => showBulkSalePriceDialog(
                      context: context, state: state, onChanged: onChanged),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Variant stock list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.variants.length,
            itemBuilder: (context, index) {
              final variant = state.variants[index];
              final isEven = index.isEven;
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven
                      ? AppColors.bgLight.withOpacity(0.5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _accentColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(variant.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Stock with stepper
                        Expanded(
                          child: _buildStockStepper(variant),
                        ),
                        const SizedBox(width: 8),
                        // Purchase price
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(
                                'purchase_${variant.sku}_${variant.purchasePrice}'),
                            initialValue:
                                variant.purchasePrice.toStringAsFixed(2),
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration('Alis').copyWith(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 10, right: 4),
                                child: Text('\u20BA',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.danger)),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 0, minHeight: 0),
                            ),
                            onChanged: (val) {
                              variant.purchasePrice =
                                  double.tryParse(val) ?? 0;
                              onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sale price
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(
                                'sale_${variant.sku}_${variant.salePrice}'),
                            initialValue:
                                variant.salePrice.toStringAsFixed(2),
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration('Satis').copyWith(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 10, right: 4),
                                child: Text('\u20BA',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success)),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 0, minHeight: 0),
                            ),
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockStepper(ProductVariant variant) {
    final currentQty = variant.inventory?.physicalQuantity ?? 0;
    return Row(
      children: [
        _stepperButton(
          icon: Icons.remove_rounded,
          onTap: () {
            final newQty = (currentQty - 1).clamp(0, 999999);
            if (variant.inventory == null) {
              variant.inventory = InventoryInfo(
                warehouseCode: state.selectedWarehouses.isNotEmpty
                    ? state.selectedWarehouses.first
                    : 'WH-001',
                physicalQuantity: newQty,
              );
            } else {
              variant.inventory!.physicalQuantity = newQty;
            }
            onChanged();
          },
        ),
        Expanded(
          child: TextFormField(
            key: ValueKey(
                'stock_${variant.sku}_${variant.inventory?.physicalQuantity}'),
            initialValue:
                variant.inventory?.physicalQuantity.toString() ?? '0',
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: inputDecoration('').copyWith(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 12),
            ),
            onChanged: (val) {
              final qty = int.tryParse(val) ?? 0;
              if (variant.inventory == null) {
                variant.inventory = InventoryInfo(
                  warehouseCode: state.selectedWarehouses.isNotEmpty
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
        _stepperButton(
          icon: Icons.add_rounded,
          onTap: () {
            final newQty = currentQty + 1;
            if (variant.inventory == null) {
              variant.inventory = InventoryInfo(
                warehouseCode: state.selectedWarehouses.isNotEmpty
                    ? state.selectedWarehouses.first
                    : 'WH-001',
                physicalQuantity: newQty,
              );
            } else {
              variant.inventory!.physicalQuantity = newQty;
            }
            onChanged();
          },
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _bulkButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child, bool accentBorder = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: accentBorder
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            )
          : child,
    );
  }

  Widget _header(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _accentColor),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _accentColor)),
      ],
    );
  }
}
