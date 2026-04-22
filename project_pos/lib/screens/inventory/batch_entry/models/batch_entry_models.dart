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
        missing.add('batch.field_product_name');
      }
      if (row.categoryId != null && row.categoryId!.isNotEmpty) {
        filled++;
      } else {
        missing.add('batch.field_category');
      }
      if (brandRequired) {
        if (row.brandName != null && row.brandName!.trim().isNotEmpty) {
          filled++;
        } else {
          missing.add('batch.field_brand');
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
      missing.add('batch.field_sale_price');
    }
    if (row.quantity > 0) {
      bFilled++;
    } else {
      missing.add('batch.field_quantity');
    }
    // Mevcut ürünlerde alış fiyatı da zorunlu (cari kaydı için)
    if (isExisting && row.purchasePrice <= 0) {
      missing.add('batch.field_purchase_price');
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
        missing.add('batch.field_variant');
      } else {
        sectionC = SectionStatus.empty;
        missing.add('batch.field_variant');
      }
    } else {
      bool cHasRequired = true;
      bool cHasAny = row.barcode.isNotEmpty;
      if (showOem && oemRequired) {
        if (row.oemNumber == null || row.oemNumber!.trim().isEmpty) {
          missing.add('batch.field_oem');
          cHasRequired = false;
        } else {
          cHasAny = true;
        }
      }
      if (showShelf && shelfRequired) {
        if (row.shelfLocation == null || row.shelfLocation!.trim().isEmpty) {
          missing.add('batch.field_shelf');
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
  String size;    // Numara / Beden (display / single non-color attr value)
  String color;   // Renk
  String barcode;
  int quantity;
  double? purchasePrice; // null = karttan miras alınır
  double? salePrice;     // null = karttan miras alınır
  /// Tam attribute map'i — builder'dan üretildiğinde doldurulur.
  /// Backend'e gönderilirken bu map kullanılır (hardcoded 'Numara' yerine).
  Map<String, String>? attributesMap;

  BatchVariantRow({
    String? id,
    this.size = '',
    this.color = '',
    this.barcode = '',
    this.quantity = 1,
    this.purchasePrice,
    this.salePrice,
    this.attributesMap,
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
    Map<String, String>? attributesMap,
  }) {
    return BatchVariantRow(
      id: id,
      size: size ?? this.size,
      color: color ?? this.color,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      purchasePrice: clearPurchasePrice ? null : (purchasePrice ?? this.purchasePrice),
      salePrice: clearSalePrice ? null : (salePrice ?? this.salePrice),
      attributesMap: attributesMap ?? this.attributesMap,
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
  double discountRate; // iskonto oranı (%) — faturadan veya manuel, default 0
  int quantity;
  /// Fatura üzerindeki miktar. null ise [quantity] değeri kullanılır.
  /// Eksik teslimat durumunda invoiceQuantity > quantity olur.
  int? invoiceQuantity;
  RowStatus status;
  String? existingProductId;
  String? existingVariantId;
  String? existingVariantSku;

  // Mevcut ürün enrichment (FOUND olduğunda kart üzerinde read-only gösterilir)
  double? existingCurrentStock;
  double? existingSalePrice;
  double? existingPurchasePrice;
  double? existingLastPurchasePrice;
  String? existingShelfLocation;
  String? existingBrandName;
  List<String> existingOemCodes;

  /// Mevcut ürünün TOPLAM variant sayısı (tek variantlı=1, çoklu footwear=N).
  /// null → eşleşme yok veya backend enrichment yapmadı.
  int? existingVariantCount;

  /// Mevcut ürünün tüm varyantlarının özet listesi (Map format — JSON hazır).
  /// Her entry: {variantId, sku, name, attributes, currentStock, salePrice,
  /// shelfLocationCode, isMatched}. Kart detay UI'da tablo olarak gösterilir.
  List<Map<String, dynamic>> existingVariants;

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
    this.discountRate = 0,
    this.quantity = 1,
    this.invoiceQuantity,
    this.status = RowStatus.newProduct,
    this.existingProductId,
    this.existingVariantId,
    this.existingVariantSku,
    this.existingCurrentStock,
    this.existingSalePrice,
    this.existingPurchasePrice,
    this.existingLastPurchasePrice,
    this.existingShelfLocation,
    this.existingBrandName,
    List<String>? existingOemCodes,
    this.existingVariantCount,
    List<Map<String, dynamic>>? existingVariants,
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
        existingOemCodes = existingOemCodes ?? [],
        existingVariants = existingVariants ?? [],
        attributes = attributes ?? {},
        oemList = oemList ?? [],
        crossRefList = crossRefList ?? [],
        variantRows = variantRows ?? [];

  /// Varyantlar varsa bunların adet toplamı, yoksa kart miktar alanı.
  int get effectiveQuantity => variantRows.isNotEmpty
      ? variantRows.fold(0, (s, r) => s + r.quantity)
      : quantity;

  /// Depoya giren fiziksel adet (= quantity)
  int get receivedQty => quantity;
  /// Fatura miktarı (null → receivedQty ile aynı, eksik teslimat yok)
  int get resolvedInvoiceQty => invoiceQuantity ?? quantity;
  /// Eksik adet (0 = tam teslimat)
  int get shortageQty => (resolvedInvoiceQty - receivedQty).clamp(0, 9999);
  bool get hasShortage => shortageQty > 0;

  /// Varyantlar varsa her satır kendi fiyatı × kendi adedi, yoksa kart fiyatı × kart adedi.
  double get lineTotal => variantRows.isNotEmpty
      ? variantRows.fold(
          0.0, (s, r) => s + (r.salePrice ?? salePrice) * r.quantity)
      : salePrice * quantity;

  double get lineCost => variantRows.isNotEmpty
      ? variantRows.fold(
          0.0, (s, r) => s + (r.purchasePrice ?? purchasePrice) * r.quantity)
      : purchasePrice * quantity;

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
    double? discountRate,
    int? quantity,
    int? invoiceQuantity,
    bool clearInvoiceQuantity = false,
    RowStatus? status,
    String? existingProductId,
    String? existingVariantId,
    String? existingVariantSku,
    double? existingCurrentStock,
    double? existingSalePrice,
    double? existingPurchasePrice,
    double? existingLastPurchasePrice,
    String? existingShelfLocation,
    String? existingBrandName,
    List<String>? existingOemCodes,
    int? existingVariantCount,
    List<Map<String, dynamic>>? existingVariants,
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
      discountRate: discountRate ?? this.discountRate,
      quantity: quantity ?? this.quantity,
      invoiceQuantity: clearInvoiceQuantity ? null : (invoiceQuantity ?? this.invoiceQuantity),
      status: status ?? this.status,
      existingProductId: existingProductId ?? this.existingProductId,
      existingVariantId: existingVariantId ?? this.existingVariantId,
      existingVariantSku: existingVariantSku ?? this.existingVariantSku,
      existingCurrentStock: existingCurrentStock ?? this.existingCurrentStock,
      existingSalePrice: existingSalePrice ?? this.existingSalePrice,
      existingPurchasePrice: existingPurchasePrice ?? this.existingPurchasePrice,
      existingLastPurchasePrice:
          existingLastPurchasePrice ?? this.existingLastPurchasePrice,
      existingShelfLocation: existingShelfLocation ?? this.existingShelfLocation,
      existingBrandName: existingBrandName ?? this.existingBrandName,
      existingOemCodes: existingOemCodes ?? this.existingOemCodes,
      existingVariantCount: existingVariantCount ?? this.existingVariantCount,
      existingVariants: existingVariants ?? this.existingVariants,
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
  final String? locationId;
  final String? locationName;
  final String? locationType;
  final List<BatchEntryRow> rows;
  final bool isSubmitting;
  final bool headerCollapsed;

  BatchEntryState({
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    this.deliveryNoteNumber,
    DateTime? purchaseDate,
    this.locationId,
    this.locationName,
    this.locationType,
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
  int get shortageItems => rows.where((r) => r.isExisting && r.hasShortage).length;
  bool get hasAnyShortage => shortageItems > 0;

  int get shortageItems => rows.where((r) => r.hasShortage).length;
  bool get hasAnyShortage => shortageItems > 0;

  bool get isValid =>
      rows.isNotEmpty &&
      supplierId != null &&
      locationId != null;

  BatchEntryState copyWith({
    String? supplierId,
    String? supplierName,
    String? invoiceNumber,
    String? deliveryNoteNumber,
    DateTime? purchaseDate,
    String? locationId,
    String? locationName,
    String? locationType,
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
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      locationType: locationType ?? this.locationType,
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
  final BatchClaimInfo? claim;

  const BatchSaveResult({
    this.totalProcessed = 0,
    this.newCreated = 0,
    this.stockUpdated = 0,
    this.errors = 0,
    this.errorMessages = const [],
    this.purchaseId,
    this.claim,
  });
}

/// Backend `BatchCreateResponse.claim` alanı — fatura/teslim farkı varsa açılan
/// SupplierClaim'in özeti. Result sheet'te CTA olarak gösterilir.
class BatchClaimInfo {
  final String claimId;
  final double claimAmount;
  final int lineCount;

  const BatchClaimInfo({
    required this.claimId,
    this.claimAmount = 0,
    this.lineCount = 0,
  });

  factory BatchClaimInfo.fromJson(Map<String, dynamic> json) => BatchClaimInfo(
        claimId: json['claimId']?.toString() ?? '',
        claimAmount: (json['claimAmount'] as num?)?.toDouble() ?? 0,
        lineCount: (json['lineCount'] as num?)?.toInt() ?? 0,
      );
}
