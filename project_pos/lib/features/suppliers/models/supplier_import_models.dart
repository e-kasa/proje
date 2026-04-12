/// Tedarikçi İthalat Modelleri
/// Backend'den gelen tedarikçi ürün analiz yapısı

class SupplierImportResponse {
  final int productCount;
  final List<SupplierProductItem> products;

  SupplierImportResponse({
    required this.productCount,
    required this.products,
  });

  factory SupplierImportResponse.fromJson(Map<String, dynamic> json) {
    return SupplierImportResponse(
      productCount: json['productCount'] as int,
      products: (json['products'] as List)
          .map((p) => SupplierProductItem.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productCount': productCount,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
}

/// Tedarikçiden okunan tek bir ürün satırı
class SupplierProductItem {
  // TEDARİKÇİ BELGESİNDEN OKUNAN BİLGİLER
  final String readProductName;  // Tedarikçi faturasından okunan isim
  final int readStock;           // Tedarikçi faturasından okunan stok
  final double? readPrice;       // Opsiyonel: Okunan fiyat
  final String? readBarcode;     // Opsiyonel: Okunan barkod
  final String? readBrand;       // Opsiyonel: Okunan marka
  final String? readCategory;    // Opsiyonel: Okunan kategori

  // SİSTEMDE BULUNAN BENZER ÜRÜNLER (Backend analizi)
  final List<SystemProduct> forProduct;

  // KULLANICI KARARI (Flutter set eder)
  UserProductDecision? userDecision;

  SupplierProductItem({
    required this.readProductName,
    required this.readStock,
    this.readPrice,
    this.readBarcode,
    this.readBrand,
    this.readCategory,
    required this.forProduct,
    this.userDecision,
  });

  factory SupplierProductItem.fromJson(Map<String, dynamic> json) {
    return SupplierProductItem(
      readProductName: json['readProductName'] as String,
      readStock: json['readStock'] as int,
      readPrice: json['readPrice'] != null
          ? (json['readPrice'] as num).toDouble()
          : null,
      readBarcode: json['readBarcode'] as String?,
      readBrand: json['readBrand'] as String?,
      readCategory: json['readCategory'] as String?,
      forProduct: (json['forProduct'] as List)
          .map((p) => SystemProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'readProductName': readProductName,
      'readStock': readStock,
      'readPrice': readPrice,
      'readBarcode': readBarcode,
      'readBrand': readBrand,
      'readCategory': readCategory,
      'forProduct': forProduct.map((p) => p.toJson()).toList(),
    };
  }

  // Yardımcı metodlar
  bool get hasSystemMatches => forProduct.isNotEmpty;
  bool get isNewProduct => forProduct.isEmpty;
  bool get hasDecision => userDecision != null;
}

/// Sistemde bulunan ürün (benzer ürünlerden biri)
class SystemProduct {
  final String productId;  // Sistemdeki ürün ID'si
  final String sku;
  final String name;
  final String? slug;
  final String? categoryId;
  final String? brand;
  final String? unit;
  final String? description;
  final List<ProductVariant> variants;

  SystemProduct({
    required this.productId,
    required this.sku,
    required this.name,
    this.slug,
    this.categoryId,
    this.brand,
    this.unit,
    this.description,
    required this.variants,
  });

  factory SystemProduct.fromJson(Map<String, dynamic> json) {
    return SystemProduct(
      productId: json['productId'] as String? ?? json['id'] as String? ?? '',
      sku: json['sku'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      categoryId: json['categoryId'] as String?,
      brand: json['brand'] as String?,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      variants: (json['variants'] as List?)
              ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'sku': sku,
      'name': name,
      'slug': slug,
      'categoryId': categoryId,
      'brand': brand,
      'unit': unit,
      'description': description,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }
}

/// Ürün varyantı
class ProductVariant {
  final String? variantId;
  final String sku;
  final String name;
  final Map<String, dynamic>? attributes;
  final VariantPricing? pricing;
  final List<VariantStock>? initialStocks;
  final List<VariantBarcode>? barcodes;
  final String? notes;

  ProductVariant({
    this.variantId,
    required this.sku,
    required this.name,
    this.attributes,
    this.pricing,
    this.initialStocks,
    this.barcodes,
    this.notes,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      variantId: json['variantId'] as String? ?? json['id'] as String?,
      sku: json['sku'] as String,
      name: json['name'] as String,
      attributes: json['attributes'] as Map<String, dynamic>?,
      pricing: json['pricing'] != null
          ? VariantPricing.fromJson(json['pricing'] as Map<String, dynamic>)
          : null,
      initialStocks: (json['initialStocks'] as List?)
          ?.map((s) => VariantStock.fromJson(s as Map<String, dynamic>))
          .toList(),
      barcodes: (json['barcodes'] as List?)
          ?.map((b) => VariantBarcode.fromJson(b as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'sku': sku,
      'name': name,
      'attributes': attributes,
      'pricing': pricing?.toJson(),
      'initialStocks': initialStocks?.map((s) => s.toJson()).toList(),
      'barcodes': barcodes?.map((b) => b.toJson()).toList(),
      'notes': notes,
    };
  }
}

class VariantPricing {
  final double purchasePrice;
  final double salePrice;
  final double? taxRate;

  VariantPricing({
    required this.purchasePrice,
    required this.salePrice,
    this.taxRate,
  });

  factory VariantPricing.fromJson(Map<String, dynamic> json) {
    return VariantPricing(
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      salePrice: (json['salePrice'] as num).toDouble(),
      taxRate: json['taxRate'] != null
          ? (json['taxRate'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'taxRate': taxRate,
    };
  }
}

class VariantStock {
  final String storeId;
  final String? warehouseId;
  final int quantity;

  VariantStock({
    required this.storeId,
    this.warehouseId,
    required this.quantity,
  });

  factory VariantStock.fromJson(Map<String, dynamic> json) {
    return VariantStock(
      storeId: json['storeId'] as String,
      warehouseId: json['warehouseId'] as String?,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'warehouseId': warehouseId,
      'quantity': quantity,
    };
  }
}

class VariantBarcode {
  final String code;
  final String type;
  final bool primary;

  VariantBarcode({
    required this.code,
    required this.type,
    this.primary = false,
  });

  factory VariantBarcode.fromJson(Map<String, dynamic> json) {
    return VariantBarcode(
      code: json['code'] as String,
      type: json['type'] as String,
      primary: json['primary'] as bool? ??
               json['isPrimary'] as bool? ??
               false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type,
      'primary': primary,
    };
  }
}

/// Kullanıcı kararı
class UserProductDecision {
  final ProductImportAction action;

  // Eğer mevcut ürüne ekleniyor/eşleştiriliyor ise
  final String? selectedProductId;
  final String? selectedVariantId;

  // Eğer yeni ürün oluşturuyorsa veya düzenleme yapıldıysa
  final Map<String, dynamic>? customPayload;

  UserProductDecision({
    required this.action,
    this.selectedProductId,
    this.selectedVariantId,
    this.customPayload,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      'selectedProductId': selectedProductId,
      'selectedVariantId': selectedVariantId,
      'customPayload': customPayload,
    };
  }
}

enum ProductImportAction {
  CREATE_NEW,           // Yeni ürün oluştur
  MATCH_EXISTING,       // Mevcut ürünle eşleştir (stok ekle)
  ADD_AS_VARIANT,       // Mevcut ürüne varyant olarak ekle
  SKIP,                 // Bu ürünü atla
  EDIT_AND_CREATE,      // Düzenle ve yeni ürün oluştur
}
