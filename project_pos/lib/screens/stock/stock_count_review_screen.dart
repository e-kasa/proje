import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/stock_management_models.dart';
import '../../services/service_locator.dart';
import '../../core/widgets/widgets.dart';

/// STOK SAYIM INCELEME EKRANI
/// Sayim sonuclarini inceleyip kabul/red/duzeltme yapma
class StockCountReviewScreen extends ConsumerStatefulWidget {
  final String? countId;

  const StockCountReviewScreen({
    Key? key,
    this.countId,
  }) : super(key: key);

  @override
  ConsumerState<StockCountReviewScreen> createState() => _StockCountReviewScreenState();
}

class _StockCountReviewScreenState extends ConsumerState<StockCountReviewScreen> {
  StockCountResponse? _response;
  bool _isLoading = true;
  String? _error;
  String _filterType = 'TÜMÜ';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(stockServiceProvider);
      final data = await service.performStockCount([]);
      final products = (data['products'] as List?)?.map((item) {
        return CountedProduct.fromJson(item as Map<String, dynamic>);
      }).toList() ?? [];
      setState(() {
        _response = StockCountResponse(
          countId: widget.countId ?? '-',
          countedBy: '-',
          products: products,
          productCount: products.length,
          countDate: DateTime.now(),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Veri yuklenemedi';
        _isLoading = false;
      });
    }
  }

  int get _decidedCount {
    return _response!.products.where((p) => p.hasDecision).length;
  }

  List<CountedProduct> get _filteredProducts {
    switch (_filterType) {
      case 'FARK OLAN':
        return _response!.products.where((p) => p.hasDifference).toList();
      case 'FAZLA':
        return _response!.products.where((p) => p.isOverage).toList();
      case 'EKSİK':
        return _response!.products.where((p) => p.isShortage).toList();
      case 'FARK YOK':
        return _response!.products.where((p) => !p.hasDifference).toList();
      default:
        return _response!.products;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _response == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(child: Text(_error ?? 'Veri yuklenemedi')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: 'Stok Sayim Inceleme',
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_decidedCount}/${_response!.productCount}',
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
          // Sayım Bilgileri
          _buildCountInfo(),

          // Filtre Butonları
          _buildFilterButtons(),

          // Progress Bar
          _buildProgressBar(),

          // Ürün Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_filteredProducts[index], index + 1);
              },
            ),
          ),

          // Kaydet Butonu
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCountInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.fact_check, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sayım ID: ${_response!.countId}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sayan: ${_response!.countedBy}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = ['TÜMÜ', 'FARK OLAN', 'FAZLA', 'EKSİK', 'FARK YOK'];

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _decidedCount / _response!.productCount;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İnceleme İlerlemesi',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(_decidedCount / _response!.productCount * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(CountedProduct product, int index) {
    final hasDecision = product.hasDecision;

    Color borderColor = Colors.grey[300]!;
    Color headerColor = Colors.grey[50]!;
    String statusLabel = 'FARK YOK';

    if (hasDecision) {
      borderColor = Colors.green[400]!;
      headerColor = Colors.green[50]!;
      statusLabel = 'KARAR VERİLDİ';
    } else if (product.hasDifference) {
      if (product.differenceLevel == DifferenceLevel.HIGH) {
        borderColor = Colors.red[400]!;
        headerColor = Colors.red[50]!;
        statusLabel = 'YÜKSEK FARK';
      } else if (product.differenceLevel == DifferenceLevel.MEDIUM) {
        borderColor = Colors.orange[400]!;
        headerColor = Colors.orange[50]!;
        statusLabel = 'ORTA FARK';
      } else {
        borderColor = Colors.yellow[700]!;
        headerColor = Colors.yellow[50]!;
        statusLabel = 'DÜŞÜK FARK';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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
                      '✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // İçerik
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Ürün Bilgileri
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SKU: ${product.sku ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Barkod: ${product.barcode ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Lokasyon: ${product.locationName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sayım Karşılaştırması
                Row(
                  children: [
                    Expanded(
                      child: _buildStockBox(
                        'Sistem Stoğu',
                        product.systemStock,
                        Icons.computer,
                        Colors.blue,
                      ),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.swap_horiz,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: _buildStockBox(
                        'Sayılan Stok',
                        product.countedStock,
                        Icons.fact_check,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fark Gösterimi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: product.hasDifference
                        ? (product.isOverage
                            ? Colors.green[50]
                            : Colors.red[50])
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: product.hasDifference
                          ? (product.isOverage
                              ? Colors.green[200]!
                              : Colors.red[200]!)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        product.isOverage
                            ? Icons.add_circle_outline
                            : product.isShortage
                                ? Icons.remove_circle_outline
                                : Icons.check_circle_outline,
                        color: product.hasDifference
                            ? (product.isOverage
                                ? Colors.green[700]
                                : Colors.red[700])
                            : Colors.grey[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fark: ${product.difference >= 0 ? '+' : ''}${product.difference} Adet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: product.hasDifference
                              ? (product.isOverage
                                  ? Colors.green[700]
                                  : Colors.red[700])
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Karar Verme Alanı
          if (!hasDecision) _buildDecisionArea(product),

          // Karar Özeti
          if (hasDecision) _buildDecisionSummary(product),
        ],
      ),
    );
  }

  Widget _buildStockBox(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value Adet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionArea(CountedProduct product) {
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
          if (product.hasDifference)
            // Fark varsa seçenekler
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDecisionButton(
                        'Sayımı Kabul Et',
                        Icons.check_circle,
                        Colors.green,
                        () => _makeDecision(product, CountAction.ACCEPT_COUNT),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDecisionButton(
                        'Tekrar Say',
                        Icons.replay,
                        Colors.orange,
                        () => _makeDecision(product, CountAction.RECOUNT),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDecisionButton(
                        'Yok Say',
                        Icons.close,
                        Colors.grey,
                        () => _makeDecision(product, CountAction.IGNORE),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            // Fark yoksa tek buton
            _buildDecisionButton(
              'Onayla',
              Icons.check,
              Colors.green,
              () => _makeDecision(product, CountAction.ACCEPT_COUNT),
            ),
        ],
      ),
    );
  }

  Widget _buildDecisionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    AppButton.primary(
      text: label,
      icon: icon, size: 18,
      onPressed: onTap,
    ),
  }

  Widget _buildDecisionSummary(CountedProduct product) {
    final decision = product.userDecision!;
    String actionText = '';
    IconData actionIcon = Icons.check;
    Color actionColor = Colors.green;

    switch (decision.action) {
      case CountAction.ACCEPT_COUNT:
        actionText = 'Sayım kabul edildi, sistem güncellenecek';
        actionIcon = Icons.check_circle;
        actionColor = Colors.green;
        break;
      case CountAction.RECOUNT:
        actionText = 'Tekrar sayım yapılacak';
        actionIcon = Icons.replay;
        actionColor = Colors.orange;
        break;
      case CountAction.MANUAL_ADJUST:
        actionText = 'Manuel düzeltme yapılacak';
        actionIcon = Icons.edit;
        actionColor = Colors.blue;
        break;
      case CountAction.IGNORE:
        actionText = 'Fark yok sayıldı';
        actionIcon = Icons.close;
        actionColor = Colors.grey;
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
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _makeDecision(CountedProduct product, CountAction action) {
    setState(() {
      product.userDecision = CountDecision(action: action);
    });
  }

  Widget _buildSaveButton() {
    final allDecided = _decidedCount == _response!.productCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Kararlar: $_decidedCount/${_response!.productCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: allDecided ? () {} : null,
            icon: const Icon(Icons.check),
            label: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}