enum RowStatus { newProduct, existing, matched, error, saving, saved }

// ── Kart tamamlanma sistemi ────────────────────────────────────────────────────

enum SectionStatus { complete, partial, empty }

enum CardReadiness { draft, incomplete, ready, saving, saved, error }

class BatchRowCompletion {
  final SectionStatus sectionA; // Ürün Bilgileri
  final SectionStatus sectionB; // Fiyat & Stok
  final SectionStatus sectionC; // Detaylar / Sektör
  final CardReadiness readiness;
  final List<String> missingFields;

  const BatchRowCompletion({
    required this.sectionA,
    required this.sectionB,
    required this.sectionC,
    required this.readiness,
    required this.missingFields,
  });

  /// Sektör konfigürasyonu yerine raw field flag'leri alır (import döngüsünü önler)
  static BatchRowCompletion compute(
    BatchEntryRow row, {
    required bool isExisting,
    required bool brandRequired,
    required bool oemRequired,
    required bool shelfRequired,
    required bool showOem,
    required bool showShelf,
    bool showVariantTable = false, // Footwear: varyant tablosu aktif mi
  }) {
    // Kayıt durumu → readiness'ı direkt belirler
    if (row.status == RowStatus.saved) {
      return const BatchRowCompletion(
        sectionA: SectionStatus.complete,
        sectionB: SectionStatus.complete,
        sectionC: SectionStatus.complete,
        readiness: CardReadiness.saved,
        missingFields: [],
      );
    }
    if (row.status == RowStatus.saving) {
      return const BatchRowCompletion(
        sectionA: SectionStatus.complete,
        sectionB: SectionStatus.complete,
        sectionC: SectionStatus.complete,
        readiness: CardReadiness.saving,
        missingFields: [],
      );
    }
    if (row.status == RowStatus.error) {
      return BatchRowCompletion(
        sectionA: SectionStatus.complete,
        sectionB: SectionStatus.complete,
        sectionC: SectionStatus.complete,
        readiness: CardReadiness.error,
        missingFields: row.errorMessage != null ? [row.errorMessage!] : [],
      );
    }

    final missing = <String>[];

    // ── Bölüm A: Ürün Bilgileri ──────────────────────────────────────────────
    final SectionStatus sectionA;
    if (isExisting) {
      sectionA = SectionStatus.complete;
    } else {
      int filled = 0;
      final int required = 2 + (brandRequired ? 1 : 0);
      if (row.productName.trim().isNotEmpty) {
        filled++;
      } else {
        missing.add('Ürün adı');
      }
      if (row.categoryId != null && row.categoryId!.isNotEmpty) {
        filled++;
      } else {
        missing.add('Kategori');
      }
      if (brandRequired) {
        if (row.brandName != null && row.brandName!.trim().isNotEmpty) {
          filled++;
        } else {
          missing.add('Marka');
        }
      }
      sectionA = filled == required
          ? SectionStatus.complete
          : filled > 0
              ? SectionStatus.partial
              : SectionStatus.empty;
    }

    // ── Bölüm B: Fiyat & Stok ────────────────────────────────────────────────
    int bFilled = 0;
    if (row.salePrice > 0) {
      bFilled++;
    } else {
      missing.add('Satış fiyatı');
    }
    if (row.quantity > 0) {
      bFilled++;
    } else {
      missing.add('Adet');
    }
    // Mevcut ürünlerde alış fiyatı da zorunlu (cari kaydı için)
    if (isExisting && row.purchasePrice <= 0) {
      missing.add('Alış fiyatı');
    }
    final SectionStatus sectionB = bFilled >= 2
        ? SectionStatus.complete
        : bFilled > 0
            ? SectionStatus.partial
            : SectionStatus.empty;

    // ── Bölüm C: Detaylar ────────────────────────────────────────────────────
    final SectionStatus sectionC;
    if (showVariantTable) {
      // Footwear: en az bir geçerli varyant satırı gerekli
      final validCount = row.variantRows.where((v) => v.isValid).length;
      if (validCount > 0) {
        sectionC = SectionStatus.complete;
      } else if (row.variantRows.isNotEmpty) {
        sectionC = SectionStatus.partial;
        missing.add('Varyant (numara/beden)');
      } else {
        sectionC = SectionStatus.empty;
        missing.add('Varyant (numara/beden)');
      }
    } else {
      bool cHasRequired = true;
      bool cHasAny = row.barcode.isNotEmpty;
      if (showOem && oemRequired) {
        if (row.oemNumber == null || row.oemNumber!.trim().isEmpty) {
          missing.add('OEM No');
          cHasRequired = false;
        } else {
          cHasAny = true;
        }
      }
      if (showShelf && shelfRequired) {
        if (row.shelfLocation == null || row.shelfLocation!.trim().isEmpty) {
          missing.add('Raf kodu');
          cHasRequired = false;
        } else {
          cHasAny = true;
        }
      }
      if (row.oemList.isNotEmpty || (row.shelfLocation?.isNotEmpty ?? false)) {
        cHasAny = true;
      }
      sectionC = (cHasRequired && cHasAny)
          ? SectionStatus.complete
          : (!cHasRequired)
              ? SectionStatus.partial
              : SectionStatus.empty;
    }

    // ── Genel hazırlık ───────────────────────────────────────────────────────
    final bool hasAnything = sectionA != SectionStatus.empty ||
        sectionB != SectionStatus.empty;
    final CardReadiness readiness;
    if (!hasAnything) {
      readiness = CardReadiness.draft;
    } else if (missing.isNotEmpty) {
      readiness = CardReadiness.incomplete;
    } else {
      readiness = CardReadiness.ready;
    }

    return BatchRowCompletion(
      sectionA: sectionA,
      sectionB: sectionB,
      sectionC: sectionC,
      readiness: readiness,
      missingFields: missing,
    );
  }
}

/// ID uretici - uuid paketi yerine basit counter + timestamp tabanli
int _idCounter = 0;
String _generateId() {
  _idCounter++;
  return '${DateTime.now().millisecondsSinceEpoch}-$_idCounter';
}

// ── Footwear varyant satırı ───────────────────────────────────────────────────
class BatchVariantRow {
  final String id;
  String size;    // Numara / Beden
  String color;   // Renk
  String barcode;
  int quantity;
  double? purchasePrice; // null = karttan miras alınır
  double? salePrice;     // null = karttan miras alınır

  BatchVariantRow({
    String? id,
    this.size = '',
    this.color = '',
    this.barcode = '',
    this.quantity = 1,
    this.purchasePrice,
    this.salePrice,
  }) : id = id ?? _generateId();

  bool get isValid => size.trim().isNotEmpty && quantity > 0;

  BatchVariantRow copyWith({
    String? size,
    String? color,
    String? barcode,
    int? quantity,
    double? purchasePrice,
    bool clearPurchasePrice = false,
    double? salePrice,
    bool clearSalePrice = false,
  }) {
    return BatchVariantRow(
      id: id,
      size: size ?? this.size,
      color: color ?? this.color,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      purchasePrice: clearPurchasePrice ? null : (purchasePrice ?? this.purchasePrice),
      salePrice: clearSalePrice ? null : (salePrice ?? this.salePrice),
    );
  }
}

class BatchEntryRow {
  final String id;
  String barcode;
  String productName;
  String? oemNumber;
  String? brandId;
  String? brandName;
  String? categoryId;
  String? categoryName;
  String? unitId;
  double purchasePrice;
  double salePrice;
  double vatRate;
  int quantity;
  RowStatus status;
  String? existingProductId;
  String? existingVariantId;
  String? existingVariantSku;
  String? errorMessage;
  bool isExpanded;

  // Ek bilgiler (quick_product_dialog)
  String? description;
  String? shelfLocation;
  int minStockLevel;
  bool vatIncluded;
  Map<String, String> attributes;
  List<Map<String, String>> oemList;
  List<Map<String, String>> crossRefList;

  // Footwear çoklu varyant (size × color kombinasyonları)
  List<BatchVariantRow> variantRows;

  BatchEntryRow({
    String? id,
    this.barcode = '',
    this.productName = '',
    this.oemNumber,
    this.brandId,
    this.brandName,
    this.categoryId,
    this.categoryName,
    this.unitId,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.vatRate = 20.0,
    this.quantity = 1,
    this.status = RowStatus.newProduct,
    this.existingProductId,
    this.existingVariantId,
    this.existingVariantSku,
    this.errorMessage,
    this.isExpanded = false,
    this.description,
    this.shelfLocation,
    this.minStockLevel = 10,
    this.vatIncluded = false,
    Map<String, String>? attributes,
    List<Map<String, String>>? oemList,
    List<Map<String, String>>? crossRefList,
    List<BatchVariantRow>? variantRows,
  })  : id = id ?? _generateId(),
        attributes = attributes ?? {},
        oemList = oemList ?? [],
        crossRefList = crossRefList ?? [],
        variantRows = variantRows ?? [];

  double get lineTotal => salePrice * quantity;
  double get lineCost => purchasePrice * quantity;
  double get lineProfit => lineTotal - lineCost;
  double get profitMargin =>
      salePrice > 0 ? ((salePrice - purchasePrice) / salePrice * 100) : 0;

  bool get isNew => status == RowStatus.newProduct;
  bool get isExisting =>
      status == RowStatus.existing || status == RowStatus.matched;
  bool get hasError => status == RowStatus.error;
  bool get isSaved => status == RowStatus.saved;

  BatchEntryRow copyWith({
    String? barcode,
    String? productName,
    String? oemNumber,
    String? brandId,
    String? brandName,
    String? categoryId,
    String? categoryName,
    String? unitId,
    double? purchasePrice,
    double? salePrice,
    double? vatRate,
    int? quantity,
    RowStatus? status,
    String? existingProductId,
    String? existingVariantId,
    String? existingVariantSku,
    String? errorMessage,
    bool? isExpanded,
    String? description,
    String? shelfLocation,
    int? minStockLevel,
    bool? vatIncluded,
    Map<String, String>? attributes,
    List<Map<String, String>>? oemList,
    List<Map<String, String>>? crossRefList,
    List<BatchVariantRow>? variantRows,
  }) {
    return BatchEntryRow(
      id: id,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      oemNumber: oemNumber ?? this.oemNumber,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unitId: unitId ?? this.unitId,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      vatRate: vatRate ?? this.vatRate,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      existingProductId: existingProductId ?? this.existingProductId,
      existingVariantId: existingVariantId ?? this.existingVariantId,
      existingVariantSku: existingVariantSku ?? this.existingVariantSku,
      errorMessage: errorMessage ?? this.errorMessage,
      isExpanded: isExpanded ?? this.isExpanded,
      description: description ?? this.description,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      vatIncluded: vatIncluded ?? this.vatIncluded,
      attributes: attributes ?? this.attributes,
      oemList: oemList ?? this.oemList,
      crossRefList: crossRefList ?? this.crossRefList,
      variantRows: variantRows ?? this.variantRows,
    );
  }
}

class BatchEntryState {
  final String? supplierId;
  final String? supplierName;
  final String? invoiceNumber;
  final String? deliveryNoteNumber;
  final DateTime purchaseDate;
  final String? storeId;
  final String? storeName;
  final String? warehouseId;
  final String? warehouseName;
  final List<BatchEntryRow> rows;
  final bool isSubmitting;
  final bool headerCollapsed;

  BatchEntryState({
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.deliveryNoteNumber,
    DateTime? purchaseDate,
    this.storeId,
    this.storeName,
    this.warehouseId,
    this.warehouseName,
    this.rows = const [],
    this.isSubmitting = false,
    this.headerCollapsed = false,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  int get totalItems => rows.length;
  int get newItems =>
      rows.where((r) => r.status == RowStatus.newProduct).length;
  int get existingItems => rows.where((r) => r.isExisting).length;
  int get savedItems => rows.where((r) => r.isSaved).length;
  int get errorItems => rows.where((r) => r.hasError).length;
  double get totalCost => rows.fold(0, (sum, r) => sum + r.lineCost);
  double get totalSale => rows.fold(0, (sum, r) => sum + r.lineTotal);
  double get totalProfit => totalSale - totalCost;

  bool get isValid =>
      rows.isNotEmpty &&
      supplierId != null &&
      warehouseId != null &&
      storeId != null;

  BatchEntryState copyWith({
    String? supplierId,
    String? supplierName,
    String? invoiceNumber,
    String? deliveryNoteNumber,
    DateTime? purchaseDate,
    String? storeId,
    String? storeName,
    String? warehouseId,
    String? warehouseName,
    List<BatchEntryRow>? rows,
    bool? isSubmitting,
    bool? headerCollapsed,
  }) {
    return BatchEntryState(
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      deliveryNoteNumber: deliveryNoteNumber ?? this.deliveryNoteNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      rows: rows ?? this.rows,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      headerCollapsed: headerCollapsed ?? this.headerCollapsed,
    );
  }
}

class BatchSaveResult {
  final int totalProcessed;
  final int newCreated;
  final int stockUpdated;
  final int errors;
  final List<String> errorMessages;
  final String? purchaseId;

  const BatchSaveResult({
    this.totalProcessed = 0,
    this.newCreated = 0,
    this.stockUpdated = 0,
    this.errors = 0,
    this.errorMessages = const [],
    this.purchaseId,
  });
}
