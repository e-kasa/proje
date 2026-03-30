import 'package:flutter/material.dart';
import '../../models/backend_product_import.dart';
import '../../services/mock_backend_import_data.dart';
import '../../core/theme/app_colors.dart';

/// Basitleştirilmiş Bulk Import Ekranı
/// Backend'den gelen hazır formatı gösterir ve kullanıcı kararlarını toplar
class SimplifiedBulkImportScreen extends StatefulWidget {
  final String? importId;

  const SimplifiedBulkImportScreen({
    super.key,
    this.importId,
  });

  @override
  State<SimplifiedBulkImportScreen> createState() =>
      _SimplifiedBulkImportScreenState();
}

class _SimplifiedBulkImportScreenState
    extends State<SimplifiedBulkImportScreen> {
  late BackendImportResponse _response;
  bool _loading = true;
  ProductImportStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Mock data yükle (gerçekte backend'den gelecek)
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _response = MockBackendImportData.getMockImportResponse();
      _loading = false;
    });
  }

  List<BackendAnalyzedProduct> get _filteredProducts {
    if (_filterStatus == null) return _response.products;
    return _response.products.where((p) => p.status == _filterStatus).toList();
  }

  int _getStatusCount(ProductImportStatus status) {
    return _response.products.where((p) => p.status == status).length;
  }

  int get _approvedCount {
    return _response.products
        .where((p) => p.userDecision?.action == ImportAction.APPROVE)
        .length;
  }

  int get _skippedCount {
    return _response.products
        .where((p) => p.userDecision?.action == ImportAction.SKIP)
        .length;
  }

  Future<void> _handleSave() async {
    // Kararları topla
    final decisions = _response.products
        .where((p) => p.userDecision != null)
        .map((p) => {
              'tempId': p.tempId,
              'action': p.userDecision!.action.name,
              'payload': p.userDecision!.modifiedPayload ?? p.payload,
              'selectedProductId': p.userDecision?.selectedProductId,
            })
        .toList();

    if (decisions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir ürün için karar verin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Backend'e gönder
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await Future.delayed(const Duration(seconds: 2)); // Simüle et

      if (!mounted) return;
      Navigator.pop(context); // Dialog kapat

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${decisions.length} ürün başarıyla kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dialog kapat

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplu Ürün İçe Aktarma'),
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _approvedCount > 0 ? _handleSave : null,
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(
                'Kaydet ($_approvedCount)',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatistics(),
                _buildFilters(),
                Expanded(child: _buildProductList()),
              ],
            ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          _buildStatCard(
            'Toplam',
            _response.total.toString(),
            Icons.inventory_2,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Yeni',
            _getStatusCount(ProductImportStatus.NEW).toString(),
            Icons.add_circle,
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Benzer',
            _getStatusCount(ProductImportStatus.SIMILAR).toString(),
            Icons.compare_arrows,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Mevcut',
            _getStatusCount(ProductImportStatus.EXACT).toString(),
            Icons.check_circle,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Tümü', null),
          const SizedBox(width: 8),
          _buildFilterChip('Yeni', ProductImportStatus.NEW),
          const SizedBox(width: 8),
          _buildFilterChip('Benzer', ProductImportStatus.SIMILAR),
          const SizedBox(width: 8),
          _buildFilterChip('Mevcut', ProductImportStatus.EXACT),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ProductImportStatus? status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
      },
    );
  }

  Widget _buildProductList() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return const Center(
        child: Text('Bu filtrede ürün yok'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(BackendAnalyzedProduct product) {
    final hasDecision = product.userDecision != null;
    final isApproved = product.userDecision?.action == ImportAction.APPROVE;
    final isSkipped = product.userDecision?.action == ImportAction.SKIP;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (product.status) {
      case ProductImportStatus.NEW:
        statusColor = Colors.green;
        statusText = 'YENİ ÜRÜN';
        statusIcon = Icons.add_circle;
        break;
      case ProductImportStatus.SIMILAR:
        statusColor = Colors.orange;
        statusText = 'BENZER ÜRÜN';
        statusIcon = Icons.compare_arrows;
        break;
      case ProductImportStatus.EXACT:
        statusColor = Colors.purple;
        statusText = 'MEVCUT ÜRÜN';
        statusIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasDecision ? 4 : 2,
      color: isApproved
          ? Colors.green[50]
          : isSkipped
              ? Colors.grey[100]
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(product.confidence * 100).toInt()}%',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${product.sku}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product.salePrice.toStringAsFixed(2)} ₺',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Alış: ${product.purchasePrice.toStringAsFixed(2)} ₺',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (product.reason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.reason!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Similar Products
                if (product.similarProducts != null &&
                    product.similarProducts!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Benzer Ürünler:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...product.similarProducts!.map((similar) => Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    similar.productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    similar.reason,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(similar.similarity * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                // Actions
                const SizedBox(height: 12),
                _buildActions(product),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BackendAnalyzedProduct product) {
    final hasDecision = product.userDecision != null;

    if (hasDecision) {
      final action = product.userDecision!.action;
      String actionText;
      Color actionColor;
      IconData actionIcon;

      switch (action) {
        case ImportAction.APPROVE:
          actionText = 'Onaylandı';
          actionColor = Colors.green;
          actionIcon = Icons.check_circle;
          break;
        case ImportAction.SKIP:
          actionText = 'Atlandı';
          actionColor = Colors.grey;
          actionIcon = Icons.cancel;
          break;
        case ImportAction.ADD_AS_VARIANT:
          actionText = 'Varyant olarak eklenecek';
          actionColor = Colors.purple;
          actionIcon = Icons.add_box;
          break;
        case ImportAction.CREATE_NEW:
          actionText = 'Yeni ürün oluşturulacak';
          actionColor = Colors.blue;
          actionIcon = Icons.add_circle;
          break;
        default:
          actionText = 'Düzenlendi';
          actionColor = Colors.orange;
          actionIcon = Icons.edit;
      }

      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: actionColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(actionIcon, color: actionColor, size: 18),
            const SizedBox(width: 8),
            Text(
              actionText,
              style: TextStyle(
                color: actionColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  product.userDecision = null;
                });
              },
              child: const Text('Değiştir'),
            ),
          ],
        ),
      );
    }

    // Show action buttons based on status
    if (product.status == ProductImportStatus.SIMILAR) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                product.userDecision = UserImportDecision(
                  action: ImportAction.ADD_AS_VARIANT,
                  selectedProductId: product.similarProducts?.first.productId,
                );
              });
            },
            icon: const Icon(Icons.add_box, size: 18),
            label: const Text('Varyant Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                product.userDecision = UserImportDecision(
                  action: ImportAction.CREATE_NEW,
                );
              });
            },
            icon: const Icon(Icons.add_circle, size: 18),
            label: const Text('Yeni Ürün'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                product.userDecision = UserImportDecision(
                  action: ImportAction.SKIP,
                );
              });
            },
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Atla'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                product.userDecision = UserImportDecision(
                  action: ImportAction.APPROVE,
                );
              });
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              product.userDecision = UserImportDecision(
                action: ImportAction.SKIP,
              );
            });
          },
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Atla'),
        ),
      ],
    );
  }
}
