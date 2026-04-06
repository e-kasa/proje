import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../widgets/wizard_common_widgets.dart';
import '../widgets/variant_image_widgets.dart';

class PreviewStep extends StatelessWidget {
  final WizardState state;
  final bool isMobile;

  const PreviewStep({
    super.key,
    required this.state,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final totalStock = state.variants
        .fold<int>(0, (sum, v) => sum + (v.inventory?.physicalQuantity ?? 0));
    final totalPurchase = state.variants.fold<double>(
        0, (s, v) => s + ((v.inventory?.physicalQuantity ?? 0) * v.purchasePrice));
    final totalSale = state.variants.fold<double>(
        0, (s, v) => s + ((v.inventory?.physicalQuantity ?? 0) * v.salePrice));
    final profit = totalSale - totalPurchase;

    return Column(
      children: [
        _buildSummaryRow(totalStock, totalPurchase, totalSale, profit),
        const SizedBox(height: 16),
        _buildProductInfo(),
        const SizedBox(height: 16),
        if (state.isParcaci &&
            (state.oemNumbers.isNotEmpty ||
                state.crossReferences.isNotEmpty ||
                state.shelfNumberController.text.isNotEmpty)) ...[
          _buildAutoPartsInfo(),
          const SizedBox(height: 16),
        ],
        _buildLocationInfo(),
        const SizedBox(height: 16),
        _buildVariantsTable(context),
        const SizedBox(height: 16),
        _buildImagesSection(context),
        const SizedBox(height: 16),
        _buildJsonPayload(context),
      ],
    );
  }

  // ─── Summary Row ──────────────────────────────────────────────────────────

  Widget _buildSummaryRow(
      int stock, double purchase, double sale, double profit) {
    final items = [
      _SummaryItem(
          label: 'Varyant',
          value: '${state.variants.length}',
          color: AppColors.primary),
      _SummaryItem(
          label: 'Stok', value: '$stock', color: AppColors.info),
      _SummaryItem(
          label: 'Alış',
          value: '₺${purchase.toStringAsFixed(0)}',
          color: AppColors.danger),
      _SummaryItem(
          label: 'Satış',
          value: '₺${sale.toStringAsFixed(0)}',
          color: AppColors.success),
      _SummaryItem(
          label: 'Kâr',
          value: '₺${profit.toStringAsFixed(0)}',
          color: profit >= 0 ? AppColors.success : AppColors.danger),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: item != items.last ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(item.value,
                    style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: item.color)),
                const SizedBox(height: 2),
                Text(item.label,
                    style: TextStyle(
                        fontSize: 10, color: item.color.withOpacity(0.7))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Product Info ─────────────────────────────────────────────────────────

  Widget _buildProductInfo() {
    final categoryLabel = state.categories
        .firstWhere((c) => c['value'] == state.selectedCategory,
            orElse: () => <String, String>{'label': '-'})['label']
        ?.toString() ?? '-';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.info_outline_rounded, 'Ürün Bilgileri'),
          const SizedBox(height: 12),
          _infoRow('Ürün Adı', state.productNameController.text),
          _infoRow('SKU', state.skuController.text),
          _infoRow('Kategori', categoryLabel),
          _infoRow('Marka', state.brandController.text.isEmpty
              ? '-'
              : state.brandController.text),
          _infoRow('Birim', state.selectedUnit),
          _infoRow('Alış Fiyatı', '₺${state.basePurchasePriceController.text}'),
          _infoRow('Satış Fiyatı', '₺${state.basePriceController.text}'),
          _infoRow(
              'KDV',
              '% ${state.selectedVatRate}'
              '${state.vatIncluded ? " (Dahil)" : " (Hariç)"}'),
          _infoRow('Sektör', state.sectorType.displayName),
        ],
      ),
    );
  }

  // ─── Auto Parts Info ──────────────────────────────────────────────────────

  Widget _buildAutoPartsInfo() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.build_circle_rounded, 'Oto Parça Bilgileri'),
          const SizedBox(height: 12),
          if (state.shelfNumberController.text.isNotEmpty)
            _infoRow('Raf Konumu', state.shelfNumberController.text),
          if (state.oemNumbers.isNotEmpty)
            _infoRow(
                'OEM Numaraları',
                state.oemNumbers
                    .map((o) => o['oemNumber'])
                    .where((s) => s != null && s.isNotEmpty)
                    .join(', ')),
          if (state.crossReferences.isNotEmpty)
            _infoRow(
                'Çapraz Referanslar',
                state.crossReferences
                    .map((c) =>
                        '${c['crossRefNumber']} (${c['crossRefBrand']})')
                    .where((s) => s.isNotEmpty)
                    .join(', ')),
        ],
      ),
    );
  }

  // ─── Location Info ────────────────────────────────────────────────────────

  Widget _buildLocationInfo() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.location_on_rounded, 'Konum'),
          const SizedBox(height: 12),
          _infoRow(
              'Mağaza',
              state.selectedStores.isEmpty
                  ? '-'
                  : state.selectedStores
                      .map((v) => state.stores
                          .firstWhere((s) => s['value'] == v,
                              orElse: () =>
                                  <String, dynamic>{'label': v})['label']
                          ?.toString() ?? v)
                      .join(', ')),
          _infoRow(
              'Depo',
              state.selectedWarehouses.isEmpty
                  ? '-'
                  : state.selectedWarehouses
                      .map((v) => state.warehouses
                          .firstWhere((w) => w['value'] == v,
                              orElse: () =>
                                  <String, dynamic>{'label': v})['label']
                          ?.toString() ?? v)
                      .join(', ')),
        ],
      ),
    );
  }

  // ─── Variants Table ───────────────────────────────────────────────────────

  Widget _buildVariantsTable(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(Icons.table_chart_rounded,
              'Varyantlar (${state.variants.length})'),
          const SizedBox(height: 12),
          if (isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.swipe_rounded, size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text('Kaydırarak tüm sütunları görün',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.info)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppColors.primary.withOpacity(0.04)),
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              headingRowHeight: 40,
              columnSpacing: isMobile ? 16 : 32,
              horizontalMargin: 8,
              columns: const [
                DataColumn(
                    label: Text('#',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(
                    label: Text('Varyant',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(
                    label: Text('SKU',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(
                    label: Text('Stok',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(
                    label: Text('Alış',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(
                    label: Text('Satış',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12))),
              ],
              rows: state.variants.asMap().entries.map((entry) {
                final v = entry.value;
                final qty = v.inventory?.physicalQuantity ?? 0;
                return DataRow(cells: [
                  DataCell(Text('${entry.key + 1}',
                      style: const TextStyle(fontSize: 12))),
                  DataCell(Text(v.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500))),
                  DataCell(Text(v.sku,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 10))),
                  DataCell(Text('$qty',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: qty > 0
                              ? AppColors.success
                              : AppColors.danger))),
                  DataCell(Text('₺${v.purchasePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.danger))),
                  DataCell(Text('₺${v.salePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.success))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Images Section ───────────────────────────────────────────────────────

  Widget _buildImagesSection(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _header(Icons.image_rounded, 'Görseller'),
              const Spacer(),
              Text('${state.productImages.length} görsel',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Görsel seçici yakında eklenecek...'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                }, isMobile: isMobile);
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
                    Icon(Icons.add_photo_alternate_rounded,
                        size: 40, color: AppColors.textMuted.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text('Henüz görsel eklenmedi',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── JSON Payload ─────────────────────────────────────────────────────────

  Widget _buildJsonPayload(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text('API Payload',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const Spacer(),
              IconButton(
                icon:
                    const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('JSON kopyalandı!'),
                        backgroundColor: AppColors.success),
                  );
                },
                tooltip: 'Kopyala',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                state.buildJsonPreview(),
                style: const TextStyle(
                    color: Colors.white60, fontFamily: 'monospace', fontSize: 10),
              ),
            ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final Color color;

  _SummaryItem(
      {required this.label, required this.value, required this.color});
}
