import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/sector_config.dart';
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

  Color get _accentColor => switch (state.sectorType) {
        SectorType.autoParts => AppColors.orange,
        SectorType.footwear => AppColors.pink,
        SectorType.technology => AppColors.info,
        SectorType.general => AppColors.primary,
      };

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
          _SectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Temel Bilgiler',
            subtitle: state.sectorType.displayName,
          ),
          const SizedBox(height: 16),
          buildFormField(
            label: 'Urun Adi',
            required: true,
            child: TextField(
              controller: state.productNameController,
              decoration: inputDecoration(
                state.isParcaci
                    ? 'Orn: On Fren Balatasi Takimi'
                    : state.isGiyim
                        ? 'Orn: Slim Fit Erkek Tisort'
                        : 'Urun adini girin',
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
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded,
                                color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              if (state.skuController.text.isNotEmpty) {
                                Clipboard.setData(ClipboardData(
                                    text: state.skuController.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        const Text('SKU kopyalandi'),
                                    duration:
                                        const Duration(milliseconds: 1200),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.dark,
                                  ),
                                );
                              }
                            },
                            tooltip: 'Kopyala',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded,
                                color: AppColors.primary, size: 20),
                            onPressed: () {
                              state.generateSKU();
                              onChanged();
                            },
                            tooltip: 'Otomatik uret',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                          const SizedBox(width: 4),
                        ],
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
            label: 'Aciklama',
            child: TextField(
              controller: state.descriptionController,
              maxLines: 2,
              decoration: inputDecoration('Urun hakkinda kisa bilgi...'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pricing ──────────────────────────────────────────────────────────────

  Widget _buildProfitBadge() {
    final purchase =
        double.tryParse(state.basePurchasePriceController.text) ?? 0;
    final sale = double.tryParse(state.basePriceController.text) ?? 0;

    if (purchase <= 0 || sale <= 0) return const SizedBox.shrink();

    final profit = sale - purchase;
    final margin = (profit / purchase) * 100;
    final isPositive = profit > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive
            ? AppColors.success.withOpacity(0.08)
            : AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.danger.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 16,
            color: isPositive ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 6),
          Text(
            'Kar: ${profit >= 0 ? "+" : ""}${profit.toStringAsFixed(2)} TL (${margin.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context) {
    final priceFields = [
      Expanded(
        child: buildFormField(
          label: 'Alis Fiyati',
          child: TextField(
            controller: state.basePurchasePriceController,
            keyboardType: TextInputType.number,
            decoration: inputDecoration('0.00').copyWith(
              prefixText: 'TL ',
              prefixStyle: const TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ),
      SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 12 : 0),
      Expanded(
        child: buildFormField(
          label: 'Satis Fiyati',
          required: true,
          child: TextField(
            controller: state.basePriceController,
            keyboardType: TextInputType.number,
            decoration: inputDecoration('0.00').copyWith(
              prefixText: 'TL ',
              prefixStyle: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w600),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              icon: Icons.payments_rounded, title: 'Fiyatlandirma'),
          const SizedBox(height: 16),
          if (isMobile)
            Column(children: priceFields)
          else
            Row(children: priceFields),
          const SizedBox(height: 10),
          _buildProfitBadge(),
        ],
      ),
    );
  }

  // ─── Auto Parts ───────────────────────────────────────────────────────────

  Widget _buildAutoPartsCard(BuildContext context) {
    return _card(
      accentBorderColor: AppColors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.build_circle_rounded,
            title: 'Oto Parca Bilgileri',
            color: AppColors.orange,
          ),
          const SizedBox(height: 16),
          buildFormField(
            label: 'Raf Konumu',
            child: TextField(
              controller: state.shelfNumberController,
              decoration: inputDecoration('Orn: A-03-R2').copyWith(
                prefixIcon: Icon(Icons.shelves,
                    color: AppColors.orange, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // OEM Numbers
          _buildDynamicList(
            title: 'OEM Numaralari',
            icon: Icons.confirmation_number_rounded,
            accentColor: AppColors.orange,
            items: state.oemNumbers,
            emptyIcon: Icons.confirmation_number_outlined,
            emptyText: 'Henuz OEM numarasi eklenmedi',
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
                        inputDecoration('OEM No (orn: 04465-02220)')
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
                        inputDecoration('Uretici').copyWith(isDense: true),
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
          const SizedBox(height: 8),
          Divider(color: AppColors.border.withOpacity(0.5), height: 24),
          const SizedBox(height: 4),

          // Cross References
          _buildDynamicList(
            title: 'Capraz Referanslar',
            icon: Icons.compare_arrows_rounded,
            accentColor: AppColors.orange,
            items: state.crossReferences,
            emptyIcon: Icons.compare_arrows_outlined,
            emptyText: 'Henuz capraz referans eklenmedi',
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
                        inputDecoration('Referans No (orn: GDB3550)')
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
                    decoration: inputDecoration('Marka (orn: TRW)')
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
    Color accentColor = AppColors.primary,
    IconData emptyIcon = Icons.inbox_rounded,
    String emptyText = 'Henuz eklenmedi',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            if (items.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor),
                ),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add_rounded, size: 16, color: accentColor),
              label: Text('Ekle',
                  style: TextStyle(fontSize: 12, color: accentColor)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.bgLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(emptyIcon,
                    size: 28, color: accentColor.withOpacity(0.3)),
                const SizedBox(height: 6),
                Text(emptyText,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text('Eklemek icin yukardaki "Ekle" butonunu kullanin',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted.withOpacity(0.5))),
              ],
            ),
          ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final isEven = index % 2 == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isEven
                  ? Colors.transparent
                  : AppColors.bgLight.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border.withOpacity(isEven ? 0.3 : 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: itemBuilder(index)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.danger, size: 20),
                  onPressed: () => onRemove(index),
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
      accentBorderColor: AppColors.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.checkroom_rounded,
            title: 'Giyim Bilgileri',
            color: AppColors.pink,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildFormField(
                  label: 'Kumas / Materyal',
                  child: TextField(
                    controller: state.fabricController,
                    decoration: inputDecoration('Orn: %100 Pamuk'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildFormField(
                  label: 'Sezon',
                  child: TextField(
                    controller: state.seasonController,
                    decoration: inputDecoration('Orn: 2026 Ilkbahar-Yaz'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: buildFormField(
                  label: 'KDV Orani',
                  child: DropdownButtonFormField<double>(
                    value: state.selectedVatRate,
                    decoration: inputDecoration('KDV %'),
                    items: const [
                      DropdownMenuItem(value: 0.0, child: Text('% 0 -- Muaf')),
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
                  label: 'OTV %',
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
              Expanded(
                  child: _toggleChip(
                label: 'Fiyat KDV Dahil',
                value: state.vatIncluded,
                onTap: () {
                  state.vatIncluded = !state.vatIncluded;
                  onChanged();
                },
                activeColor: AppColors.success,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _toggleChip(
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

  Widget _card({required Widget child, Color? accentBorderColor}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (accentBorderColor != null)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentBorderColor,
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: child,
              ),
            ),
          ],
        ),
      ),
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
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: c),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: c),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.withOpacity(0.4), c.withOpacity(0.0)],
              stops: const [0.0, 1.0],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

