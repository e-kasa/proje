import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/auth_events.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';

/// Kimlik doğrulama durum yöneticisi.
///
/// JWT tabanlı login/logout, token saklama ([SharedPreferences]) ve
/// otomatik oturum kontrolü sağlar. [ApiClient] 401 döndüğünde
/// [AuthEvents] üzerinden logout tetiklenir ve router `/login`'e yönlendirir.
/// JWT payload'undan kullanıcı bilgileri (`sessionInstance`) decode edilir.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  late final StreamSubscription<void> _unauthorizedSub;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    _checkAuthAsync();
    // ApiClient 401 alıp token yenilenemezse → logout (router /login'e yönlendirir)
    _unauthorizedSub = AuthEvents.onUnauthorized.listen((_) => logout());
  }

  @override
  void dispose() {
    _unauthorizedSub.cancel();
    super.dispose();
  }

  void _checkAuthAsync() {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        final userJson = prefs.getString(AppConstants.userKey);
        final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
        final sessionId = prefs.getString('session_id');

        if (token != null && userJson != null) {
          final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
          state = state.copyWith(
            user: user,
            token: token,
            refreshToken: refreshToken,
            sessionId: sessionId,
            isAuthenticated: true,
          );
        }
      } catch (e) {
        AppLogger.error('Auth check error', tag: 'Auth', error: e);
      }
    });
  }

  /// Kullanıcı girişi yapar. Token ve kullanıcı bilgilerini saklar.
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.login(username, password);

      final status = response['status'] as int? ?? 0;
      if (status != 200) {
        final messages = response['messages'];
        throw Exception(messages?.toString() ?? 'Giriş başarısız');
      }

      final payload = response['payload'] as Map<String, dynamic>;
      final accessToken = payload['accessToken'] as String;
      final refreshToken = payload['refreshToken'] as String;
      final sessionId = payload['sessionId'] as String;

      final user = _decodeUserFromJwt(accessToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
      await prefs.setString('session_id', sessionId);
      // Gateway'e X-Company-Code header'ı olarak gönderilecek — domain çözümlemeyi bypass eder
      if (user.selectedCompanyCode.isNotEmpty) {
        await prefs.setString(AppConstants.companyCodeKey, user.selectedCompanyCode);
      }

      state = state.copyWith(
        user: user,
        token: accessToken,
        refreshToken: refreshToken,
        sessionId: sessionId,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Oturumu kapatır ve saklanan token/kullanıcı bilgilerini temizler.
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      await prefs.remove(AppConstants.userKey);
      await prefs.remove('session_id');
      await prefs.remove(AppConstants.companyCodeKey);
    } catch (e) {
      AppLogger.error('Logout error', tag: 'Auth', error: e);
    }
    state = AuthState.initial();
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  /// JWT payload'undan (base64) kullanıcı bilgilerini çözer.
  /// Backend sessionInstance alanını JSON string olarak gönderir.
  User _decodeUserFromJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Geçersiz token formatı');

    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final jwtPayload = jsonDecode(decoded) as Map<String, dynamic>;

    final sessionInstanceStr = jwtPayload['sessionInstance'] as String;
    final sessionInstance = jsonDecode(sessionInstanceStr) as Map<String, dynamic>;
    final userInfo = sessionInstance['userInformation'] as Map<String, dynamic>;

    return User(
      id: userInfo['id'] as String? ?? '',
      username: userInfo['username'] as String? ?? '',
      displayName: userInfo['fullName'] as String? ?? '',
      email: userInfo['email'] as String? ?? '',
      selectedCompanyCode: userInfo['selectedCompanyCode'] as String? ?? '',
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});