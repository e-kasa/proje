import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';

/// Satis servisi -- Satis islemleri icin backend API cagrilari yonetir.
///
/// Backend endpoint: `product/api/v1/sales`
class SalesService {
  final ApiClient _apiClient;

  SalesService(this._apiClient);

  static const String _base = 'product/api/v1/sales';

  /// Satislari listeler.
  ///
  /// [startDate], [endDate] ile tarih araligi, [customerId] ile musteri,
  /// [paymentMethod] ile odeme yontemi, [paymentStatus] ile durum filtreleme destekler.
  Future<List<Map<String, dynamic>>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
    String? paymentMethod, // cash, credit_card, debit_card, bank_transfer
    String? paymentStatus, // paid, pending, cancelled
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (customerId != null) queryParams['customerId'] = customerId;
      if (paymentMethod != null) queryParams['paymentMethod'] = paymentMethod;
      if (paymentStatus != null) queryParams['paymentStatus'] = paymentStatus;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(_base, queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('getSales hata: $e');
      rethrow;
    }
  }

  /// Bir musterinin acik bakiyeli satislarini getirir (Sprint 7 — alisveris bazli odeme).
  ///
  /// Backend [GET /api/v1/sales?customerId=X] sonucunu `status=pending` ile filtreler;
  /// veriler `saleDate` desc sirali doner (yeniden eskiye).
  ///
  /// Sprint 11: opsiyonel [vehiclePlate] parametresi backend `?vehiclePlate=` filter'ina
  /// gider — sadece o plakaya ait satislari doner (parcaci sektor plate-based tahsilat).
  /// null/bos plate → tum acik satislar (Sprint 7 davranisi korunur).
  ///
  /// Mevcut [getSales] `int? customerId` signature ile uyumsuz oldugu icin ayri metod.
  Future<List<Map<String, dynamic>>> getCustomerOpenSales(
    String customerId, {
    String? vehiclePlate,
  }) async {
    try {
      final params = <String, dynamic>{
        'customerId': customerId,
        'isCancelled': false,
      };
      if (vehiclePlate != null && vehiclePlate.isNotEmpty) {
        params['vehiclePlate'] = vehiclePlate;
      }
      final response = await _apiClient.get(_base, queryParameters: params);
      final all = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      // status=pending — backend SaleControllerImpl.toMap() hesaplar (remainingAmount > 0)
      final open = all.where((s) => s['status'] == 'pending').toList();
      // En yeni once
      open.sort((a, b) {
        final da = DateTime.tryParse(a['saleDate']?.toString() ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['saleDate']?.toString() ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });
      return open;
    } catch (e) {
      debugPrint('getCustomerOpenSales hata: $e');
      rethrow;
    }
  }

  /// Tek bir satisi ID ile getirir.
  Future<Map<String, dynamic>> getSaleById(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('getSaleById hata: $e');
      rethrow;
    }
  }

  /// Yeni satis olusturur (POS ekranindan).
  ///
  /// [data] satis kalemleri, musteri bilgisi ve odeme detaylarini icerir.
  Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Mevcut satisi gunceller.
  Future<Map<String, dynamic>> updateSale(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Satisi iptal eder.
  ///
  /// [reason] iptal nedenini belirtir.
  Future<Map<String, dynamic>> cancelSale(String id, String reason) async {
    try {
      final response = await _apiClient.patch('$_base/$id/cancel', data: {'reason': reason});
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Satis kalemlerini getirir.
  Future<List<Map<String, dynamic>>> getSaleItems(String saleId) async {
    try {
      final response = await _apiClient.get('$_base/$saleId/items');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('getSaleItems hata: $e');
      rethrow;
    }
  }

  /// Satis istatistiklerini getirir.
  ///
  /// [startDate] ve [endDate] ile tarih araligi filtreleme destekler.
  Future<Map<String, dynamic>> getSalesStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get('$_base/stats', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Gunluk satis raporunu getirir.
  Future<List<Map<String, dynamic>>> getDailySalesReport({
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date.toIso8601String();

      final response = await _apiClient.get('$_base/daily-report', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      debugPrint('getDailySalesReport hata: $e');
      rethrow;
    }
  }

  /// Satis iadesi olusturur.
  ///
  /// [data] iade kalemleri ve nedenini icerir.
  Future<Map<String, dynamic>> createSaleReturn(String saleId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('$_base/$saleId/returns', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Satis fisini yazdirir.
  Future<Map<String, dynamic>> printReceipt(String saleId) async {
    try {
      final response = await _apiClient.post('$_base/$saleId/print');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
