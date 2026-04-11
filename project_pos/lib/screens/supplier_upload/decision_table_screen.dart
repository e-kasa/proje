import 'package:flutter/material.dart';
import '../../core/widgets/widgets.dart';

/// EKRAN 4: Karar Ver (Ana Ekran - Tablo Görünümü)
/// Kullanıcı her ürün için karar verir: Stok Ekle, Varyant Ekle, Yeni Ürün, Atla
class DecisionTableScreen extends StatefulWidget {
  final String uploadId;
  final String supplierName;
  final List<ProductDecisionItem> products;

  const DecisionTableScreen({
    super.key,
    required this.uploadId,
    required this.supplierName,
    required this.products,
  });

  @override
  State<DecisionTableScreen> createState() => _DecisionTableScreenState();
}

class _DecisionTableScreenState extends State<DecisionTableScreen> {
  late List<ProductDecisionItem> _products;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.products);
  }

  int get _decidedCount =>
      _products.where((p) => p.userDecision != null).length;

  void _handleDecision(int index, String decision) {
    setState(() {
      _products[index].userDecision = decision;
    });

    // Modal açılması gereken kararlar
    if (decision == 'CREATE_NEW') {
      _showCreateNewProductModal(index);
    } else if (decision == 'ADD_VARIANT') {
      _showAddVariantPanel(index);
    }
  }

  void _showCreateNewProductModal(int index) {
    showDialog(
      context: context,
      builder: (context) => CreateNewProductDialog(
        productName: _products[index].readProductName,
        quantity: _products[index].readQuantity,
        costPrice: _products[index].readCostPrice,
        onSave: (data) {
          setState(() {
            _products[index].decisionData = data;
          });
        },
      ),
    );
  }

  void _showAddVariantPanel(int index) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Varyant Ekle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Varyant Adi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: skuCtrl,
              decoration: const InputDecoration(
                labelText: 'SKU',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fiyat',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _products[index].decisionData ??= {};
                  _products[index].decisionData!['variants'] ??= [];
                  (_products[index].decisionData!['variants'] as List).add({
                    'name': nameCtrl.text,
                    'sku': skuCtrl.text,
                    'price': double.tryParse(priceCtrl.text) ?? 0,
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Ekle'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDecisions() async {
    // Tüm ürünler için karar verilmiş mi kontrol et
    final undecided = _products.where((p) => p.userDecision == null).toList();
    if (undecided.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eksik Kararlar'),
          content: Text(
            '${undecided.length} ürün için karar verilmedi. Devam etmek istiyor musunuz? (Bu ürünler atlanacak)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Collect decisions for backend (will be used when backend endpoint is ready)
      // ignore: unused_local_variable
      final decisions = _products
          .where((p) => p.userDecision != null)
          .map((p) => {
                'productName': p.readProductName,
                'decision': p.userDecision,
                'data': p.decisionData,
              })
          .toList();

      // TODO: Uncomment when backend endpoint is ready
      // await ref.read(bulkImportServiceProvider).saveDecisions(
      //   importId: widget.uploadId,
      //   products: decisions,
      // );

      // For now, simulate save
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        AppToast.success(context, 'Kararlar basariyla kaydedildi!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: '📋 Tedarikçi: ${widget.supplierName}',
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _decidedCount == _products.length
                          ? Icons.check_circle
                          : Icons.pending,
                      color: _decidedCount == _products.length
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_decidedCount/${_products.length} Karar Verildi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveDecisions,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Kaydediliyor...' : 'Tümünü Kaydet'),
                ),
              ],
            ),
          ),

          // Product Table
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = _products[index];
                return _ProductDecisionCard(
                  product: product,
                  index: index,
                  onDecisionChanged: (decision) =>
                      _handleDecision(index, decision),
                );
              },
            ),
          ),

          // Bottom Actions
          Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('İptal'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveDecisions,
                  icon: const Icon(Icons.check),
                  label: const Text('Kararları Kaydet'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Product Decision Card Widget
class _ProductDecisionCard extends StatelessWidget {
  final ProductDecisionItem product;
  final int index;
  final Function(String) onDecisionChanged;

  const _ProductDecisionCard({
    required this.product,
    required this.index,
    required this.onDecisionChanged,
  });

  Color _getMatchColor() {
    if (product.isNewProduct) return Colors.red;
    if (product.matchScore >= 90) return Colors.green;
    if (product.matchScore >= 70) return Colors.orange;
    return Colors.grey;
  }

  String _getMatchText() {
    if (product.isNewProduct) return 'Yeni ürün';
    return '%${product.matchScore} eşleşme';
  }

  List<String> _getDropdownOptions() {
    if (product.isNewProduct) {
      return ['CREATE_NEW', 'SKIP'];
    } else if (product.matchScore == 100) {
      return ['ADD_STOCK', 'ADD_VARIANT', 'CREATE_NEW', 'SKIP'];
    } else {
      return ['ADD_VARIANT', 'ADD_STOCK', 'CREATE_NEW', 'SKIP'];
    }
  }

  String _getDecisionLabel(String decision) {
    switch (decision) {
      case 'ADD_STOCK':
        return '✅ Stok Ekle';
      case 'ADD_VARIANT':
        return '📦 Varyant Ekle';
      case 'CREATE_NEW':
        return '➕ Yeni Ürün';
      case 'SKIP':
        return '⏭️ Atla';
      default:
        return 'Karar Ver';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDecided = product.userDecision != null;

    return Card(
      elevation: isDecided ? 1 : 2,
      color: isDecided ? Colors.green[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Row Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.readProductName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getMatchColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getMatchText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getMatchColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${product.readQuantity} adet × ${product.readCostPrice.toStringAsFixed(2)}₺',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (product.matchedProductName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '→ ${product.matchedProductName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Decision Dropdown
                PopupMenuButton<String>(
                  initialValue: product.userDecision,
                  onSelected: onDecisionChanged,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDecided ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.userDecision != null
                              ? _getDecisionLabel(product.userDecision!)
                              : 'Karar Ver',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) {
                    return _getDropdownOptions().map((decision) {
                      return PopupMenuItem<String>(
                        value: decision,
                        child: Text(_getDecisionLabel(decision)),
                      );
                    }).toList();
                  },
                ),
              ],
            ),

            // Decision Details
            if (isDecided) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getDecisionSummary(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDecisionSummary() {
    switch (product.userDecision) {
      case 'ADD_STOCK':
        return 'Mevcut ürüne stok eklenecek';
      case 'ADD_VARIANT':
        return 'Varyant bilgileri girildi';
      case 'CREATE_NEW':
        return 'Yeni ürün oluşturulacak';
      case 'SKIP':
        return 'Ürün atlandı';
      default:
        return 'Karar verildi';
    }
  }
}

/// Create New Product Dialog
class CreateNewProductDialog extends StatefulWidget {
  final String productName;
  final double quantity;
  final double costPrice;
  final Function(Map<String, dynamic>) onSave;

  const CreateNewProductDialog({
    super.key,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.onSave,
  });

  @override
  State<CreateNewProductDialog> createState() => _CreateNewProductDialogState();
}

class _CreateNewProductDialogState extends State<CreateNewProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _brandController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellPriceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productName);
    _categoryController = TextEditingController();
    _brandController = TextEditingController();
    _costPriceController =
        TextEditingController(text: widget.costPrice.toStringAsFixed(2));
    _sellPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'name': _nameController.text,
        'category': _categoryController.text,
        'brand': _brandController.text,
        'costPrice': double.parse(_costPriceController.text),
        'sellPrice': double.parse(_sellPriceController.text),
        'quantity': widget.quantity,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '➕ Yeni Ürün Oluştur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ürün adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category and Brand
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Marka',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Prices
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Alış Fiyatı (₺)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Satış Fiyatı (₺)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Oluştur'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ─── Product Decision Item Model ───────────────────────────────────────────

class ProductDecisionItem {
  final String readProductName;
  final double readQuantity;
  final double readCostPrice;
  final double readSellPrice;
  final String sku;
  final bool isNewProduct;
  final double matchScore;
  final String? matchedProductName;
  String? userDecision;
  Map<String, dynamic>? decisionData;

  ProductDecisionItem({
    required this.readProductName,
    required this.readQuantity,
    required this.readCostPrice,
    required this.readSellPrice,
    required this.sku,
    this.isNewProduct = true,
    this.matchScore = 0,
    this.matchedProductName,
    this.userDecision,
    this.decisionData,
  });
}