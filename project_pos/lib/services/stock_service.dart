import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

/// Stok servisi -- Stok hareketleri ve yonetimi icin backend API cagrilari.
///
/// Backend endpoint: `product/api/v1/stock-movements`
/// Transfer endpoint: `product/api/v1/stock-transfers`
class StockService {
  final ApiClient _apiClient;

  StockService(this._apiClient);

  /// Stok hareketlerini listeler.
  ///
  /// [productId] ile urun, [movementType] ile hareket tipi (in, out, adjustment, return),
  /// [startDate] ve [endDate] ile tarih araligi filtreleme destekler.
  Future<List<Map<String, dynamic>>> getStockMovements({
    int? productId,
    String? movementType, // in, out, adjustment, return
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (productId != null) queryParams['productId'] = productId;
      if (movementType != null) queryParams['movementType'] = movementType;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('product/api/v1/stock-movements', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('getStockMovements hata: $e');
      rethrow;
    }
  }

  /// Yeni stok hareketi olusturur.
  ///
  /// [data] icerigi: `productId`, `quantity`, `movementType` (in/out/adjustment).
  Future<Map<String, dynamic>> createStockMovement(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('product/api/v1/stock-movements', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Dusuk stoklu urunleri getirir.
  ///
  /// [threshold] ile esik degeri belirlenebilir, varsayilan 10.
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int? threshold,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (threshold != null) queryParams['threshold'] = threshold;

      final response = await _apiClient.get('product/api/v1/stock-movements/low-stock', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('getLowStockProducts hata: $e');
      rethrow;
    }
  }

  /// Stokta olmayan urunleri getirir.
  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    try {
      final response = await _apiClient.get('product/api/v1/stock-movements/out-of-stock');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('getOutOfStockProducts hata: $e');
      rethrow;
    }
  }

  /// Kritik stok seviyesindeki urunleri getirir (stok <= esik).
  Future<List<Map<String, dynamic>>> getCriticalStockProducts() async {
    try {
      final response = await _apiClient.get('product/api/v1/stock-movements/critical');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('getCriticalStockProducts hata: $e');
      rethrow;
    }
  }

  /// Stok duzeltmesi yapar.
  ///
  /// [quantity] yeni stok miktari, [reason] duzeltme nedeni.
  Future<Map<String, dynamic>> adjustStock({
    required String productId,
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post('product/api/v1/stock-movements', data: {
        'productId': productId,
        'quantity': quantity,
        'reason': reason,
        'notes': notes,
      });
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Toplu stok guncelleme yapar.
  ///
  /// [items] her biri `productId` ve `quantity` iceren liste.
  Future<List<Map<String, dynamic>>> bulkStockUpdate(List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiClient.post('product/api/v1/stock-movements/bulk-update', data: {'items': items});
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      rethrow;
    }
  }

  /// Depolar/magazalar arasi stok transferi olusturur.
  Future<Map<String, dynamic>> createTransfer(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('product/api/v1/stock-transfers', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Stok istatistiklerini getirir (toplam, dusuk stok, stok degeri vb.).
  Future<Map<String, dynamic>> getStockStats() async {
    try {
      final response = await _apiClient.get('product/api/v1/stock-movements/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Stok sayimi/denetimi gerceklestirir.
  ///
  /// [items] sayilan urunlerin `productId` ve `quantity` bilgilerini icerir.
  /// Sistem miktari ile sayilan miktar arasindaki farklari raporlar.
  Future<Map<String, dynamic>> performStockCount(List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiClient.post('product/api/v1/stock-movements/count', data: {'items': items});
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
