import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

/// Birlesik Parca Arama Servisi — /product/api/part-search
class PartSearchService {
  final ApiClient _apiClient;
  PartSearchService(this._apiClient);

  static const String _base = 'product/api/part-search';

  /// Parca ara (isim, SKU, OEM, capraz referans, barkod + arac filtresi)
  Future<List<Map<String, dynamic>>> search({
    String? keyword,
    String? make,
    String? model,
    int? year,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (keyword != null && keyword.isNotEmpty) params['q'] = keyword;
      if (make != null && make.isNotEmpty) params['make'] = make;
      if (model != null && model.isNotEmpty) params['model'] = model;
      if (year != null) params['year'] = year;

      debugPrint('Parca arama: $params');
      final response = await _apiClient.get(_base, queryParameters: params);
      final data = response.data['data'];
      if (data is List) {
        final list = data.cast<Map<String, dynamic>>();
        debugPrint('Parca arama sonucu: ${list.length} kayit');
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('PartSearch hata: $e');
      return [];
    }
  }
}
