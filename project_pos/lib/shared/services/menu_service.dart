import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/models/menu_models.dart';

class MenuService {
  final ApiClient _apiClient;

  MenuService(this._apiClient);

  Future<List<MenuCategoryModel>> getMenusForUser() async {
    final response = await _apiClient.get('security/api/get-menu-for-user');
    final data = response.data as Map<String, dynamic>;
    final payload = data['payload'] as List?;
    if (payload == null) return [];
    return payload
        .map((e) => MenuCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
