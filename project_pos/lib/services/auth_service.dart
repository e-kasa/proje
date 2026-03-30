import '../core/data/mock_data.dart';
import '../core/api/api_client.dart';

class AuthService {
  
  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = true;
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _apiClient.post(
      'security/authenticate',
      data: {
        'username': username,
        'password': password,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      'auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _apiClient.post('auth/logout');
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _apiClient.get('auth/me');
    return response.data as Map<String, dynamic>;
  }
}
