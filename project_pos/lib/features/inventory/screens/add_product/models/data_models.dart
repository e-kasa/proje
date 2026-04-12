import 'package:flutter/material.dart';

// ─── Data Models ─────────────────────────────────────────────────────────────

class ProductAttribute {
  String name;
  IconData icon;
  List<String> values;

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
  List<String> images;

  ProductVariant({
    required this.sku,
    required this.name,
    required this.attributes,
    required this.purchasePrice,
    required this.salePrice,
    this.inventory,
    required this.barcodes,
    required this.notes,
    this.images = const [],
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
