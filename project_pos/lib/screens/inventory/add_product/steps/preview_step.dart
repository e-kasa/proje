import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import '../../../../core/config/sector_config.dart';
import '../models/wizard_state.dart';
import '../widgets/variant_image_widgets.dart';

class PreviewStep extends ConsumerWidget {
  final WizardState state;
  final bool isMobile;

  const PreviewStep({
    super.key,
    required this.state,
    required this.isMobile,
  });

  Color get _accentColor => switch (state.sectorType) {
    SectorType.autoParts => AppColors.orange,
    SectorType.footwear => AppColors.pink,
    SectorType.technology => AppColors.info,
    SectorType.general => AppColors.primary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final totalStock = state.variants
        .fold<int>(0, (sum, v) => sum + (v.inventory?.physicalQuantity ?? 0));
    final totalPurchase = state.variants.fold<double>(
        0, (s, v) => s + ((v.inventory?.physicalQuantity ?? 0) * v.purchasePrice));
    final totalSale = state.variants.fold<double>(
        0, (s, v) => s + ((v.inventory?.physicalQuantity ?? 0) * v.salePrice));
    final profit = totalSale - totalPurchase;

    return Column(
      children: [
        _buildSummaryRow(totalStock, totalPurchase, totalSale, profit, t),
        const SizedBox(height: 16),
        _buildProductInfo(t),
        const SizedBox(height: 16),
        if (state.isParcaci &&
            (state.oemNumbers.isNotEmpty ||
                state.crossReferences.isNotEmpty ||
                state.shelfNumberController.text.isNotEmpty)) ...[
          _buildAutoPartsInfo(t),
          const SizedBox(height: 16),
        ],
        _buildLocationInfo(t),
        const SizedBox(height: 16),
        _buildVariantsTable(context, t),
        const SizedBox(height: 16),
        _buildImagesSection(context, t),
        const SizedBox(height: 16),
        _buildJsonPayload(context, t),
      ],
    );
  }

  // ─── Summary Row ──────────────────────────────────────────────────────────

  Widget _buildSummaryRow(
      int stock, double purchase, double sale, double profit, String Function(String) t) {
    final items = [
      _SummaryItem(
        label: t('product.variant'),
        value: '${state.variants.length}',
        color: _accentColor,
        icon: Icons.layers_rounded,
      ),
      _SummaryItem(
        label: t('inventory.stock'),
        value: '$stock',
        color: AppColors.info,
        icon: Icons.inventory_2_rounded,
      ),
      _SummaryItem(
        label: t('product.purchase'),
        value: '\u20ba${purchase.toStringAsFixed(0)}',
        color: AppColors.danger,
        icon: Icons.shopping_cart_rounded,
      ),
      _SummaryItem(
        label: t('product.sale'),
        value: '\u20ba${sale.toStringAsFixed(0)}',
        color: AppColors.success,
        icon: Icons.point_of_sale_rounded,
      ),
      _SummaryItem(
        label: t('product.profit'),
        value: '\u20ba${profit.toStringAsFixed(0)}',
        color: profit >= 0 ? AppColors.success : AppColors.danger,
        icon: Icons.trending_up_rounded,
      ),
    ];

    final child = Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: item != items.last ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withValues(alpha: 0.08),
                  item.color.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.color.withValues(alpha: 0.15)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -4,
                  top: -4,
                  child: Icon(
                    item.icon,
                    size: 32,
                    color: item.color.withValues(alpha: 0.07),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.w800,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: item.color.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(child: child),
      );
    }
    return child;
  }

  // ─── Product Info ─────────────────────────────────────────────────────────

  Widget _buildProductInfo(String Function(String) t) {
    final categoryLabel = state.categories
        .firstWhere((c) => c['value'] == state.selectedCategory,
            orElse: () => <String, String>{'label': '-'})['label']
        ?.toString() ?? '-';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.info_outline_rounded, t('product.product_info')),
          const SizedBox(height: 16),
          _infoRow(t('product.product_name'), state.productNameController.text),
          _divider(),
          _infoRow('SKU', state.skuController.text),
          _divider(),
          _infoRow(t('product.category'), categoryLabel),
          _divider(),
          _infoRow(
            t('product.brand'),
            state.brandController.text.isEmpty
                ? '-'
                : state.brandController.text,
          ),
          _divider(),
          _infoRow(t('product.unit'), state.selectedUnit),
          _divider(),
          _infoRow(t('product.purchase_price'), '\u20ba${state.basePurchasePriceController.text}'),
          _divider(),
          _infoRow(t('product.sale_price'), '\u20ba${state.basePriceController.text}'),
          _divider(),
          _infoRow(
            t('product.vat'),
            '% ${state.selectedVatRate}'
            '${state.vatIncluded ? " (${t('product.included')})" : " (${t('product.excluded')})"}',
          ),
          _divider(),
          _sectorRow(t),
        ],
      ),
    );
  }

  Widget _sectorRow(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              t('product.sector'),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              state.sectorType.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Auto Parts Info ──────────────────────────────────────────────────────

  Widget _buildAutoPartsInfo(String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.build_circle_rounded, t('product.auto_parts_info')),
          const SizedBox(height: 16),
          if (state.shelfNumberController.text.isNotEmpty) ...[
            _infoRow(t('product.shelf_location'), state.shelfNumberController.text),
            if (state.oemNumbers.isNotEmpty || state.crossReferences.isNotEmpty)
              _divider(),
          ],
          if (state.oemNumbers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      t('product.oem_numbers'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state.oemNumbers
                          .map((o) => o['oemNumber'])
                          .where((s) => s != null && s.isNotEmpty)
                          .map((oem) => _chip(
                                oem!,
                                AppColors.orange,
                                Icons.precision_manufacturing_rounded,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            if (state.crossReferences.isNotEmpty) _divider(),
          ],
          if (state.crossReferences.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      t('product.cross_references'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state.crossReferences
                          .map((c) {
                            final num = c['crossRefNumber'] ?? '';
                            final brand = c['crossRefBrand'] ?? '';
                            if (num.isEmpty) return null;
                            final label = brand.isNotEmpty
                                ? '$num ($brand)'
                                : num;
                            return _chip(
                              label,
                              AppColors.info,
                              Icons.compare_arrows_rounded,
                            );
                          })
                          .whereType<Widget>()
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Location Info ────────────────────────────────────────────────────────

  Widget _buildLocationInfo(String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.location_on_rounded, t('product.location')),
          const SizedBox(height: 16),
          _infoRow(
            t('product.store'),
            state.selectedStores.isEmpty
                ? '-'
                : state.selectedStores
                    .map((v) => state.stores
                        .firstWhere((s) => s['value'] == v,
                            orElse: () =>
                                <String, dynamic>{'label': v})['label']
                        ?.toString() ?? v)
                    .join(', '),
          ),
          _divider(),
          _infoRow(
            t('product.warehouse'),
            state.selectedWarehouses.isEmpty
                ? '-'
                : state.selectedWarehouses
                    .map((v) => state.warehouses
                        .firstWhere((w) => w['value'] == v,
                            orElse: () =>
                                <String, dynamic>{'label': v})['label']
                        ?.toString() ?? v)
                    .join(', '),
          ),
        ],
      ),
    );
  }

  // ─── Variants Table ───────────────────────────────────────────────────────

  Widget _buildVariantsTable(BuildContext context, String Function(String) t) {
    final totalStock = state.variants
        .fold<int>(0, (sum, v) => sum + (v.inventory?.physicalQuantity ?? 0));
    final totalPurchase = state.variants.fold<double>(
        0, (s, v) => s + ((v.inventory?.physicalQuantity ?? 0) * v.purchasePrice));
    final totalSale = state.variants.fold<double>(
        0, (s, v) => s + ((v.inventory?.physicalQuantity ?? 0) * v.salePrice));
    final totalProfit = totalSale - totalPurchase;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            Icons.table_chart_rounded,
            '${t('product.variants')} (${state.variants.length})',
          ),
          const SizedBox(height: 12),
          if (isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.swipe_rounded, size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    t('common.scroll_to_see_all'),
                    style: TextStyle(fontSize: 10, color: AppColors.info),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                _accentColor.withValues(alpha: 0.06),
              ),
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              headingRowHeight: 42,
              columnSpacing: isMobile ? 16 : 32,
              horizontalMargin: 8,
              columns: [
                _tableColumn('#'),
                _tableColumn(t('product.variant')),
                _tableColumn('SKU'),
                _tableColumn(t('inventory.stock')),
                _tableColumn(t('product.purchase')),
                _tableColumn(t('product.sale')),
                _tableColumn(t('product.profit')),
              ],
              rows: [
                ...state.variants.asMap().entries.map((entry) {
                  final v = entry.value;
                  final qty = v.inventory?.physicalQuantity ?? 0;
                  final rowProfit = (v.salePrice - v.purchasePrice) * qty;
                  final isZeroStock = qty == 0;

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (isZeroStock) {
                          return AppColors.warning.withValues(alpha: 0.06);
                        }
                        if (entry.key.isOdd) {
                          return AppColors.bgLight.withValues(alpha: 0.5);
                        }
                        return null;
                      },
                    ),
                    cells: [
                      DataCell(Text(
                        '${entry.key + 1}',
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(Text(
                        v.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      DataCell(Text(
                        v.sku,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      )),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isZeroStock)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 13,
                                color: AppColors.warning,
                              ),
                            ),
                          Text(
                            '$qty',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: qty > 0
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      )),
                      DataCell(Text(
                        '\u20ba${v.purchasePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      )),
                      DataCell(Text(
                        '\u20ba${v.salePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      )),
                      DataCell(Text(
                        '\u20ba${rowProfit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: rowProfit >= 0
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      )),
                    ],
                  );
                }),
                // Total row
                DataRow(
                  color: WidgetStateProperty.all(
                    _accentColor.withValues(alpha: 0.08),
                  ),
                  cells: [
                    const DataCell(SizedBox.shrink()),
                    DataCell(Text(
                      t('common.total').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _accentColor,
                      ),
                    )),
                    const DataCell(SizedBox.shrink()),
                    DataCell(Text(
                      '$totalStock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _accentColor,
                      ),
                    )),
                    DataCell(Text(
                      '\u20ba${totalPurchase.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    )),
                    DataCell(Text(
                      '\u20ba${totalSale.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    )),
                    DataCell(Text(
                      '\u20ba${totalProfit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: totalProfit >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _tableColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: _accentColor,
        ),
      ),
    );
  }

  // ─── Images Section ───────────────────────────────────────────────────────

  Widget _buildImagesSection(BuildContext context, String Function(String) t) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _header(Icons.image_rounded, t('product.images')),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.productImages.length} ${t('common.image')}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 4 : 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: state.productImages.length + 1,
            itemBuilder: (context, index) {
              if (index == state.productImages.length) {
                return buildAddImageButton(() {
                  AppToast.info(context, t('product.image_picker_coming'));
                }, isMobile: isMobile, t: t);
              }
              return buildImagePreview(state.productImages[index], () {
                state.productImages.removeAt(index);
              });
            },
          ),
          if (state.productImages.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('product.no_images_yet'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── JSON Payload ─────────────────────────────────────────────────────────

  Widget _buildJsonPayload(BuildContext context, String Function(String) t) {
    final jsonString = state.buildJsonPreview();

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1e293b).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.code_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'API Payload',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: jsonString));
                    AppToast.success(context, t('common.copied'));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copy_rounded,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t('common.copy'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: SingleChildScrollView(
              child: _buildSyntaxHighlightedJson(jsonString),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyntaxHighlightedJson(String json) {
    final spans = <TextSpan>[];
    final keyColor = const Color(0xFF7dd3fc); // light blue
    final stringColor = const Color(0xFF86efac); // light green
    final numberColor = const Color(0xFFfde68a); // light amber
    final boolNullColor = const Color(0xFFc4b5fd); // light purple
    final punctuationColor = Colors.white.withValues(alpha: 0.4);

    final lines = json.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) {
        spans.add(const TextSpan(text: '\n'));
      }
      _highlightLine(
        line,
        spans,
        keyColor: keyColor,
        stringColor: stringColor,
        numberColor: numberColor,
        boolNullColor: boolNullColor,
        punctuationColor: punctuationColor,
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10.5,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }

  void _highlightLine(
    String line,
    List<TextSpan> spans, {
    required Color keyColor,
    required Color stringColor,
    required Color numberColor,
    required Color boolNullColor,
    required Color punctuationColor,
  }) {
    // Match JSON key-value patterns
    final keyValuePattern = RegExp(r'^(\s*)"([^"]+)"(\s*:\s*)(.*)$');
    final match = keyValuePattern.firstMatch(line);

    if (match != null) {
      final indent = match.group(1) ?? '';
      final key = match.group(2) ?? '';
      final colon = match.group(3) ?? '';
      final value = match.group(4) ?? '';

      // Indent
      if (indent.isNotEmpty) {
        spans.add(TextSpan(text: indent, style: TextStyle(color: punctuationColor)));
      }
      // Key with quotes
      spans.add(TextSpan(text: '"', style: TextStyle(color: keyColor)));
      spans.add(TextSpan(text: key, style: TextStyle(color: keyColor, fontWeight: FontWeight.w600)));
      spans.add(TextSpan(text: '"', style: TextStyle(color: keyColor)));
      // Colon
      spans.add(TextSpan(text: colon, style: TextStyle(color: punctuationColor)));
      // Value
      _highlightValue(value, spans,
        stringColor: stringColor,
        numberColor: numberColor,
        boolNullColor: boolNullColor,
        punctuationColor: punctuationColor,
      );
    } else {
      // Non key-value lines (brackets, commas, etc.)
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        spans.add(TextSpan(text: line, style: TextStyle(color: punctuationColor)));
      } else {
        _highlightValue(line, spans,
          stringColor: stringColor,
          numberColor: numberColor,
          boolNullColor: boolNullColor,
          punctuationColor: punctuationColor,
        );
      }
    }
  }

  void _highlightValue(
    String value,
    List<TextSpan> spans, {
    required Color stringColor,
    required Color numberColor,
    required Color boolNullColor,
    required Color punctuationColor,
  }) {
    final trimmed = value.trim();
    final trailingComma = trimmed.endsWith(',');
    final cleaned = trailingComma
        ? trimmed.substring(0, trimmed.length - 1).trim()
        : trimmed;

    // Leading whitespace
    final leadingSpaces = value.length - value.trimLeft().length;
    if (leadingSpaces > 0) {
      spans.add(TextSpan(
        text: value.substring(0, leadingSpaces),
        style: TextStyle(color: punctuationColor),
      ));
    }

    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      // String value
      spans.add(TextSpan(text: cleaned, style: TextStyle(color: stringColor)));
    } else if (cleaned == 'true' || cleaned == 'false') {
      spans.add(TextSpan(text: cleaned, style: TextStyle(color: boolNullColor, fontWeight: FontWeight.w600)));
    } else if (cleaned == 'null') {
      spans.add(TextSpan(text: cleaned, style: TextStyle(color: boolNullColor, fontStyle: FontStyle.italic)));
    } else if (RegExp(r'^-?\d+\.?\d*$').hasMatch(cleaned)) {
      spans.add(TextSpan(text: cleaned, style: TextStyle(color: numberColor)));
    } else if (cleaned == '{' || cleaned == '}' || cleaned == '[' || cleaned == ']') {
      spans.add(TextSpan(text: cleaned, style: TextStyle(color: punctuationColor)));
    } else {
      spans.add(TextSpan(text: cleaned, style: TextStyle(color: punctuationColor)));
    }

    if (trailingComma) {
      spans.add(TextSpan(text: ',', style: TextStyle(color: punctuationColor)));
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _header(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _accentColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border.withValues(alpha: 0.3),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}