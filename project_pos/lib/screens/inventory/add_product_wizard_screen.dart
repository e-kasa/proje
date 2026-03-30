import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';
import 'package:dio/dio.dart';
import '../../models/bulk_import_models.dart';

class AddProductWizardScreen extends ConsumerStatefulWidget {
  final bool fromBulkImport;
  final Map<String, dynamic>? importData;
  final String? tempId;

  const AddProductWizardScreen({
    super.key,
    this.fromBulkImport = false,
    this.importData,
    this.tempId,
  });

  @override
  ConsumerState<AddProductWizardScreen> createState() => _AddProductWizardScreenState();
}

class _AddProductWizardScreenState extends ConsumerState<AddProductWizardScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Responsive helpers
  bool get _isMobile => MediaQuery.of(context).size.width < 600;
  bool get _isTablet => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 900;
  double get _screenWidth => MediaQuery.of(context).size.width;

  // Step 1: Basic Info
  final _productNameController = TextEditingController();
  final _skuController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController(text: '0');
  final _basePurchasePriceController = TextEditingController(text: '0');
  String? _selectedCategory;
  String _selectedUnit = 'pcs';

  // Vergi alanları (Step 1)
  double _selectedVatRate = 20.0;   // KDV oranı (%)
  bool _vatIncluded = false;         // Fiyat KDV dahil mi?
  final _specialTaxRateController = TextEditingController();   // ÖTV (%)
  final _withholdingTaxRateController = TextEditingController(); // Stopaj (%)
  bool _taxExempt = false;           // Vergiden muaf

  // Step 2: Variants
  String _productType = 'simple'; // 'simple' or 'variant'
  String? _selectedPreset; // 'clothing', 'electronics', 'shoes', 'custom'
  List<ProductAttribute> _attributes = []; // Dinamik attribute listesi
  List<ProductVariant> _variants = [];
  bool _showAllVariants = false; // Varyant önizlemesinde tümünü göster

  // Step 3: Stock & Barcode
  List<String> _selectedStores = [];
  List<String> _selectedWarehouses = [];
  String? _selectedSupplier;
  final _stockLocationController = TextEditingController();
  final _shelfNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _deliveryNoteController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _globalNotesController = TextEditingController();
  final _bulkStockController = TextEditingController();
  final _bulkPurchasePriceController = TextEditingController();
  final _bulkSalePriceController = TextEditingController();

  List<Map<String, dynamic>> _suppliers = [];
  bool _loadingSuppliers = false;
  bool _isSaving = false;

  // Images
  List<String> _productImages = []; // Ürün görselleri (base64 veya path)
  String _variantSearchQuery = ''; // Varyant arama
  final Set<int> _expandedVariants = {}; // Açık varyant indeksleri
  bool _colorGroupedView = true; // Renk bazlı görünüm (default: açık)
  String _groupingAttribute = 'Renk'; // Gruplandırma özelliği

  // Kategoriler — backend'den yüklenir
  List<Map<String, dynamic>> _categories = [];

  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _brands = [];

  final _units = [
    {'value': 'pcs', 'label': 'Adet'},
    {'value': 'kg',  'label': 'Kilogram (Kg)'},
    {'value': 'g',   'label': 'Gram (G)'},
    {'value': 'lt',  'label': 'Litre (Lt)'},
    {'value': 'mt',  'label': 'Metre (Mt)'},
    {'value': 'm2',  'label': 'Metrekare (m²)'},
    {'value': 'box', 'label': 'Kutu'},
    {'value': 'pkg', 'label': 'Paket'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    _generateSKU();
    _initializeDefaultVariant();

    // Pre-populate from bulk import data
    if (widget.fromBulkImport && widget.importData != null) {
      _populateFromImportData(widget.importData!);
    }
  }

  void _initializeDefaultVariant() {
    if (_variants.isEmpty) {
      _variants.add(ProductVariant(
        sku: _skuController.text,
        name: 'Varsayılan Varyant',
        attributes: {},
        purchasePrice: 0,
        salePrice: 0,
        inventory: InventoryInfo(warehouseCode: 'WH-001', physicalQuantity: 0),
        barcodes: [],
        notes: '',
      ));
    }
  }

  void _populateFromImportData(Map<String, dynamic> data) {
    // Basic Info (Step 1)
    if (data['name'] != null) {
      _productNameController.text = data['name'].toString();
    }
    if (data['sku'] != null) {
      _skuController.text = data['sku'].toString();
    }
    if (data['barcode'] != null) {
      // Barcode will be added to the variant
      final barcode = data['barcode'].toString();
      if (_variants.isNotEmpty && barcode.isNotEmpty) {
        _variants[0].barcodes = [
          BarcodeInfo(code: barcode, type: 'EAN13', isPrimary: true),
        ];
      }
    }
    if (data['buyPrice'] != null) {
      _basePurchasePriceController.text = data['buyPrice'].toString();
      if (_variants.isNotEmpty) {
        _variants[0].purchasePrice = double.tryParse(data['buyPrice'].toString()) ?? 0;
      }
    }
    if (data['sellPrice'] != null) {
      _basePriceController.text = data['sellPrice'].toString();
      if (_variants.isNotEmpty) {
        _variants[0].salePrice = double.tryParse(data['sellPrice'].toString()) ?? 0;
      }
    }
    if (data['stock'] != null) {
      final stock = int.tryParse(data['stock'].toString()) ?? 0;
      if (_variants.isNotEmpty && _variants[0].inventory != null) {
        _variants[0].inventory!.physicalQuantity = stock;
      }
    }
    if (data['categoryId'] != null) {
      _selectedCategory = data['categoryId'].toString();
    }
    if (data['brandId'] != null) {
      _brandController.text = data['brandId'].toString();
    }
    if (data['unit'] != null) {
      _selectedUnit = data['unit'].toString();
    }

    setState(() {}); // Update UI with pre-populated data
  }

  void _generateSKU() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    _skuController.text = 'SKU-$timestamp';
  }

  Future<void> _loadDropdowns() async {
    setState(() => _loadingSuppliers = true);

    // ── 1. TEDARİKÇİ ──────────────────────────────────────────────
    try {
      final suppliers = await ref.read(supplierServiceProvider).getSuppliers();
      debugPrint('✅ Tedarikçiler yüklendi: ${suppliers.length} kayıt');
      if (mounted) setState(() => _suppliers = suppliers);
    } catch (e) {
      debugPrint('❌ Tedarikçi yükleme hatası: $e');
    }

    // ── 2. DEPO ───────────────────────────────────────────────────
    try {
      final warehouses = await ref.read(warehouseServiceProvider).getWarehouses(isActive: true);
      debugPrint('✅ Depolar yüklendi: ${warehouses.length} kayıt');
      if (mounted) {
        setState(() {
          _warehouses = warehouses.map((w) {
            final code = w['code']?.toString() ?? w['warehouseCode']?.toString() ?? w['id']?.toString() ?? '';
            String emoji = '📦';
            if (w['type'] == 'main') emoji = '🏢';
            else if (w['type'] == 'regional') emoji = '🏪';
            return <String, dynamic>{'value': code, 'label': '$emoji ${w['name']}'};
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Depo yükleme hatası: $e');
    }

    // ── 3. MAĞAZA ─────────────────────────────────────────────────
    try {
      final stores = await ref.read(storeServiceProvider).getStores(isActive: true);
      debugPrint('✅ Mağazalar yüklendi: ${stores.length} kayıt');
      if (mounted) {
        setState(() {
          _stores = stores.map((s) {
            final code = s['code']?.toString() ?? s['storeCode']?.toString() ?? s['id']?.toString() ?? '';
            String emoji = '🏪';
            if (s['type'] == 'flagship') emoji = '🏢';
            else if (s['type'] == 'outlet') emoji = '🏬';
            return <String, dynamic>{'value': code, 'label': '$emoji ${s['name']}'};
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Mağaza yükleme hatası: $e');
    }

    // ── 4. KATEGORİ ───────────────────────────────────────────────
    try {
      final rawCats = await ref.read(companyCategoryServiceProvider).getMyCategoryList();
      debugPrint('✅ Kategoriler yüklendi: ${rawCats.length} kayıt');
      final categories = rawCats.map((c) => <String, dynamic>{
        'id': c['categoryId'],
        'name': c['categoryName'],
        'level': c['categoryLevel'],
        'parentId': c['categoryParentId'],
        'sortOrder': c['displayOrder'],
        'icon': c['categoryIcon'],
      }).toList();
      if (mounted) setState(() => _categories = _buildCategoryTree(categories));
    } catch (e) {
      debugPrint('❌ Kategori yükleme hatası: $e');
    }

    // ── 5. MARKA ──────────────────────────────────────────────────
    try {
      final brands = await ref.read(brandServiceProvider).getActiveBrands();
      debugPrint('✅ Markalar yüklendi: ${brands.length} kayıt');
      if (mounted) setState(() => _brands = brands);
    } catch (e) {
      debugPrint('❌ Marka yükleme hatası: $e');
    }

    if (mounted) setState(() => _loadingSuppliers = false);
  }

  // ─────────────────────────────────────────────────────────────────
  // ÇOKLU SEÇİM — chip listesi + dropdown ile ekleme
  // ─────────────────────────────────────────────────────────────────

  Widget _buildMultiSelectChips({
    required List<String> selectedValues,
    required List<Map<String, dynamic>> allOptions,
    required String hintText,
    required IconData icon,
    required Function(List<String>) onChanged,
  }) {
    final unselected = allOptions.where((o) => !selectedValues.contains(o['value'])).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedValues.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: selectedValues.map((val) {
              final opt = allOptions.firstWhere(
                (o) => o['value'] == val,
                orElse: () => <String, dynamic>{'value': val, 'label': val},
              );
              return Chip(
                label: Text(opt['label']?.toString() ?? val, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.danger),
                onDeleted: () {
                  final newList = List<String>.from(selectedValues)..remove(val);
                  onChanged(newList);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        if (unselected.isNotEmpty)
          DropdownButtonFormField<String>(
            value: null,
            decoration: _inputDecoration(hintText).copyWith(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
            ),
            items: unselected.map<DropdownMenuItem<String>>((opt) {
              return DropdownMenuItem<String>(
                value: opt['value'] as String,
                child: Text(opt['label']?.toString() ?? ''),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null && !selectedValues.contains(val)) {
                onChanged([...selectedValues, val]);
              }
            },
          )
        else if (selectedValues.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text('Henüz seçenek yüklenmedi', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // KATEGORİ SEÇİCİ — tıklanabilir kart + bottom-sheet ağaç görünümü
  // ─────────────────────────────────────────────────────────────────

  /// Seçili kategoriyi gösteren, tıklandığında bottom-sheet açan buton.
  Widget _buildCategoryPickerButton() {
    final cat = _selectedCategory != null
        ? _categories.firstWhere(
            (c) => c['value'] == _selectedCategory,
            orElse: () => <String, dynamic>{},
          )
        : null;

    final hasSelection = cat != null && cat.isNotEmpty;
    final label = hasSelection ? (cat['label'] as String? ?? '') : '';

    // Seviyeyi etiket önekinden çöz
    int level = 0;
    if (label.startsWith('      └─')) {
      level = 2;
    } else if (label.startsWith('   └─')) {
      level = 1;
    }

    const levelColors = [Color(0xFF1E88E5), Color(0xFFFF9800), Color(0xFF9C27B0)];
    final levelColor =
        level < levelColors.length ? levelColors[level] : AppColors.primary;
    const levelIcons = ['📁', '📂', '📄'];
    final levelIcon =
        level < levelIcons.length ? levelIcons[level] : '📄';

    return GestureDetector(
      onTap: () {
        if (_categories.isEmpty) return;
        _showCategoryPickerSheet();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasSelection
              ? levelColor.withValues(alpha: 0.04)
              : Colors.white,
          border: Border.all(
            color: hasSelection ? levelColor.withValues(alpha: 0.5) : Colors.grey.shade300,
            width: hasSelection ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _categories.isEmpty
            ? Row(children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade400),
                ),
                const SizedBox(width: 8),
                Text('Yükleniyor...',
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ])
            : Row(
                children: [
                  if (hasSelection) ...[
                    // Kategori ikonu
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                          child: Text(levelIcon,
                              style: const TextStyle(fontSize: 13))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.trim(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            level == 0
                                ? 'Ana Kategori'
                                : level == 1
                                    ? 'Alt Kategori'
                                    : 'Alt-Alt Kategori',
                            style: TextStyle(
                              fontSize: 10,
                              color: levelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Temizle butonu
                    GestureDetector(
                      onTap: () => setState(() => _selectedCategory = null),
                      child: Icon(Icons.close,
                          size: 16, color: Colors.grey.shade400),
                    ),
                  ] else ...[
                    Icon(Icons.account_tree_outlined,
                        size: 18, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kategori seçin',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400),
                  ],
                ],
              ),
      ),
    );
  }

  /// Firma kategorilerini 3 seviyeli ağaç görünümünde listeleyen bottom-sheet.
  void _showCategoryPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.70,
        maxChildSize: 0.95,
        minChildSize: 0.40,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Tutamaç
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Başlık satırı
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_tree_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kategori Seç',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Text('Firmaya tanımlı kategoriler',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (_selectedCategory != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _selectedCategory = null);
                          Navigator.pop(sheetCtx);
                        },
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text('Temizle'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Kategori listesi
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                  itemCount: _categories.length,
                  itemBuilder: (_, idx) {
                    final cat = _categories[idx];
                    final value = cat['value'] as String? ?? '';
                    final rawLabel = cat['label'] as String? ?? '';
                    final isSelected = value == _selectedCategory;

                    // Seviyeyi etiket önekinden çöz
                    int level = 0;
                    if (rawLabel.startsWith('      └─')) {
                      level = 2;
                    } else if (rawLabel.startsWith('   └─')) {
                      level = 1;
                    }

                    const levelColors = [
                      Color(0xFF1E88E5),
                      Color(0xFFFF9800),
                      Color(0xFF9C27B0),
                    ];
                    const levelIcons = ['📁', '📂', '📄'];
                    const levelLabels = [
                      'Ana Kategori',
                      'Alt Kategori',
                      'Alt-Alt'
                    ];

                    final lColor = level < levelColors.length
                        ? levelColors[level]
                        : AppColors.primary;
                    final lIcon = level < levelIcons.length
                        ? levelIcons[level]
                        : '📄';
                    final lLabel = level < levelLabels.length
                        ? levelLabels[level]
                        : '';
                    final indent = level * 20.0;

                    return Padding(
                      padding: EdgeInsets.only(left: indent, bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() => _selectedCategory = value);
                          Navigator.pop(sheetCtx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? lColor.withValues(alpha: 0.12)
                                : level == 0
                                    ? Colors.grey.shade50
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? lColor.withValues(alpha: 0.6)
                                  : level == 0
                                      ? Colors.grey.shade200
                                      : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // İkon kutusu
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: lColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(lIcon,
                                      style:
                                          const TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // İsim + seviye etiketi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rawLabel.trim(),
                                      style: TextStyle(
                                        fontSize: level == 0 ? 14 : 13,
                                        fontWeight: level == 0
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? lColor
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (lLabel.isNotEmpty)
                                      Text(
                                        lLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: lColor.withValues(alpha: 0.8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Seçim işareti
                              if (isSelected)
                                Icon(Icons.check_circle_rounded,
                                    color: lColor, size: 22)
                              else
                                Icon(Icons.chevron_right,
                                    color: Colors.grey.shade300, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// getMyCategories() / getCategoryTree() gibi nested ağaç yapısını
  /// parentId korunarak düz listeye çevirir.
  /// children dizisi varsa recursive olarak işler.
  List<Map<String, dynamic>> _flattenCategoryTree(
    List<Map<String, dynamic>> tree, {
    String? parentId,
  }) {
    final result = <Map<String, dynamic>>[];
    for (final item in tree) {
      final flatItem = Map<String, dynamic>.from(item);
      // parentId backend'den gelmiyorsa parametreden ayarla
      if (flatItem['parentId'] == null && parentId != null) {
        flatItem['parentId'] = parentId;
      }
      result.add(flatItem);

      final children = item['children'];
      if (children is List && children.isNotEmpty) {
        result.addAll(
          _flattenCategoryTree(
            children.cast<Map<String, dynamic>>(),
            parentId: item['id']?.toString(),
          ),
        );
      }
    }
    return result;
  }

  /// Backend kategorilerini 3 seviyeli dropdown için düz listeye çevirir.
  /// Seviye 0 (kök)  → 📁 Kategori Adı
  /// Seviye 1 (alt)  →   └─ Alt Kategori
  /// Seviye 2 (torun)→     └─ Alt-Alt Kategori
  List<Map<String, dynamic>> _buildCategoryTree(List<Map<String, dynamic>> raw) {
    if (raw.isEmpty) return [];

    final result = <Map<String, dynamic>>[];

    // Seviye 0: kök kategoriler (parentId null veya boş)
    final roots = raw
        .where((c) => c['parentId'] == null || c['parentId'].toString().isEmpty)
        .toList()
      ..sort((a, b) => ((a['sortOrder'] as int?) ?? 0)
          .compareTo((b['sortOrder'] as int?) ?? 0));

    // Seviye 1: kök kategorilerin çocukları
    final level1 = raw
        .where((c) =>
            c['parentId'] != null &&
            c['parentId'].toString().isNotEmpty &&
            roots.any((r) => r['id']?.toString() == c['parentId']?.toString()))
        .toList()
      ..sort((a, b) => ((a['sortOrder'] as int?) ?? 0)
          .compareTo((b['sortOrder'] as int?) ?? 0));

    // Seviye 2: seviye-1 kategorilerin çocukları
    final level2 = raw
        .where((c) =>
            c['parentId'] != null &&
            c['parentId'].toString().isNotEmpty &&
            level1.any((l) => l['id']?.toString() == c['parentId']?.toString()))
        .toList()
      ..sort((a, b) => ((a['sortOrder'] as int?) ?? 0)
          .compareTo((b['sortOrder'] as int?) ?? 0));

    for (final root in roots) {
      final rootId = root['id']?.toString() ?? '';
      result.add({'value': rootId, 'label': '📁 ${root['name']}'});

      for (final child in level1.where((c) => c['parentId']?.toString() == rootId)) {
        final childId = child['id']?.toString() ?? '';
        result.add({'value': childId, 'label': '   └─ ${child['name']}'});

        for (final grand in level2.where((c) => c['parentId']?.toString() == childId)) {
          result.add({
            'value': grand['id']?.toString() ?? '',
            'label': '      └─ ${grand['name']}',
          });
        }
      }
    }

    // Hiç parentId bilgisi yoksa düz liste döndür
    if (result.isEmpty) {
      return raw
          .map((c) => {
                'value': c['id']?.toString() ?? '',
                'label': c['name']?.toString() ?? '',
              })
          .toList();
    }

    return result;
  }

  // Step 2: Preset Templates
  Map<String, List<ProductAttribute>> _getPresetTemplates() {
    return {
      'clothing': [
        ProductAttribute(name: 'Renk', icon: Icons.palette, values: ['Kırmızı', 'Mavi', 'Siyah', 'Beyaz']),
        ProductAttribute(name: 'Beden', icon: Icons.straighten, values: ['XS', 'S', 'M', 'L', 'XL', 'XXL']),
      ],
      'electronics': [
        ProductAttribute(name: 'RAM', icon: Icons.memory, values: ['4GB', '8GB', '16GB', '32GB']),
        ProductAttribute(name: 'Depolama', icon: Icons.storage, values: ['128GB', '256GB', '512GB', '1TB']),
        ProductAttribute(name: 'Renk', icon: Icons.palette, values: ['Gümüş', 'Uzay Grisi', 'Altın']),
      ],
      'shoes': [
        ProductAttribute(name: 'Renk', icon: Icons.palette, values: ['Siyah', 'Beyaz', 'Mavi']),
        ProductAttribute(name: 'Numara', icon: Icons.straighten, values: ['38', '39', '40', '41', '42', '43', '44', '45']),
      ],
    };
  }

  void _applyPreset(String presetKey) {
    final presets = _getPresetTemplates();
    final preset = presets[presetKey];
    if (preset != null) {
      setState(() {
        _selectedPreset = presetKey;
        _attributes = preset.map((attr) => ProductAttribute(
          name: attr.name,
          icon: attr.icon,
          values: List.from(attr.values), // Deep copy
        )).toList();
      });
    }
  }

  void _addAttribute(String name, IconData icon) {
    setState(() {
      _attributes.add(ProductAttribute(name: name, icon: icon, values: []));
    });
  }

  void _removeAttribute(int index) {
    setState(() {
      _attributes.removeAt(index);
    });
  }

  void _addValueToAttribute(int attrIndex, String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      if (!_attributes[attrIndex].values.contains(value.trim())) {
        _attributes[attrIndex].values.add(value.trim());
      }
    });
  }

  void _removeValueFromAttribute(int attrIndex, int valueIndex) {
    setState(() {
      _attributes[attrIndex].values.removeAt(valueIndex);
    });
  }

  // Step 2: Generate Variants (Dynamic System)
  void _generateVariants() {
    final variants = <ProductVariant>[];

    if (_productType == 'simple') {
      variants.add(ProductVariant(
        sku: _skuController.text,
        name: _productNameController.text.isEmpty ? 'Ürün' : _productNameController.text,
        attributes: {},
        purchasePrice: double.tryParse(_basePurchasePriceController.text) ?? 0,
        salePrice: double.tryParse(_basePriceController.text) ?? 0,
        inventory: InventoryInfo(warehouseCode: 'WH-001', physicalQuantity: 0),
        barcodes: [],
        notes: '',
      ));
    } else {
      // Dinamik attribute sistemi
      final attributesWithValues = _attributes.where((attr) => attr.values.isNotEmpty).toList();

      if (attributesWithValues.isEmpty) {
        _showWarning('⚠️ En az bir özellik ve değer ekleyin');
        return;
      }

      // Tüm kombinasyonları oluştur (Cartesian product)
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

      // Her kombinasyon için varyant oluştur
      int index = 0;
      for (final combo in combinations) {
        index++;
        final variantName = combo.values.join(' - ');

        variants.add(ProductVariant(
          sku: '${_skuController.text}-V$index',
          name: '${_productNameController.text} - $variantName',
          attributes: combo,
          purchasePrice: double.tryParse(_basePurchasePriceController.text) ?? 0,
          salePrice: double.tryParse(_basePriceController.text) ?? 0,
          inventory: InventoryInfo(warehouseCode: 'WH-001', physicalQuantity: 0),
          barcodes: [],
          notes: '',
        ));
      }
    }

    setState(() => _variants = variants);
    _showSuccess('✓ ${variants.length} varyant oluşturuldu!');
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_productNameController.text.trim().isEmpty) {
          _showError('⚠️ Ürün adı zorunludur');
          return false;
        }
        if (_productNameController.text.trim().length < 3) {
          _showError('⚠️ Ürün adı en az 3 karakter olmalıdır');
          return false;
        }
        if (_selectedCategory == null) {
          _showError('⚠️ Kategori seçimi zorunludur');
          return false;
        }
        final basePrice = double.tryParse(_basePriceController.text) ?? 0;
        if (basePrice <= 0) {
          _showError('⚠️ Geçerli bir fiyat giriniz (0\'dan büyük olmalı)');
          return false;
        }
        return true;
      case 1:
        if (_variants.isEmpty) {
          _showWarning('⚠️ Varyant oluşturulmadı, varsayılan varyant kullanılacak');
        }
        return true;
      case 2:
        if (_selectedStores.isEmpty) {
          _showError('⚠️ En az bir mağaza seçimi zorunludur');
          return false;
        }
        if (_selectedWarehouses.isEmpty) {
          _showError('⚠️ En az bir depo seçimi zorunludur');
          return false;
        }
        return true;
      case 3:
      case 4:
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.warning),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _handleNext() {
    if (!_validateCurrentStep()) return;


    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _handlePrevious() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _jumpToStep(int step) {
    if (step < _currentStep) {
      setState(() => _currentStep = step);
    }
  }

  // Toplu Stok Dialog
  Future<void> _showBulkStockDialog() async {
    if (_variants.isEmpty) {
      _showWarning('⚠️ Henüz varyant oluşturulmamış!');
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: AppColors.info, size: 24),
            const SizedBox(width: 12),
            const Text('Toplu Stok Uygula', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Stok Miktarı',
                hintText: '100',
                prefixIcon: const Icon(Icons.inventory_2, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_variants.length} varyanta uygulanacak',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final qty = int.tryParse(controller.text);
              if (qty != null && qty >= 0) {
                Navigator.pop(context, qty);
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Uygula'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        for (var variant in _variants) {
          if (variant.inventory == null) {
            variant.inventory = InventoryInfo(
              warehouseCode: _selectedWarehouses.isNotEmpty ? _selectedWarehouses.first : 'WH-001',
              physicalQuantity: result,
            );
          } else {
            variant.inventory!.physicalQuantity = result;
          }
        }
      });
      _showSuccess('✅ ${_variants.length} varyanta $result adet stok uygulandı!');
    }
  }

  // Toplu Alış Fiyatı Dialog
  Future<void> _showBulkPurchasePriceDialog() async {
    if (_variants.isEmpty) {
      _showWarning('⚠️ Henüz varyant oluşturulmamış!');
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.attach_money, color: AppColors.danger, size: 24),
            const SizedBox(width: 12),
            const Text('Toplu Alış Fiyatı', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Alış Fiyatı',
                hintText: '100.00',
                prefixText: '₺ ',
                prefixIcon: const Icon(Icons.attach_money, size: 20, color: AppColors.danger),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_variants.length} varyanta uygulanacak',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null && price >= 0) {
                Navigator.pop(context, price);
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Uygula'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        for (var variant in _variants) {
          variant.purchasePrice = result;
        }
      });
      _showSuccess('✅ ${_variants.length} varyanta ₺${result.toStringAsFixed(2)} alış fiyatı uygulandı!');
    }
  }

  // Toplu Satış Fiyatı Dialog
  Future<void> _showBulkSalePriceDialog() async {
    if (_variants.isEmpty) {
      _showWarning('⚠️ Henüz varyant oluşturulmamış!');
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sell, color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            const Text('Toplu Satış Fiyatı', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Satış Fiyatı',
                hintText: '150.00',
                prefixText: '₺ ',
                prefixIcon: const Icon(Icons.sell, size: 20, color: AppColors.success),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_variants.length} varyanta uygulanacak',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null && price >= 0) {
                Navigator.pop(context, price);
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Uygula'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        for (var variant in _variants) {
          variant.salePrice = result;
        }
      });
      _showSuccess('✅ ${_variants.length} varyanta ₺${result.toStringAsFixed(2)} satış fiyatı uygulandı!');
    }
  }

  Map<String, dynamic> _buildPayload() {
    // purchase yalnızca tedarikçi + fatura + tarih girilmişse eklenir
    final hasPurchase = (_selectedSupplier?.isNotEmpty == true) &&
        _invoiceNumberController.text.isNotEmpty &&
        _purchaseDateController.text.isNotEmpty;

    return {
      'product': {
        'sku': _skuController.text,
        'name': _productNameController.text,
        'categoryId': _selectedCategory ?? '',   // String UUID, int değil
        'brand': _brandController.text,
        'unit': _selectedUnit,
        'description': _descriptionController.text,
      },
      'variants': _variants.map((v) => {
        'sku': v.sku,
        'name': v.name,
        'attributes': v.attributes,
        'pricing': {
          'purchasePrice': v.purchasePrice,
          'salePrice': v.salePrice,
          'vatRate': _selectedVatRate,
          'vatIncluded': _vatIncluded,
          'specialTaxRate': _specialTaxRateController.text.isNotEmpty
              ? double.tryParse(_specialTaxRateController.text)
              : null,
          'withholdingTaxRate': _withholdingTaxRateController.text.isNotEmpty
              ? double.tryParse(_withholdingTaxRateController.text)
              : null,
          'taxExempt': _taxExempt,
        },
        'initialStocks': _selectedWarehouses.isNotEmpty
            ? _selectedWarehouses.expand((wh) =>
                _selectedStores.isNotEmpty
                    ? _selectedStores.map((st) => {
                          'storeId': st,
                          'warehouseId': wh,
                          'quantity': v.inventory?.physicalQuantity ?? 0,
                        })
                    : [{'storeId': null, 'warehouseId': wh, 'quantity': v.inventory?.physicalQuantity ?? 0}]
              ).toList()
            : [
                {
                  'storeId': _selectedStores.isNotEmpty ? _selectedStores.first : null,
                  'warehouseId': v.inventory?.warehouseCode ?? '',
                  'quantity': v.inventory?.physicalQuantity ?? 0,
                }
              ],
        'barcodes': v.barcodes.map((b) => {
          'code': b.code,
          'type': b.type,
          'isPrimary': b.isPrimary,
        }).toList(),
      }).toList(),
      'purchase': hasPurchase
          ? {
              'supplierId': _selectedSupplier,
              'invoiceNumber': _invoiceNumberController.text,
              'deliveryNoteNumber': _deliveryNoteController.text.isEmpty
                  ? null
                  : _deliveryNoteController.text,
              'purchaseDate': _purchaseDateController.text,
              'storeId': _selectedStores.isNotEmpty ? _selectedStores.first : null,
              'warehouseId': _selectedWarehouses.isNotEmpty ? _selectedWarehouses.first : null,
              'notes': _globalNotesController.text.isEmpty
                  ? null
                  : _globalNotesController.text,
            }
          : null,
    };
  }

  Future<void> _handleSubmit() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSaving = true);

    try {
      final payload = _buildPayload();
      await ref.read(productServiceProvider).createProduct(payload);

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccess('✅ ${_productNameController.text} başarıyla kaydedildi! ${_variants.length} varyant oluşturuldu.');

        // Return UserDecision if from bulk import, otherwise return true
        if (widget.fromBulkImport && widget.tempId != null) {
          final decision = UserDecision.create(
            tempId: widget.tempId!,
            product: payload,
          );
          Navigator.pop(context, decision);
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (error) {
      debugPrint('❌ HATA: $error');
      String msg = 'Ürün kaydedilemedi';
      if (error is DioException) {
        final data = error.response?.data;
        if (data is Map) {
          msg = data['message']?.toString() ??
              ((data['errors'] as List?)
                      ?.map((e) => (e is Map ? e['message'] : e)?.toString() ?? '')
                      .where((s) => s.isNotEmpty)
                      .join('\n') ??
                  msg);
        }
      } else {
        msg = '$msg: $error';
      }
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('❌ $msg');
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _skuController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _specialTaxRateController.dispose();
    _withholdingTaxRateController.dispose();
    _basePriceController.dispose();
    _basePurchasePriceController.dispose();
    _stockLocationController.dispose();
    _shelfNumberController.dispose();
    _invoiceNumberController.dispose();
    _deliveryNoteController.dispose();
    _purchaseDateController.dispose();
    _globalNotesController.dispose();
    _bulkStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = ((_currentStep + 1) / _totalSteps) * 100;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildModernHeader(),
      body: Column(
        children: [
          _buildProgressBar(progressPercent),
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(_isMobile ? 8 : 16),
              child: _buildStepContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationFooter(),
    );
  }

  PreferredSizeWidget _buildModernHeader() {
    final stepSubtitles = [
      'Ürün adı, kategori, fiyat',
      'Renk, beden, özellikler',
      'Depo, stok, tedarikçi',
      'Ürün resimleri',
      'Kontrol ve kayıt'
    ];

    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yeni Ürün Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Adım ${_currentStep + 1} / $_totalSteps',
                  style: const TextStyle(color: Color(0xFF667eea), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stepSubtitles[_currentStep],
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProgressBar(double percent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 12,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF764ba2)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '%${percent.round()} Tamamlandı',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    if (_isMobile) {
      return _buildMobileStepIndicator();
    }
    return _buildDesktopStepIndicator();
  }

  // Modern Mobile Step Indicator - Horizontal Scrollable
  Widget _buildMobileStepIndicator() {
    final stepData = [
      {'title': 'Tümü Bilgiler', 'icon': Icons.info, 'color': const Color(0xFF667eea)},
      {'title': 'Varyantlar', 'icon': Icons.layers, 'color': const Color(0xFF764ba2)},
      {'title': 'Barkod', 'icon': Icons.qr_code_2, 'color': const Color(0xFFf093fb)},
      {'title': 'Görseller', 'icon': Icons.image, 'color': const Color(0xFF4facfe)},
      {'title': 'Önizleme', 'icon': Icons.visibility, 'color': const Color(0xFF43e97b)},
    ];

    return Container(
      height: 75,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: stepData.length,
        itemBuilder: (context, index) {
          final step = stepData[index];
          final isCurrent = _currentStep == index;
          final isCompleted = _currentStep > index;
          final color = step['color'] as Color;

          return GestureDetector(
            onTap: () => _jumpToStep(index),
            child: Container(
              width: 68,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: isCurrent
                    ? LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isCurrent
                    ? (isCompleted ? AppColors.success.withOpacity(0.1) : Colors.grey[100])
                    : null,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? color
                      : isCompleted
                          ? AppColors.success
                          : Colors.grey[300]!,
                  width: isCurrent ? 2 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? Colors.white.withOpacity(0.3)
                          : isCompleted
                              ? AppColors.success
                              : Colors.grey[300],
                    ),
                    child: Icon(
                      isCompleted && !isCurrent ? Icons.check_circle : step['icon'] as IconData,
                      color: isCurrent
                          ? Colors.white
                          : isCompleted
                              ? Colors.white
                              : Colors.grey[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      step['title'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent
                            ? Colors.white
                            : isCompleted
                                ? AppColors.success
                                : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Desktop Step Indicator
  Widget _buildDesktopStepIndicator() {
    final stepData = [
      {'title': 'Temel\nBilgiler', 'icon': Icons.info, 'color': const Color(0xFF667eea)},
      {'title': 'Varyantlar', 'icon': Icons.layers, 'color': const Color(0xFF764ba2)},
      {'title': 'Stok &\nBarkod', 'icon': Icons.inventory_2, 'color': const Color(0xFFf093fb)},
      {'title': 'Görseller', 'icon': Icons.image, 'color': const Color(0xFF4facfe)},
      {'title': 'Önizleme', 'icon': Icons.visibility, 'color': const Color(0xFF43e97b)},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        children: [
          Row(
            children: List.generate(stepData.length, (index) {
              final step = stepData[index];
              final isCurrent = _currentStep == index;
              final isCompleted = _currentStep > index;
              final color = step['color'] as Color;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _jumpToStep(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: isCurrent
                          ? LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: !isCurrent
                          ? (isCompleted ? AppColors.success.withOpacity(0.1) : const Color(0xFFF8F9FA))
                          : null,
                      border: Border.all(
                        color: isCurrent
                            ? color
                            : isCompleted
                                ? AppColors.success
                                : const Color(0xFFE9ECEF),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : isCompleted
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? Colors.white.withOpacity(0.25)
                                : isCompleted
                                    ? AppColors.success
                                    : const Color(0xFFE9ECEF),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.white.withOpacity(0.5)
                                  : isCompleted
                                      ? const Color(0xFF20C997)
                                      : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isCompleted && !isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.success.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Icon(
                            isCompleted && !isCurrent ? Icons.check_circle : step['icon'] as IconData,
                            color: isCurrent
                                ? Colors.white
                                : isCompleted
                                    ? Colors.white
                                    : const Color(0xFF6C757D),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                            color: isCurrent
                                ? Colors.white
                                : isCompleted
                                    ? AppColors.success
                                    : const Color(0xFF6C757D),
                            shadows: isCurrent
                                ? [const Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2Variants();
      case 2:
        return _buildStep3StockBarcode();
      case 3:
        return _buildStep4Images();
      case 4:
        return _buildStep5Preview();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: BASIC INFO
  Widget _buildStep1BasicInfo() {
    return Container(
      padding: EdgeInsets.all(_isMobile ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isMobile ? 12 : 14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(_isMobile ? 10 : 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: BorderRadius.circular(_isMobile ? 8 : 10),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.white, size: _isMobile ? 20 : 22),
                SizedBox(width: _isMobile ? 8 : 10),
                Text(
                  'Temel Ürün Bilgileri',
                  style: TextStyle(color: Colors.white, fontSize: _isMobile ? 15 : 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: _isMobile ? 16 : 18),

          // Product Name
          _buildFormField(
            label: 'Ürün Adı',
            required: true,
            child: TextField(
              controller: _productNameController,
              decoration: _inputDecoration('Örn: iPhone 15 Pro Max'),
            ),
          ),
          SizedBox(height: _isMobile ? 12 : 14),

          // SKU & Category Row
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'SKU',
                  required: true,
                  child: TextField(
                    controller: _skuController,
                    decoration: _inputDecoration('Stok Kodu').copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: _generateSKU,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'Kategori',
                  required: true,
                  child: _buildCategoryPickerButton(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Brand & Unit Row
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Marka',
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: _brandController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.toLowerCase();
                      if (query.isEmpty) {
                        return _brands.map((b) => b['name']?.toString() ?? '');
                      }
                      return _brands
                          .map((b) => b['name']?.toString() ?? '')
                          .where((name) => name.toLowerCase().contains(query));
                    },
                    onSelected: (String selection) {
                      setState(() => _brandController.text = selection);
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: _inputDecoration('Marka ara... (örn: Nike)').copyWith(
                          prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 18),
                        ),
                        onChanged: (val) => _brandController.text = val,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final name = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.label_outline, size: 16, color: AppColors.primary),
                                  title: Text(name),
                                  onTap: () => onSelected(name),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'Birim',
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: _inputDecoration('Birim seçin'),
                    items: _units.map<DropdownMenuItem<String>>((unit) {
                      return DropdownMenuItem<String>(
                        value: unit['value'],
                        child: Text(unit['label'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val ?? 'pcs'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Purchase & Sale Price Row
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'Alış Fiyatı',
                  child: TextField(
                    controller: _basePurchasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('0.00').copyWith(
                      prefixText: '₺ ',
                      prefixStyle: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'Satış Fiyatı',
                  required: true,
                  child: TextField(
                    controller: _basePriceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('0.00').copyWith(
                      prefixText: '₺ ',
                      prefixStyle: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── VERGİ BİLGİLERİ ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long, color: Color(0xFFF57F17), size: 18),
                    SizedBox(width: 8),
                    Text('Vergi Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF57F17))),
                  ],
                ),
                const SizedBox(height: 12),

                // KDV Oranı + KDV Dahil
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildFormField(
                        label: 'KDV Oranı',
                        child: DropdownButtonFormField<double>(
                          value: _selectedVatRate,
                          decoration: _inputDecoration('KDV %').copyWith(
                            prefixIcon: const Icon(Icons.percent, size: 16, color: Color(0xFFF57F17)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0.0,  child: Text('% 0  — Muaf')),
                            DropdownMenuItem(value: 1.0,  child: Text('% 1')),
                            DropdownMenuItem(value: 8.0,  child: Text('% 8')),
                            DropdownMenuItem(value: 10.0, child: Text('% 10')),
                            DropdownMenuItem(value: 18.0, child: Text('% 18')),
                            DropdownMenuItem(value: 20.0, child: Text('% 20')),
                          ],
                          onChanged: (val) => setState(() => _selectedVatRate = val ?? 20.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildFormField(
                        label: 'ÖTV Oranı (opsiyonel)',
                        child: TextField(
                          controller: _specialTaxRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration('Örn: 15.5').copyWith(
                            suffixText: '%',
                            prefixIcon: const Icon(Icons.local_gas_station, size: 16, color: Color(0xFFF57F17)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildFormField(
                        label: 'Stopaj (opsiyonel)',
                        child: TextField(
                          controller: _withholdingTaxRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration('Örn: 10').copyWith(
                            suffixText: '%',
                            prefixIcon: const Icon(Icons.account_balance, size: 16, color: Color(0xFFF57F17)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // KDV Dahil + Vergiden Muaf toggle row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _vatIncluded = !_vatIncluded),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _vatIncluded ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _vatIncluded ? const Color(0xFF4CAF50) : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(_vatIncluded ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: _vatIncluded ? const Color(0xFF4CAF50) : Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              const Text('Fiyat KDV Dahil', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _taxExempt = !_taxExempt),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _taxExempt ? const Color(0xFF9C27B0).withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _taxExempt ? const Color(0xFF9C27B0) : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(_taxExempt ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: _taxExempt ? const Color(0xFF9C27B0) : Colors.grey, size: 18),
                              const SizedBox(width: 8),
                              const Text('Vergiden Muaf', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _buildFormField(
            label: 'Açıklama',
            child: TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _inputDecoration('Ürün hakkında detaylı bilgi...'),
            ),
          ),

        ],
      ),
    );
  }

  // STEP 2: VARIANTS
  // STEP 2: VARIANTS
  Widget _buildStep2Variants() {
    return Container(
      padding: EdgeInsets.all(_isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(_isMobile ? 10 : 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: BorderRadius.circular(_isMobile ? 8 : 10),
            ),
            child: Row(
              children: [
                Icon(Icons.layers, color: Colors.white, size: _isMobile ? 20 : 22),
                SizedBox(width: _isMobile ? 8 : 10),
                Text(
                  'Ürün Tipi & Varyantlar',
                  style: TextStyle(color: Colors.white, fontSize: _isMobile ? 15 : 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: _isMobile ? 16 : 18),

          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ürün Tipi Seçimi', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'Basit Ürün: Varyant olmadan tek bir ürün (Örn: USB Kablo)\nVaryantlı Ürün: Farklı renk, beden, özelliklere sahip (Örn: Tişört - S/M/L)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Product Type Cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _productType = 'simple';
                      _generateVariants();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _productType == 'simple' ? AppColors.success.withOpacity(0.1) : Colors.white,
                      border: Border.all(
                        color: _productType == 'simple' ? AppColors.success : AppColors.border,
                        width: _productType == 'simple' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: _productType == 'simple' ? AppColors.success : AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text('Basit Ürün', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Varyant yok', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        if (_productType == 'simple') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Seçili', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _productType = 'variant'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _productType == 'variant' ? AppColors.primary.withOpacity(0.1) : Colors.white,
                      border: Border.all(
                        color: _productType == 'variant' ? AppColors.primary : AppColors.border,
                        width: _productType == 'variant' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.layers,
                          size: 48,
                          color: _productType == 'variant' ? AppColors.primary : AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text('Varyantlı Ürün', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Renk, beden vb.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        if (_productType == 'variant') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Seçili', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_productType == 'simple') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✓ Basit Ürün Otomatik Oluşturuldu',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${_variants.isNotEmpty ? _variants[0].sku : "-"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_productType == 'variant') ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // 🆕 Preset Template Selection
            const Text(
              '📦 Hızlı Şablon Seç (İsteğe Bağlı)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetButton('clothing', '👕 Giyim', Icons.checkroom),
                _buildPresetButton('electronics', '💻 Elektronik', Icons.computer),
                _buildPresetButton('shoes', '👟 Ayakkabı', Icons.shopping_bag),
                _buildPresetButton('custom', '➕ Özel', Icons.add_circle_outline),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // 🆕 Dynamic Attributes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ürün Özellikleri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddAttributeDialog,
                  icon: const Icon(Icons.add_circle, size: 20),
                  label: const Text('Yeni Özellik'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_attributes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3), style: BorderStyle.solid),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Yukarıdan hızlı şablon seçin veya "Yeni Özellik" ile özel özellik ekleyin',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._attributes.asMap().entries.map((entry) {
                final index = entry.key;
                final attr = entry.value;
                return _buildAttributeCard(index, attr);
              }).toList(),

            // Generate Button
            if (_attributes.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateVariants,
                  icon: const Icon(Icons.bolt),
                  label: Text('Varyantları Oluştur (${_calculateTotalVariants()} varyant)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // 🆕 Variant Preview with Expand/Collapse
            if (_variants.isNotEmpty && _variants.first.attributes.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildVariantPreview(),
            ],
          ],
        ],
      ),
    );
  }
  // Helper: Preset Button
  Widget _buildPresetButton(String key, String label, IconData icon) {
    final isSelected = _selectedPreset == key;
    return GestureDetector(
      onTap: () {
        if (key == 'custom') {
          setState(() {
            _selectedPreset = 'custom';
            _attributes = [];
          });
        } else {
          _applyPreset(key);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _isMobile ? 12 : 16, vertical: _isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: _isMobile ? 12 : 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 16, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }

  // Helper: Attribute Card with Tag Input
  Widget _buildAttributeCard(int index, ProductAttribute attr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(attr.icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                attr.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeAttribute(index),
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.danger,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...attr.values.asMap().entries.map((entry) {
                final valueIndex = entry.key;
                final value = entry.value;
                return Chip(
                  label: Text(value, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeValueFromAttribute(index, valueIndex),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  deleteIconColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),

              // Add Value Button
              ActionChip(
                label: const Text('+ Ekle', style: TextStyle(fontSize: 12)),
                onPressed: () => _showAddValueDialog(index, attr.name),
                backgroundColor: AppColors.success.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.success.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Variant Preview
  Widget _buildVariantPreview() {
    final displayLimit = _showAllVariants ? _variants.length : 5;
    final displayedVariants = _variants.take(displayLimit).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 Varyant Önizleme',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_variants.length} Varyant',
                    style: const TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedVariants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final variant = displayedVariants[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                title: Text(variant.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('SKU: ${variant.sku}', style: const TextStyle(fontSize: 11)),
                trailing: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: variant.attributes.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          if (_variants.length > 5)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: TextButton.icon(
                onPressed: () => setState(() => _showAllVariants = !_showAllVariants),
                icon: Icon(_showAllVariants ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(
                  _showAllVariants ? 'Daha Az Göster' : 'Tümünü Göster (+${_variants.length - 5} varyant)',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Dialog: Add New Attribute
  void _showAddAttributeDialog() {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.label;

    final iconOptions = [
      {'icon': Icons.palette, 'label': 'Renk'},
      {'icon': Icons.straighten, 'label': 'Beden/Numara'},
      {'icon': Icons.memory, 'label': 'RAM'},
      {'icon': Icons.storage, 'label': 'Depolama'},
      {'icon': Icons.category, 'label': 'Model'},
      {'icon': Icons.label, 'label': 'Diğer'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text('Yeni Özellik Ekle'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Özellik Adı',
                  hintText: 'Örn: Renk, Beden, RAM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('İkon Seç:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: iconOptions.map((opt) {
                  final icon = opt['icon'] as IconData;
                  final isSelected = selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 24, color: isSelected ? AppColors.primary : AppColors.textMuted),
                          const SizedBox(height: 4),
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  _addAttribute(nameController.text.trim(), selectedIcon);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog: Add Value to Attribute
  void _showAddValueDialog(int attrIndex, String attrName) {
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_attributes[attrIndex].icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('$attrName Değeri Ekle'),
          ],
        ),
        content: TextField(
          controller: valueController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Değer',
            hintText: 'Örn: ${attrName == "Renk" ? "Kırmızı" : attrName == "Beden" ? "M" : "8GB"}',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              _addValueToAttribute(attrIndex, val.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (valueController.text.trim().isNotEmpty) {
                _addValueToAttribute(attrIndex, valueController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  // Helper: Calculate Total Variants
  int _calculateTotalVariants() {
    final attributesWithValues = _attributes.where((attr) => attr.values.isNotEmpty).toList();
    if (attributesWithValues.isEmpty) return 0;

    int total = 1;
    for (final attr in attributesWithValues) {
      total *= attr.values.length;
    }
    return total;
  }

  // STEP 3: STOCK & BARCODE
  Widget _buildStep3StockBarcode() {
    // Calculate statistics
    final totalStock = _variants.fold<int>(0, (sum, v) => sum + (v.inventory?.physicalQuantity ?? 0));
    final totalPurchaseValue = _variants.fold<double>(0, (sum, v) {
      final qty = v.inventory?.physicalQuantity ?? 0;
      return sum + (qty * v.purchasePrice);
    });
    final totalSaleValue = _variants.fold<double>(0, (sum, v) {
      final qty = v.inventory?.physicalQuantity ?? 0;
      return sum + (qty * v.salePrice);
    });
    final totalProfit = totalSaleValue - totalPurchaseValue;
    final profitMargin = totalPurchaseValue > 0 ? (totalProfit / totalPurchaseValue) * 100 : 0;
    final variantsWithStock = _variants.where((v) => (v.inventory?.physicalQuantity ?? 0) > 0).length;

    // Stat card data
    final statCards = [
      {'label': '📦 Toplam\nStok', 'value': '$totalStock', 'color': AppColors.success},
      {'label': '💵 Alış\nDeğeri', 'value': '₺${totalPurchaseValue.toStringAsFixed(2)}', 'color': AppColors.danger},
      {'label': '💰 Satış\nDeğeri', 'value': '₺${totalSaleValue.toStringAsFixed(2)}', 'color': AppColors.success},
      {'label': '${totalProfit >= 0 ? "💰" : "⚠️"} Toplam\nKâr', 'value': '₺${totalProfit.toStringAsFixed(2)}', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger},
      {'label': '📈 Kâr\nMarjı', 'value': '${profitMargin.toStringAsFixed(1)}%', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger},
      {'label': '🏷️ Stoklu\nVaryant', 'value': '$variantsWithStock/${_variants.length}', 'color': AppColors.warning},
    ];

    return Column(
      children: [
        // Store, Warehouse, Supplier
        Container(
            padding: EdgeInsets.all(_isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.store, color: AppColors.info),
                      SizedBox(width: 12),
                      Text('Depo, Mağaza ve Tedarikçi Bilgileri', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildFormField(
                  label: 'Mağaza',
                  required: true,
                  child: _buildMultiSelectChips(
                    selectedValues: _selectedStores,
                    allOptions: _stores,
                    hintText: 'Mağaza ekle...',
                    icon: Icons.store,
                    onChanged: (vals) => setState(() => _selectedStores = vals),
                  ),
                ),
                const SizedBox(height: 12),

                _buildFormField(
                  label: 'Depo',
                  required: true,
                  child: _buildMultiSelectChips(
                    selectedValues: _selectedWarehouses,
                    allOptions: _warehouses,
                    hintText: 'Depo ekle...',
                    icon: Icons.warehouse,
                    onChanged: (vals) => setState(() => _selectedWarehouses = vals),
                  ),
                ),
                const SizedBox(height: 12),

                _buildFormField(
                  label: 'Tedarikçi',
                  child: DropdownButtonFormField<String>(
                    value: _selectedSupplier,
                    decoration: _inputDecoration('Tedarikçi seçin').copyWith(
                      prefixIcon: const Icon(Icons.business, color: AppColors.primary, size: 18),
                    ),
                    items: _suppliers.map<DropdownMenuItem<String>>((sup) {
                      // Backend: name, contactName alanları döner
                      final name = sup['name']?.toString() ?? sup['companyName']?.toString() ?? '-';
                      final contact = sup['contactName']?.toString() ?? '';
                      final label = contact.isNotEmpty ? '$name ($contact)' : name;
                      return DropdownMenuItem<String>(
                        value: sup['id'].toString(),
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSupplier = val),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        label: 'Fatura No',
                        child: TextField(
                          controller: _invoiceNumberController,
                          decoration: _inputDecoration('FT-2024-001').copyWith(
                            prefixIcon: const Icon(Icons.receipt, color: AppColors.primary, size: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        label: 'Alış Tarihi',
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _purchaseDateController.text.isNotEmpty
                                  ? DateTime.tryParse(_purchaseDateController.text) ?? DateTime.now()
                                  : DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(primary: AppColors.primary),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                _purchaseDateController.text =
                                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                          child: IgnorePointer(
                            child: TextField(
                              controller: _purchaseDateController,
                              decoration: _inputDecoration('Tarih seçin').copyWith(
                                prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                                suffixIcon: _purchaseDateController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () => setState(() => _purchaseDateController.clear()),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bulk Operations
          Container(
            padding: EdgeInsets.all(_isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.warning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hızlı Toplu İşlemler', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Tüm varyantlara aynı değeri ata', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3 Buton Yan Yana
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showBulkStockDialog,
                        icon: Icon(Icons.inventory_2, size: _isMobile ? 18 : 20),
                        label: Text(
                          _isMobile ? 'Stok' : 'Stok Uygula',
                          style: TextStyle(fontSize: _isMobile ? 11 : 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          padding: EdgeInsets.symmetric(
                            horizontal: _isMobile ? 8 : 16,
                            vertical: _isMobile ? 12 : 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showBulkPurchasePriceDialog,
                        icon: Icon(Icons.attach_money, size: _isMobile ? 18 : 20),
                        label: Text(
                          _isMobile ? 'Alış' : 'Alış Fiyatı',
                          style: TextStyle(fontSize: _isMobile ? 11 : 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: EdgeInsets.symmetric(
                            horizontal: _isMobile ? 8 : 16,
                            vertical: _isMobile ? 12 : 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showBulkSalePriceDialog,
                        icon: Icon(Icons.sell, size: _isMobile ? 18 : 20),
                        label: Text(
                          _isMobile ? 'Satış' : 'Satış Fiyatı',
                          style: TextStyle(fontSize: _isMobile ? 11 : 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: EdgeInsets.symmetric(
                            horizontal: _isMobile ? 8 : 16,
                            vertical: _isMobile ? 12 : 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Variants List
          Container(
            padding: EdgeInsets.all(_isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Varyant Stok Bilgileri (${_variants.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _variants.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final variant = _variants[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(variant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        // Row 1: Stok, Alış Fiyatı, Satış Fiyatı
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('stock_${variant.sku}_${variant.inventory?.physicalQuantity}'),
                                initialValue: variant.inventory?.physicalQuantity.toString() ?? '0',
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('Stok').copyWith(
                                  prefixIcon: const Icon(Icons.inventory_2, size: 18),
                                ),
                                onChanged: (val) {
                                  final qty = int.tryParse(val) ?? 0;
                                  setState(() {
                                    if (variant.inventory == null) {
                                      variant.inventory = InventoryInfo(
                                        warehouseCode: _selectedWarehouses.isNotEmpty ? _selectedWarehouses.first : 'WH-001',
                                        physicalQuantity: qty,
                                      );
                                    } else {
                                      variant.inventory!.physicalQuantity = qty;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('purchase_${variant.sku}_${variant.purchasePrice}'),
                                initialValue: variant.purchasePrice.toStringAsFixed(2),
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('Alış').copyWith(
                                  prefixIcon: const Icon(Icons.attach_money, size: 18, color: AppColors.danger),
                                  prefixText: '₺',
                                ),
                                onChanged: (val) {
                                  final price = double.tryParse(val) ?? 0;
                                  setState(() {
                                    variant.purchasePrice = price;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('sale_${variant.sku}_${variant.salePrice}'),
                                initialValue: variant.salePrice.toStringAsFixed(2),
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('Satış').copyWith(
                                  prefixIcon: const Icon(Icons.sell, size: 18, color: AppColors.success),
                                  prefixText: '₺',
                                ),
                                onChanged: (val) {
                                  final price = double.tryParse(val) ?? 0;
                                  setState(() {
                                    variant.salePrice = price;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Row 2: Barkod
                        TextField(
                          decoration: _inputDecoration('Barkod').copyWith(
                            prefixIcon: const Icon(Icons.qr_code, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Statistics Cards - Moved to bottom
          _buildResponsiveStatGrid(statCards),
    ],
  );
  }

  Widget _buildResponsiveStatGrid(List<Map<String, dynamic>> statCards) {
    // Mobile: 3 columns, Tablet+: 6 columns (single row)
    final crossAxisCount = _isMobile ? 3 : 6;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _isMobile ? 1.2 : 1.6, // Even more compact
        crossAxisSpacing: _isMobile ? 4 : 6,
        mainAxisSpacing: _isMobile ? 4 : 6,
      ),
      itemCount: statCards.length,
      itemBuilder: (context, index) {
        final card = statCards[index];
        return _buildStatCard(
          card['label'] as String,
          card['value'] as String,
          card['color'] as Color,
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    // Extract emoji and text from label
    final parts = label.split('\n');
    final emoji = parts[0].contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))
        ? parts[0].split(' ')[0]
        : '';
    final title = emoji.isNotEmpty
        ? parts[0].substring(emoji.length).trim() + (parts.length > 1 ? ' ${parts[1]}' : '')
        : label.replaceAll('\n', ' ');

    return Container(
      padding: EdgeInsets.all(_isMobile ? 4 : 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.10), color.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_isMobile ? 6 : 8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: _isMobile ? 3 : 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emoji Icon
          if (emoji.isNotEmpty)
            Text(
              emoji,
              style: TextStyle(fontSize: _isMobile ? 12 : 16),
            ),
          if (emoji.isNotEmpty) SizedBox(height: _isMobile ? 1 : 2),
          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: _isMobile ? 11 : 14,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(height: _isMobile ? 1 : 2),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: _isMobile ? 7 : 8,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // STEP 4: IMAGES
  Widget _buildStep4Images() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Ürün Görselleri
          Container(
            padding: EdgeInsets.all(_isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(_isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                    borderRadius: BorderRadius.circular(_isMobile ? 8 : 10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.image, color: Colors.white, size: _isMobile ? 20 : 22),
                      SizedBox(width: _isMobile ? 8 : 10),
                      const Expanded(
                        child: Text(
                          'Ürün Görselleri',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_productImages.length} görsel',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Görsel Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _isMobile ? 3 : 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: _productImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _productImages.length) {
                      // Add button
                      return _buildAddImageButton(() => _addProductImage());
                    }
                    // Image preview
                    return _buildImagePreview(_productImages[index], () => _removeProductImage(index));
                  },
                ),

                if (_productImages.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.add_photo_alternate, size: 60, color: AppColors.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz görsel eklenmedi',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _addProductImage,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('İlk Görseli Ekle'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Varyant Görselleri
          if (_variants.isNotEmpty)
            Container(
              padding: EdgeInsets.all(_isMobile ? 12 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.collections, color: AppColors.info),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Varyant Görselleri', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Her varyant için özel görseller (isteğe bağlı)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Görünüm Modu Seçimi
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(_colorGroupedView ? Icons.palette : Icons.view_list, color: AppColors.warning, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _colorGroupedView ? 'Renk Gruplu Görünüm' : 'Varyant Listesi',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Text(
                                      _colorGroupedView ? 'Renkler gruplandırılmış' : 'Tüm varyantlar ayrı ayrı',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _colorGroupedView,
                                onChanged: (val) => setState(() => _colorGroupedView = val),
                                activeColor: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Gruplandırma seçimi (sadece gruplu görünümdeyken)
                  if (_colorGroupedView && _getAvailableAttributes().isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.filter_list, size: 18, color: AppColors.info),
                                    const SizedBox(width: 8),
                                    const Text('Gruplandırma:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _getAvailableAttributes().contains(_groupingAttribute) ? _groupingAttribute : (_getAvailableAttributes().isNotEmpty ? _getAvailableAttributes().first : null),
                                          isDense: true,
                                          items: _getAvailableAttributes().map<DropdownMenuItem<String>>((attr) {
                                            return DropdownMenuItem<String>(
                                              value: attr,
                                              child: Row(
                                                children: [
                                                  Icon(_getIconForAttribute(attr), size: 14, color: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  Text(attr, style: const TextStyle(fontSize: 12)),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) => setState(() => _groupingAttribute = val ?? (_getAvailableAttributes().isNotEmpty ? _getAvailableAttributes().first : 'Renk')),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Arama + İstatistik
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Varyant ara...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _variantSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setState(() => _variantSearchQuery = ''),
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _variantSearchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.apps, size: 16, color: AppColors.info),
                            const SizedBox(width: 6),
                            Text(
                              '${_getFilteredVariants().length}/${_variants.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hızlı İşlemler
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _expandedVariants.addAll(List.generate(_variants.length, (i) => i))),
                        icon: const Icon(Icons.unfold_more, size: 16),
                        label: const Text('Tümünü Aç', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => setState(() => _expandedVariants.clear()),
                        icon: const Icon(Icons.unfold_less, size: 16),
                        label: const Text('Tümünü Kapat', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Varyant listesi (Renk Gruplu veya Normal)
                  if (_getFilteredVariants().isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Varyant bulunamadı',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else if (_colorGroupedView && _hasColorAttribute())
                    // Renk bazlı gruplandırılmış görünüm
                    _buildColorGroupedView()
                  else
                    // Normal varyant listesi
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _getFilteredVariants().length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final variantIndex = _getFilteredVariants()[index];
                        final variant = _variants[variantIndex];
                        return _buildVariantImageAccordion(variant, variantIndex);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: AppColors.primary, size: _isMobile ? 24 : 32),
            const SizedBox(height: 4),
            Text(
              'Ekle',
              style: TextStyle(color: AppColors.primary, fontSize: _isMobile ? 10 : 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imagePath, VoidCallback onRemove) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
        color: Colors.grey[100],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Icon(Icons.image, size: 40, color: AppColors.textMuted.withOpacity(0.5)),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filtrelenmiş varyant indekslerini döndür
  List<int> _getFilteredVariants() {
    if (_variantSearchQuery.isEmpty) {
      return List.generate(_variants.length, (i) => i);
    }
    final query = _variantSearchQuery.toLowerCase();
    return List.generate(_variants.length, (i) => i).where((i) {
      final variant = _variants[i];
      return variant.name.toLowerCase().contains(query) ||
          variant.sku.toLowerCase().contains(query) ||
          variant.attributes.values.any((attr) => attr.toLowerCase().contains(query));
    }).toList();
  }

  // Mevcut attribute'leri getir
  List<String> _getAvailableAttributes() {
    final attributes = <String>{};
    for (final variant in _variants) {
      attributes.addAll(variant.attributes.keys);
    }
    return attributes.toList()..sort();
  }

  // Attribute için icon belirle
  IconData _getIconForAttribute(String attribute) {
    switch (attribute.toLowerCase()) {
      case 'renk':
      case 'color':
        return Icons.palette;
      case 'beden':
      case 'size':
        return Icons.straighten;
      case 'kapasite':
      case 'capacity':
        return Icons.storage;
      case 'ram':
        return Icons.memory;
      case 'depolama':
      case 'storage':
        return Icons.sd_storage;
      case 'model':
        return Icons.category;
      default:
        return Icons.label;
    }
  }

  // Varyantlarda seçili attribute var mı kontrol et
  bool _hasColorAttribute() {
    return _variants.any((v) => v.attributes.containsKey(_groupingAttribute));
  }

  // Seçili attribute'e göre grupla (generic)
  Map<String, List<int>> _groupVariantsByColor() {
    final groups = <String, List<int>>{};
    final filteredIndices = _getFilteredVariants();

    for (final index in filteredIndices) {
      final variant = _variants[index];
      final value = variant.attributes[_groupingAttribute] ?? 'Diğer';
      groups.putIfAbsent(value, () => []).add(index);
    }

    return groups;
  }

  // Renk gruplu görünüm
  Widget _buildColorGroupedView() {
    final colorGroups = _groupVariantsByColor();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: colorGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final color = colorGroups.keys.elementAt(index);
        final variantIndices = colorGroups[color]!;
        return _buildColorGroup(color, variantIndices);
      },
    );
  }

  // Renk grubu kartı
  Widget _buildColorGroup(String color, List<int> variantIndices) {
    // Grup için ortak görseller (ilk varyantın görselleri)
    final firstVariant = _variants[variantIndices.first];
    final groupImages = firstVariant.images;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.primary.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _groupingAttribute == 'Renk' ? _getColorForAttribute(color) : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: (_groupingAttribute == 'Renk' ? _getColorForAttribute(color) : AppColors.primary).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Icon(_getIconForAttribute(_groupingAttribute), color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      color,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${variantIndices.length} varyant (${groupImages.length} görsel)',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _applyImagesToColorGroup(color, variantIndices),
                icon: const Icon(Icons.sync, size: 16),
                label: Text(
                  _isMobile ? 'Uygula' : 'Tümüne uygula',
                  style: const TextStyle(fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Görseller
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _isMobile ? 4 : 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: groupImages.length + 1,
            itemBuilder: (context, imgIndex) {
              if (imgIndex == groupImages.length) {
                return _buildAddImageButton(() => _addColorGroupImage(color, variantIndices));
              }
              return _buildImagePreview(groupImages[imgIndex], () => _removeColorGroupImage(color, variantIndices, imgIndex));
            },
          ),
          const SizedBox(height: 12),

          // Varyant listesi (kompakt)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: variantIndices.map((variantIndex) {
              final variant = _variants[variantIndex];
              final size = variant.attributes['Beden'] ?? variant.attributes['Size'] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
                ),
                child: Text(
                  size.isNotEmpty ? size : variant.sku,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Renk için arka plan rengi belirle
  Color _getColorForAttribute(String color) {
    switch (color.toLowerCase()) {
      case 'kırmızı':
      case 'red':
        return Colors.red;
      case 'mavi':
      case 'blue':
        return Colors.blue;
      case 'yeşil':
      case 'green':
        return Colors.green;
      case 'sarı':
      case 'yellow':
        return Colors.yellow.shade700;
      case 'siyah':
      case 'black':
        return Colors.black;
      case 'beyaz':
      case 'white':
        return Colors.grey.shade400;
      case 'turuncu':
      case 'orange':
        return Colors.orange;
      case 'mor':
      case 'purple':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  // Renk grubuna görsel ekle
  void _addColorGroupImage(String color, List<int> variantIndices) {
    final newImage = 'color_${color}_image_${_variants[variantIndices.first].images.length + 1}.jpg';
    setState(() {
      for (final index in variantIndices) {
        _variants[index].images = [..._variants[index].images, newImage];
      }
    });
    _showSuccess('✅ $color renginin tüm bedenlerine görsel eklendi (${variantIndices.length} varyant)');
  }

  // Renk grubundan görsel sil
  void _removeColorGroupImage(String color, List<int> variantIndices, int imageIndex) {
    setState(() {
      for (final index in variantIndices) {
        final images = List<String>.from(_variants[index].images);
        if (images.length > imageIndex) {
          images.removeAt(imageIndex);
          _variants[index].images = images;
        }
      }
    });
    _showSuccess('🗑️ $color renginin tüm bedenlerinden görsel kaldırıldı');
  }

  // Bir renk grubunun görsellerini tüm bedenlerine uygula
  void _applyImagesToColorGroup(String color, List<int> variantIndices) {
    if (variantIndices.isEmpty) return;

    final firstVariantImages = _variants[variantIndices.first].images;
    setState(() {
      for (final index in variantIndices) {
        _variants[index].images = List<String>.from(firstVariantImages);
      }
    });
    _showSuccess('✅ $color renginin görselleri ${variantIndices.length} bedene kopyalandı');
  }

  Widget _buildVariantImageAccordion(ProductVariant variant, int variantIndex) {
    final isExpanded = _expandedVariants.contains(variantIndex);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
        color: isExpanded ? Colors.white : Colors.grey[50],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedVariants.add(variantIndex);
              } else {
                _expandedVariants.remove(variantIndex);
              }
            });
          },
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: variant.images.isEmpty ? AppColors.textMuted.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              variant.images.isEmpty ? Icons.image_not_supported : Icons.image,
              color: variant.images.isEmpty ? AppColors.textMuted : AppColors.success,
              size: 20,
            ),
          ),
          title: Text(
            variant.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          subtitle: Text(
            variant.sku,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: variant.images.isEmpty ? AppColors.textMuted.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 12,
                      color: variant.images.isEmpty ? AppColors.textMuted : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${variant.images.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: variant.images.isEmpty ? AppColors.textMuted : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textMuted,
              ),
            ],
          ),
          children: [
            // Varyant görsel grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _isMobile ? 4 : 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: variant.images.length + 1,
              itemBuilder: (context, imageIndex) {
                if (imageIndex == variant.images.length) {
                  // Add button
                  return _buildAddImageButton(() => _addVariantImage(variantIndex));
                }
                // Image preview
                return _buildImagePreview(variant.images[imageIndex], () => _removeVariantImage(variantIndex, imageIndex));
              },
            ),
          ],
        ),
      ),
    );
  }

  // Image operations
  void _addProductImage() {
    setState(() {
      _productImages.add('mock_image_${_productImages.length + 1}.jpg');
    });
    _showSuccess('✅ Ürün görseli eklendi');
  }

  void _removeProductImage(int index) {
    setState(() {
      _productImages.removeAt(index);
    });
    _showSuccess('🗑️ Görsel kaldırıldı');
  }

  void _addVariantImage(int variantIndex) {
    setState(() {
      _variants[variantIndex].images = [..._variants[variantIndex].images, 'variant_${variantIndex}_image_${_variants[variantIndex].images.length + 1}.jpg'];
    });
    _showSuccess('✅ Varyant görseli eklendi');
  }

  void _removeVariantImage(int variantIndex, int imageIndex) {
    setState(() {
      final images = List<String>.from(_variants[variantIndex].images);
      images.removeAt(imageIndex);
      _variants[variantIndex].images = images;
    });
    _showSuccess('🗑️ Varyant görseli kaldırıldı');
  }

  // STEP 5: PREVIEW
  Widget _buildStep5Preview() {
    final totalStock = _variants.fold<int>(0, (sum, v) => sum + (v.inventory?.physicalQuantity ?? 0));
    final totalPurchaseValue = _variants.fold<double>(0, (sum, v) {
      final qty = v.inventory?.physicalQuantity ?? 0;
      return sum + (qty * v.purchasePrice);
    });
    final totalSaleValue = _variants.fold<double>(0, (sum, v) {
      final qty = v.inventory?.physicalQuantity ?? 0;
      return sum + (qty * v.salePrice);
    });
    final totalProfit = totalSaleValue - totalPurchaseValue;
    final profitMargin = totalPurchaseValue > 0 ? (totalProfit / totalPurchaseValue) * 100 : 0;

    // Summary card data
    final summaryCards = [
      {'value': '${_variants.length}', 'label': 'Toplam Varyant', 'color': const Color(0xFF667eea)},
      {'value': '$totalStock', 'label': 'Toplam Stok', 'color': AppColors.success},
      {'value': '₺${totalPurchaseValue.toStringAsFixed(2)}', 'label': 'Alış Değeri', 'color': AppColors.danger},
      {'value': '₺${totalSaleValue.toStringAsFixed(2)}', 'label': 'Satış Değeri', 'color': AppColors.info},
      {'value': '₺${totalProfit.toStringAsFixed(2)}', 'label': 'Toplam Kâr', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger},
      {'value': '${profitMargin.toStringAsFixed(1)}%', 'label': 'Kâr Marjı', 'color': totalProfit >= 0 ? AppColors.success : AppColors.danger},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary Cards - Responsive Grid
          _buildResponsiveSummaryGrid(summaryCards),
          const SizedBox(height: 16),

          // Product Info
          _buildInfoCard(
            'Ürün Bilgileri',
            [
              _buildInfoRow('Ürün Adı', _productNameController.text),
              _buildInfoRow('SKU', _skuController.text),
              _buildInfoRow('Kategori', _categories.firstWhere((c) => c['value'] == _selectedCategory, orElse: () => <String, String>{'label': '-'})['label'] ?? '-'),
              _buildInfoRow('Marka', _brandController.text.isEmpty ? '-' : _brandController.text),
              _buildInfoRow('Birim', _selectedUnit),
              _buildInfoRow('Alış Fiyatı', '₺${_basePurchasePriceController.text}'),
              _buildInfoRow('Satış Fiyatı', '₺${_basePriceController.text}'),
              _buildInfoRow('KDV Oranı', '% $_selectedVatRate${_vatIncluded ? " (Dahil)" : " (Hariç)"}'),
              if (_specialTaxRateController.text.isNotEmpty)
                _buildInfoRow('ÖTV Oranı', '% ${_specialTaxRateController.text}'),
              if (_withholdingTaxRateController.text.isNotEmpty)
                _buildInfoRow('Stopaj', '% ${_withholdingTaxRateController.text}'),
              if (_taxExempt)
                _buildInfoRow('Vergi Durumu', '⚡ Vergiden Muaf'),
            ],
          ),
          const SizedBox(height: 16),

          // Store & Warehouse Info
          _buildInfoCard(
            'Depo & Mağaza',
            [
              _buildInfoRow('Mağaza', _selectedStores.isEmpty ? '-' : _selectedStores.map((v) => _stores.firstWhere((s) => s['value'] == v, orElse: () => <String, dynamic>{'label': v})['label']?.toString() ?? v).join(', ')),
              _buildInfoRow('Depo', _selectedWarehouses.isEmpty ? '-' : _selectedWarehouses.map((v) => _warehouses.firstWhere((w) => w['value'] == v, orElse: () => <String, dynamic>{'label': v})['label']?.toString() ?? v).join(', ')),
            ],
          ),
          const SizedBox(height: 16),

          // Variants Table
          Container(
            padding: EdgeInsets.all(_isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Varyantlar (${_variants.length})',
                  style: TextStyle(
                    fontSize: _isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: _isMobile ? 12 : 16),
                if (_isMobile)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.swipe, size: 14, color: Color(0xFF667eea)),
                        SizedBox(width: 4),
                        Text(
                          'Kaydırarak tüm sütunları görün',
                          style: TextStyle(fontSize: 10, color: Color(0xFF667eea)),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: _isMobile ? 8 : 0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF667eea).withOpacity(0.1)),
                    dataRowHeight: _isMobile ? 40 : 48,
                    headingRowHeight: _isMobile ? 36 : 44,
                    columnSpacing: _isMobile ? 12 : 32,
                    horizontalMargin: _isMobile ? 6 : 16,
                    columns: [
                      DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _isMobile ? 10 : 12))),
                      DataColumn(label: Text('Varyant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _isMobile ? 10 : 12))),
                      DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _isMobile ? 10 : 12))),
                      DataColumn(label: Text('Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _isMobile ? 10 : 12))),
                      DataColumn(label: Text('Alış Fiyat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _isMobile ? 10 : 12))),
                      DataColumn(label: Text('Satış Fiyat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _isMobile ? 10 : 12))),
                      DataColumn(label: Text('Toplam Kâr', style: TextStyle(fontWeight: FontWeight.bold, fontSize: _isMobile ? 10 : 12))),
                    ],
                    rows: _variants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final v = entry.value;
                      final qty = v.inventory?.physicalQuantity ?? 0;
                      final profitPerUnit = v.salePrice - v.purchasePrice;
                      final totalProfit = qty * profitPerUnit;
                      final textSize = _isMobile ? 10.0 : 12.0;
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}', style: TextStyle(fontSize: textSize))),
                        DataCell(Text(v.name, style: TextStyle(fontSize: textSize, fontWeight: FontWeight.w600))),
                        DataCell(Text(v.sku, style: TextStyle(fontFamily: 'monospace', fontSize: _isMobile ? 9 : 10))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: qty > 0 ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('$qty', style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold, color: qty > 0 ? AppColors.success : AppColors.danger)),
                        )),
                        DataCell(Text('₺${v.purchasePrice.toStringAsFixed(2)}', style: TextStyle(color: AppColors.danger, fontSize: textSize))),
                        DataCell(Text('₺${v.salePrice.toStringAsFixed(2)}', style: TextStyle(color: AppColors.success, fontSize: textSize))),
                        DataCell(Text('₺${totalProfit.toStringAsFixed(2)}', style: TextStyle(color: totalProfit >= 0 ? AppColors.success : AppColors.danger, fontSize: textSize, fontWeight: FontWeight.bold))),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // JSON Payload
          Container(
            padding: EdgeInsets.all(_isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2d3748),
              borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.code, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Backend Payload (JSON)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: _isMobile ? 13 : 14),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                      onPressed: () {
                        // TODO: Copy to clipboard
                        _showSuccess('JSON kopyalandı!');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _buildJsonPreview(),
                      style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white60, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Bu JSON POST /api/v1/products endpoint\'ine gönderilecek',
                        style: TextStyle(color: Colors.white60, fontSize: _isMobile ? 10 : 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildJsonPreview() {
    try {
      final payload = _buildPayload();
      return const JsonEncoder.withIndent('  ').convert(payload);
    } catch (e) {
      return '{\n  "error": "JSON oluşturulamadı: $e"\n}';
    }
  }

  Widget _buildResponsiveSummaryGrid(List<Map<String, dynamic>> summaryCards) {
    // Mobile: 3 columns, Tablet+: 6 columns (single row, ultra compact like Step 3)
    final crossAxisCount = _isMobile ? 3 : 6;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _isMobile ? 1.2 : 1.6,
        crossAxisSpacing: _isMobile ? 4 : 6,
        mainAxisSpacing: _isMobile ? 4 : 6,
      ),
      itemCount: summaryCards.length,
      itemBuilder: (context, index) {
        final card = summaryCards[index];
        return _buildSummaryCard(
          card['value'] as String,
          card['label'] as String,
          card['color'] as Color,
        );
      },
    );
  }

  Widget _buildSummaryCard(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(_isMobile ? 4 : 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_isMobile ? 6 : 8),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: _isMobile ? 3 : 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isMobile ? 11 : 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          SizedBox(height: _isMobile ? 1 : 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: _isMobile ? 7 : 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(_isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: _isMobile ? 6 : 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: _isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _isMobile ? 12 : 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, bool required = false, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (required) const Text(' *', style: TextStyle(color: AppColors.danger)),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.bgLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildNavigationFooter() {
    return Container(
      padding: EdgeInsets.all(_isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFF667eea), width: _isMobile ? 2 : 3)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: _isMobile ? 4 : 8, offset: Offset(0, _isMobile ? -1 : -2))],
      ),
      child: SafeArea(
        child: _isMobile ? _buildMobileNavigation() : _buildDesktopNavigation(),
      ),
    );
  }

  Widget _buildMobileNavigation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step name indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            ['Temel Bilgiler', 'Varyantlar', 'Stok & Barkod', 'Görseller', 'Önizleme'][_currentStep],
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        // Buttons row
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: _handlePrevious,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Geri', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 8),
            Expanded(
              flex: _currentStep > 0 ? 2 : 3,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _currentStep < _totalSteps - 1 ? _handleNext : _handleSubmit,
                icon: Icon(
                  _currentStep < _totalSteps - 1 ? Icons.arrow_forward : Icons.save,
                  size: 16,
                ),
                label: Text(
                  _isSaving ? 'Kaydediliyor...' : _currentStep < _totalSteps - 1 ? 'İleri' : 'Kaydet',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep < _totalSteps - 1 ? AppColors.primary : AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _handlePrevious,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
          )
        else
          const SizedBox(width: 100),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(8)),
          child: Text(
            ['Temel Bilgiler', 'Varyantlar', 'Stok & Barkod', 'Görseller', 'Önizleme'][_currentStep],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _currentStep < _totalSteps - 1 ? _handleNext : _handleSubmit,
              icon: Icon(_currentStep < _totalSteps - 1 ? Icons.arrow_forward : Icons.save),
              label: Text(_isSaving ? 'Kaydediliyor...' : _currentStep < _totalSteps - 1 ? 'İleri' : 'Ürünü Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < _totalSteps - 1 ? AppColors.primary : AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Data Models
class ProductAttribute {
  String name; // "Renk", "RAM", "Beden", etc.
  IconData icon; // Icon for UI
  List<String> values; // ["Kırmızı", "Mavi", "Siyah"]

  ProductAttribute({
    required this.name,
    required this.icon,
    List<String>? values,
  }) : values = values ?? [];
}

class ProductVariant {
  String sku;
  String name;
  Map<String, String> attributes;
  double purchasePrice;
  double salePrice;
  InventoryInfo? inventory;
  List<BarcodeInfo> barcodes;
  String notes;
  List<String> images; // Varyant görselleri

  ProductVariant({
    required this.sku,
    required this.name,
    required this.attributes,
    required this.purchasePrice,
    required this.salePrice,
    this.inventory,
    required this.barcodes,
    required this.notes,
    this.images = const [], // Default boş liste
  });
}

class InventoryInfo {
  String warehouseCode;
  int physicalQuantity;

  InventoryInfo({required this.warehouseCode, required this.physicalQuantity});
}

class BarcodeInfo {
  String code;
  String type;
  bool isPrimary;

  BarcodeInfo({required this.code, required this.type, required this.isPrimary});
}
