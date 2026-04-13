import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/core/utils/app_logger.dart';

class UserService {
  final ApiClient _apiClient;

  // Backend endpoint'leri: security/api/users (v1 değil)
  static const String _base      = 'security/api/users';
  static const String _rolesBase = 'security/api/users/available-roles';

  UserService(this._apiClient);

  // ─── Kullanici Listesi ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUsers({
    String? search,
    String? role,
    bool? isActive,
    int? page,
    int? limit,
  }) async {
    try {
      final resp = await _apiClient.get(
        _base,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'role':     role,
          'isActive': isActive,
          'page':     page,
          'limit':    limit,
        }..removeWhere((_, v) => v == null),
      );
      final data = resp.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e, st) {
      AppLogger.error('Kullanicilar yuklenemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Kullanici Detay ───────────────────────────────────────────

  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final resp = await _apiClient.get('$_base/$id');
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Kullanici detay yuklenemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Kullanici Olustur ─────────────────────────────────────────
  // data: { userName, displayName, password, languageVal, storeId, roles: [code] }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.post(_base, data: data);
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Kullanici olusturulamadi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Kullanici Guncelle ────────────────────────────────────────
  // data: { displayName, languageVal, storeId, userType }

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.put('$_base/$id', data: data);
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Kullanici guncellenemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Kullanici Durum Degistir ──────────────────────────────────

  Future<void> toggleUserStatus(String id) async {
    try {
      await _apiClient.patch('$_base/$id/toggle-status');
    } catch (e, st) {
      AppLogger.error('Kullanici durumu degistirilemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Rol Ata ───────────────────────────────────────────────────
  // Backend AssignRoleRequest: { roleCode: "CASHIER" }

  Future<void> assignRole(String userId, String roleCode) async {
    try {
      await _apiClient.post(
        '$_base/$userId/roles',
        data: {'roleCode': roleCode},
      );
    } catch (e, st) {
      AppLogger.error('Rol atanamadi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Rol Kaldir ────────────────────────────────────────────────

  Future<void> removeRole(String userId, String roleCode) async {
    try {
      await _apiClient.delete('$_base/$userId/roles/$roleCode');
    } catch (e, st) {
      AppLogger.error('Rol kaldirillamadi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Sifre Sifirla (Admin) ─────────────────────────────────────

  Future<void> resetPassword(String userId, String newPassword) async {
    try {
      await _apiClient.post(
        '$_base/$userId/reset-password',
        data: {'newPassword': newPassword},
      );
    } catch (e, st) {
      AppLogger.error('Sifre sifirlanamadi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Firma Rolleri (Dropdown için) ────────────────────────────
  // Dönen alanlar: { id, code, name, description, isActive }

  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final resp = await _apiClient.get(_rolesBase);
      final data = resp.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e, st) {
      AppLogger.error('Roller yuklenemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Firma Ayarlari ────────────────────────────────────────────

  Future<Map<String, dynamic>> getCompanySettings() async {
    try {
      final resp = await _apiClient.get('product/api/v1/company/settings');
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : {};
    } catch (e, st) {
      AppLogger.error('Firma ayarlari yuklenemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCompanySettings(Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.put('product/api/v1/company/settings', data: data);
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Firma ayarlari guncellenemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }
}
