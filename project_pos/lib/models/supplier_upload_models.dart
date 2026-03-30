import 'package:flutter/material.dart';

/// Backend'den Gelen Veri Yapısı
class SupplierUploadResponse {
  final int productCount;
  final List<ReadProductItem> products;

  SupplierUploadResponse({
    required this.productCount,
    required this.products,
  });

  factory SupplierUploadResponse.fromJson(Map<String, dynamic> json) {
    return SupplierUploadResponse(
      productCount: json['productCount'] as int,
      products: (json['products'] as List<dynamic>)
          .map((p) => ReadProductItem.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Tedarikçiden Okunan Ürün
class ReadProductItem {
  final String readProductName;
  final int readStock;
  final List<SimilarProduct> similarProducts;

  // User decision
  String? selectedAction; // 'ADD_STOCK', 'CREATE_NEW', 'SKIP'
  SimilarProduct? selectedProduct;
  ProductVariant? selectedVariant;
  int? stockToAdd;
  double? updatedPurchasePrice;

  ReadProductItem({
    required this.readProductName,
    required this.readStock,
    required this.similarProducts,
    this.selectedAction,
    this.selectedProduct,
    this.selectedVariant,
    this.stockToAdd,
    this.updatedPurchasePrice,
  });

  factory ReadProductItem.fromJson(Map<String, dynamic> json) {
    return ReadProductItem(
      readProductName: json['readProductName'] as String,
      readStock: json['readStock'] as int,
      similarProducts: (json['similarProducts'] as List<dynamic>)
          .map((p) => SimilarProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasDecision => selectedAction != null;
  bool get isNewProduct => similarProducts.isEmpty;
}

/// Sistemde Bulunan Benzer Ürün
class SimilarProduct {
  final String sku;
  final String name;
  final String slug;
  final String categoryId;
  final String brand;
  final String unit;
  final String description;
  final List<ProductVariant> variants;

  SimilarProduct({
    required this.sku,
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.brand,
    required this.unit,
    required this.description,
    required this.variants,
  });

  factory SimilarProduct.fromJson(Map<String, dynamic> json) {
    return SimilarProduct(
      sku: json['sku'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      description: json['description'] as String? ?? '',
      variants: (json['variants'] as List<dynamic>)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  String get displayName => '$name - $sku ($brand)';
}

/// Ürün Varyantı
class ProductVariant {
  final String sku;
  final String name;
  final Map<String, dynamic> attributes;
  final VariantPricing pricing;
  final List<InitialStock> initialStocks;
  final List<Barcode> barcodes;
  final String? notes;

  ProductVariant({
    required this.sku,
    required this.name,
    required this.attributes,
    required this.pricing,
    required this.initialStocks,
    required this.barcodes,
    this.notes,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      sku: json['sku'] as String,
      name: json['name'] as String,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      pricing: VariantPricing.fromJson(json['pricing'] as Map<String, dynamic>),
      initialStocks: (json['initialStocks'] as List<dynamic>)
          .map((s) => InitialStock.fromJson(s as Map<String, dynamic>))
          .toList(),
      barcodes: (json['barcodes'] as List<dynamic>)
          .map((b) => Barcode.fromJson(b as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  String get attributesText {
    return attributes.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  String? get primaryBarcode {
    final primary = barcodes.where((b) => b.isPrimary).firstOrNull;
    return primary?.code ?? barcodes.firstOrNull?.code;
  }

  int get totalStock {
    return initialStocks.fold(0, (sum, stock) => sum + stock.quantity);
  }
}

class VariantPricing {
  final double purchasePrice;
  final double salePrice;

  VariantPricing({
    required this.purchasePrice,
    required this.salePrice,
  });

  factory VariantPricing.fromJson(Map<String, dynamic> json) {
    return VariantPricing(
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      salePrice: (json['salePrice'] as num).toDouble(),
    );
  }
}

class InitialStock {
  final String storeId;
  final String warehouseId;
  final int quantity;

  InitialStock({
    required this.storeId,
    required this.warehouseId,
    required this.quantity,
  });

  factory InitialStock.fromJson(Map<String, dynamic> json) {
    return InitialStock(
      storeId: json['storeId'] as String,
      warehouseId: json['warehouseId'] as String,
      quantity: json['quantity'] as int,
    );
  }
}

class Barcode {
  final String code;
  final String type;
  final bool isPrimary;

  Barcode({
    required this.code,
    required this.type,
    this.isPrimary = false,
  });

  factory Barcode.fromJson(Map<String, dynamic> json) {
    return Barcode(
      code: json['code'] as String,
      type: json['type'] as String? ?? 'EAN13',
      isPrimary: json['isPrimary'] as bool? ?? json['primary'] as bool? ?? false,
    );
  }
}

// Extension for Iterable
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
