// ignore_for_file: constant_identifier_names

/// Bulk Import System - Data Models
///
/// Bu dosya toplu ürün içe aktarma sisteminin tüm veri modellerini içerir.
/// Backend API ile uyumlu şekilde tasarlanmıştır.

// ============================================================================
// ENUMS
// ============================================================================

/// Ürün durumu - Backend'in analiz sonucu
enum ProductStatus {
  NEW,                    // Yeni ürün, eşleşme yok
  CONFLICT,               // Tam eşleşme (SKU/Barcode)
  POTENTIAL_MATCH,        // İsim benzerliği yüksek
  ADD_VARIANT,            // Ana ürün var, yeni varyant eklenebilir
  UPDATE_VARIANT,         // Varyant var, güncellenebilir
  NEEDS_VARIANTS,         // Varyant bilgisi eksik
  CREATE_VARIANT_GROUP,   // Çoklu varyant, ana ürün oluşturulabilir
  ERROR,                  // Kritik hata
}

/// Kullanıcı aksiyonu tipi
enum ActionType {
  CREATE,                 // Yeni ürün oluştur
  UPDATE_STOCK,           // Sadece stok güncelle
  UPDATE_PRICE,           // Sadece fiyat güncelle
  UPDATE_BOTH,            // Stok + fiyat güncelle
  MATCH,                  // Önerilen ürünle eşleştir
  MATCH_MANUAL,           // Manuel eşleştir
  ADD_VARIANT,            // Varyant ekle
  UPDATE_VARIANT,         // Varyant güncelle
  CREATE_VARIANTS,        // Varyantlar oluştur
  CREATE_VARIANT_GROUP,   // Ana ürün + varyantlar oluştur
  SKIP,                   // Atla
}

/// Stok güncelleme modu
enum StockUpdateMode {
  ADD,                    // Mevcut stoka ekle
  REPLACE,                // Stoğu değiştir
}

/// Birleştirme stratejisi
enum MergeStrategy {
  UPDATE_STOCK,           // Sadece stok güncelle
  UPDATE_PRICE,           // Sadece fiyat güncelle
  UPDATE_BOTH,            // Her ikisini güncelle
  NO_UPDATE,              // Güncelleme yapma
}

// ============================================================================
// CORE MODELS
// ============================================================================

/// Varyant modeli
class Variant {
  final String? id;
  final String sku;
  final String barcode;
  final Map<String, String> attributes; // {color: "Beyaz", size: "M"}
  final int stock;
  final double? buyPrice;
  final double? sellPrice;

  Variant({
    this.id,
    required this.sku,
    required this.barcode,
    required this.attributes,
    required this.stock,
    this.buyPrice,
    this.sellPrice,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String?,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String,
      attributes: Map<String, String>.from(json['attributes'] as Map),
      stock: json['stock'] as int,
      buyPrice: (json['buyPrice'] as num?)?.toDouble(),
      sellPrice: (json['sellPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sku': sku,
      'barcode': barcode,
      'attributes': attributes,
      'stock': stock,
      if (buyPrice != null) 'buyPrice': buyPrice,
      if (sellPrice != null) 'sellPrice': sellPrice,
    };
  }

  Variant copyWith({
    String? id,
    String? sku,
    String? barcode,
    Map<String, String>? attributes,
    int? stock,
    double? buyPrice,
    double? sellPrice,
  }) {
    return Variant(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      attributes: attributes ?? this.attributes,
      stock: stock ?? this.stock,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
    );
  }
}

/// Eşleşen ürün bilgisi (Backend'den gelen)
class MatchedProduct {
  final String id;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String brand;
  final int currentStock;
  final double currentBuyPrice;
  final double currentSellPrice;
  final List<Variant> variants;
  final double similarity; // 0-1 arası benzerlik skoru
  final DateTime lastUpdated;

  MatchedProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.brand,
    required this.currentStock,
    required this.currentBuyPrice,
    required this.currentSellPrice,
    required this.variants,
    required this.similarity,
    required this.lastUpdated,
  });

  factory MatchedProduct.fromJson(Map<String, dynamic> json) {
    return MatchedProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String,
      currentStock: json['currentStock'] as int,
      currentBuyPrice: (json['currentBuyPrice'] as num).toDouble(),
      currentSellPrice: (json['currentSellPrice'] as num).toDouble(),
      variants: (json['variants'] as List?)
              ?.map((v) => Variant.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      similarity: (json['similarity'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'brand': brand,
      'currentStock': currentStock,
      'currentBuyPrice': currentBuyPrice,
      'currentSellPrice': currentSellPrice,
      'variants': variants.map((v) => v.toJson()).toList(),
      'similarity': similarity,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

/// Varyant analizi sonucu
class VariantAnalysis {
  final bool isVariant;
  final String baseProductName;
  final Map<String, String> detectedAttributes;
  final ParentProduct? parentProduct;
  final String suggestedVariantType; // 'size', 'color', 'both'
  final double confidence; // 0-1 arası güvenilirlik

  VariantAnalysis({
    required this.isVariant,
    required this.baseProductName,
    required this.detectedAttributes,
    this.parentProduct,
    required this.suggestedVariantType,
    required this.confidence,
  });

  factory VariantAnalysis.fromJson(Map<String, dynamic> json) {
    return VariantAnalysis(
      isVariant: json['isVariant'] as bool,
      baseProductName: json['baseProductName'] as String,
      detectedAttributes:
          Map<String, String>.from(json['detectedAttributes'] as Map),
      parentProduct: json['parentProduct'] != null
          ? ParentProduct.fromJson(json['parentProduct'] as Map<String, dynamic>)
          : null,
      suggestedVariantType: json['suggestedVariantType'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isVariant': isVariant,
      'baseProductName': baseProductName,
      'detectedAttributes': detectedAttributes,
      if (parentProduct != null) 'parentProduct': parentProduct!.toJson(),
      'suggestedVariantType': suggestedVariantType,
      'confidence': confidence,
    };
  }
}

/// Ana ürün bilgisi (varyant analizinde)
class ParentProduct {
  final String id;
  final String name;
  final List<Variant> existingVariants;

  ParentProduct({
    required this.id,
    required this.name,
    required this.existingVariants,
  });

  factory ParentProduct.fromJson(Map<String, dynamic> json) {
    return ParentProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      existingVariants: (json['existingVariants'] as List)
          .map((v) => Variant.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'existingVariants': existingVariants.map((v) => v.toJson()).toList(),
    };
  }
}

/// Önerilen aksiyon
class SuggestedAction {
  final ActionType action;
  final String label;
  final String description;
  final bool recommended;
  final String? icon;

  SuggestedAction({
    required this.action,
    required this.label,
    required this.description,
    this.recommended = false,
    this.icon,
  });

  factory SuggestedAction.fromJson(Map<String, dynamic> json) {
    return SuggestedAction(
      action: ActionType.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => ActionType.SKIP,
      ),
      label: json['label'] as String,
      description: json['description'] as String,
      recommended: json['recommended'] as bool? ?? false,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'label': label,
      'description': description,
      'recommended': recommended,
      if (icon != null) 'icon': icon,
    };
  }
}

/// Analiz edilmiş ürün (Backend'den gelen ana model)
class AnalyzedProduct {
  // Import bilgisi
  final String tempId;
  final String importId;

  // Ürün bilgileri
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String brand;
  final String unit;
  final double buyPrice;
  final double sellPrice;
  final double taxRate;
  final int stock;
  final String? description;

  // Backend analiz sonuçları
  final ProductStatus status;
  final double confidence;

  // Eşleşme bilgisi
  final MatchedProduct? matchedProduct;

  // Varyant analizi
  final VariantAnalysis? variantAnalysis;

  // Önerilen aksiyonlar
  final List<SuggestedAction> suggestedActions;
  final String? recommendedAction;

  // Hatalar ve uyarılar
  final List<String>? errors;
  final List<String>? warnings;

  // Kullanıcı kararı (frontend sets this)
  UserDecision? userDecision;

  AnalyzedProduct({
    required this.tempId,
    required this.importId,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.brand,
    required this.unit,
    required this.buyPrice,
    required this.sellPrice,
    required this.taxRate,
    required this.stock,
    this.description,
    required this.status,
    required this.confidence,
    this.matchedProduct,
    this.variantAnalysis,
    required this.suggestedActions,
    this.recommendedAction,
    this.errors,
    this.warnings,
    this.userDecision,
  });

  factory AnalyzedProduct.fromJson(Map<String, dynamic> json) {
    return AnalyzedProduct(
      tempId: json['tempId'] as String,
      importId: json['importId'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String,
      unit: json['unit'] as String,
      buyPrice: (json['buyPrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
      taxRate: (json['taxRate'] as num).toDouble(),
      stock: json['stock'] as int,
      description: json['description'] as String?,
      status: ProductStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProductStatus.ERROR,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      matchedProduct: json['matchedProduct'] != null
          ? MatchedProduct.fromJson(json['matchedProduct'] as Map<String, dynamic>)
          : null,
      variantAnalysis: json['variantAnalysis'] != null
          ? VariantAnalysis.fromJson(json['variantAnalysis'] as Map<String, dynamic>)
          : null,
      suggestedActions: (json['suggestedActions'] as List)
          .map((a) => SuggestedAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      recommendedAction: json['recommendedAction'] as String?,
      errors: (json['errors'] as List?)?.cast<String>(),
      warnings: (json['warnings'] as List?)?.cast<String>(),
      userDecision: json['userDecision'] != null
          ? UserDecision.fromJson(json['userDecision'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tempId': tempId,
      'importId': importId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'brand': brand,
      'unit': unit,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'taxRate': taxRate,
      'stock': stock,
      if (description != null) 'description': description,
      'status': status.name,
      'confidence': confidence,
      if (matchedProduct != null) 'matchedProduct': matchedProduct!.toJson(),
      if (variantAnalysis != null) 'variantAnalysis': variantAnalysis!.toJson(),
      'suggestedActions': suggestedActions.map((a) => a.toJson()).toList(),
      if (recommendedAction != null) 'recommendedAction': recommendedAction,
      if (errors != null) 'errors': errors,
      if (warnings != null) 'warnings': warnings,
      if (userDecision != null) 'userDecision': userDecision!.toJson(),
    };
  }

  AnalyzedProduct copyWith({
    UserDecision? userDecision,
    ProductStatus? status,
  }) {
    return AnalyzedProduct(
      tempId: tempId,
      importId: importId,
      name: name,
      sku: sku,
      barcode: barcode,
      category: category,
      brand: brand,
      unit: unit,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      taxRate: taxRate,
      stock: stock,
      description: description,
      status: status ?? this.status,
      confidence: confidence,
      matchedProduct: matchedProduct,
      variantAnalysis: variantAnalysis,
      suggestedActions: suggestedActions,
      recommendedAction: recommendedAction,
      errors: errors,
      warnings: warnings,
      userDecision: userDecision ?? this.userDecision,
    );
  }
}

// ============================================================================
// USER DECISION MODELS (Frontend → Backend)
// ============================================================================

/// Kullanıcı kararı (base class)
class UserDecision {
  final String tempId;
  final ActionType action;
  final Map<String, dynamic> data;

  UserDecision({
    required this.tempId,
    required this.action,
    required this.data,
  });

  factory UserDecision.fromJson(Map<String, dynamic> json) {
    return UserDecision(
      tempId: json['tempId'] as String,
      action: ActionType.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => ActionType.SKIP,
      ),
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tempId': tempId,
      'action': action.name,
      'data': data,
    };
  }

  // Factory constructors for different action types
  factory UserDecision.create({
    required String tempId,
    required Map<String, dynamic> product,
    List<Variant>? variants,
  }) {
    return UserDecision(
      tempId: tempId,
      action: ActionType.CREATE,
      data: {
        'product': product,
        if (variants != null) 'variants': variants.map((v) => v.toJson()).toList(),
      },
    );
  }

  factory UserDecision.updateStock({
    required String tempId,
    required String productId,
    required StockUpdateMode mode,
    required int value,
  }) {
    return UserDecision(
      tempId: tempId,
      action: ActionType.UPDATE_STOCK,
      data: {
        'productId': productId,
        'updateType': 'stock',
        'stockUpdate': {
          'mode': mode.name,
          'value': value,
        },
      },
    );
  }

  factory UserDecision.updatePrice({
    required String tempId,
    required String productId,
    double? buyPrice,
    double? sellPrice,
  }) {
    return UserDecision(
      tempId: tempId,
      action: ActionType.UPDATE_PRICE,
      data: {
        'productId': productId,
        'updateType': 'price',
        'priceUpdate': {
          if (buyPrice != null) 'buyPrice': buyPrice,
          if (sellPrice != null) 'sellPrice': sellPrice,
        },
      },
    );
  }

  factory UserDecision.match({
    required String tempId,
    required String matchedProductId,
    required MergeStrategy mergeStrategy,
    Map<String, dynamic>? stockUpdate,
    Map<String, dynamic>? priceUpdate,
  }) {
    return UserDecision(
      tempId: tempId,
      action: ActionType.MATCH,
      data: {
        'matchedProductId': matchedProductId,
        'mergeStrategy': mergeStrategy.name,
        if (stockUpdate != null) 'stockUpdate': stockUpdate,
        if (priceUpdate != null) 'priceUpdate': priceUpdate,
      },
    );
  }

  factory UserDecision.addVariant({
    required String tempId,
    required String productId,
    required Variant variant,
    bool updateExisting = false,
  }) {
    return UserDecision(
      tempId: tempId,
      action: ActionType.ADD_VARIANT,
      data: {
        'productId': productId,
        'variant': variant.toJson(),
        'updateExisting': updateExisting,
      },
    );
  }

  factory UserDecision.createVariants({
    required String tempId,
    required Map<String, dynamic> baseProduct,
    required List<Variant> variants,
  }) {
    return UserDecision(
      tempId: tempId,
      action: ActionType.CREATE_VARIANTS,
      data: {
        'baseProduct': baseProduct,
        'variants': variants.map((v) => v.toJson()).toList(),
      },
    );
  }

  factory UserDecision.skip({
    required String tempId,
    String? reason,
  }) {
    return UserDecision(
      tempId: tempId,
      action: ActionType.SKIP,
      data: {
        if (reason != null) 'reason': reason,
      },
    );
  }
}

// ============================================================================
// API REQUEST/RESPONSE MODELS
// ============================================================================

/// Upload Response
class UploadResponse {
  final String importId;
  final String fileName;
  final DateTime uploadedAt;
  final List<AnalyzedProduct> products;
  final ImportStatistics statistics;

  UploadResponse({
    required this.importId,
    required this.fileName,
    required this.uploadedAt,
    required this.products,
    required this.statistics,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      importId: json['importId'] as String,
      fileName: json['fileName'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      products: (json['products'] as List)
          .map((p) => AnalyzedProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      statistics: ImportStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
    );
  }
}

/// Import Statistics
class ImportStatistics {
  final int total;
  final int newProducts;
  final int conflicts;
  final int potentialMatches;
  final int addVariants;
  final int updateVariants;
  final int needsVariants;
  final int createVariantGroups;
  final int errors;

  ImportStatistics({
    required this.total,
    required this.newProducts,
    required this.conflicts,
    required this.potentialMatches,
    required this.addVariants,
    required this.updateVariants,
    required this.needsVariants,
    required this.createVariantGroups,
    required this.errors,
  });

  factory ImportStatistics.fromJson(Map<String, dynamic> json) {
    return ImportStatistics(
      total: json['total'] as int,
      newProducts: json['new'] as int,
      conflicts: json['conflict'] as int,
      potentialMatches: json['potentialMatch'] as int,
      addVariants: json['addVariant'] as int,
      updateVariants: json['updateVariant'] as int,
      needsVariants: json['needsVariants'] as int,
      createVariantGroups: json['createVariantGroup'] as int,
      errors: json['error'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'new': newProducts,
      'conflict': conflicts,
      'potentialMatch': potentialMatches,
      'addVariant': addVariants,
      'updateVariant': updateVariants,
      'needsVariants': needsVariants,
      'createVariantGroup': createVariantGroups,
      'error': errors,
    };
  }
}

/// Confirm Request
class ConfirmRequest {
  final String importId;
  final List<UserDecision> decisions;

  ConfirmRequest({
    required this.importId,
    required this.decisions,
  });

  Map<String, dynamic> toJson() {
    return {
      'importId': importId,
      'decisions': decisions.map((d) => d.toJson()).toList(),
    };
  }
}

/// Confirm Response
class ConfirmResponse {
  final bool success;
  final String importId;
  final DateTime processedAt;
  final SaveResults results;
  final List<CreatedProduct> createdProducts;
  final List<UpdatedProduct> updatedProducts;
  final List<SaveError> errors;

  ConfirmResponse({
    required this.success,
    required this.importId,
    required this.processedAt,
    required this.results,
    required this.createdProducts,
    required this.updatedProducts,
    required this.errors,
  });

  factory ConfirmResponse.fromJson(Map<String, dynamic> json) {
    return ConfirmResponse(
      success: json['success'] as bool,
      importId: json['importId'] as String,
      processedAt: DateTime.parse(json['processedAt'] as String),
      results: SaveResults.fromJson(json['results'] as Map<String, dynamic>),
      createdProducts: (json['createdProducts'] as List)
          .map((p) => CreatedProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      updatedProducts: (json['updatedProducts'] as List)
          .map((p) => UpdatedProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      errors: (json['errors'] as List)
          .map((e) => SaveError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SaveResults {
  final int created;
  final int updated;
  final int variantsAdded;
  final int skipped;
  final int failed;

  SaveResults({
    required this.created,
    required this.updated,
    required this.variantsAdded,
    required this.skipped,
    required this.failed,
  });

  factory SaveResults.fromJson(Map<String, dynamic> json) {
    return SaveResults(
      created: json['created'] as int,
      updated: json['updated'] as int,
      variantsAdded: json['variantsAdded'] as int,
      skipped: json['skipped'] as int,
      failed: json['failed'] as int,
    );
  }
}

class CreatedProduct {
  final String tempId;
  final String productId;
  final String sku;

  CreatedProduct({
    required this.tempId,
    required this.productId,
    required this.sku,
  });

  factory CreatedProduct.fromJson(Map<String, dynamic> json) {
    return CreatedProduct(
      tempId: json['tempId'] as String,
      productId: json['productId'] as String,
      sku: json['sku'] as String,
    );
  }
}

class UpdatedProduct {
  final String tempId;
  final String productId;

  UpdatedProduct({
    required this.tempId,
    required this.productId,
  });

  factory UpdatedProduct.fromJson(Map<String, dynamic> json) {
    return UpdatedProduct(
      tempId: json['tempId'] as String,
      productId: json['productId'] as String,
    );
  }
}

class SaveError {
  final String tempId;
  final String error;
  final String code;

  SaveError({
    required this.tempId,
    required this.error,
    required this.code,
  });

  factory SaveError.fromJson(Map<String, dynamic> json) {
    return SaveError(
      tempId: json['tempId'] as String,
      error: json['error'] as String,
      code: json['code'] as String,
    );
  }
}

// ============================================================================
// BULK SAVE PAYLOAD BUILDER
// ============================================================================

/// Bulk Import için Backend Payload Oluşturucu
/// 
/// Kullanıcı kararlarını alıp backend'in beklediği formata çevirir.
/// AddProductWizardScreen'in _buildPayload() formatıyla uyumludur.
class BulkSavePayloadBuilder {
  /// Tüm kullanıcı kararlarını backend formatına çevirir
  static List<Map<String, dynamic>> buildBulkPayload({
    required List<AnalyzedProduct> products,
    String? supplierId,
    String? invoiceNumber,
    String? deliveryNote,
    String? purchaseDate,
    String? notes,
  }) {
    final payloads = <Map<String, dynamic>>[];

    for (final product in products) {
      // Sadece karar verilmiş ürünleri işle
      if (product.userDecision == null) continue;

      final decision = product.userDecision!;
      Map<String, dynamic>? payload;

      switch (decision.action) {
        case ActionType.CREATE:
          payload = _buildCreatePayload(product, decision, 
            supplierId: supplierId,
            invoiceNumber: invoiceNumber,
            deliveryNote: deliveryNote,
            purchaseDate: purchaseDate,
            notes: notes,
          );
          break;

        case ActionType.UPDATE_STOCK:
        case ActionType.UPDATE_PRICE:
        case ActionType.UPDATE_BOTH:
          payload = _buildUpdatePayload(product, decision);
          break;

        case ActionType.MATCH:
        case ActionType.MATCH_MANUAL:
          payload = _buildMatchPayload(product, decision);
          break;

        case ActionType.ADD_VARIANT:
        case ActionType.UPDATE_VARIANT:
          payload = _buildVariantPayload(product, decision);
          break;

        case ActionType.SKIP:
          // Skip edilenler listede yer almaz
          continue;

        default:
          continue;
      }

      if (payload != null) {
        payloads.add(payload);
      }
    }

    return payloads;
  }

  /// Yeni ürün oluşturma payload'u
  static Map<String, dynamic> _buildCreatePayload(
    AnalyzedProduct product,
    UserDecision decision, {
    String? supplierId,
    String? invoiceNumber,
    String? deliveryNote,
    String? purchaseDate,
    String? notes,
  }) {
    // UserDecision.data içinde AddProductWizardScreen'den gelen payload var
    final productData = decision.data['product'] as Map<String, dynamic>?;
    
    if (productData != null) {
      // AddProductWizardScreen'den gelen tam payload'u kullan
      return {
        'tempId': product.tempId,
        'action': 'CREATE',
        ...productData,
      };
    }

    // Eğer AddProductWizardScreen kullanılmadıysa, manuel oluştur
    return {
      'tempId': product.tempId,
      'action': 'CREATE',
      'product': {
        'sku': product.sku,
        'name': product.name,
        'slug': product.name.toLowerCase().replaceAll(' ', '-'),
        'categoryId': int.tryParse(product.category ?? '0') ?? 0,
        'brand': product.brand ?? '',
        'unit': product.unit ?? 'pcs',
        'description': product.description ?? '',
      },
      'variants': [
        {
          'sku': product.sku,
          'name': 'Varsayılan Varyant',
          'attributes': {},
          'pricing': {
            'purchasePrice': product.buyPrice ?? 0,
            'salePrice': product.sellPrice ?? 0,
          },
          'initialStocks': [
            {
              'storeId': null,
              'warehouseId': 'WH-001',
              'quantity': product.stock ?? 0,
            }
          ],
          'barcodes': product.barcode != null && product.barcode!.isNotEmpty
              ? [
                  {
                    'code': product.barcode,
                    'type': 'EAN13',
                    'primary': true,
                  }
                ]
              : [],
        }
      ],
      'purchase': {
        'supplierId': supplierId ?? '',
        'invoiceNumber': invoiceNumber ?? '',
        'deliveryNoteNumber': deliveryNote ?? '',
        'purchaseDate': purchaseDate ?? DateTime.now().toIso8601String(),
        'notes': notes ?? '',
      },
    };
  }

  /// Stok/fiyat güncelleme payload'u
  static Map<String, dynamic> _buildUpdatePayload(
    AnalyzedProduct product,
    UserDecision decision,
  ) {
    final updateData = decision.data;
    return {
      'tempId': product.tempId,
      'action': decision.action.name,
      'productId': updateData['productId'],
      'variantId': updateData['variantId'],
      if (decision.action == ActionType.UPDATE_STOCK || 
          decision.action == ActionType.UPDATE_BOTH) ...{
        'stock': {
          'mode': updateData['stockMode'] ?? 'ADD',
          'value': updateData['stockValue'] ?? 0,
        },
      },
      if (decision.action == ActionType.UPDATE_PRICE || 
          decision.action == ActionType.UPDATE_BOTH) ...{
        'pricing': {
          if (updateData['buyPrice'] != null)
            'purchasePrice': updateData['buyPrice'],
          if (updateData['sellPrice'] != null)
            'salePrice': updateData['sellPrice'],
        },
      },
    };
  }

  /// Eşleştirme payload'u
  static Map<String, dynamic> _buildMatchPayload(
    AnalyzedProduct product,
    UserDecision decision,
  ) {
    final matchData = decision.data;
    return {
      'tempId': product.tempId,
      'action': 'MATCH',
      'productId': matchData['matchedProductId'],
      'variantId': matchData['matchedVariantId'],
      'updateStock': matchData['updateStock'] ?? true,
      'updatePrice': matchData['updatePrice'] ?? false,
      if (matchData['updateStock'] == true) ...{
        'stock': {
          'mode': matchData['stockMode'] ?? 'ADD',
          'value': product.stock ?? 0,
        },
      },
      if (matchData['updatePrice'] == true) ...{
        'pricing': {
          'purchasePrice': product.buyPrice,
          'salePrice': product.sellPrice,
        },
      },
    };
  }

  /// Varyant ekleme/güncelleme payload'u
  static Map<String, dynamic> _buildVariantPayload(
    AnalyzedProduct product,
    UserDecision decision,
  ) {
    final variantData = decision.data;
    return {
      'tempId': product.tempId,
      'action': decision.action.name,
      'productId': variantData['productId'],
      'variant': {
        'sku': product.sku,
        'name': variantData['variantName'] ?? product.name,
        'attributes': variantData['attributes'] ?? {},
        'pricing': {
          'purchasePrice': product.buyPrice ?? 0,
          'salePrice': product.sellPrice ?? 0,
        },
        'initialStocks': [
          {
            'storeId': null,
            'warehouseId': 'WH-001',
            'quantity': product.stock ?? 0,
          }
        ],
        'barcodes': product.barcode != null && product.barcode!.isNotEmpty
            ? [
                {
                  'code': product.barcode,
                  'type': 'EAN13',
                  'primary': true,
                }
              ]
            : [],
      },
    };
  }

  /// Payload özeti (debug/preview için)
  static Map<String, dynamic> getSummary(List<Map<String, dynamic>> payloads) {
    final summary = <String, int>{};
    var totalProducts = 0;
    var totalVariants = 0;
    var totalStock = 0;

    for (final payload in payloads) {
      final action = payload['action'] as String?;
      summary[action ?? 'UNKNOWN'] = (summary[action ?? 'UNKNOWN'] ?? 0) + 1;

      if (action == 'CREATE') {
        totalProducts++;
        final variants = payload['variants'] as List?;
        if (variants != null) {
          totalVariants += variants.length;
          for (final variant in variants) {
            final stocks = variant['initialStocks'] as List?;
            if (stocks != null) {
              for (final stock in stocks) {
                totalStock += (stock['quantity'] as num?)?.toInt() ?? 0;
              }
            }
          }
        }
      }
    }

    return {
      'totalPayloads': payloads.length,
      'totalProducts': totalProducts,
      'totalVariants': totalVariants,
      'totalStock': totalStock,
      'actionBreakdown': summary,
    };
  }
}
