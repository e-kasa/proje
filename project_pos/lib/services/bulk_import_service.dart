import 'dart:io';
import '../core/api/api_client.dart';
import '../models/bulk_import_models.dart';

/// Bulk Import Service - Backend API entegrasyonu
///
/// Backend akışı:
/// 1. POST /bulk-import/upload → Dosya yükle
/// 2. GET /bulk-import/analyze/{id} → Analiz sonucu al
/// 3. POST /bulk-import/save → Kararları kaydet
class BulkImportService {
  final ApiClient _apiClient;

  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = true;

  BulkImportService(this._apiClient);

  /// 1. Tedarikçi dosyasını backend'e yükle (Excel/CSV)
  ///
  /// Backend dosyayı okur, analiz eder ve import ID döner
  Future<String> uploadFile(File file) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return 'IMPORT-${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      // FormData ile dosya gönderimi (multipart/form-data)
      final response = await _apiClient.post(
        'bulk-import/upload',
        data: {
          'file': file,
        },
      );

      return response.data['data']['importId'] as String;
    } catch (e) {
      throw Exception('Dosya yüklenemedi: ${e.toString()}');
    }
  }

  /// 2. Analiz sonucunu al
  ///
  /// Backend şunları döner:
  /// - YENİ ürünler (sistemde yok)
  /// - ÇAKIŞAN ürünler (SKU/Barcode var ama fiyat farklı)
  /// - MEVCUT ürünler (birebir aynı)
  /// - BENZER ürünler (isim benzerliği)
  Future<Map<String, dynamic>> getAnalysisResult(String importId) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      // Mock data döner (şu anki MockAnalyzedProducts kullanılıyor)
      throw UnimplementedError('Mock data başka yerden geliyor');
    }

    try {
      final response = await _apiClient.get(
        'bulk-import/analyze/$importId',
      );

      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Analiz sonucu alınamadı: ${e.toString()}');
    }
  }

  /// 3. Kararları backend'e gönder ve kaydet
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
    if (useMockData) {
      // Mock simülasyonu (ProductService.bulkSaveProducts kullanıyor)
      final results = <String, dynamic>{
        'success': <Map<String, dynamic>>[],
        'errors': <Map<String, dynamic>>[],
        'summary': {
          'total': products.length,
          'created': 0,
          'updated': 0,
          'matched': 0,
          'skipped': 0,
          'failed': 0,
        },
      };

      for (var i = 0; i < products.length; i++) {
        onProgress?.call(i + 1, products.length);
        await Future.delayed(const Duration(milliseconds: 200));

        final payload = products[i];
        final action = payload['action'] as String?;

        try {
          switch (action) {
            case 'CREATE':
              results['success'].add({
                'tempId': payload['tempId'],
                'productId': 'PROD-${DateTime.now().millisecondsSinceEpoch + i}',
                'action': 'CREATE',
              });
              results['summary']['created']++;
              break;

            case 'UPDATE_STOCK':
            case 'UPDATE_PRICE':
            case 'UPDATE_BOTH':
              results['success'].add({
                'tempId': payload['tempId'],
                'productId': payload['productId'],
                'action': action,
              });
              results['summary']['updated']++;
              break;

            case 'MATCH':
              results['success'].add({
                'tempId': payload['tempId'],
                'productId': payload['productId'],
                'action': 'MATCH',
              });
              results['summary']['matched']++;
              break;

            default:
              results['summary']['skipped']++;
          }
        } catch (e) {
          results['errors'].add({
            'tempId': payload['tempId'],
            'error': e.toString(),
          });
          results['summary']['failed']++;
        }
      }

      return BulkSaveResult.fromJson(results);
    }

    // Real API call
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
      throw Exception('Kayıt başarısız: ${e.toString()}');
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

    throw Exception('Analiz zaman aşımına uğradı');
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
