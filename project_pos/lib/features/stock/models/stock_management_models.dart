/// STOK YÖNETİMİ DATA MODELLERİ
/// Tedarikçi ithalat yapısından esinlenilmiştir

// =============================================================================
// 1. MULTI-WAREHOUSE STOCK MODELS
// =============================================================================

/// Depo/Mağaza Stok Bilgisi
class WarehouseStockItem {
  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;
  final String? brand;
  final String? category;

  // Depo Stok Detayları
  final List<LocationStock> locationStocks;

  // Toplam Bilgiler
  final int totalStock;
  final double? unitPrice;
  final String? unit;

  WarehouseStockItem({
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    this.brand,
    this.category,
    required this.locationStocks,
    required this.totalStock,
    this.unitPrice,
    this.unit,
  });

  factory WarehouseStockItem.fromJson(Map<String, dynamic> json) {
    return WarehouseStockItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      locationStocks: (json['locationStocks'] as List<dynamic>)
          .map((e) => LocationStock.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalStock: json['totalStock'] as int,
      unitPrice: json['unitPrice'] as double?,
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'barcode': barcode,
      'brand': brand,
      'category': category,
      'locationStocks': locationStocks.map((e) => e.toJson()).toList(),
      'totalStock': totalStock,
      'unitPrice': unitPrice,
      'unit': unit,
    };
  }
}

/// Konum Bazında Stok (Depo/Mağaza/Şube)
class LocationStock {
  final String locationId;
  final String locationName;
  final LocationType locationType; // WAREHOUSE, STORE, BRANCH
  final int quantity;
  final String? shelfLocation; // Raf konumu: A-01, B-12 vb.
  final int? minStock;
  final int? maxStock;
  final DateTime? lastUpdated;

  LocationStock({
    required this.locationId,
    required this.locationName,
    required this.locationType,
    required this.quantity,
    this.shelfLocation,
    this.minStock,
    this.maxStock,
    this.lastUpdated,
  });

  bool get isLowStock => minStock != null && quantity <= minStock!;
  bool get isCriticalStock => quantity <= 5;
  bool get isOutOfStock => quantity == 0;

  factory LocationStock.fromJson(Map<String, dynamic> json) {
    return LocationStock(
      locationId: json['locationId'] as String,
      locationName: json['locationName'] as String,
      locationType: LocationType.values.firstWhere(
        (e) => e.name == json['locationType'],
        orElse: () => LocationType.WAREHOUSE,
      ),
      quantity: json['quantity'] as int,
      shelfLocation: json['shelfLocation'] as String?,
      minStock: json['minStock'] as int?,
      maxStock: json['maxStock'] as int?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'locationName': locationName,
      'locationType': locationType.name,
      'quantity': quantity,
      'shelfLocation': shelfLocation,
      'minStock': minStock,
      'maxStock': maxStock,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}

enum LocationType {
  WAREHOUSE,  // Depo
  STORE,      // Mağaza
  BRANCH,     // Şube
}

// =============================================================================
// 2. STOCK TRANSFER MODELS (Tedarikçi İthalat Benzeri)
// =============================================================================

/// Stok Transfer Talebi Listesi (Backend'den gelen)
class StockTransferResponse {
  final String transferId;
  final int itemCount;
  final List<TransferItem> items;
  final TransferStatus status;
  final DateTime createdAt;
  final String? createdBy;

  StockTransferResponse({
    required this.transferId,
    required this.itemCount,
    required this.items,
    required this.status,
    required this.createdAt,
    this.createdBy,
  });

  factory StockTransferResponse.fromJson(Map<String, dynamic> json) {
    return StockTransferResponse(
      transferId: json['transferId'] as String,
      itemCount: json['itemCount'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => TransferItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: TransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransferStatus.PENDING,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'itemCount': itemCount,
      'items': items.map((e) => e.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

/// Transfer Edilecek Ürün (Supplier Import benzeri)
class TransferItem {
  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;
  final int requestedQuantity; // Talep edilen miktar
  final int availableStock;    // Kaynak depodaki mevcut stok

  // Kaynak ve hedef bilgileri
  final LocationStock sourceLocation;
  final LocationStock? targetLocation;

  // Kullanıcı kararı (tedarikçi ithalat benzeri)
  TransferDecision? userDecision;

  TransferItem({
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    required this.requestedQuantity,
    required this.availableStock,
    required this.sourceLocation,
    this.targetLocation,
    this.userDecision,
  });

  bool get hasDecision => userDecision != null;
  bool get isStockSufficient => availableStock >= requestedQuantity;
  bool get needsPartialTransfer => availableStock < requestedQuantity && availableStock > 0;

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      requestedQuantity: json['requestedQuantity'] as int,
      availableStock: json['availableStock'] as int,
      sourceLocation: LocationStock.fromJson(json['sourceLocation'] as Map<String, dynamic>),
      targetLocation: json['targetLocation'] != null
          ? LocationStock.fromJson(json['targetLocation'] as Map<String, dynamic>)
          : null,
      userDecision: json['userDecision'] != null
          ? TransferDecision.fromJson(json['userDecision'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'barcode': barcode,
      'requestedQuantity': requestedQuantity,
      'availableStock': availableStock,
      'sourceLocation': sourceLocation.toJson(),
      'targetLocation': targetLocation?.toJson(),
      'userDecision': userDecision?.toJson(),
    };
  }
}

/// Kullanıcı Transfer Kararı
class TransferDecision {
  final TransferAction action;
  final int? approvedQuantity; // Onaylanan miktar (partial için)
  final String? reason;
  final String? notes;

  TransferDecision({
    required this.action,
    this.approvedQuantity,
    this.reason,
    this.notes,
  });

  factory TransferDecision.fromJson(Map<String, dynamic> json) {
    return TransferDecision(
      action: TransferAction.values.firstWhere(
        (e) => e.name == json['action'],
      ),
      approvedQuantity: json['approvedQuantity'] as int?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'approvedQuantity': approvedQuantity,
      'reason': reason,
      'notes': notes,
    };
  }
}

enum TransferAction {
  APPROVE_FULL,      // Tam onayla
  APPROVE_PARTIAL,   // Kısmi onayla
  REJECT,            // Reddet
  REQUEST_MORE_INFO, // Ek bilgi iste
}

enum TransferStatus {
  PENDING,     // Beklemede
  APPROVED,    // Onaylandı
  IN_TRANSIT,  // Yolda
  COMPLETED,   // Tamamlandı
  REJECTED,    // Reddedildi
  CANCELLED,   // İptal edildi
}

// =============================================================================
// 3. STOCK COUNT MODELS (Sayım)
// =============================================================================

/// Stok Sayım Response (Excel'den upload sonrası)
class StockCountResponse {
  final String countId;
  final int productCount;
  final List<CountedProduct> products;
  final DateTime countDate;
  final String? countedBy;

  StockCountResponse({
    required this.countId,
    required this.productCount,
    required this.products,
    required this.countDate,
    this.countedBy,
  });

  factory StockCountResponse.fromJson(Map<String, dynamic> json) {
    return StockCountResponse(
      countId: json['countId'] as String,
      productCount: json['productCount'] as int,
      products: (json['products'] as List<dynamic>)
          .map((e) => CountedProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      countDate: DateTime.parse(json['countDate'] as String),
      countedBy: json['countedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'countId': countId,
      'productCount': productCount,
      'products': products.map((e) => e.toJson()).toList(),
      'countDate': countDate.toIso8601String(),
      'countedBy': countedBy,
    };
  }
}

/// Sayılan Ürün
class CountedProduct {
  final String productId;
  final String productName;
  final String? sku;
  final String? barcode;

  final int systemStock;   // Sistemdeki stok
  final int countedStock;  // Sayılan stok
  final int difference;    // Fark

  final String locationId;
  final String locationName;

  // Kullanıcı kararı
  CountDecision? userDecision;

  CountedProduct({
    required this.productId,
    required this.productName,
    this.sku,
    this.barcode,
    required this.systemStock,
    required this.countedStock,
    required this.difference,
    required this.locationId,
    required this.locationName,
    this.userDecision,
  });

  bool get hasDecision => userDecision != null;
  bool get hasDifference => difference != 0;
  bool get isOverage => difference > 0; // Fazla
  bool get isShortage => difference < 0; // Eksi

  DifferenceLevel get differenceLevel {
    final percent = (difference.abs() / systemStock * 100);
    if (percent == 0) return DifferenceLevel.NONE;
    if (percent < 5) return DifferenceLevel.LOW;
    if (percent < 15) return DifferenceLevel.MEDIUM;
    return DifferenceLevel.HIGH;
  }

  factory CountedProduct.fromJson(Map<String, dynamic> json) {
    return CountedProduct(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      systemStock: json['systemStock'] as int,
      countedStock: json['countedStock'] as int,
      difference: json['difference'] as int,
      locationId: json['locationId'] as String,
      locationName: json['locationName'] as String,
      userDecision: json['userDecision'] != null
          ? CountDecision.fromJson(json['userDecision'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'barcode': barcode,
      'systemStock': systemStock,
      'countedStock': countedStock,
      'difference': difference,
      'locationId': locationId,
      'locationName': locationName,
      'userDecision': userDecision?.toJson(),
    };
  }
}

/// Sayım Kararı
class CountDecision {
  final CountAction action;
  final String? reason;
  final String? notes;
  final int? adjustedQuantity; // Manuel düzeltme için

  CountDecision({
    required this.action,
    this.reason,
    this.notes,
    this.adjustedQuantity,
  });

  factory CountDecision.fromJson(Map<String, dynamic> json) {
    return CountDecision(
      action: CountAction.values.firstWhere(
        (e) => e.name == json['action'],
      ),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      adjustedQuantity: json['adjustedQuantity'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'reason': reason,
      'notes': notes,
      'adjustedQuantity': adjustedQuantity,
    };
  }
}

enum CountAction {
  ACCEPT_COUNT,     // Sayımı kabul et (sistem güncellensin)
  RECOUNT,          // Tekrar say
  MANUAL_ADJUST,    // Manuel düzelt
  IGNORE,           // Yok say
}

enum DifferenceLevel {
  NONE,    // Fark yok
  LOW,     // Düşük fark (<5%)
  MEDIUM,  // Orta fark (5-15%)
  HIGH,    // Yüksek fark (>15%)
}
