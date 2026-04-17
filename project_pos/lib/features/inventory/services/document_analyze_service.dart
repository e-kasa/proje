import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';

/// Fatura / İrsaliye PDF analiz servisi.
///
/// Backend: POST /product/api/v1/document/analyze (multipart)
/// Yanıt: Her satır için matchStatus (FOUND / NOT_FOUND) + eşleşen ürün bilgisi
class DocumentAnalyzeService {
  final ApiClient _apiClient;
  DocumentAnalyzeService(this._apiClient);

  /// Bytes + dosya adı ile belge analizi yapar (web + native ortak yol).
  Future<DocumentAnalyzeResult> analyzeDocumentFromBytes(
      Uint8List bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _apiClient.post(
        'product/api/v1/document/analyze',
        data: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return DocumentAnalyzeResult.fromJson(data);
    } catch (e) {
      debugPrint('DocumentAnalyzeService.analyzeDocumentFromBytes hata: $e');
      rethrow;
    }
  }

  /// Native için eski File-tabanlı yol (backward compat).
  Future<DocumentAnalyzeResult> analyzeDocument(File file) async {
    final bytes = await file.readAsBytes();
    final filename = file.path.split(Platform.pathSeparator).last;
    return analyzeDocumentFromBytes(bytes, filename);
  }
}

// ── MODELLER ──────────────────────────────────────────────────────────────────

class DocumentAnalyzeResult {
  final String fileName;
  final int totalItems;
  final int foundItems;
  final int notFoundItems;
  final List<DocumentAnalyzeItem> items;

  /// true → belge taranmış görüntüydü, Python OCR ile işlendi.
  final bool scannedPdf;

  /// Parse yöntemi: "POSITIONAL" | "REGEX" | "OCR"
  final String? parseMethod;

  const DocumentAnalyzeResult({
    required this.fileName,
    required this.totalItems,
    required this.foundItems,
    required this.notFoundItems,
    required this.items,
    this.scannedPdf = false,
    this.parseMethod,
  });

  factory DocumentAnalyzeResult.fromJson(Map<String, dynamic> json) {
    return DocumentAnalyzeResult(
      fileName: json['fileName'] as String? ?? '',
      totalItems: json['totalItems'] as int? ?? 0,
      foundItems: json['foundItems'] as int? ?? 0,
      notFoundItems: json['notFoundItems'] as int? ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => DocumentAnalyzeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      scannedPdf: json['scannedPdf'] as bool? ?? false,
      parseMethod: json['parseMethod'] as String?,
    );
  }
}

// ── VARYANT KALEMİ ──────────────────────────────────────────────────────────

/// Tek bir beden/renk/numara kombinasyonu (Durum 2 — her varyant ayrı satır)
class DocumentVariantItem {
  /// "XL", "Siyah", "42" vb.
  final String attributeValue;

  /// "SIZE" | "COLOR" | "OTHER"
  final String attributeType;

  final double? quantity;

  /// null → ana satırdan miras alınır
  final double? unitPrice;

  final String? barcode;
  final String? rawText;

  const DocumentVariantItem({
    required this.attributeValue,
    required this.attributeType,
    this.quantity,
    this.unitPrice,
    this.barcode,
    this.rawText,
  });

  factory DocumentVariantItem.fromJson(Map<String, dynamic> json) {
    return DocumentVariantItem(
      attributeValue: json['attributeValue'] as String? ?? '',
      attributeType: json['attributeType'] as String? ?? 'OTHER',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      barcode: json['barcode'] as String?,
      rawText: json['rawText'] as String?,
    );
  }
}

class DocumentAnalyzeItem {
  final int rowIndex;
  final String rawText;
  final String? extractedName;
  final String? extractedCode;
  final double? extractedQuantity;
  final double? extractedUnitPrice;
  final String matchStatus; // FOUND | NOT_FOUND
  final String? matchedProductId;
  final String? matchedVariantId;
  final String? matchedProductName;
  final String? matchedSku;
  final String? matchType; // BARCODE | OEM | NAME

  // ── Sprint 1 ekleme: birim + KDV + toplam ──
  final String? unit;        // "ADET" | "KG" | "LT" | null
  final double? vatRate;     // 8.0 | 18.0 | 20.0 | null
  final bool? vatIncluded;   // KDV dahil mi? null = bilinmiyor
  final double? totalPrice;  // satır toplamı | null

  // ── Sprint 1 ekleme: eşleşme güveni + uyarı bayrakları ──
  final double? matchConfidence;       // BARCODE=1.0, OEM=0.9, NAME=0.5, NOT_FOUND=0.0
  final List<String> warningFlags;     // NAME_MATCH_UNCERTAIN | PRICE_MISMATCH | NO_PRICE | DUPLICATE_MERGED | VARIANT_GROUP | OCR_PROCESSED

  // ── Varyant grup alanları ──────────────────────────────────────────────────
  /// true → bu satır birden fazla varyantın gruplanmış hali (Durum 2)
  final bool variantGroup;

  /// Varyant alt satırları — yalnızca variantGroup=true ise dolu
  final List<DocumentVariantItem> variants;

  const DocumentAnalyzeItem({
    required this.rowIndex,
    required this.rawText,
    this.extractedName,
    this.extractedCode,
    this.extractedQuantity,
    this.extractedUnitPrice,
    required this.matchStatus,
    this.matchedProductId,
    this.matchedVariantId,
    this.matchedProductName,
    this.matchedSku,
    this.matchType,
    this.unit,
    this.vatRate,
    this.vatIncluded,
    this.totalPrice,
    this.matchConfidence,
    this.warningFlags = const [],
    this.variantGroup = false,
    this.variants = const [],
  });

  bool get isFound        => matchStatus == 'FOUND';
  bool get isOcrProcessed => warningFlags.contains('OCR_PROCESSED');

  bool get isNameMatch       => matchType == 'NAME';
  bool get hasPriceMismatch  => warningFlags.contains('PRICE_MISMATCH');
  bool get isDuplicateMerged => warningFlags.contains('DUPLICATE_MERGED');
  bool get hasNoPrice        => warningFlags.contains('NO_PRICE');
  bool get isHighConfidence  => (matchConfidence ?? 0) >= 0.9;
  bool get isLowConfidence   => isFound && (matchConfidence ?? 0) < 0.6;

  factory DocumentAnalyzeItem.fromJson(Map<String, dynamic> json) {
    return DocumentAnalyzeItem(
      rowIndex: json['rowIndex'] as int? ?? 0,
      rawText: json['rawText'] as String? ?? '',
      extractedName: json['extractedName'] as String?,
      extractedCode: json['extractedCode'] as String?,
      extractedQuantity: (json['extractedQuantity'] as num?)?.toDouble(),
      extractedUnitPrice: (json['extractedUnitPrice'] as num?)?.toDouble(),
      matchStatus: json['matchStatus'] as String? ?? 'NOT_FOUND',
      matchedProductId: json['matchedProductId'] as String?,
      matchedVariantId: json['matchedVariantId'] as String?,
      matchedProductName: json['matchedProductName'] as String?,
      matchedSku: json['matchedSku'] as String?,
      matchType: json['matchType'] as String?,
      unit: json['unit'] as String?,
      vatRate: (json['vatRate'] as num?)?.toDouble(),
      vatIncluded: json['vatIncluded'] as bool?,
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble(),
      warningFlags: List<String>.from(json['warningFlags'] ?? []),
      variantGroup: json['variantGroup'] as bool? ?? false,
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((e) => DocumentVariantItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
