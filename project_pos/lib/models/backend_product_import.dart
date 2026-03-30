/// Backend'den gelen ürün import response modeli
/// Backend zaten kayıt formatında JSON döndürür + analiz metadatası ekler

class BackendImportResponse {
  final String importId;
  final int total;
  final List<BackendAnalyzedProduct> products;

  BackendImportResponse({
    required this.importId,
    required this.total,
    required this.products,
  });

  factory BackendImportResponse.fromJson(Map<String, dynamic> json) {
    return BackendImportResponse(
      importId: json['importId'] as String,
      total: json['total'] as int,
      products: (json['products'] as List)
          .map((p) => BackendAnalyzedProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BackendAnalyzedProduct {
  final String tempId;

  // Backend'in analizi
  final ProductImportStatus status;
  final double confidence;

  // KAYIT FORMATINDA PAYLOAD (Backend tarafından hazır!)
  // Bu payload direkt save endpoint'ine gönderilebilir
  final Map<String, dynamic> payload;

  // Benzer ürünler (eğer BENZER status ise)
  final List<SimilarProduct>? similarProducts;

  // Öneriler
  final List<String> suggestions;
  final String? reason;

  // KULLANICI KARARI (Flutter tarafında set edilir)
  UserImportDecision? userDecision;

  BackendAnalyzedProduct({
    required this.tempId,
    required this.status,
    required this.confidence,
    required this.payload,
    this.similarProducts,
    required this.suggestions,
    this.reason,
    this.userDecision,
  });

  factory BackendAnalyzedProduct.fromJson(Map<String, dynamic> json) {
    return BackendAnalyzedProduct(
      tempId: json['tempId'] as String,
      status: ProductImportStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ProductImportStatus.NEW,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      payload: json['payload'] as Map<String, dynamic>,
      similarProducts: json['similarProducts'] != null
          ? (json['similarProducts'] as List)
              .map((s) => SimilarProduct.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      suggestions: (json['suggestions'] as List?)
              ?.map((s) => s.toString())
              .toList() ?? [],
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tempId': tempId,
      'status': status.name,
      'confidence': confidence,
      'payload': payload,
      'similarProducts': similarProducts?.map((s) => s.toJson()).toList(),
      'suggestions': suggestions,
      'reason': reason,
    };
  }

  // Payload içindeki ürün bilgilerine kolay erişim
  String get productName =>
      (payload['product'] as Map<String, dynamic>?)?['name'] as String? ?? '';

  String get sku =>
      (payload['product'] as Map<String, dynamic>?)?['sku'] as String? ?? '';

  double get purchasePrice {
    final variants = payload['variants'] as List?;
    if (variants == null || variants.isEmpty) return 0.0;
    final pricing = (variants[0] as Map<String, dynamic>)['pricing'] as Map<String, dynamic>?;
    return (pricing?['purchasePrice'] as num?)?.toDouble() ?? 0.0;
  }

  double get salePrice {
    final variants = payload['variants'] as List?;
    if (variants == null || variants.isEmpty) return 0.0;
    final pricing = (variants[0] as Map<String, dynamic>)['pricing'] as Map<String, dynamic>?;
    return (pricing?['salePrice'] as num?)?.toDouble() ?? 0.0;
  }

  int get stock {
    final variants = payload['variants'] as List?;
    if (variants == null || variants.isEmpty) return 0;
    final stocks = (variants[0] as Map<String, dynamic>)['initialStocks'] as List?;
    if (stocks == null || stocks.isEmpty) return 0;
    return (stocks[0] as Map<String, dynamic>)['quantity'] as int? ?? 0;
  }
}

enum ProductImportStatus {
  NEW,      // Sistemde yok, yeni oluşturulacak
  SIMILAR,  // Benzer ürünler var, kullanıcı karar verecek
  EXACT,    // Tam eşleşme, sadece stok güncellenecek
}

class SimilarProduct {
  final String productId;
  final String productName;
  final double similarity;
  final String reason;

  SimilarProduct({
    required this.productId,
    required this.productName,
    required this.similarity,
    required this.reason,
  });

  factory SimilarProduct.fromJson(Map<String, dynamic> json) {
    return SimilarProduct(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      similarity: (json['similarity'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'similarity': similarity,
      'reason': reason,
    };
  }
}

class UserImportDecision {
  final ImportAction action;
  final String? selectedProductId; // SIMILAR durumunda hangi ürüne eklenecek
  final Map<String, dynamic>? modifiedPayload; // Kullanıcı düzenlediyse

  UserImportDecision({
    required this.action,
    this.selectedProductId,
    this.modifiedPayload,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'selectedProductId': selectedProductId,
      'modifiedPayload': modifiedPayload,
    };
  }
}

enum ImportAction {
  APPROVE,          // Olduğu gibi kaydet
  SKIP,             // Bu ürünü atlama
  EDIT,             // Düzenle ve kaydet
  ADD_AS_VARIANT,   // Benzer ürüne varyant olarak ekle
  CREATE_NEW,       // Benzer olsa da yeni ürün oluştur
}
