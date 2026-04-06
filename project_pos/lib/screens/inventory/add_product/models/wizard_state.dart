import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/service_locator.dart';
import '../../../../models/bulk_import_models.dart';
import 'data_models.dart';

export 'data_models.dart';

part 'wizard_actions.dart';

// ─── RetainedFields ─────────────────────────────────────────────────────────

class RetainedFields {
  final String? categoryId;
  final String selectedUnit;
  final double selectedVatRate;
  final bool vatIncluded;
  final bool taxExempt;
  final String? specialTaxRate;
  final String? withholdingTaxRate;
  final String? supplierId;
  final List<String> selectedStores;
  final List<String> selectedWarehouses;
  final String brandText;

  RetainedFields({
    this.categoryId,
    this.selectedUnit = 'pcs',
    this.selectedVatRate = 20.0,
    this.vatIncluded = false,
    this.taxExempt = false,
    this.specialTaxRate,
    this.withholdingTaxRate,
    this.supplierId,
    this.selectedStores = const [],
    this.selectedWarehouses = const [],
    this.brandText = '',
  });
}

// ─── WizardState ChangeNotifier ──────────────────────────────────────────────

class WizardState extends ChangeNotifier {
  /// Public trigger for notifyListeners, used by extensions in wizard_actions.dart.
  void notify() => notifyListeners();
  // Step 1: Basic Info
  final productNameController = TextEditingController();
  final skuController = TextEditingController();
  final brandController = TextEditingController();
  final descriptionController = TextEditingController();
  final basePriceController = TextEditingController(text: '0');
  final basePurchasePriceController = TextEditingController(text: '0');
  String? selectedCategory;
  String selectedUnit = 'pcs';

  // Tax fields (Step 1)
  double selectedVatRate = 20.0;
  bool vatIncluded = false;
  final specialTaxRateController = TextEditingController();
  final withholdingTaxRateController = TextEditingController();
  bool taxExempt = false;

  // Step 2: Variants
  String productType = 'simple';
  String? selectedPreset;
  List<ProductAttribute> attributes = [];
  List<ProductVariant> variants = [];
  bool showAllVariants = false;

  // Step 3: Stock & Barcode
  List<String> selectedStores = [];
  List<String> selectedWarehouses = [];
  String? selectedSupplier;
  final stockLocationController = TextEditingController();
  final shelfNumberController = TextEditingController();
  final invoiceNumberController = TextEditingController();
  final deliveryNoteController = TextEditingController();
  final purchaseDateController = TextEditingController();
  final globalNotesController = TextEditingController();
  final bulkStockController = TextEditingController();
  final bulkPurchasePriceController = TextEditingController();
  final bulkSalePriceController = TextEditingController();

  List<Map<String, dynamic>> suppliers = [];
  bool loadingSuppliers = false;
  bool isSaving = false;

  // OEM & Cross Reference
  List<Map<String, String>> oemNumbers = [];
  List<Map<String, String>> crossReferences = [];

  // Images
  List<String> productImages = [];
  String variantSearchQuery = '';
  final Set<int> expandedVariants = {};
  bool colorGroupedView = true;
  String groupingAttribute = 'Renk';

  // Dropdown data
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> stores = [];
  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> brands = [];

  final units = [
    {'value': 'pcs', 'label': 'Adet'},
    {'value': 'kg',  'label': 'Kilogram (Kg)'},
    {'value': 'g',   'label': 'Gram (G)'},
    {'value': 'lt',  'label': 'Litre (Lt)'},
    {'value': 'mt',  'label': 'Metre (Mt)'},
    {'value': 'm2',  'label': 'Metrekare (m\u00b2)'},
    {'value': 'box', 'label': 'Kutu'},
    {'value': 'pkg', 'label': 'Paket'},
  ];

  // ─── Preset Templates ────────────────────────────────────────────────────

  Map<String, List<ProductAttribute>> getPresetTemplates() {
    return {
      'clothing': [
        ProductAttribute(name: 'Renk', icon: Icons.palette, values: ['K\u0131rm\u0131z\u0131', 'Mavi', 'Siyah', 'Beyaz']),
        ProductAttribute(name: 'Beden', icon: Icons.straighten, values: ['XS', 'S', 'M', 'L', 'XL', 'XXL']),
      ],
      'electronics': [
        ProductAttribute(name: 'RAM', icon: Icons.memory, values: ['4GB', '8GB', '16GB', '32GB']),
        ProductAttribute(name: 'Depolama', icon: Icons.storage, values: ['128GB', '256GB', '512GB', '1TB']),
        ProductAttribute(name: 'Renk', icon: Icons.palette, values: ['G\u00fcm\u00fc\u015f', 'Uzay Grisi', 'Alt\u0131n']),
      ],
      'shoes': [
        ProductAttribute(name: 'Renk', icon: Icons.palette, values: ['Siyah', 'Beyaz', 'Mavi']),
        ProductAttribute(name: 'Numara', icon: Icons.straighten, values: ['38', '39', '40', '41', '42', '43', '44', '45']),
      ],
    };
  }

  // ─── Init / Load ─────────────────────────────────────────────────────────

  void generateSKU() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    skuController.text = 'SKU-$timestamp';
  }

  void initializeDefaultVariant() {
    if (variants.isEmpty) {
      variants.add(ProductVariant(
        sku: skuController.text,
        name: 'Varsay\u0131lan Varyant',
        attributes: {},
        purchasePrice: 0,
        salePrice: 0,
        inventory: InventoryInfo(warehouseCode: 'WH-001', physicalQuantity: 0),
        barcodes: [],
        notes: '',
      ));
    }
  }

  Future<void> loadDropdowns(WidgetRef ref) async {
    loadingSuppliers = true;
    notifyListeners();

    // 1. Suppliers
    try {
      final sups = await ref.read(supplierServiceProvider).getSuppliers();
      debugPrint('\u2705 Tedarik\u00e7iler y\u00fcklendi: ${sups.length} kay\u0131t');
      suppliers = sups;
    } catch (e) {
      debugPrint('\u274c Tedarik\u00e7i y\u00fckleme hatas\u0131: $e');
    }

    // 2. Warehouses
    try {
      final whs = await ref.read(warehouseServiceProvider).getWarehouses(isActive: true);
      debugPrint('\u2705 Depolar y\u00fcklendi: ${whs.length} kay\u0131t');
      warehouses = whs.map((w) {
        final code = w['code']?.toString() ?? w['warehouseCode']?.toString() ?? w['id']?.toString() ?? '';
        String emoji = '\ud83d\udce6';
        if (w['type'] == 'main') emoji = '\ud83c\udfe2';
        else if (w['type'] == 'regional') emoji = '\ud83c\udfea';
        return <String, dynamic>{'value': code, 'label': '$emoji ${w['name']}'};
      }).toList();
    } catch (e) {
      debugPrint('\u274c Depo y\u00fckleme hatas\u0131: $e');
    }

    // 3. Stores
    try {
      final sts = await ref.read(storeServiceProvider).getStores(isActive: true);
      debugPrint('\u2705 Ma\u011fazalar y\u00fcklendi: ${sts.length} kay\u0131t');
      stores = sts.map((s) {
        final code = s['code']?.toString() ?? s['storeCode']?.toString() ?? s['id']?.toString() ?? '';
        String emoji = '\ud83c\udfea';
        if (s['type'] == 'flagship') emoji = '\ud83c\udfe2';
        else if (s['type'] == 'outlet') emoji = '\ud83c\udfec';
        return <String, dynamic>{'value': code, 'label': '$emoji ${s['name']}'};
      }).toList();
    } catch (e) {
      debugPrint('\u274c Ma\u011faza y\u00fckleme hatas\u0131: $e');
    }

    // 4. Categories
    try {
      final rawCats = await ref.read(companyCategoryServiceProvider).getMyCategoryList();
      debugPrint('\u2705 Kategoriler y\u00fcklendi: ${rawCats.length} kay\u0131t');
      final cats = rawCats.map((c) => <String, dynamic>{
        'id': c['categoryId'],
        'name': c['categoryName'],
        'level': c['categoryLevel'],
        'parentId': c['categoryParentId'],
        'sortOrder': c['displayOrder'],
        'icon': c['categoryIcon'],
      }).toList();
      categories = buildCategoryTree(cats);
    } catch (e) {
      debugPrint('\u274c Kategori y\u00fckleme hatas\u0131: $e');
    }

    // 5. Brands
    try {
      final brs = await ref.read(brandServiceProvider).getActiveBrands();
      debugPrint('\u2705 Markalar y\u00fcklendi: ${brs.length} kay\u0131t');
      brands = brs;
    } catch (e) {
      debugPrint('\u274c Marka y\u00fckleme hatas\u0131: $e');
    }

    loadingSuppliers = false;
    notifyListeners();
  }

  // ─── Attribute / Variant Methods ─────────────────────────────────────────

  void applyPreset(String presetKey) {
    final presets = getPresetTemplates();
    final preset = presets[presetKey];
    if (preset != null) {
      selectedPreset = presetKey;
      attributes = preset.map((attr) => ProductAttribute(
        name: attr.name,
        icon: attr.icon,
        values: List.from(attr.values),
      )).toList();
      notifyListeners();
    }
  }

  void addAttribute(String name, IconData icon) {
    attributes.add(ProductAttribute(name: name, icon: icon, values: []));
    notifyListeners();
  }

  void removeAttribute(int index) {
    attributes.removeAt(index);
    notifyListeners();
  }

  void addValueToAttribute(int attrIndex, String value) {
    if (value.trim().isEmpty) return;
    if (!attributes[attrIndex].values.contains(value.trim())) {
      attributes[attrIndex].values.add(value.trim());
      notifyListeners();
    }
  }

  void removeValueFromAttribute(int attrIndex, int valueIndex) {
    attributes[attrIndex].values.removeAt(valueIndex);
    notifyListeners();
  }

  int calculateTotalVariants() {
    final attributesWithValues = attributes.where((attr) => attr.values.isNotEmpty).toList();
    if (attributesWithValues.isEmpty) return 0;
    int total = 1;
    for (final attr in attributesWithValues) {
      total *= attr.values.length;
    }
    return total;
  }

  /// Returns false if a warning should be shown (no attributes with values).
  bool generateVariants(BuildContext context) {
    final newVariants = <ProductVariant>[];

    if (productType == 'simple') {
      newVariants.add(ProductVariant(
        sku: skuController.text,
        name: productNameController.text.isEmpty ? '\u00dcr\u00fcn' : productNameController.text,
        attributes: {},
        purchasePrice: double.tryParse(basePurchasePriceController.text) ?? 0,
        salePrice: double.tryParse(basePriceController.text) ?? 0,
        inventory: InventoryInfo(warehouseCode: 'WH-001', physicalQuantity: 0),
        barcodes: [],
        notes: '',
      ));
    } else {
      final attributesWithValues = attributes.where((attr) => attr.values.isNotEmpty).toList();

      if (attributesWithValues.isEmpty) {
        return false; // caller should show warning
      }

      List<Map<String, String>> combinations = [{}];
      for (final attr in attributesWithValues) {
        final newCombinations = <Map<String, String>>[];
        for (final combo in combinations) {
          for (final value in attr.values) {
            newCombinations.add({...combo, attr.name: value});
          }
        }
        combinations = newCombinations;
      }

      int index = 0;
      for (final combo in combinations) {
        index++;
        final variantName = combo.values.join(' - ');
        newVariants.add(ProductVariant(
          sku: '${skuController.text}-V$index',
          name: '${productNameController.text} - $variantName',
          attributes: combo,
          purchasePrice: double.tryParse(basePurchasePriceController.text) ?? 0,
          salePrice: double.tryParse(basePriceController.text) ?? 0,
          inventory: InventoryInfo(warehouseCode: 'WH-001', physicalQuantity: 0),
          barcodes: [],
          notes: '',
        ));
      }
    }

    variants = newVariants;
    notifyListeners();
    return true;
  }

  // ─── Validation ──────────────────────────────────────────────────────────

  /// Returns null if valid, or an error message string.
  String? validateStep(int step) {
    switch (step) {
      case 0:
        if (productNameController.text.trim().isEmpty) {
          return '\u26a0\ufe0f \u00dcr\u00fcn ad\u0131 zorunludur';
        }
        if (productNameController.text.trim().length < 3) {
          return '\u26a0\ufe0f \u00dcr\u00fcn ad\u0131 en az 3 karakter olmal\u0131d\u0131r';
        }
        if (selectedCategory == null) {
          return '\u26a0\ufe0f Kategori se\u00e7imi zorunludur';
        }
        final basePrice = double.tryParse(basePriceController.text) ?? 0;
        if (basePrice <= 0) {
          return '\u26a0\ufe0f Ge\u00e7erli bir fiyat giriniz (0\'dan b\u00fcy\u00fck olmal\u0131)';
        }
        return null;
      case 1:
        // Warning only, not blocking
        return null;
      case 2:
        if (selectedStores.isEmpty) {
          return '\u26a0\ufe0f En az bir ma\u011faza se\u00e7imi zorunludur';
        }
        if (selectedWarehouses.isEmpty) {
          return '\u26a0\ufe0f En az bir depo se\u00e7imi zorunludur';
        }
        return null;
      default:
        return null;
    }
  }
}