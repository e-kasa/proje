import 'dart:io';
import '../core/api/api_client.dart';
import '../models/bulk_import_models.dart';

/// Bulk Import Service - Backend API entegrasyonu
///
/// Backend akisi:
/// 1. POST /bulk-import/upload -> Dosya yukle
/// 2. GET /bulk-import/analyze/{id} -> Analiz sonucu al
/// 3. POST /bulk-import/save -> Kararlari kaydet
class BulkImportService {
  final ApiClient _apiClient;

  BulkImportService(this._apiClient);

  /// 1. Tedarikci dosyasini backend'e yukle (Excel/CSV)
  ///
  /// Backend dosyayi okur, analiz eder ve import ID doner
  Future<String> uploadFile(File file) async {
    try {
      // FormData ile dosya gonderimi (multipart/form-data)
      final response = await _apiClient.post(
        'bulk-import/upload',
        data: {
          'file': file,
        },
      );

      return response.data['data']['importId'] as String;
    } catch (e) {
      throw Exception('Dosya yuklenemedi: ${e.toString()}');
    }
  }

  /// 2. Analiz sonucunu al
  ///
  /// Backend sunlari doner:
  /// - YENI urunler (sistemde yok)
  /// - CAKISAN urunler (SKU/Barcode var ama fiyat farkli)
  /// - MEVCUT urunler (birebir ayni)
  /// - BENZER urunler (isim benzerligi)
  Future<Map<String, dynamic>> getAnalysisResult(String importId) async {
    try {
      final response = await _apiClient.get(
        'bulk-import/analyze/$importId',
      );

      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Analiz sonucu alinamadi: ${e.toString()}');
    }
  }

  /// 3. Kararlari backend'e gonder ve kaydet
  ///
  /// Format:
  /// ```json
  /// [
  ///   {
  ///     "product": {...},
  ///     "variants": [{...}],
  ///     "purchase": {...}
  ///   }
  /// ]
  /// ```
  Future<BulkSaveResult> saveDecisions({
    required String importId,
    required List<Map<String, dynamic>> products,
    void Function(int current, int total)? onProgress,
  }) async {
    try {
      final response = await _apiClient.post(
        'bulk-import/save',
        data: {
          'importId': importId,
          'products': products,
        },
      );

      return BulkSaveResult.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Kayit basarisiz: ${e.toString()}');
    }
  }

  /// Polling ile analiz durumunu kontrol et
  ///
  /// Backend dosyayi async isliyorsa kullanilir
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
        // Henuz hazir degil, tekrar dene
      }

      await Future.delayed(pollInterval);
    }

    throw Exception('Analiz zaman asimina ugradi');
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
