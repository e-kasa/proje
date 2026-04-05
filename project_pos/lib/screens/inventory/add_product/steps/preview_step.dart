import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../widgets/wizard_common_widgets.dart';

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

    final summaryCards = [
      {'value': '${state.variants.length}', 'label': 'Toplam Varyant', 'color': const Color(0xFF667eea)},
      {'value': '$totalStock', 'label': 'Toplam Stok', 'color': AppColors.success},
      {'value': '\u20ba${totalPurchaseValue.toStringAsFixed(2)}', 'label': 'Al\u0131\u015f De\u011feri', 'color': AppColors.danger},
      {'value': '\u20ba${totalSaleValue.toStringAsFixed(2)}', 'label': 'Sat\u0131\u015f De\u011feri', 'color': AppColors.info},
      {'value': '\u20ba${totalProfit.toStringAsFixed(2)}', 'label': 'Toplam K\u00e2r', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger},
      {'value': '${profitMargin.toStringAsFixed(1)}%', 'label': 'K\u00e2r Marj\u0131', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          buildResponsiveSummaryGrid(summaryCards, isMobile: isMobile),
          const SizedBox(height: 16),

          // Product Info
          buildInfoCard(
            '\u00dcr\u00fcn Bilgileri',
            [
              buildInfoRow('\u00dcr\u00fcn Ad\u0131', state.productNameController.text),
              buildInfoRow('SKU', state.skuController.text),
              buildInfoRow('Kategori', state.categories.firstWhere((c) => c['value'] == state.selectedCategory, orElse: () => <String, String>{'label': '-'})['label'] ?? '-'),
              buildInfoRow('Marka', state.brandController.text.isEmpty ? '-' : state.brandController.text),
              buildInfoRow('Birim', state.selectedUnit),
              buildInfoRow('Al\u0131\u015f Fiyat\u0131', '\u20ba${state.basePurchasePriceController.text}'),
              buildInfoRow('Sat\u0131\u015f Fiyat\u0131', '\u20ba${state.basePriceController.text}'),
              buildInfoRow('KDV Oran\u0131', '% ${state.selectedVatRate}${state.vatIncluded ? " (Dahil)" : " (Hari\u00e7)"}'),
              if (state.specialTaxRateController.text.isNotEmpty)
                buildInfoRow('\u00d6TV Oran\u0131', '% ${state.specialTaxRateController.text}'),
              if (state.withholdingTaxRateController.text.isNotEmpty)
                buildInfoRow('Stopaj', '% ${state.withholdingTaxRateController.text}'),
              if (state.taxExempt)
                buildInfoRow('Vergi Durumu', '\u26a1 Vergiden Muaf'),
            ],
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),

          // Auto parts info
          if (state.oemNumbers.isNotEmpty || state.crossReferences.isNotEmpty || state.shelfNumberController.text.isNotEmpty)
            buildInfoCard(
              'Oto Parca Bilgileri',
              [
                if (state.shelfNumberController.text.isNotEmpty)
                  buildInfoRow('Raf Konumu', state.shelfNumberController.text),
                if (state.oemNumbers.isNotEmpty)
                  buildInfoRow('OEM Numaralari', state.oemNumbers.map((o) => o['oemNumber']).where((s) => s != null && s.isNotEmpty).join(', ')),
                if (state.crossReferences.isNotEmpty)
                  buildInfoRow('Capraz Referanslar', state.crossReferences.map((c) => '${c['crossRefNumber']} (${c['crossRefBrand']})').where((s) => s.isNotEmpty).join(', ')),
              ],
              isMobile: isMobile,
            ),
          if (state.oemNumbers.isNotEmpty || state.crossReferences.isNotEmpty || state.shelfNumberController.text.isNotEmpty)
            const SizedBox(height: 16),

          // Store & Warehouse
          buildInfoCard(
            'Depo & Ma\u011faza',
            [
              buildInfoRow('Ma\u011faza', state.selectedStores.isEmpty ? '-' : state.selectedStores.map((v) => state.stores.firstWhere((s) => s['value'] == v, orElse: () => <String, dynamic>{'label': v})['label']?.toString() ?? v).join(', ')),
              buildInfoRow('Depo', state.selectedWarehouses.isEmpty ? '-' : state.selectedWarehouses.map((v) => state.warehouses.firstWhere((w) => w['value'] == v, orElse: () => <String, dynamic>{'label': v})['label']?.toString() ?? v).join(', ')),
            ],
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),

          // Variants Table
          _buildVariantsTable(context, totalProfit),
          const SizedBox(height: 16),

          // JSON Payload
          _buildJsonPayload(context),
        ],
      ),
    );
  }

  Widget _buildVariantsTable(BuildContext context, double totalProfit) {
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
          Text('Varyantlar (${state.variants.length})', style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold)),
          SizedBox(height: isMobile ? 12 : 16),
          if (isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.swipe, size: 14, color: Color(0xFF667eea)),
                  SizedBox(width: 4),
                  Text('Kayd\u0131rarak t\u00fcm s\u00fctunlar\u0131 g\u00f6r\u00fcn', style: TextStyle(fontSize: 10, color: Color(0xFF667eea))),
                ],
              ),
            ),
          SizedBox(height: isMobile ? 8 : 0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF667eea).withOpacity(0.1)),
              dataRowHeight: isMobile ? 40 : 48,
              headingRowHeight: isMobile ? 36 : 44,
              columnSpacing: isMobile ? 12 : 32,
              horizontalMargin: isMobile ? 6 : 16,
              columns: [
                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12))),
                DataColumn(label: Text('Varyant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12))),
                DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12))),
                DataColumn(label: Text('Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12))),
                DataColumn(label: Text('Al\u0131\u015f Fiyat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12))),
                DataColumn(label: Text('Sat\u0131\u015f Fiyat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12))),
                DataColumn(label: Text('Toplam K\u00e2r', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12))),
              ],
              rows: state.variants.asMap().entries.map((entry) {
                final index = entry.key;
                final v = entry.value;
                final qty = v.inventory?.physicalQuantity ?? 0;
                final profitPerUnit = v.salePrice - v.purchasePrice;
                final variantTotalProfit = qty * profitPerUnit;
                final textSize = isMobile ? 10.0 : 12.0;
                return DataRow(cells: [
                  DataCell(Text('${index + 1}', style: TextStyle(fontSize: textSize))),
                  DataCell(Text(v.name, style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w600))),
                  DataCell(Text(v.sku, style: TextStyle(fontFamily: 'monospace', fontSize: isMobile ? 9 : 10))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: qty > 0 ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$qty', style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold, color: qty > 0 ? AppColors.success : AppColors.danger)),
                  )),
                  DataCell(Text('\u20ba${v.purchasePrice.toStringAsFixed(2)}', style: TextStyle(color: AppColors.danger, fontSize: textSize))),
                  DataCell(Text('\u20ba${v.salePrice.toStringAsFixed(2)}', style: TextStyle(color: AppColors.success, fontSize: textSize))),
                  DataCell(Text('\u20ba${variantTotalProfit.toStringAsFixed(2)}', style: TextStyle(color: variantTotalProfit >= 0 ? AppColors.success : AppColors.danger, fontSize: textSize, fontWeight: FontWeight.bold))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonPayload(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3748),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.code, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Backend Payload (JSON)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 14)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON kopyanland\u0131!'), backgroundColor: AppColors.success),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                state.buildJsonPreview(),
                style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white60, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Bu JSON POST /api/v1/products endpoint\'ine g\u00f6nderilecek',
                  style: TextStyle(color: Colors.white60, fontSize: isMobile ? 10 : 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
