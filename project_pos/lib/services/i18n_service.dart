import '../core/api/api_client.dart';

class I18nService {
  final ApiClient _apiClient;

  I18nService(this._apiClient);

  /// Tum mesaj ve bundle'lari backend'den ceker.
  /// [lang] → "TR" veya "EN"
  Future<Map<String, dynamic>> getAllTranslations({String lang = 'TR'}) async {
    final response = await _apiClient.get(
      'security/i18n/all',
      queryParameters: {'lang': lang},
    );
    final data = response.data as Map<String, dynamic>;
    return data['payload'] as Map<String, dynamic>? ?? {};
  }
}
