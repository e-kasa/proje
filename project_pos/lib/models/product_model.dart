import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    String? description,
    required double price,
    double? costPrice,
    String? sku,
    String? barcode,
    int? quantity,
    int? minStock,
    String? category,
    String? brand,
    String? unit,
    List<String>? images,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
