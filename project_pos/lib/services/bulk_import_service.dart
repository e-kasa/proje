import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';

/// Bulk Import Service - Backend API entegrasyonu
///
/// Backend akışı:
/// 1. POST /bulk-import/upload       → Dosya yükle (sektör bilgisiyle)
/// 2. GET  /bulk-import/analyze/{id} → Analiz sonucu al
/// 3. POST /bulk-import/save         → Kararları kaydet
/// 4. GET  /bulk-import/template/{sector} → Sektöre özel şablon indir
class BulkImportService {
  final ApiClient _apiClient;

  BulkImportService(this._apiClient);

  /// 1. Dosyayı backend'e yükle (multipart/form-data)
  ///
  /// [sector]: parcaci / giyim / genel — Backend hangi kolonları beklediğini bilir
  Future<String> uploadFile(File file, {String sector = 'genel'}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
        'sector': sector,
      });

      final response = await _apiClient.post(
        'bulk-import/upload',
        data: formData,
      );

      return response.data['data']['importId'] as String;
    } catch (e) {
      throw Exception('Dosya yüklenemedi: ${_extractError(e)}');
    }
  }

  /// 2. Analiz sonucunu al
  ///
  /// Backend döner:
  /// - YENI ürünler (sistemde yok)
  /// - ÇAKIŞAN ürünler (SKU/Barcode var ama fiyat farklı)
  /// - MEVCUT ürünler (birebir aynı)
  /// - BENZER ürünler (isim benzerliği)
  Future<Map<String, dynamic>> getAnalysisResult(String importId) async {
    try {
      final response = await _apiClient.get(
        'bulk-import/analyze/$importId',
      );

      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Analiz sonucu alınamadı: ${_extractError(e)}');
    }
  }

  /// 3. Kararları backend'e gönder ve kaydet
  ///
  /// [products] listesi CreateProductRequest yapısında olmalıdır:
  /// ```json
  /// {
  ///   "product": { "sku", "name", "categoryId", "brand", "unit", "sector", "metadata" },
  ///   "variants": [{ "sku", "name", "pricing", "initialStocks", "barcodes" }],
  ///   "oemNumbers": [{ "oemNumber", "manufacturer", "isPrimary" }],
  ///   "crossReferences": [{ "crossRefNumber", "crossRefBrand", "notes" }],
  ///   "purchase": { "supplierId", "invoiceNumber", "purchaseDate" }
  /// }
  /// ```
  Future<BulkSaveResult> saveDecisions({
    required String importId,
    required List<Map<String, dynamic>> products,
    String? sector,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      final response = await _apiClient.post(
        'bulk-import/save',
        data: {
          'importId': importId,
          'sector': sector,
          'products': products,
        },
      );

      return BulkSaveResult.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Kayıt başarısız: ${_extractError(e)}');
    }
  }

  /// 4. Sektöre özel Excel şablonu indir
  Future<void> downloadTemplate(String sector) async {
    try {
      await _apiClient.get(
        'bulk-import/template/$sector',
        // options: Options(responseType: ResponseType.bytes),
      );
      // TODO: Save file to downloads directory
    } catch (e) {
      throw Exception('Şablon indirilemedi: ${_extractError(e)}');
    }
  }

  /// Polling ile analiz durumunu kontrol et
  ///
  /// Backend dosyayı async işliyorsa kullanılır
  Future<Map<String, dynamic>> waitForAnalysis({
    required String importId,
    Duration pollInterval = const Duration(seconds: 2),
    int maxAttempts = 30,
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final result = await getAnalysisResult(importId);
        if (result['status'] == 'COMPLETED') {
          return result;
        }
      } catch (e) {
        // Henüz hazır değil, tekrar dene
      }

      await Future.delayed(pollInterval);
    }

    throw Exception('Analiz zaman aşımına uğradı (${maxAttempts * pollInterval.inSeconds}s)');
  }

  /// Hata mesajı çıkarma
  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message']?.toString() ?? e.message ?? e.toString();
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }
}

/// Bulk save sonucu
class BulkSaveResult {
  final List<Map<String, dynamic>> success;
  final List<Map<String, dynamic>> errors;
  final Map<String, dynamic> summary;

  BulkSaveResult({
    required this.success,
    required this.errors,
    required this.summary,
  });

  factory BulkSaveResult.fromJson(Map<String, dynamic> json) {
    return BulkSaveResult(
      success: List<Map<String, dynamic>>.from(json['success'] ?? []),
      errors: List<Map<String, dynamic>>.from(json['errors'] ?? []),
      summary: Map<String, dynamic>.from(json['summary'] ?? {}),
    );
  }

  int get totalCreated => summary['created'] ?? 0;
  int get totalUpdated => summary['updated'] ?? 0;
  int get totalMatched => summary['matched'] ?? 0;
  int get totalFailed => summary['failed'] ?? 0;
  int get totalProcessed => totalCreated + totalUpdated + totalMatched;

  bool get hasErrors => errors.isNotEmpty || totalFailed > 0;
  bool get isSuccess => !hasErrors && totalProcessed > 0;
}
