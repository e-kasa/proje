import 'package:project_pos/core/api/api_client.dart';

/// Firma-Kategori Servisi
///
/// Global kategori havuzundan firmanın seçtiği kategorileri yönetir.
/// Flutter uygulaması kategori listesi istediğinde bu servisi kullanır —
/// böylece login olan firmanın kategorileri (örn: berkspt → sadece Giyim) gelir.
class CompanyCategoryService {
  final ApiClient _apiClient;

  CompanyCategoryService(this._apiClient);

  // Base path — API Gateway üzerinden: /product/api/company-category
  static const String _basePath = 'product/api/company-category';

  // -------------------------------------------------------------------------
  // Firmanın kategorilerini AĞAÇ yapısında getir
  // Flutter'da kategori listesi gösterirken bu method kullanılır
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyCategories() async {
    try {
      final response = await _apiClient.get('$_basePath/my-categories');
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Firma kategorileri getirilemedi: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Düz liste (ağaç değil) — sadece ID ve isimler
  //
  // Defensive filter (Sprint 31 #10): backend `getMyCategoryList()` zaten
  // ACTIVE + isSoftDeleted=false satırlarını döner. Yine de network'ten gelen
  // veriye güvenmemek için DRAFT/INACTIVE/ARCHIVED ya da soft-delete edilmiş
  // kategorileri burada da elemiyoruz. `status` alanı yoksa (eski API)
  // backward-compat için kayıt geçer.
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyCategoryList() async {
    try {
      final response = await _apiClient.get('$_basePath/list');
      final data = response.data['data'] as List<dynamic>? ?? [];
      // 'id' / 'name' key'lerini normalize et — wizard ve batch her ikisi de
      // bu key'leri bekler. Backend 'categoryId' / 'categoryName' dönebilir.
      return data
          .cast<Map<String, dynamic>>()
          .where(_isCategoryPubliclyVisible)
          .map((m) => <String, dynamic>{
                'id': m['categoryId'] ?? m['id'] ?? '',
                'name': m['categoryName'] ?? m['name'] ?? '',
                'parentId': m['categoryParentId'] ?? m['parentId'],
                'level': m['categoryLevel'] ?? m['level'],
                'sortOrder': m['displayOrder'] ?? m['sortOrder'] ?? 0,
                'icon': m['categoryIcon'] ?? m['icon'],
                'status': m['categoryStatus'] ?? m['status'],
              })
          .toList();
    } catch (e) {
      throw Exception('Kategori listesi getirilemedi: $e');
    }
  }

  bool _isCategoryPubliclyVisible(Map<String, dynamic> raw) {
    final softDeleted = raw['isSoftDeleted'] ?? raw['isDeleted'];
    if (softDeleted == true) return false;
    final status = (raw['categoryStatus'] ?? raw['status'])?.toString();
    if (status == null || status.isEmpty) return true; // eski API → geçir
    return status.toUpperCase() == 'ACTIVE';
  }

  // -------------------------------------------------------------------------
  // "Kategori Tanımla" ekranı için — tüm global kategoriler + hangisi seçili?
  // isSelected: true → firmanın seçtiği, false → henüz seçilmemiş
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllCategoriesWithSelection() async {
    try {
      final response = await _apiClient.get('$_basePath/all-with-selection');
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Global kategoriler getirilemedi: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Firmaya tek bir kategori ekle
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> addCategory(String categoryId, {int displayOrder = 0}) async {
    try {
      final response = await _apiClient.post(
        _basePath,
        data: {
          'categoryId': categoryId,
          'displayOrder': displayOrder,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Kategori eklenemedi: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Firmadan tek bir kategori kaldır
  // -------------------------------------------------------------------------
  Future<void> removeCategory(String categoryId) async {
    try {
      await _apiClient.delete('$_basePath/$categoryId');
    } catch (e) {
      throw Exception('Kategori kaldırılamadı: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Toplu güncelleme — "Kaydet" butonuna basıldığında
  // selectedCategoryIds: seçilen tüm kategori ID'leri
  // -------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> bulkSetCategories(List<String> selectedCategoryIds) async {
    try {
      final response = await _apiClient.put(
        '$_basePath/bulk',
        data: {'categoryIds': selectedCategoryIds},
      );
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Kategori seçimi kaydedilemedi: $e');
    }
  }
}
