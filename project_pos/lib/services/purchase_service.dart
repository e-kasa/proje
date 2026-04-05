import '../core/api/api_client.dart';

/// Satın alma servisi — Satın alma işlemleri için backend API çağrıları.
///
/// Backend endpoint: `product/api/v1/purchases`
/// Fatura oluşturma, iptal, iade ve istatistik endpoint'lerini kapsar.
class PurchaseService {
  final ApiClient _apiClient;

  static const String _base = 'product/api/v1/purchases';

  PurchaseService(this._apiClient);

  /// Satın alma listesini getirir.
  /// [supplierId] verilirse sadece o tedarikçinin alımları gelir.
  /// [isCancelled] ile iptal filtresi uygulanabilir.
  Future<List<Map<String, dynamic>>> getPurchases({
    String? supplierId,
    bool? isCancelled,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (supplierId != null) params['supplierId'] = supplierId;
      if (isCancelled != null) params['isCancelled'] = isCancelled.toString();

      final response = await _apiClient.get(_base, queryParameters: params);
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      throw Exception('Satın alma listesi alınamadı: $e');
    }
  }

  /// Tek bir satın alma kaydını getirir.
  Future<Map<String, dynamic>> getPurchaseById(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Satın alma bulunamadı: $e');
    }
  }

  /// Yeni satın alma oluşturur.
  /// [request] içeriği:
  ///   - supplierId (String, zorunlu)
  ///   - invoiceNumber (String, zorunlu)
  ///   - purchaseDate (String ISO — 'yyyy-MM-dd', zorunlu)
  ///   - storeId (String, zorunlu)
  ///   - warehouseId (String, zorunlu)
  ///   - items: [{ variantId, quantity, unitPrice }]
  ///   - notes (String, opsiyonel)
  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> request) async {
    try {
      final response = await _apiClient.post(_base, data: request);
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Satın alma oluşturulamadı: $e');
    }
  }

  /// Satın alma günceller (belge bilgileri, notlar).
  Future<Map<String, dynamic>> updatePurchase(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Satın alma güncellenemedi: $e');
    }
  }

  /// Satın almayı iptal eder.
  Future<Map<String, dynamic>> cancelPurchase(String id) async {
    try {
      final response = await _apiClient.patch('$_base/$id/cancel');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Satın alma iptal edilemedi: $e');
    }
  }

  /// Satın alma iadesi oluşturur.
  /// [data] içeriği:
  ///   - items: [{ productId, variantId, quantity, unitPrice, reason }]
  ///   - reason (String — genel iade nedeni)
  ///   - notes (String, opsiyonel)
  Future<Map<String, dynamic>> createPurchaseReturn(String purchaseId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('$_base/$purchaseId/returns', data: data);
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Satın alma iadesi oluşturulamadı: $e');
    }
  }

  /// İstatistikler: totalPurchases, activePurchases, cancelledPurchases,
  /// totalSpent, totalDebt
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.get('$_base/stats');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      return {};
    }
  }
}
