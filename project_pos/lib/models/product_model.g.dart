// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      minStock: (json['minStock'] as num?)?.toInt(),
      category: json['category'] as String?,
      brand: json['brand'] as String?,
      unit: json['unit'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'costPrice': instance.costPrice,
      'sku': instance.sku,
      'barcode': instance.barcode,
      'quantity': instance.quantity,
      'minStock': instance.minStock,
      'category': instance.category,
      'brand': instance.brand,
      'unit': instance.unit,
      'images': instance.images,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
