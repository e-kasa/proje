import 'package:flutter/material.dart';
import '../../models/supplier_import_models.dart';
import '../../services/mock_supplier_import_data.dart';

/// TOPLU ÜRÜN YÜKLEME - TABLO + DROPDOWN TASARIM
/// Dokümantasyon: TOPLU_URUN_YUKLEME_EKRAN_AKISI.md
/// Her satırda "Karar Ver" dropdown, senaryoya göre farklı seçenekler
class SupplierImportTableDropdownScreen extends StatefulWidget {
  const SupplierImportTableDropdownScreen({Key? key}) : super(key: key);

  @override
  State<SupplierImportTableDropdownScreen> createState() =>
      _SupplierImportTableDropdownScreenState();
}

class _SupplierImportTableDropdownScreenState
    extends State<SupplierImportTableDropdownScreen> {
  List<SupplierProductItem> _products = [];
  Set<int> _expandedRows = {};
  String _filterType = 'TÜMÜ';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _products = MockSupplierImportData.getMockProducts();
        _isLoading = false;
      });
    });
  }

  int get _decidedCount =>
      _products.where((p) => p.userDecision != null).length;

  List<SupplierProductItem> get _filteredProducts {
    switch (_filterType) {
      case 'YENİ ÜRÜN':
        return _products.where((p) => p.isNewProduct).toList();
      case 'BENZER VAR':
        return _products.where((p) => p.hasSystemMatches).toList();
      case 'KARAR VERİLDİ':
        return _products.where((p) => p.hasDecision).toList();
      case 'BEKLEYEN':
        return _products.where((p) => !p.hasDecision).toList();
      default:
        return _products;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '📊 Toplu Ürün Yükleme - İnceleme',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          if (_decidedCount == _products.length && _products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _saveAllDecisions,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Tümünü Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFileInfoHeader(),
                _buildProgressBar(),
                _buildFilterButtons(),
                Expanded(child: _buildProductTable()),
              ],
            ),
    );
  }

  Widget _buildFileInfoHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Dosya: tedarikci_fis_2024.xlsx',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Icon(Icons.timer, color: Colors.grey[600], size: 18),
              const SizedBox(width: 4),
              Text(
                'Analiz: 2.3 saniye',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                  '📦 Toplam', '${_products.length} ürün', Colors.blue),
              const SizedBox(width: 12),
              _buildStatChip(
                  '✅ Karar Verildi',
                  '$_decidedCount/${_products.length}',
                  Colors.green),
              const SizedBox(width: 12),
              _buildStatChip('⏳ Bekleyen',
                  '${_products.length - _decidedCount}', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress =
        _products.isEmpty ? 0.0 : _decidedCount / _products.length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          if (_decidedCount == _products.length && _products.isNotEmpty)
            Text(
              '✅ Tüm ürünler için karar verildi! Kaydetmek için butona tıklayın.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = ['TÜMÜ', 'YENİ ÜRÜN', 'BENZER VAR', 'KARAR VERİLDİ', 'BEKLEYEN'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _filterType == filter;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filterType = filter;
                  });
                },
                selectedColor: Colors.blue[700],
                backgroundColor: Colors.grey[200],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductTable() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Bu filtre için ürün bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final globalIndex = _products.indexOf(product);
        return _buildProductRow(product, globalIndex);
      },
    );
  }

  Widget _buildProductRow(SupplierProductItem product, int index) {
    final isExpanded = _expandedRows.contains(index);
    final rowNumber = index + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: product.hasDecision
              ? Colors.green.shade300
              : Colors.grey.shade300,
          width: product.hasDecision ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$rowNumber',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Product Info from Excel
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.readProductName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adet: ${product.readStock}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (product.readPrice != null)
                        Text(
                          'Fiyat: ${product.readPrice!.toStringAsFixed(2)} TL',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (product.readBarcode != null)
                        Text(
                          'Barkod: ${product.readBarcode}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        )
                      else
                        Text(
                          'Barkod: -',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // System Match Info + Decision Dropdown
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Match Status Badge
                      _buildMatchStatusBadge(product),
                      const SizedBox(height: 8),

                      // Decision or Dropdown
                      if (product.hasDecision)
                        _buildDecisionDisplay(product)
                      else
                        _buildDecisionDropdown(product, index),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expanded Detail Panel
          if (isExpanded) _buildDetailPanel(product, index),
        ],
      ),
    );
  }

  Widget _buildMatchStatusBadge(SupplierProductItem product) {
    Color badgeColor;
    String badgeText;
    String icon;

    if (product.isNewProduct) {
      badgeColor = Colors.blue;
      badgeText = 'Yeni Ürün';
      icon = '🔵';
    } else {
      final topMatch = product.forProduct.first;
      if (topMatch.matchType == ProductMatchType.BARCODE_EXACT) {
        badgeColor = Colors.green;
        badgeText = '%100 Barkod Eşleşti';
        icon = '✅';
      } else {
        badgeColor = Colors.orange;
        badgeText = '%${topMatch.matchScore} Benzer Var';
        icon = '🟠';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionDisplay(SupplierProductItem product) {
    final decision = product.userDecision!;
    String decisionText;
    IconData decisionIcon;
    Color decisionColor;

    switch (decision.action) {
      case ProductImportAction.CREATE_NEW:
        decisionText = 'Yeni Ürün Oluşturuldu';
        decisionIcon = Icons.add_circle;
        decisionColor = Colors.blue;
        break;
      case ProductImportAction.ADD_VARIANT:
        decisionText = 'Varyant Eklendi';
        decisionIcon = Icons.add_box;
        decisionColor = Colors.purple;
        break;
      case ProductImportAction.ADD_STOCK:
        decisionText = 'Stok Eklendi';
        decisionIcon = Icons.inventory;
        decisionColor = Colors.green;
        break;
      case ProductImportAction.UPDATE_PRICE:
        decisionText = 'Fiyat Güncellendi';
        decisionIcon = Icons.attach_money;
        decisionColor = Colors.teal;
        break;
      case ProductImportAction.MATCH_EXISTING:
        decisionText = 'Mevcut Ürüne Eşlendi';
        decisionIcon = Icons.check_circle;
        decisionColor = Colors.green;
        break;
      case ProductImportAction.EDIT_AND_CREATE:
        decisionText = 'Düzenlendi ve Oluşturuldu';
        decisionIcon = Icons.edit;
        decisionColor = Colors.orange;
        break;
      case ProductImportAction.SKIP:
        decisionText = 'İptal Edildi';
        decisionIcon = Icons.cancel;
        decisionColor = Colors.red;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(decisionIcon, size: 16, color: decisionColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                decisionText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: decisionColor,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => _editDecision(product),
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Düzenle', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => _cancelDecision(product),
              icon: const Icon(Icons.close, size: 14),
              label: const Text('İptal', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDecisionDropdown(SupplierProductItem product, int index) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleDecisionSelection(product, value),
      itemBuilder: (context) {
        if (product.isNewProduct) {
          return _buildNewProductDropdownItems();
        } else {
          final topMatch = product.forProduct.first;
          if (topMatch.matchType == ProductMatchType.BARCODE_EXACT) {
            return _buildExactMatchDropdownItems(product);
          } else {
            return _buildSimilarProductDropdownItems(product, index);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Karar Ver',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildNewProductDropdownItems() {
    return [
      const PopupMenuItem(
        value: 'create_new',
        child: Row(
          children: [
            Icon(Icons.add_circle, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Text('➕ Yeni Ürün Oluştur'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'manual_match',
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: Colors.orange),
            SizedBox(width: 8),
            Text('🔍 Manuel Eşleştir'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'cancel',
        child: Row(
          children: [
            Icon(Icons.cancel, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('❌ İptal Et'),
          ],
        ),
      ),
    ];
  }

  List<PopupMenuEntry<String>> _buildExactMatchDropdownItems(
      SupplierProductItem product) {
    return [
      const PopupMenuItem(
        value: 'add_stock',
        child: Row(
          children: [
            Icon(Icons.inventory, size: 18, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('✅ Stok Ekle')),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'update_price',
        child: Row(
          children: [
            Icon(Icons.attach_money, size: 18, color: Colors.teal),
            SizedBox(width: 8),
            Expanded(child: Text('💰 Fiyat Güncelle')),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'stock_and_price',
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('✅ Stok+Fiyat Güncelle')),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'view_detail',
        child: Row(
          children: [
            Icon(Icons.visibility, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('👁️ Ürün Detayı')),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'cancel',
        child: Row(
          children: [
            Icon(Icons.cancel, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('❌ İptal Et'),
          ],
        ),
      ),
    ];
  }

  List<PopupMenuEntry<String>> _buildSimilarProductDropdownItems(
      SupplierProductItem product, int index) {
    final topMatch = product.forProduct.first;
    return [
      PopupMenuItem(
        value: 'add_variant',
        child: Row(
          children: [
            const Icon(Icons.add_box, size: 18, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '📦 Varyant Ekle\n(${topMatch.name}\'e ekle)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'add_stock',
        child: Row(
          children: [
            Icon(Icons.inventory, size: 18, color: Colors.green),
            SizedBox(width: 8),
            Expanded(child: Text('✅ Stok Ekle')),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'edit_and_create',
        child: Row(
          children: [
            Icon(Icons.edit, size: 18, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('✏️ Düzenle ve Ekle')),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'create_new',
        child: Row(
          children: [
            Icon(Icons.add_circle, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('➕ Yeni Ürün Oluştur')),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'view_detail',
        child: Row(
          children: [
            const Icon(Icons.visibility, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
                child: Text('👁️ Detay Gör (${product.forProduct.length})')),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'cancel',
        child: Row(
          children: [
            Icon(Icons.cancel, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('❌ İptal Et'),
          ],
        ),
      ),
    ];
  }

  Widget _buildDetailPanel(SupplierProductItem product, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  '🔍 BENZER ÜRÜNLER DETAYI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _expandedRows.remove(index);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Similar Products List
          ...product.forProduct.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final systemProduct = entry.value;
            return _buildSimilarProductCard(systemProduct, idx, product);
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSimilarProductCard(
      SystemProduct systemProduct, int rank, SupplierProductItem parentProduct) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '$rank️⃣',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  systemProduct.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  '%${systemProduct.matchScore} Eşleşme',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _buildDetailText('SKU', systemProduct.sku),
              _buildDetailText('Kategori', systemProduct.category),
              if (systemProduct.brand != null)
                _buildDetailText('Marka', systemProduct.brand!),
            ],
          ),
          const SizedBox(height: 8),

          // Variants
          if (systemProduct.variants.isNotEmpty) ...[
            Text(
              '📦 Varyantlar:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            ...systemProduct.variants.take(3).map((variant) {
              final variantName =
                  variant.attributes.values.join(' / ');
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• $variantName - Stok: ${variant.stock} - Fiyat: ${variant.price.toStringAsFixed(2)} TL',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              );
            }),
            if (systemProduct.variants.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '... ve ${systemProduct.variants.length - 3} varyant daha',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddVariantModal(parentProduct, systemProduct),
                icon: const Icon(Icons.add_box, size: 14),
                label: const Text('Varyant Ekle', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _addStock(parentProduct, systemProduct),
                icon: const Icon(Icons.inventory, size: 14),
                label: const Text('Stok Ekle', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showCreateNewProductModal(parentProduct),
                icon: const Icon(Icons.add_circle, size: 14),
                label: const Text('Yeni Ürün', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailText(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDecisionSelection(SupplierProductItem product, String value) {
    switch (value) {
      case 'create_new':
        _showCreateNewProductModal(product);
        break;
      case 'add_variant':
        if (product.forProduct.isNotEmpty) {
          _showAddVariantModal(product, product.forProduct.first);
        }
        break;
      case 'add_stock':
        if (product.forProduct.isNotEmpty) {
          _addStock(product, product.forProduct.first);
        }
        break;
      case 'update_price':
        if (product.forProduct.isNotEmpty) {
          _updatePrice(product, product.forProduct.first);
        }
        break;
      case 'stock_and_price':
        if (product.forProduct.isNotEmpty) {
          _updateStockAndPrice(product, product.forProduct.first);
        }
        break;
      case 'edit_and_create':
        _showEditAndCreateModal(product);
        break;
      case 'view_detail':
        _toggleDetailPanel(product);
        break;
      case 'manual_match':
        _showManualMatchDialog(product);
        break;
      case 'cancel':
        _skipProduct(product);
        break;
    }
  }

  void _showCreateNewProductModal(SupplierProductItem product) {
    showDialog(
      context: context,
      builder: (context) => _CreateNewProductModal(
        product: product,
        onSave: (decision) {
          setState(() {
            product.userDecision = decision;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Yeni ürün kararı kaydedildi'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showAddVariantModal(
      SupplierProductItem product, SystemProduct targetProduct) {
    showDialog(
      context: context,
      builder: (context) => _AddVariantModal(
        product: product,
        targetProduct: targetProduct,
        onSave: (decision) {
          setState(() {
            product.userDecision = decision;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Varyant ekleme kararı kaydedildi'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showEditAndCreateModal(SupplierProductItem product) {
    showDialog(
      context: context,
      builder: (context) => _EditAndCreateModal(
        product: product,
        onSave: (decision) {
          setState(() {
            product.userDecision = decision;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Düzenle ve oluştur kararı kaydedildi'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _addStock(SupplierProductItem product, SystemProduct targetProduct) {
    setState(() {
      product.userDecision = UserProductDecision(
        action: ProductImportAction.ADD_STOCK,
        targetProductId: targetProduct.productId,
        quantity: product.readStock,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ ${product.readStock} adet stok ekleme kararı kaydedildi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updatePrice(SupplierProductItem product, SystemProduct targetProduct) {
    setState(() {
      product.userDecision = UserProductDecision(
        action: ProductImportAction.UPDATE_PRICE,
        targetProductId: targetProduct.productId,
        newPrice: product.readPrice,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '💰 Fiyat güncelleme kararı kaydedildi: ${product.readPrice?.toStringAsFixed(2)} TL'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _updateStockAndPrice(
      SupplierProductItem product, SystemProduct targetProduct) {
    setState(() {
      product.userDecision = UserProductDecision(
        action: ProductImportAction.MATCH_EXISTING,
        targetProductId: targetProduct.productId,
        quantity: product.readStock,
        newPrice: product.readPrice,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Stok ve fiyat güncelleme kararı kaydedildi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleDetailPanel(SupplierProductItem product) {
    final index = _products.indexOf(product);
    setState(() {
      if (_expandedRows.contains(index)) {
        _expandedRows.remove(index);
      } else {
        _expandedRows.add(index);
      }
    });
  }

  void _showManualMatchDialog(SupplierProductItem product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Manuel Ürün Eşleştir'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Ürün Ara',
                hintText: 'Ürün adı, SKU veya barkod girin',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),
            Text('Bu özellik yakında eklenecek...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _skipProduct(SupplierProductItem product) {
    setState(() {
      product.userDecision = UserProductDecision(
        action: ProductImportAction.SKIP,
        notes: 'Kullanıcı tarafından iptal edildi',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Ürün iptal edildi'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _editDecision(SupplierProductItem product) {
    // Reset decision to allow re-selection
    setState(() {
      product.userDecision = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Karar sıfırlandı, tekrar seçim yapabilirsiniz'),
      ),
    );
  }

  void _cancelDecision(SupplierProductItem product) {
    setState(() {
      product.userDecision = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Karar iptal edildi'),
      ),
    );
  }

  void _saveAllDecisions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💾 Tüm Değişiklikleri Kaydet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Özet:'),
            const SizedBox(height: 8),
            ..._generateSummary(),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Bu işlem geri alınamaz. Emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('← İncelemeye Dön'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _performSave();
            },
            icon: const Icon(Icons.save),
            label: const Text('Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _generateSummary() {
    final summary = <String, int>{};
    for (final product in _products) {
      if (product.userDecision != null) {
        final action = product.userDecision!.action;
        summary[action.name] = (summary[action.name] ?? 0) + 1;
      }
    }

    return summary.entries.map((entry) {
      String actionText;
      switch (ProductImportAction.values.firstWhere((e) => e.name == entry.key)) {
        case ProductImportAction.CREATE_NEW:
          actionText = 'yeni ürün oluşturulacak';
          break;
        case ProductImportAction.ADD_VARIANT:
          actionText = 'ürüne varyant eklenecek';
          break;
        case ProductImportAction.ADD_STOCK:
          actionText = 'ürüne stok eklenecek';
          break;
        case ProductImportAction.UPDATE_PRICE:
          actionText = 'ürünün fiyatı güncellenecek';
          break;
        case ProductImportAction.MATCH_EXISTING:
          actionText = 'ürünün stok+fiyatı güncellenecek';
          break;
        case ProductImportAction.EDIT_AND_CREATE:
          actionText = 'ürün düzenlenip oluşturulacak';
          break;
        case ProductImportAction.SKIP:
          actionText = 'ürün iptal edildi';
          break;
      }
      return Text('• ${entry.value} $actionText');
    }).toList();
  }

  void _performSave() {
    // Simulate backend save
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Kaydediliyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading
      _showSuccessScreen();
    });
  }

  void _showSuccessScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ İşlem Başarılı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('📦 ${_products.length} ürün başarıyla kaydedildi'),
            const SizedBox(height: 8),
            const Text('⏱️ İşlem süresi: 2.0 saniye'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('➕ Yeni Yükleme Yap'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('📦 Ürünlere Git'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MODAL WIDGETS
// =============================================================================

class _CreateNewProductModal extends StatefulWidget {
  final SupplierProductItem product;
  final Function(UserProductDecision) onSave;

  const _CreateNewProductModal({
    required this.product,
    required this.onSave,
  });

  @override
  State<_CreateNewProductModal> createState() => _CreateNewProductModalState();
}

class _CreateNewProductModalState extends State<_CreateNewProductModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.readProductName);
    _skuController = TextEditingController();
    _priceController = TextEditingController(
        text: widget.product.readPrice?.toStringAsFixed(2) ?? '');
    _stockController =
        TextEditingController(text: widget.product.readStock.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    '➕ Yeni Ürün Oluştur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Excel Info Section
                      Text(
                        '📄 Excel\'den Gelen Bilgiler:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ürün Adı: ${widget.product.readProductName}'),
                            Text('Miktar: ${widget.product.readStock} adet'),
                            if (widget.product.readPrice != null)
                              Text(
                                  'Fiyat: ${widget.product.readPrice!.toStringAsFixed(2)} TL'),
                            if (widget.product.readBarcode != null)
                              Text('Barkod: ${widget.product.readBarcode}')
                            else
                              const Text('Barkod: Yok'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Edit Section
                      Text(
                        '⚙️ Ürün Bilgilerini Düzenle:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ürün Adı *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Zorunlu alan' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _skuController,
                              decoration: const InputDecoration(
                                labelText: 'SKU Kodu *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Zorunlu alan' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Kategori *',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Giyim', 'Elektronik', 'Gıda', 'Diğer']
                                  .map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ))
                                  .toList(),
                              onChanged: (value) {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Satış Fiyatı',
                                border: OutlineInputBorder(),
                                suffixText: 'TL',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                labelText: 'İlk Stok',
                                border: OutlineInputBorder(),
                                suffixText: 'adet',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('← Geri Dön'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSave(UserProductDecision(
                          action: ProductImportAction.CREATE_NEW,
                          newProductData: {
                            'name': _nameController.text,
                            'sku': _skuController.text,
                            'price': double.tryParse(_priceController.text),
                            'stock': int.tryParse(_stockController.text),
                          },
                        ));
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Ürünü Oluştur ve Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVariantModal extends StatefulWidget {
  final SupplierProductItem product;
  final SystemProduct targetProduct;
  final Function(UserProductDecision) onSave;

  const _AddVariantModal({
    required this.product,
    required this.targetProduct,
    required this.onSave,
  });

  @override
  State<_AddVariantModal> createState() => _AddVariantModalState();
}

class _AddVariantModalState extends State<_AddVariantModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _stockController;
  String? _selectedColor;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    _stockController =
        TextEditingController(text: widget.product.readStock.toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[600],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_box, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    '📦 Varyant Ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target Product Info
                      Text(
                        '🎯 Seçili Ürün:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.targetProduct.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('SKU: ${widget.targetProduct.sku}'),
                            Text(
                                'Mevcut Varyantlar: ${widget.targetProduct.variants.length}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Excel Info
                      Text(
                        '📄 Excel\'den Gelen:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ürün: ${widget.product.readProductName}'),
                            Text('Miktar: ${widget.product.readStock} adet'),
                            if (widget.product.readPrice != null)
                              Text(
                                  'Fiyat: ${widget.product.readPrice!.toStringAsFixed(2)} TL'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Variant Details
                      Text(
                        '⚙️ Varyant Bilgileri:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Renk',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Kırmızı', 'Mavi', 'Yeşil', 'Siyah', 'Beyaz']
                            .map((color) => DropdownMenuItem(
                                  value: color,
                                  child: Text(color),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedColor = value),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Beden',
                          border: OutlineInputBorder(),
                        ),
                        items: ['S', 'M', 'L', 'XL', 'XXL']
                            .map((size) => DropdownMenuItem(
                                  value: size,
                                  child: Text(size),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedSize = value),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stok Miktarı',
                          border: OutlineInputBorder(),
                          suffixText: 'adet',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('← Geri Dön'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onSave(UserProductDecision(
                        action: ProductImportAction.ADD_VARIANT,
                        targetProductId: widget.targetProduct.productId,
                        variantData: {
                          'color': _selectedColor,
                          'size': _selectedSize,
                          'stock': int.tryParse(_stockController.text),
                        },
                      ));
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Varyant Ekle ve Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditAndCreateModal extends StatelessWidget {
  final SupplierProductItem product;
  final Function(UserProductDecision) onSave;

  const _EditAndCreateModal({
    required this.product,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    // This would be similar to CreateNewProductModal but with edit capabilities
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✏️ Düzenle ve Oluştur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Bu modal yakında detaylandırılacak...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                onSave(UserProductDecision(
                  action: ProductImportAction.EDIT_AND_CREATE,
                ));
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
