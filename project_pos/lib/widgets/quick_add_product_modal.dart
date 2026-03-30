import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuickAddProductModal extends StatefulWidget {
  const QuickAddProductModal({super.key});

  @override
  State<QuickAddProductModal> createState() => _QuickAddProductModalState();
}

class _QuickAddProductModalState extends State<QuickAddProductModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  String _selectedUnit = 'pcs';
  bool _isSaving = false;

  final List<String> _categories = [
    'Elektronik',
    'Giyim',
    'Ayakkabı',
    'Aksesuar',
    'Ev & Yaşam',
    'Gıda',
    'Kozmetik',
  ];

  final List<Map<String, String>> _units = [
    {'value': 'pcs', 'label': 'Adet'},
    {'value': 'kg', 'label': 'Kg'},
    {'value': 'g', 'label': 'Gram'},
    {'value': 'lt', 'label': 'Litre'},
    {'value': 'box', 'label': 'Kutu'},
  ];

  @override
  void initState() {
    super.initState();
    _generateSKU();
  }

  void _generateSKU() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _skuController.text = 'PRD$timestamp';
  }

  void _scanBarcode() {
    // TODO: Implement barcode scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barkod okuyucu açılıyor...')),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ürün başarıyla eklendi!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hızlı Ürün Ekle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Temel bilgileri girin',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Product Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Ürün Adı *',
                          hintText: 'Nike Air Max 90',
                          prefixIcon: const Icon(Icons.inventory_2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Ürün adı gerekli' : null,
                      ),
                      const SizedBox(height: 16),

                      // SKU & Barcode
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _skuController,
                              decoration: InputDecoration(
                                labelText: 'SKU *',
                                prefixIcon: const Icon(Icons.tag),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _generateSKU,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'SKU gerekli' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: InputDecoration(
                                labelText: 'Barkod',
                                prefixIcon: const Icon(Icons.qr_code),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.camera_alt, size: 20),
                                  onPressed: _scanBarcode,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori *',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        validator: (value) =>
                            value == null ? 'Kategori seçin' : null,
                      ),
                      const SizedBox(height: 16),

                      // Price, Stock, Unit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Fiyat *',
                                prefixIcon: const Icon(Icons.attach_money),
                                suffixText: '₺',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Gerekli';
                                if (double.tryParse(value!) == null) {
                                  return 'Geçersiz';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Stok *',
                                prefixIcon: const Icon(Icons.numbers),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Gerekli';
                                if (int.tryParse(value!) == null) {
                                  return 'Geçersiz';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: InputDecoration(
                                labelText: 'Birim',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit['value'],
                                  child: Text(unit['label']!),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedUnit = value!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Kaydet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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

// Helper function to show the modal
Future<bool?> showQuickAddProductModal(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const QuickAddProductModal(),
  );
}
