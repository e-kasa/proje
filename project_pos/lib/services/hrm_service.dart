import '../core/api/api_client.dart';
import '../core/utils/app_logger.dart';

/// HRM Service - Insan Kaynaklari Yonetimi
class HrmService {
  final ApiClient _apiClient;

  HrmService(this._apiClient);

  // Get all employees
  Future<List<Map<String, dynamic>>> getEmployees({
    String? department,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (department != null) queryParams['department'] = department;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;

      final response = await _apiClient.get('product/api/v1/hrm/employees', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Failed to fetch employees', tag: 'HrmService', error: e);
      rethrow;
    }
  }

  // Get employee by ID
  Future<Map<String, dynamic>> getEmployeeById(int id) async {
    try {
      final response = await _apiClient.get('product/api/v1/hrm/employees/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch employee by id: $id', tag: 'HrmService', error: e);
      rethrow;
    }
  }

  // Create employee
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('product/api/v1/hrm/employees', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to create employee', tag: 'HrmService', error: e);
      rethrow;
    }
  }

  // Update employee
  Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('product/api/v1/hrm/employees/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to update employee: $id', tag: 'HrmService', error: e);
      rethrow;
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(int id) async {
    try {
      await _apiClient.delete('product/api/v1/hrm/employees/$id');
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete employee: $id', tag: 'HrmService', error: e);
      rethrow;
    }
  }

  // Toggle employee status
  Future<bool> toggleEmployeeStatus(int id) async {
    try {
      await _apiClient.post('product/api/v1/hrm/employees/$id/toggle-status');
      return true;
    } catch (e) {
      AppLogger.error('Failed to toggle employee status: $id', tag: 'HrmService', error: e);
      rethrow;
    }
  }

  // Get departments
  Future<List<String>> getDepartments() async {
    try {
      final response = await _apiClient.get('product/api/v1/hrm/departments');
      return List<String>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Failed to fetch departments', tag: 'HrmService', error: e);
      rethrow;
    }
  }

  // Get employee statistics
  Future<Map<String, dynamic>> getEmployeeStats() async {
    try {
      final response = await _apiClient.get('product/api/v1/hrm/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch employee stats', tag: 'HrmService', error: e);
      rethrow;
    }
  }
}
