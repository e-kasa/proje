import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../widgets/wizard_common_widgets.dart';
import '../widgets/category_picker.dart';

class BasicInfoStep extends StatelessWidget {
  final WizardState state;
  final VoidCallback onChanged;
  final bool isMobile;

  const BasicInfoStep({
    super.key,
    required this.state,
    required this.onChanged,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBasicInfoCard(context),
        const SizedBox(height: 16),
        _buildPricingCard(context),
        const SizedBox(height: 16),
        if (state.isParcaci) ...[
          _buildAutoPartsCard(context),
          const SizedBox(height: 16),
        ],
        if (state.isGiyim) ...[
          _buildClothingCard(context),
          const SizedBox(height: 16),
        ],
        _buildTaxCard(context),
      ],
    );
  }

  // ─── Basic Info ───────────────────────────────────────────────────────────

  Widget _buildBasicInfoCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              icon: Icons.info_outline_rounded, title: 'Temel Bilgiler'),
          const SizedBox(height: 14),
          buildFormField(
            label: 'Ürün Adı',
            required: true,
            child: TextField(
              controller: state.productNameController,
              decoration: inputDecoration(
                state.isParcaci
                    ? 'Örn: Ön Fren Balatası Takımı'
                    : state.isGiyim
                        ? 'Örn: Slim Fit Erkek Tişört'
                        : 'Ürün adını girin',
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'SKU',
                  required: true,
                  child: TextField(
                    controller: state.skuController,
                    decoration: inputDecoration('Stok Kodu').copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.primary, size: 20),
                        onPressed: () {
                          state.generateSKU();
                          onChanged();
                        },
                        tooltip: 'Otomatik üret',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Kategori',
                  required: true,
                  child:
                      CategoryPickerButton(state: state, onChanged: onChanged),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'Marka',
                  child: Autocomplete<String>(
                    initialValue:
                        TextEditingValue(text: state.brandController.text),
                    optionsBuilder: (textEditingValue) {
                      final query = textEditingValue.text.toLowerCase();
                      if (query.isEmpty) {
                        return state.brands
                            .map((b) => b['name']?.toString() ?? '');
                      }
                      return state.brands
                          .map((b) => b['name']?.toString() ?? '')
                          .where(
                              (name) => name.toLowerCase().contains(query));
                    },
                    onSelected: (selection) {
                      state.brandController.text = selection;
                      onChanged();
                    },
                    fieldViewBuilder:
                        (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: inputDecoration('Marka ara...').copyWith(
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.primary, size: 18),
                        ),
                        onChanged: (val) => state.brandController.text = val,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final name = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.label_outline,
                                      size: 16, color: AppColors.primary),
                                  title: Text(name),
                                  onTap: () => onSelected(name),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Birim',
                  child: DropdownButtonFormField<String>(
                    value: state.selectedUnit,
                    decoration: inputDecoration('Birim'),
                    items: state.units.map<DropdownMenuItem<String>>((unit) {
                      return DropdownMenuItem<String>(
                        value: unit['value'],
                        child: Text(unit['label'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      state.selectedUnit = val ?? 'pcs';
                      onChanged();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          buildFormField(
            label: 'Açıklama',
            child: TextField(
              controller: state.descriptionController,
              maxLines: 2,
              decoration: inputDecoration('Ürün hakkında kısa bilgi...'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pricing ──────────────────────────────────────────────────────────────

  Widget _buildPricingCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              icon: Icons.payments_rounded, title: 'Fiyatlandırma'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'Alış Fiyatı',
                  child: TextField(
                    controller: state.basePurchasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: inputDecoration('0.00').copyWith(
                      prefixText: '₺ ',
                      prefixStyle: const TextStyle(
                          color: AppColors.danger, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Satış Fiyatı',
                  required: true,
                  child: TextField(
                    controller: state.basePriceController,
                    keyboardType: TextInputType.number,
                    decoration: inputDecoration('0.00').copyWith(
                      prefixText: '₺ ',
                      prefixStyle: const TextStyle(
                          color: AppColors.success, fontWeight: FontWeight.w600),
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

  // ─── Auto Parts ───────────────────────────────────────────────────────────

  Widget _buildAutoPartsCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.build_circle_rounded,
            title: 'Oto Parça Bilgileri',
            color: AppColors.orange,
          ),
          const SizedBox(height: 14),
          buildFormField(
            label: 'Raf Konumu',
            child: TextField(
              controller: state.shelfNumberController,
              decoration: inputDecoration('Örn: A-03-R2').copyWith(
                prefixIcon: Icon(Icons.shelves,
                    color: AppColors.orange, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // OEM Numbers
          _buildDynamicList(
            title: 'OEM Numaraları',
            icon: Icons.confirmation_number_rounded,
            items: state.oemNumbers,
            onAdd: () {
              state.oemNumbers
                  .add({'oemNumber': '', 'manufacturer': ''});
              onChanged();
            },
            onRemove: (i) {
              state.oemNumbers.removeAt(i);
              onChanged();
            },
            itemBuilder: (i) => Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration:
                        inputDecoration('OEM No (örn: 04465-02220)')
                            .copyWith(isDense: true),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) =>
                        state.oemNumbers[i]['oemNumber'] = val,
                    controller: TextEditingController(
                        text: state.oemNumbers[i]['oemNumber']),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration:
                        inputDecoration('Üretici').copyWith(isDense: true),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) =>
                        state.oemNumbers[i]['manufacturer'] = val,
                    controller: TextEditingController(
                        text: state.oemNumbers[i]['manufacturer']),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Cross References
          _buildDynamicList(
            title: 'Çapraz Referanslar',
            icon: Icons.compare_arrows_rounded,
            items: state.crossReferences,
            onAdd: () {
              state.crossReferences.add(
                  {'crossRefNumber': '', 'crossRefBrand': '', 'notes': ''});
              onChanged();
            },
            onRemove: (i) {
              state.crossReferences.removeAt(i);
              onChanged();
            },
            itemBuilder: (i) => Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration:
                        inputDecoration('Referans No (örn: GDB3550)')
                            .copyWith(isDense: true),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) =>
                        state.crossReferences[i]['crossRefNumber'] = val,
                    controller: TextEditingController(
                        text: state.crossReferences[i]['crossRefNumber']),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: inputDecoration('Marka (örn: TRW)')
                        .copyWith(isDense: true),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) =>
                        state.crossReferences[i]['crossRefBrand'] = val,
                    controller: TextEditingController(
                        text: state.crossReferences[i]['crossRefBrand']),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicList({
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required Widget Function(int) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Ekle', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 22),
            child: Text('Henüz eklenmedi',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ...items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: itemBuilder(entry.key)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.danger, size: 20),
                  onPressed: () => onRemove(entry.key),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Clothing ─────────────────────────────────────────────────────────────

  Widget _buildClothingCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.checkroom_rounded,
            title: 'Giyim Bilgileri',
            color: AppColors.pink,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'Kumaş / Materyal',
                  child: TextField(
                    controller: state.fabricController,
                    decoration: inputDecoration('Örn: %100 Pamuk'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Sezon',
                  child: TextField(
                    controller: state.seasonController,
                    decoration: inputDecoration('Örn: 2026 İlkbahar-Yaz'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tax ───────────────────────────────────────────────────────────────────

  Widget _buildTaxCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              icon: Icons.receipt_long_rounded, title: 'Vergi Bilgileri'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: buildFormField(
                  label: 'KDV Oranı',
                  child: DropdownButtonFormField<double>(
                    value: state.selectedVatRate,
                    decoration: inputDecoration('KDV %'),
                    items: const [
                      DropdownMenuItem(value: 0.0, child: Text('% 0 — Muaf')),
                      DropdownMenuItem(value: 1.0, child: Text('% 1')),
                      DropdownMenuItem(value: 8.0, child: Text('% 8')),
                      DropdownMenuItem(value: 10.0, child: Text('% 10')),
                      DropdownMenuItem(value: 18.0, child: Text('% 18')),
                      DropdownMenuItem(value: 20.0, child: Text('% 20')),
                    ],
                    onChanged: (val) {
                      state.selectedVatRate = val ?? 20.0;
                      onChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'ÖTV %',
                  child: TextField(
                    controller: state.specialTaxRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: inputDecoration('Opsiyonel'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Stopaj %',
                  child: TextField(
                    controller: state.withholdingTaxRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: inputDecoration('Opsiyonel'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _toggleChip(
                label: 'Fiyat KDV Dahil',
                value: state.vatIncluded,
                onTap: () {
                  state.vatIncluded = !state.vatIncluded;
                  onChanged();
                },
                activeColor: AppColors.success,
              )),
              const SizedBox(width: 12),
              Expanded(child: _toggleChip(
                label: 'Vergiden Muaf',
                value: state.taxExempt,
                onTap: () {
                  state.taxExempt = !state.taxExempt;
                  onChanged();
                },
                activeColor: AppColors.secondary,
              )),
            ],
          ),
        ],
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

  Widget _toggleChip({
    required String label,
    required bool value,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: value ? activeColor : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              value
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: value ? activeColor : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color:
                          value ? activeColor : AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Section Header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Row(
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: c),
        ),
      ],
    );
  }
}

