import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';

/// Reference data helpers for product edit form dropdowns.
/// TODO: Replace with API-driven reference data when backend endpoints are available.
class _ReferenceData {
  static List<String> getCategories() => [
    'Giyim', 'Elektronik', 'Gida', 'Kozmetik', 'Ev & Yasam',
    'Spor', 'Oyuncak', 'Kirtasiye', 'Diger',
  ];

  static List<String> getBrands() => [
    'Genel', 'Nike', 'Adidas', 'Samsung', 'Apple', 'LG',
    'Beko', 'Arcelik', 'Diger',
  ];

  static List<Map<String, dynamic>> getTaxRates() => [
    {'label': '%0', 'value': 0.0},
    {'label': '%1', 'value': 0.01},
    {'label': '%8', 'value': 0.08},
    {'label': '%10', 'value': 0.10},
    {'label': '%18', 'value': 0.18},
    {'label': '%20', 'value': 0.20},
  ];

  static List<Map<String, String>> getUnits() => [
    {'label': 'Adet', 'value': 'ADET'},
    {'label': 'Kilogram', 'value': 'KG'},
    {'label': 'Litre', 'value': 'LT'},
    {'label': 'Metre', 'value': 'MT'},
    {'label': 'Paket', 'value': 'PKT'},
    {'label': 'Kutu', 'value': 'KTU'},
  ];
}

/// Toplu İçe Aktarma - Ürün Düzenleme ve Manuel Eşleştirme Modal
class EditProductModal extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onSave;
  final List<Map<String, dynamic>>? existingProducts; // Sistemdeki mevcut ürünler

  const EditProductModal({
    super.key,
    required this.product,
    required this.onSave,
    this.existingProducts,
  });

  @override
  State<EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends State<EditProductModal> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _buyPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  // Dropdown values
  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedUnit;
  double? _selectedTaxRate;

  // Conflict resolution
  String? _selectedExistingProductId; // Manuel eşleştirme için
  String _resolutionMode = 'edit'; // 'edit' veya 'match'

  @override
  void initState() {
    super.initState();

    // Initialize controllers with product data
    _nameController = TextEditingController(text: widget.product['name']);
    _skuController = TextEditingController(text: widget.product['sku']);
    _barcodeController = TextEditingController(text: widget.product['barcode']);
    _buyPriceController = TextEditingController(
      text: widget.product['buyPrice'] > 0 ? widget.product['buyPrice'].toString() : '',
    );
    _sellPriceController = TextEditingController(
      text: widget.product['sellPrice'] > 0 ? widget.product['sellPrice'].toString() : '',
    );
    _stockController = TextEditingController(text: widget.product['stock'].toString());
    _descriptionController = TextEditingController(text: widget.product['description'] ?? '');

    // Initialize dropdown values
    _selectedCategory = widget.product['category'];
    _selectedBrand = widget.product['brand'];
    _selectedUnit = widget.product['unit'];
    _selectedTaxRate = widget.product['taxRate'];

    // If conflict exists, default to match mode
    if (widget.product['status'] == 'conflict') {
      _resolutionMode = 'match';
      _selectedExistingProductId = widget.product['existingProduct']?['id'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_resolutionMode == 'match') {
      if (_selectedExistingProductId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen eşleştirilecek ürünü seçin'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Match with existing product
      final updatedProduct = Map<String, dynamic>.from(widget.product);
      updatedProduct['status'] = 'matched';
      updatedProduct['matchedProductId'] = _selectedExistingProductId;
      updatedProduct['resolution'] = 'update';

      widget.onSave(updatedProduct);
      Navigator.pop(context);
      return;
    }

    // Edit mode - validate form
    if (_formKey.currentState!.validate()) {
      final updatedProduct = Map<String, dynamic>.from(widget.product);

      // Update all fields
      updatedProduct['name'] = _nameController.text.trim();
      updatedProduct['sku'] = _skuController.text.trim();
      updatedProduct['barcode'] = _barcodeController.text.trim();
      updatedProduct['category'] = _selectedCategory;
      updatedProduct['brand'] = _selectedBrand;
      updatedProduct['unit'] = _selectedUnit;
      updatedProduct['taxRate'] = _selectedTaxRate;
      updatedProduct['buyPrice'] = double.tryParse(_buyPriceController.text) ?? 0.0;
      updatedProduct['sellPrice'] = double.tryParse(_sellPriceController.text) ?? 0.0;
      updatedProduct['stock'] = int.tryParse(_stockController.text) ?? 0;
      updatedProduct['description'] = _descriptionController.text.trim();

      // Re-validate product status
      final errors = <String>[];
      if (updatedProduct['sku'].isEmpty) errors.add('SKU alanı boş');
      if (updatedProduct['barcode'].isEmpty) errors.add('Barkod alanı boş');
      if (updatedProduct['buyPrice'] == 0.0) errors.add('Alış fiyatı belirtilmemiş');
      if (updatedProduct['sellPrice'] == 0.0) errors.add('Satış fiyatı belirtilmemiş');

      if (errors.isEmpty) {
        updatedProduct['status'] = 'new'; // Fixed - now valid
        updatedProduct['errors'] = null;
      } else {
        updatedProduct['status'] = 'error';
        updatedProduct['errors'] = errors;
      }

      widget.onSave(updatedProduct);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConflict = widget.product['status'] == 'conflict';
    final hasExistingProducts = widget.existingProducts != null && widget.existingProducts!.isNotEmpty;

    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 720),
        child: Scaffold(
          appBar: AppAppBar.primary(
            title: 'Ürün Düzenle / Eşleştir',
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Mode Toggle (for conflict products)
              if (isConflict && hasExistingProducts) ...[
                Container(
                  color: AppColors.bgLight,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'match',
                              label: Text('Mevcut Ürünle Eşleştir'),
                              icon: Icon(Icons.link),
                            ),
                            ButtonSegment(
                              value: 'edit',
                              label: Text('Bilgileri Düzenle'),
                              icon: Icon(Icons.edit),
                            ),
                          ],
                          selected: {_resolutionMode},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _resolutionMode = newSelection.first;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _resolutionMode == 'match'
                      ? _buildMatchingMode()
                      : _buildEditMode(),
                ),
              ),

              // Bottom Actions
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 12),
                    AppButton.success(

                      text: _resolutionMode == 'match' ? 'Eşleştir' : 'Kaydet',

                      icon: Icons.save,

                      onPressed: _saveProduct,

                    ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchingMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bu ürünü sistemdeki mevcut bir ürünle eşleştirin. Seçilen ürün güncellenecektir.',
                  style: TextStyle(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Current Product Info
        const Text(
          'İçe Aktarılan Ürün:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildProductInfoCard(widget.product, AppColors.primary),
        const SizedBox(height: 24),

        // Existing Products Selection
        const Text(
          'Eşleştirilecek Mevcut Ürün:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Show default matched product if exists
        if (widget.product['existingProduct'] != null) ...[
          const Text(
            'Sistem Önerisi (Otomatik Tespit):',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          _buildSelectableProductCard(
            widget.product['existingProduct'],
            isSelected: _selectedExistingProductId == widget.product['existingProduct']['id'],
            onSelect: () {
              setState(() {
                _selectedExistingProductId = widget.product['existingProduct']['id'];
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Show other available products
        if (hasExistingProducts) ...[
          const Text(
            'Diğer Mevcut Ürünler:',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ...widget.existingProducts!.map((product) {
            // Skip if it's the auto-detected one (already shown above)
            if (product['id'] == widget.product['existingProduct']?['id']) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSelectableProductCard(
                product,
                isSelected: _selectedExistingProductId == product['id'],
                onSelect: () {
                  setState(() {
                    _selectedExistingProductId = product['id'];
                  });
                },
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error warnings if any
          if (widget.product['errors'] != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: AppColors.danger),
                      const SizedBox(width: 12),
                      const Text(
                        'Aşağıdaki hataları düzeltin:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var error in widget.product['errors'])
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 4),
                      child: Text('• $error'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Basic Information
          const Text(
            'Temel Bilgiler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ürün Adı *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ürün adı gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'SKU gerekli';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barkod *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Barkod gerekli';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category & Brand
          const Text(
            'Kategori ve Marka',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: _ReferenceData.getCategories().map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  decoration: const InputDecoration(
                    labelText: 'Marka',
                    border: OutlineInputBorder(),
                  ),
                  items: _ReferenceData.getBrands().map((brand) {
                    return DropdownMenuItem(
                      value: brand,
                      child: Text(brand),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBrand = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pricing
          const Text(
            'Fiyatlandırma',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _buyPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Alış Fiyatı (₺) *',
                    border: OutlineInputBorder(),
                    prefixText: '₺ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Alış fiyatı gerekli';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Geçerli bir fiyat girin';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _sellPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Satış Fiyatı (₺) *',
                    border: OutlineInputBorder(),
                    prefixText: '₺ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Satış fiyatı gerekli';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Geçerli bir fiyat girin';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<double>(
                  value: _selectedTaxRate,
                  decoration: const InputDecoration(
                    labelText: 'KDV Oranı',
                    border: OutlineInputBorder(),
                  ),
                  items: _ReferenceData.getTaxRates().map((rate) {
                    return DropdownMenuItem(
                      value: rate['value'] as double,
                      child: Text(rate['label'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTaxRate = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Birim',
                    border: OutlineInputBorder(),
                  ),
                  items: _ReferenceData.getUnits().map((unit) {
                    return DropdownMenuItem(
                      value: unit['value'],
                      child: Text(unit['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stock
          const Text(
            'Stok Bilgisi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Stok Miktarı',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final stock = int.tryParse(value);
                if (stock == null || stock < 0) {
                  return 'Geçerli bir stok miktarı girin';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Description
          const Text(
            'Açıklama',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Ürün Açıklaması',
              border: OutlineInputBorder(),
              hintText: 'Ürün hakkında detaylı bilgi...',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard(Map<String, dynamic> product, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor),
        borderRadius: BorderRadius.circular(8),
        color: accentColor.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product['name'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('SKU', product['sku'].isEmpty ? '-' : product['sku']),
          _buildInfoRow('Barkod', product['barcode'].isEmpty ? '-' : product['barcode']),
          _buildInfoRow('Kategori', product['category'] ?? '-'),
          _buildInfoRow('Marka', product['brand'] ?? '-'),
          _buildInfoRow('Alış Fiyatı', '₺${product['buyPrice']}'),
          _buildInfoRow('Satış Fiyatı', '₺${product['sellPrice']}'),
          _buildInfoRow('Stok', '${product['stock']}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableProductCard(
    Map<String, dynamic> product, {
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.success : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.success.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onSelect(),
              activeColor: AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product['sku']} | Barkod: ${product['barcode']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    'Stok: ${product['stock']} | Alış: ₺${product['buyPrice']} | Satış: ₺${product['sellPrice']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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