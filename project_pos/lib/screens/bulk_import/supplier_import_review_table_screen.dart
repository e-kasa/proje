import 'package:flutter/material.dart';
import '../../models/supplier_import_models.dart';
import '../../services/mock_supplier_import_data.dart';

/// Tedarikçi İthalat Review Ekranı - Tablo/Grid Tabanlı
/// Her ürün için detaylı bilgi kutucukları ile kompakt görünüm
class SupplierImportReviewTableScreen extends StatefulWidget {
  final String? importId;

  const SupplierImportReviewTableScreen({
    Key? key,
    this.importId,
  }) : super(key: key);

  @override
  State<SupplierImportReviewTableScreen> createState() =>
      _SupplierImportReviewTableScreenState();
}

class _SupplierImportReviewTableScreenState
    extends State<SupplierImportReviewTableScreen> {
  late SupplierImportResponse _response;
  String _filterType = 'TÜM ÜRÜNLER'; // Filter state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Mock data yükle
    _response = MockSupplierImportData.getMockSupplierImport();
  }

  // Kaç ürün için karar verildi
  int get _decidedCount {
    return _response.products.where((p) => p.hasDecision).length;
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
          'Tedarikçi Ürün Kontrolü',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_decidedCount}/${_response.productCount}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre/Sekme Butonları
          _buildFilterButtons(),

          // Ürün Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _response.products.length,
              itemBuilder: (context, index) {
                return _buildProductRow(
                  _response.products[index],
                  index + 1,
                );
              },
            ),
          ),

          // Kaydet Butonu
          _buildSaveButton(),
        ],
      ),
    );
  }

  // Üst Filtre Butonları
  Widget _buildFilterButtons() {
    final filters = [
      'TÜM ÜRÜNLER',
      'YENİ ÜRÜNLER',
      'BENZER ÜRÜNLER',
      'KARAR VERİLENLER',
      'BEKLEYENLER',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                    fontSize: 11,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Her Ürün Satırı
  Widget _buildProductRow(SupplierProductItem product, int rowNumber) {
    final hasSystemMatch = product.hasSystemMatches;
    final hasDecision = product.hasDecision;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasDecision ? Colors.green : Colors.red[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sıra No + Ürün Adı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasDecision ? Colors.green[50] : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$rowNumber. ürün',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'ad: ${product.readProductName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (hasDecision)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '✓ Karar Verildi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // İçerik: Eğer sistemde eşleşme varsa detayları göster
          if (hasSystemMatch)
            _buildSystemMatchContent(product)
          else
            _buildNewProductContent(product),

          // Karar Verme Alanı (eğer karar verilmediyse)
          if (!hasDecision) _buildDecisionArea(product),

          // Eğer karar verildiyse göster
          if (hasDecision) _buildDecisionSummary(product),
        ],
      ),
    );
  }

  // Sistemde Eşleşme Var - Bilgi Kutuları
  Widget _buildSystemMatchContent(SupplierProductItem product) {
    final systemProduct = product.forProduct.first;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Bilgi Kutusu (Grid Layout)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoBox(
                'sistemdeki ürün',
                systemProduct.name,
                Icons.shopping_bag,
              ),
              _buildInfoBox(
                'ürünün varyantları',
                '${systemProduct.variants.length} varyant',
                Icons.grid_view,
              ),
              _buildInfoBox(
                'toplam stok',
                '${_calculateTotalStock(systemProduct)} adet',
                Icons.inventory,
              ),
              _buildInfoBox(
                'barkod',
                _getFirstBarcode(systemProduct) ?? 'Yok',
                Icons.qr_code,
              ),
            ],
          ),

          // "veya benzer" - Diğer Benzer Ürünler
          if (product.forProduct.length > 1) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'veya benzer:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...product.forProduct.skip(1).map((otherProduct) {
              return _buildAlternativeProductChip(otherProduct, product);
            }).toList(),
          ],

          // Uyarı/Bilgi Mesajı
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              'Önden hata seçilebilecek stok sayısına göre uygun varyantı seçiniz veya yeni ürün oluşturun.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Yeni Ürün İçeriği
  Widget _buildNewProductContent(SupplierProductItem product) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.new_releases, color: Colors.orange[700], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YENİ ÜRÜN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistemde benzer ürün bulunamadı',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stok: ${product.readStock} adet',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (product.readPrice != null)
                        Text(
                          'Fiyat: ${product.readPrice} ₺',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bilgi Kutusu (4 kutu için)
  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2, // 2 sütun
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Alternatif Benzer Ürün Chip
  Widget _buildAlternativeProductChip(
    SystemProduct product,
    SupplierProductItem supplierProduct,
  ) {
    return InkWell(
      onTap: () {
        _showProductOptionsDialog(supplierProduct, product);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.alternate_email, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  // Karar Verme Alanı
  Widget _buildDecisionArea(SupplierProductItem product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          if (product.hasSystemMatches)
            // Benzer ürünler varsa seçenekler
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDecisionButton(
                  'Stoğa Ekle',
                  Icons.add_box,
                  Colors.blue,
                  () => _makeDecision(product, ProductImportAction.MATCH_EXISTING),
                ),
                _buildDecisionButton(
                  'Varyant Ekle',
                  Icons.library_add,
                  Colors.purple,
                  () => _makeDecision(product, ProductImportAction.ADD_AS_VARIANT),
                ),
                _buildDecisionButton(
                  'Yeni Ürün',
                  Icons.add_circle,
                  Colors.orange,
                  () => _makeDecision(product, ProductImportAction.CREATE_NEW),
                ),
                _buildDecisionButton(
                  'Atla',
                  Icons.close,
                  Colors.grey,
                  () => _makeDecision(product, ProductImportAction.SKIP),
                ),
              ],
            )
          else
            // Yeni ürünse sadece 2 seçenek
            Row(
              children: [
                Expanded(
                  child: _buildDecisionButton(
                    'Yeni Ürün Oluştur',
                    Icons.add_circle,
                    Colors.green,
                    () => _makeDecision(product, ProductImportAction.CREATE_NEW),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDecisionButton(
                    'Atla',
                    Icons.close,
                    Colors.grey,
                    () => _makeDecision(product, ProductImportAction.SKIP),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Karar Butonu
  Widget _buildDecisionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Karar Özeti (Karar verildikten sonra gösterilir)
  Widget _buildDecisionSummary(SupplierProductItem product) {
    final decision = product.userDecision!;
    String actionText = '';
    IconData actionIcon = Icons.check;
    Color actionColor = Colors.green;

    switch (decision.action) {
      case ProductImportAction.CREATE_NEW:
        actionText = 'Yeni ürün olarak oluşturulacak';
        actionIcon = Icons.add_circle;
        actionColor = Colors.green;
        break;
      case ProductImportAction.MATCH_EXISTING:
        actionText = 'Stoğa eklenecek';
        actionIcon = Icons.add_box;
        actionColor = Colors.blue;
        break;
      case ProductImportAction.ADD_AS_VARIANT:
        actionText = 'Varyant olarak eklenecek';
        actionIcon = Icons.library_add;
        actionColor = Colors.purple;
        break;
      case ProductImportAction.SKIP:
        actionText = 'Atlandı';
        actionIcon = Icons.close;
        actionColor = Colors.grey;
        break;
      case ProductImportAction.EDIT_AND_CREATE:
        actionText = 'Düzenlenip yeni ürün oluşturulacak';
        actionIcon = Icons.edit;
        actionColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: actionColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: actionColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(actionIcon, color: actionColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: actionColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                product.userDecision = null;
              });
            },
            child: const Text(
              'Değiştir',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Karar Ver
  void _makeDecision(SupplierProductItem product, ProductImportAction action) {
    setState(() {
      product.userDecision = UserProductDecision(
        action: action,
        selectedProductId:
            product.hasSystemMatches ? product.forProduct.first.productId : null,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.readProductName} için karar verildi'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Ürün Seçenekleri Dialog
  void _showProductOptionsDialog(
    SupplierProductItem supplierProduct,
    SystemProduct systemProduct,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(systemProduct.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${systemProduct.sku}'),
            Text('Varyantlar: ${systemProduct.variants.length}'),
            const SizedBox(height: 16),
            const Text('Bu ürünü seçmek istiyor musunuz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                supplierProduct.userDecision = UserProductDecision(
                  action: ProductImportAction.MATCH_EXISTING,
                  selectedProductId: systemProduct.productId,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Seç'),
          ),
        ],
      ),
    );
  }

  // Kaydet Butonu
  Widget _buildSaveButton() {
    final allDecided = _decidedCount == _response.productCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: allDecided ? _saveDecisions : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save, size: 20),
              const SizedBox(width: 8),
              Text(
                allDecided
                    ? 'Kaydet ($_decidedCount Ürün)'
                    : 'Tüm ürünler için karar verin ($_decidedCount/${_response.productCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kararları Kaydet
  Future<void> _saveDecisions() async {
    // TODO: Backend'e kaydet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Başarılı!'),
        content: Text('${_decidedCount} ürün başarıyla kaydedildi.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Helper: Toplam stok hesapla
  int _calculateTotalStock(SystemProduct product) {
    // Mock data için varsayılan değer
    return 120; // TODO: Gerçek veri kullan
  }

  // Helper: İlk barkodu al
  String? _getFirstBarcode(SystemProduct product) {
    if (product.variants.isEmpty) return null;
    final firstVariant = product.variants.first;
    if (firstVariant.barcodes == null || firstVariant.barcodes!.isEmpty) return null;
    return firstVariant.barcodes!.first.code;
  }
}
