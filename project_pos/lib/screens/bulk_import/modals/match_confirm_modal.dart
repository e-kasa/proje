import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/models/bulk_import_models.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// Eşleştirme Onay Modal - POTENTIAL_MATCH durumu için
class MatchConfirmModal extends StatefulWidget {
  final AnalyzedProduct product;
  final Function(UserDecision) onDecision;

  const MatchConfirmModal({
    super.key,
    required this.product,
    required this.onDecision,
  });

  @override
  State<MatchConfirmModal> createState() => _MatchConfirmModalState();
}

class _MatchConfirmModalState extends State<MatchConfirmModal> {
  MergeStrategy _mergeStrategy = MergeStrategy.UPDATE_STOCK;
  bool _updateStock = true;
  bool _updatePrice = false;
  StockUpdateMode _stockMode = StockUpdateMode.ADD;

  void _confirm() {
    Map<String, dynamic>? stockUpdate;
    Map<String, dynamic>? priceUpdate;

    if (_updateStock) {
      stockUpdate = {
        'mode': _stockMode.name,
        'value': widget.product.stock,
      };
    }

    if (_updatePrice) {
      priceUpdate = {
        'buyPrice': widget.product.buyPrice,
        'sellPrice': widget.product.sellPrice,
      };
    }

    final decision = UserDecision.match(
      tempId: widget.product.tempId,
      matchedProductId: widget.product.matchedProduct!.id,
      mergeStrategy: _mergeStrategy,
      stockUpdate: stockUpdate,
      priceUpdate: priceUpdate,
    );

    widget.onDecision(decision);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final matched = widget.product.matchedProduct!;
    final similarity = (matched.similarity * 100).toStringAsFixed(0);

    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF9800).withValues(alpha: 0.1),
                    const Color(0xFFFF9800).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.link, color: const Color(0xFFFF9800), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ürün Eşleştirme',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Benzerlik: %$similarity',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.bgInfo,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bu ürün sistemdeki mevcut bir ürüne %$similarity benziyor. Eşleştirirseniz mevcut ürün güncellenecektir.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Comparison Table
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imported Product
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'İçe Aktarılan Ürün',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildProductCard(
                                name: widget.product.name,
                                sku: widget.product.sku,
                                barcode: widget.product.barcode,
                                stock: widget.product.stock,
                                buyPrice: widget.product.buyPrice,
                                sellPrice: widget.product.sellPrice,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Arrow
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 32),
                        ),
                        const SizedBox(width: 16),
                        // Existing Product
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sistemdeki Ürün',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildProductCard(
                                name: matched.name,
                                sku: matched.sku,
                                barcode: matched.barcode,
                                stock: matched.currentStock,
                                buyPrice: matched.currentBuyPrice,
                                sellPrice: matched.currentSellPrice,
                                color: const Color(0xFFFF9800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Merge Strategy
                    const Text(
                      'Birleştirme Stratejisi:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    CheckboxListTile(
                      title: const Text('Stok Güncelle'),
                      subtitle: Text(
                        _stockMode == StockUpdateMode.ADD
                            ? '${matched.currentStock} + ${widget.product.stock} = ${matched.currentStock + widget.product.stock}'
                            : 'Yeni stok: ${widget.product.stock}',
                      ),
                      value: _updateStock,
                      onChanged: (value) {
                        setState(() {
                          _updateStock = value ?? false;
                          _updateMergeStrategy();
                        });
                      },
                      secondary: const Icon(Icons.inventory),
                    ),

                    if (_updateStock)
                      Padding(
                        padding: const EdgeInsets.only(left: 72, bottom: 12),
                        child: SegmentedButton<StockUpdateMode>(
                          segments: const [
                            ButtonSegment(
                              value: StockUpdateMode.ADD,
                              label: Text('Ekle'),
                            ),
                            ButtonSegment(
                              value: StockUpdateMode.REPLACE,
                              label: Text('Değiştir'),
                            ),
                          ],
                          selected: {_stockMode},
                          onSelectionChanged: (Set<StockUpdateMode> newSelection) {
                            setState(() {
                              _stockMode = newSelection.first;
                            });
                          },
                        ),
                      ),

                    CheckboxListTile(
                      title: const Text('Fiyat Güncelle'),
                      subtitle: Text(
                        'Alış: ₺${widget.product.buyPrice}, Satış: ₺${widget.product.sellPrice}',
                      ),
                      value: _updatePrice,
                      onChanged: (value) {
                        setState(() {
                          _updatePrice = value ?? false;
                          _updateMergeStrategy();
                        });
                      },
                      secondary: const Icon(Icons.price_change),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  AppButton.primary(

                    text: 'Eşleştir',

                    icon: Icons.link,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateMergeStrategy() {
    if (_updateStock && _updatePrice) {
      _mergeStrategy = MergeStrategy.UPDATE_BOTH;
    } else if (_updateStock) {
      _mergeStrategy = MergeStrategy.UPDATE_STOCK;
    } else if (_updatePrice) {
      _mergeStrategy = MergeStrategy.UPDATE_PRICE;
    } else {
      _mergeStrategy = MergeStrategy.NO_UPDATE;
    }
  }

  Widget _buildProductCard({
    required String name,
    required String sku,
    required String barcode,
    required int stock,
    required double buyPrice,
    required double sellPrice,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 16),
          _buildInfoRow('SKU', sku),
          _buildInfoRow('Barkod', barcode),
          _buildInfoRow('Stok', '$stock adet'),
          _buildInfoRow('Alış Fiyatı', '₺$buyPrice'),
          _buildInfoRow('Satış Fiyatı', '₺$sellPrice'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
