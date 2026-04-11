import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// Reference data helpers for product edit form dropdowns.
class _ReferenceData {
  // Sabit kategoriler artık kullanılmıyor — API'den dinamik yükleniyor

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

class EditProductModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onSave;
  final List<Map<String, dynamic>>? existingProducts;

  const EditProductModal({
    super.key,
    required this.product,
    required this.onSave,
    this.existingProducts,
  });

  @override
  ConsumerState<EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends ConsumerState<EditProductModal> {
  String Function(String) get t => i18nOf(ref);
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _buyPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedUnit;
  double? _selectedTaxRate;

  List<String> _categoryNames = [];

  String? _selectedExistingProductId;
  String _resolutionMode = 'edit';

  @override
  void initState() {
    super.initState();
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

    _selectedCategory = widget.product['category'];
    _selectedBrand = widget.product['brand'];
    _selectedUnit = widget.product['unit'];
    _selectedTaxRate = widget.product['taxRate'];

    if (widget.product['status'] == 'conflict') {
      _resolutionMode = 'match';
      _selectedExistingProductId = widget.product['existingProduct']?['id'];
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ref.read(companyCategoryServiceProvider).getMyCategoryList();
      final names = cats
          .map((c) => c['categoryName']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _categoryNames = names;
          // Seçili kategori listede yoksa sıfırla
          if (_selectedCategory != null && !names.contains(_selectedCategory)) {
            _selectedCategory = null;
          }
        });
      }
    } catch (_) {
      // Yüklenemezse dropdown boş kalır
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
        AppToast.warning(context, t('bulk_import.select_product_to_match')); // TODO: i18n
        return;
      }

      final updatedProduct = Map<String, dynamic>.from(widget.product);
      updatedProduct['status'] = 'matched';
      updatedProduct['matchedProductId'] = _selectedExistingProductId;
      updatedProduct['resolution'] = 'update';

      widget.onSave(updatedProduct);
      Navigator.pop(context);
      return;
    }

    if (_formKey.currentState!.validate()) {
      final updatedProduct = Map<String, dynamic>.from(widget.product);

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

      final errors = <String>[];
      if (updatedProduct['sku'].isEmpty) errors.add('SKU alanı boş');
      if (updatedProduct['barcode'].isEmpty) errors.add('Barkod alanı boş');
      if (updatedProduct['buyPrice'] == 0.0) errors.add('Alış fiyatı belirtilmemiş');
      if (updatedProduct['sellPrice'] == 0.0) errors.add('Satış fiyatı belirtilmemiş');

      if (errors.isEmpty) {
        updatedProduct['status'] = 'new';
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
            title: t('bulk_import.edit_match_product'), // TODO: i18n
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
              if (isConflict && hasExistingProducts) ...[
                Container(
                  color: AppColors.bgLight,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'match',
                              label: Text(t('bulk_import.match_existing')), // TODO: i18n
                              icon: const Icon(Icons.link),
                            ),
                            ButtonSegment(
                              value: 'edit',
                              label: Text(t('common.edit')),
                              icon: const Icon(Icons.edit),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _resolutionMode == 'match'
                      ? _buildMatchingMode()
                      : _buildEditMode(),
                ),
              ),
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t('common.cancel')),
                    ),
                    const SizedBox(width: 12),
                    AppButton.success(
                      text: _resolutionMode == 'match' ? t('common.match') : t('common.save'),
                      icon: Icons.save,
                      onPressed: _saveProduct,
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
    final hasExistingProducts = widget.existingProducts != null && widget.existingProducts!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('bulk_import.match_info'), // TODO: i18n
                  style: TextStyle(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t('bulk_import.imported_product'), // TODO: i18n
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildProductInfoCard(widget.product, AppColors.primary),
        const SizedBox(height: 24),
        Text(
          t('bulk_import.existing_product_to_match'), // TODO: i18n
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.product['existingProduct'] != null) ...[
          Text(
            t('bulk_import.system_suggestion'), // TODO: i18n
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
        if (hasExistingProducts) ...[
          Text(
            t('bulk_import.other_existing_products'), // TODO: i18n
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          ...widget.existingProducts!.map((product) {
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
          if (widget.product['errors'] != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Text(
                        t('bulk_import.fix_errors_below'), // TODO: i18n
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
          Text(t('bulk_import.basic_info'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // TODO: i18n
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Ürün Adı *', border: OutlineInputBorder()),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Ürün adı gerekli' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU *', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'SKU gerekli' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'Barkod *', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Barkod gerekli' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(t('bulk_import.category_brand'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // TODO: i18n
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                  items: _categoryNames.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  decoration: const InputDecoration(labelText: 'Marka', border: OutlineInputBorder()),
                  items: _ReferenceData.getBrands().map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setState(() => _selectedBrand = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(t('bulk_import.pricing'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // TODO: i18n
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _buyPriceController,
                  decoration: const InputDecoration(labelText: 'Alış Fiyatı (₺) *', border: OutlineInputBorder(), prefixText: '₺ '),
                  keyboardType: TextInputType.number,
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Geçerli fiyat girin' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _sellPriceController,
                  decoration: const InputDecoration(labelText: 'Satış Fiyatı (₺) *', border: OutlineInputBorder(), prefixText: '₺ '),
                  keyboardType: TextInputType.number,
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Geçerli fiyat girin' : null,
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
                  decoration: const InputDecoration(labelText: 'KDV Oranı', border: OutlineInputBorder()),
                  items: _ReferenceData.getTaxRates().map((r) => DropdownMenuItem(value: r['value'] as double, child: Text(r['label'] as String))).toList(),
                  onChanged: (v) => setState(() => _selectedTaxRate = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(labelText: 'Birim', border: OutlineInputBorder()),
                  items: _ReferenceData.getUnits().map((u) => DropdownMenuItem(value: u['value'], child: Text(u['label']!))).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(t('bulk_import.stock_info'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // TODO: i18n
          const SizedBox(height: 16),
          TextFormField(
            controller: _stockController,
            decoration: const InputDecoration(labelText: 'Stok Miktarı', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Text(t('bulk_import.description'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // TODO: i18n
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Ürün Açıklaması', border: OutlineInputBorder()),
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
        color: accentColor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInfoRow('SKU', product['sku'].isEmpty ? '-' : product['sku']),
          _buildInfoRow('Barkod', product['barcode'].isEmpty ? '-' : product['barcode']),
          _buildInfoRow('Kategori', product['category'] ?? '-'),
          _buildInfoRow('Alış Fiyatı', '₺${product['buyPrice']}'),
          _buildInfoRow('Satış Fiyatı', '₺${product['sellPrice']}'),
          _buildInfoRow('Stok', '${product['stock']}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSelectableProductCard(Map<String, dynamic> product, {required bool isSelected, required VoidCallback onSelect}) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppColors.success : AppColors.border, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.success.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Radio<bool>(value: true, groupValue: isSelected, onChanged: (_) => onSelect(), activeColor: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'], style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                  Text('SKU: ${product['sku']} | Barkod: ${product['barcode']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}