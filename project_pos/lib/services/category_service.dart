import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';

/// Category Service - handles all category-related API calls
class CategoryService {
  final ApiClient _apiClient;

  CategoryService(this._apiClient);

  static const String _base = 'product/api/category';

  /// Get all categories (flat list) with optional filters
  Future<List<Map<String, dynamic>>> getCategories({
    String? search,
    bool? isActive,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null) queryParams['search'] = search;
      // Backend status endpoint: /api/category/status/ACTIVE
      // Flat list endpoint doesn't filter by status, but we pass it anyway
      if (isActive != null) queryParams['isActive'] = isActive;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(_base, queryParameters: queryParams);
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getCategories hata: $e');
      rethrow;
    }
  }

  /// Get full category tree (nested, 3 levels)
  /// Returns: [ { id, name, level, parentId, children: [...] }, ... ]
  Future<List<Map<String, dynamic>>> getCategoryTree() async {
    try {
      final response = await _apiClient.get('$_base/tree');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getCategoryTree hata: $e');
      rethrow;
    }
  }

  /// Get categories filtered by status
  Future<List<Map<String, dynamic>>> getCategoriesByStatus(String status) async {
    try {
      final response = await _apiClient.get('$_base/status/$status');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getCategoriesByStatus hata: $e');
      rethrow;
    }
  }

  /// Get root categories only (level 0)
  Future<List<Map<String, dynamic>>> getRootCategories() async {
    try {
      final response = await _apiClient.get('$_base/root');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getRootCategories hata: $e');
      rethrow;
    }
  }

  /// Get children of a category
  Future<List<Map<String, dynamic>>> getChildCategories(String parentId) async {
    try {
      final response = await _apiClient.get('$_base/children/$parentId');
      final data = response.data['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      debugPrint('getChildCategories hata: $e');
      rethrow;
    }
  }

  /// Get single category by ID (UUID String)
  Future<Map<String, dynamic>?> getCategoryById(String id) async {
    try {
      final response = await _apiClient.get('$_base/$id');
      final data = response.data['data'];
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      debugPrint('getCategoryById hata: $e');
      rethrow;
    }
  }

  /// Create new category
  /// [data] fields: name, description?, parentId?, status, sortOrder?, icon?
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_base, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Update category (UUID String id)
  Future<Map<String, dynamic>> updateCategory(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_base/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete category (soft delete via backend)
  Future<void> deleteCategory(String id) async {
    try {
      await _apiClient.delete('$_base/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle category status (ACTIVE ↔ INACTIVE)
  Future<Map<String, dynamic>> toggleStatus(String id) async {
    try {
      final response = await _apiClient.patch('$_base/$id/toggle-status');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Generate URL-friendly slug from name
  Future<String> generateSlug(String name) async {
    try {
      final response =
          await _apiClient.get('$_base/generate-slug', queryParameters: {'name': name});
      return response.data['data'] as String? ?? '';
    } catch (e) {
      debugPrint('generateSlug hata: $e');
      rethrow;
    }
  }
}
