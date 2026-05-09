import 'package:flutter/foundation.dart';
import 'package:project_pos/core/api/api_client.dart';

class AccountService {
  final ApiClient _apiClient;
  static const String _customerBase = 'product/api/v1/customers';
  static const String _statementBase = 'product/api/v1/account-statements';

  AccountService(this._apiClient);

  // ─── Müşteri Cari Hesap ─────────────────────────────────────────

  Future<Map<String, dynamic>?> getCustomerAccount(String customerId) async {
    try {
      final resp = await _apiClient.get('$_customerBase/$customerId/account');
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('getCustomerAccount hata: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerTransactions(String customerId) async {
    try {
      final resp = await _apiClient.get('$_customerBase/$customerId/transactions');
      final data = resp.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getCustomerTransactions hata: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recordCustomerPayment(
      String customerId, Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.post('$_customerBase/$customerId/payment', data: data);
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCustomerCreditLimit(
      String customerId, double newLimit) async {
    try {
      final resp = await _apiClient.put(
        '$_customerBase/$customerId/credit-limit',
        data: {'creditLimit': newLimit},
      );
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Hesap Ekstresi ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAccountStatement({
    required String accountType,
    required String accountId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final resp = await _apiClient.get(
        _statementBase,
        queryParameters: {
          'accountType': accountType,
          'accountId': accountId,
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      rethrow;
    }
  }

  // ─── Vadesi Geçmiş ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOverdueAccounts({String? accountType}) async {
    try {
      final resp = await _apiClient.get(
        '$_statementBase/overdue',
        queryParameters: {
          if (accountType != null) 'accountType': accountType,
        },
      );
      return List<Map<String, dynamic>>.from(resp.data['data'] ?? []);
    } catch (e) {
      debugPrint('getOverdueAccounts hata: $e');
      rethrow;
    }
  }

  // ─── Audit Geçmişi (Sprint 30 — issue P2.6) ─────────────────────

  /// Müşteri veya tedarikçi için kronolojik (en yeni üstte) audit-log listesi.
  /// `accountType` 'CUSTOMER' veya 'SUPPLIER'.
  Future<List<Map<String, dynamic>>> getAuditHistory({
    required String accountType,
    required String accountId,
  }) async {
    try {
      final segment = accountType.toUpperCase() == 'SUPPLIER'
          ? 'supplier'
          : 'customer';
      final resp = await _apiClient.get(
        'product/api/v1/audit/$segment/$accountId',
      );
      final data = resp.data['data'];
      if (data is Map<String, dynamic> && data['items'] is List) {
        return List<Map<String, dynamic>>.from(data['items'] as List);
      }
      return const [];
    } catch (e) {
      debugPrint('getAuditHistory hata: $e');
      rethrow;
    }
  }

  // ─── Reconcile (Admin) ──────────────────────────────────────────

  /// Drift varsa denormalize bakiyeyi ledger'a göre düzeltir.
  /// Backend RBAC: ADMIN role gerekir; 403 frontend'de yetki hatası mesajına döner.
  /// Cevap: { drift: BigDecimal, corrected: bool }
  Future<Map<String, dynamic>> reconcileAccount({
    required String accountType,
    required String accountId,
  }) async {
    final segment =
        accountType.toUpperCase() == 'SUPPLIER' ? 'supplier' : 'customer';
    try {
      final resp = await _apiClient
          .post('product/api/v1/admin/accounts/reconcile/$segment/$accountId');
      final data = resp.data['data'];
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } catch (e) {
      debugPrint('reconcileAccount hata: $e');
      rethrow;
    }
  }

  // ─── Hesap Özeti ────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAccountSummary({String? accountType}) async {
    try {
      final resp = await _apiClient.get(
        '$_statementBase/summary',
        queryParameters: {
          if (accountType != null) 'accountType': accountType,
        },
      );
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('getAccountSummary hata: $e');
      rethrow;
    }
  }
}
