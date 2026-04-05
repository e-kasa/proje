import '../core/api/api_client.dart';
import '../core/utils/app_logger.dart';

class UserService {
  final ApiClient _apiClient;
  static const String _base = 'security/api/v1/users';
  static const String _rolesBase = 'security/api/v1/roles';
  static const String _companyBase = 'product/api/v1/company/settings';

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
          if (role != null) 'role': role,
          if (isActive != null) 'isActive': isActive,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
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

  Future<Map<String, dynamic>> toggleUserStatus(String id) async {
    try {
      final resp = await _apiClient.patch('$_base/$id/toggle-status');
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Kullanici durumu degistirilemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Roller ────────────────────────────────────────────────────

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

  // ─── Rol Ata ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> assignRole(String userId, String roleId) async {
    try {
      final resp = await _apiClient.post(
        '$_base/$userId/roles',
        data: {'roleId': roleId},
      );
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Rol atanamadi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ─── Firma Ayarlari ────────────────────────────────────────────

  Future<Map<String, dynamic>> getCompanySettings() async {
    try {
      final resp = await _apiClient.get(_companyBase);
      final data = resp.data['data'];
      return data is Map<String, dynamic> ? data : {};
    } catch (e, st) {
      AppLogger.error('Firma ayarlari yuklenemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCompanySettings(Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.put(_companyBase, data: data);
      return resp.data['data'] as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Firma ayarlari guncellenemedi', tag: 'UserService', error: e, stackTrace: st);
      rethrow;
    }
  }
}
