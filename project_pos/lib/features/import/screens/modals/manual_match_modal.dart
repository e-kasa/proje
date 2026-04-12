import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/models/bulk_import_models.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// Manuel Eşleştirme Modal - NEW durumu için
/// Kullanıcı sistemdeki tüm ürünleri görebilir ve istediğiyle eşleştirebilir
class ManualMatchModal extends ConsumerStatefulWidget {
  final AnalyzedProduct product;
  final List<MatchedProduct> availableProducts; // Sistemdeki tüm ürünler
  final Function(UserDecision) onDecision;

  const ManualMatchModal({
    super.key,
    required this.product,
    required this.availableProducts,
    required this.onDecision,
  });

  @override
  ConsumerState<ManualMatchModal> createState() => _ManualMatchModalState();
}

class _ManualMatchModalState extends ConsumerState<ManualMatchModal> {
  String Function(String) get t => i18nOf(ref);
  String _searchQuery = '';
  MatchedProduct? _selectedProduct;
  MergeStrategy _mergeStrategy = MergeStrategy.UPDATE_STOCK;
  bool _updateStock = true;
  bool _updatePrice = false;
  StockUpdateMode _stockMode = StockUpdateMode.ADD;

  List<MatchedProduct> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return widget.availableProducts;
    }

    final query = _searchQuery.toLowerCase();
    return widget.availableProducts.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query);
    }).toList();
  }

  void _confirm() {
    if (_selectedProduct == null) {
      AppToast.warning(context, 'Lütfen eşleştirilecek bir ürün seçin'); // TODO: i18n bulk_import.select_product_to_match
      return;
    }

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
      matchedProductId: _selectedProduct!.id,
      mergeStrategy: _mergeStrategy,
      stockUpdate: stockUpdate,
      priceUpdate: priceUpdate,
    );

    widget.onDecision(decision);
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 720,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
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
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.search, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manuel Ürün Eşleştirme', // TODO: i18n bulk_import.manual_match_title
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.name,
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
              child: Row(
                children: [
                  // Left: Product list
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Ürün Ara', // TODO: i18n bulk_import.search_product
                              hintText: 'İsim, SKU veya Barkod', // TODO: i18n bulk_import.search_product_hint
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),

                        // Product count
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${_filteredProducts.length} ürün bulundu',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Product list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              final isSelected = _selectedProduct?.id == product.id;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Radio<String>(
                                    value: product.id,
                                    groupValue: _selectedProduct?.id,
                                    onChanged: (_) {
                                      setState(() {
                                        _selectedProduct = product;
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                  title: Text(
                                    product.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('SKU: ${product.sku}'),
                                      Text('Barkod: ${product.barcode}'),
                                      Text('Stok: ${product.currentStock} adet'),
                                      Text(
                                          'Fiyat: ₺${product.currentBuyPrice} / ₺${product.currentSellPrice}'),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedProduct = product;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(width: 1, color: AppColors.border),

                  // Right: Merge options
                  Expanded(
                    flex: 2,
                    child: _selectedProduct == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 16),
                                Text(
                                  'Eşleştirilecek ürünü\nsoldan seçin', // TODO: i18n bulk_import.select_product_from_left
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Selected product info
                                const Text(
                                  'Seçilen Ürün:', // TODO: i18n bulk_import.selected_product
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: AppColors.success, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _selectedProduct!.name,
                                              style:
                                                  const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      _buildInfoRow('SKU', _selectedProduct!.sku),
                                      _buildInfoRow('Stok', '${_selectedProduct!.currentStock}'),
                                      _buildInfoRow('Fiyat',
                                          '₺${_selectedProduct!.currentBuyPrice} / ₺${_selectedProduct!.currentSellPrice}'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Merge strategy
                                const Text(
                                  'Birleştirme Seçenekleri:', // TODO: i18n bulk_import.merge_options
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),

                                CheckboxListTile(
                                  title: const Text('Stok Güncelle'), // TODO: i18n bulk_import.update_stock
                                  subtitle: Text(
                                    _stockMode == StockUpdateMode.ADD
                                        ? '${_selectedProduct!.currentStock} + ${widget.product.stock} = ${_selectedProduct!.currentStock + widget.product.stock}'
                                        : 'Yeni stok: ${widget.product.stock}',
                                  ),
                                  value: _updateStock,
                                  onChanged: (value) {
                                    setState(() {
                                      _updateStock = value ?? false;
                                      _updateMergeStrategy();
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),

                                if (_updateStock)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 40, bottom: 12),
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
                                  title: const Text('Fiyat Güncelle'), // TODO: i18n bulk_import.update_price
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
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
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
                    child: const Text('İptal'), // TODO: i18n common.cancel
                  ),
                  const SizedBox(width: 12),
                  AppButton.primary(

                    text: 'Eşleştir', // TODO: i18n common.match

                    icon: Icons.link,
                    onPressed: _selectedProduct != null ? _confirm : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
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