import 'dart:io';
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

  /// PDF dosyasını yükler, ürün kalemlerini analiz eder.
  /// Dönen liste her belge satırı için [DocumentAnalyzeItem] içerir.
  Future<DocumentAnalyzeResult> analyzeDocument(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await _apiClient.post(
        'product/api/v1/document/analyze',
        data: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return DocumentAnalyzeResult.fromJson(data);
    } catch (e) {
      debugPrint('DocumentAnalyzeService.analyzeDocument hata: $e');
      rethrow;
    }
  }
}

// ── MODELLER ──────────────────────────────────────────────────────────────────

class DocumentAnalyzeResult {
  final String fileName;
  final int totalItems;
  final int foundItems;
  final int notFoundItems;
  final List<DocumentAnalyzeItem> items;

  const DocumentAnalyzeResult({
    required this.fileName,
    required this.totalItems,
    required this.foundItems,
    required this.notFoundItems,
    required this.items,
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
  });

  bool get isFound => matchStatus == 'FOUND';

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
    );
  }
}
