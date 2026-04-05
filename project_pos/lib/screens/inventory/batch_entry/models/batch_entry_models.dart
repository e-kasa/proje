enum RowStatus { newProduct, existing, matched, error, saving, saved }

/// ID uretici - uuid paketi yerine basit counter + timestamp tabanli
int _idCounter = 0;
String _generateId() {
  _idCounter++;
  return '${DateTime.now().millisecondsSinceEpoch}-$_idCounter';
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
  List<Map<String, String>> oemList;
  List<Map<String, String>> crossRefList;

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
    List<Map<String, String>>? oemList,
    List<Map<String, String>>? crossRefList,
  })  : id = id ?? _generateId(),
        oemList = oemList ?? [],
        crossRefList = crossRefList ?? [];

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
      oemList: oemList,
      crossRefList: crossRefList,
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
