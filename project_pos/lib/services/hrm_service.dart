import '../core/api/api_client.dart';
import '../core/utils/app_logger.dart';

/// HRM Service - İnsan Kaynakları Yönetimi
class HrmService {
  static const bool useMockData = false;
  final ApiClient _apiClient;

  HrmService(this._apiClient);

  // Mock employee data
  static final List<Map<String, dynamic>> _mockEmployees = [
    {
      'id': 1,
      'employeeNumber': 'EMP-001',
      'firstName': 'Ahmet',
      'lastName': 'Yılmaz',
      'email': 'ahmet.yilmaz@example.com',
      'phone': '+90 555 123 4567',
      'department': 'Satış',
      'position': 'Satış Müdürü',
      'salary': 25000,
      'hireDate': '2023-01-15',
      'birthDate': '1985-06-20',
      'address': 'İstanbul, Türkiye',
      'status': 'active',
      'profilePhoto': null,
    },
    {
      'id': 2,
      'employeeNumber': 'EMP-002',
      'firstName': 'Ayşe',
      'lastName': 'Demir',
      'email': 'ayse.demir@example.com',
      'phone': '+90 555 234 5678',
      'department': 'İnsan Kaynakları',
      'position': 'İK Uzmanı',
      'salary': 18000,
      'hireDate': '2023-03-01',
      'birthDate': '1990-08-15',
      'address': 'Ankara, Türkiye',
      'status': 'active',
      'profilePhoto': null,
    },
    {
      'id': 3,
      'employeeNumber': 'EMP-003',
      'firstName': 'Mehmet',
      'lastName': 'Kaya',
      'email': 'mehmet.kaya@example.com',
      'phone': '+90 555 345 6789',
      'department': 'IT',
      'position': 'Yazılım Geliştirici',
      'salary': 22000,
      'hireDate': '2022-11-10',
      'birthDate': '1992-03-25',
      'address': 'İzmir, Türkiye',
      'status': 'active',
      'profilePhoto': null,
    },
    {
      'id': 4,
      'employeeNumber': 'EMP-004',
      'firstName': 'Fatma',
      'lastName': 'Öz',
      'email': 'fatma.oz@example.com',
      'phone': '+90 555 456 7890',
      'department': 'Muhasebe',
      'position': 'Muhasebe Uzmanı',
      'salary': 16000,
      'hireDate': '2024-01-05',
      'birthDate': '1988-11-30',
      'address': 'Bursa, Türkiye',
      'status': 'active',
      'profilePhoto': null,
    },
    {
      'id': 5,
      'employeeNumber': 'EMP-005',
      'firstName': 'Can',
      'lastName': 'Arslan',
      'email': 'can.arslan@example.com',
      'phone': '+90 555 567 8901',
      'department': 'Depo',
      'position': 'Depo Sorumlusu',
      'salary': 14000,
      'hireDate': '2023-06-20',
      'birthDate': '1995-01-10',
      'address': 'Antalya, Türkiye',
      'status': 'inactive',
      'profilePhoto': null,
    },
  ];

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
      // Fallback to mock data
      var employees = List<Map<String, dynamic>>.from(_mockEmployees);

      if (department != null && department.isNotEmpty) {
        employees = employees.where((e) => e['department'] == department).toList();
      }

      if (status != null) {
        employees = employees.where((e) => e['status'] == status).toList();
      }

      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        employees = employees.where((e) {
          final name = '${e['firstName']} ${e['lastName']}'.toLowerCase();
          final email = e['email'].toString().toLowerCase();
          final empNumber = e['employeeNumber'].toString().toLowerCase();
          return name.contains(query) || email.contains(query) || empNumber.contains(query);
        }).toList();
      }

      return employees;
    }
  }

  // Get employee by ID
  Future<Map<String, dynamic>> getEmployeeById(int id) async {
    try {
      final response = await _apiClient.get('product/api/v1/hrm/employees/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch employee by id: $id', tag: 'HrmService', error: e);
      // Fallback to mock data
      return _mockEmployees.firstWhere((e) => e['id'] == id, orElse: () => {});
    }
  }

  // Create employee
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('product/api/v1/hrm/employees', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to create employee', tag: 'HrmService', error: e);
      // Fallback to mock data
      final newEmployee = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'employeeNumber': 'EMP-${_mockEmployees.length + 1}'.padLeft(7, '0'),
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockEmployees.add(newEmployee);
      return newEmployee;
    }
  }

  // Update employee
  Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('product/api/v1/hrm/employees/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to update employee: $id', tag: 'HrmService', error: e);
      // Fallback to mock data
      final index = _mockEmployees.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        _mockEmployees[index] = {..._mockEmployees[index], ...data};
        return _mockEmployees[index];
      }
      return {};
    }
  }

  // Delete employee
  Future<bool> deleteEmployee(int id) async {
    try {
      await _apiClient.delete('product/api/v1/hrm/employees/$id');
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete employee: $id', tag: 'HrmService', error: e);
      // Fallback to mock data
      _mockEmployees.removeWhere((e) => e['id'] == id);
      return true;
    }
  }

  // Toggle employee status
  Future<bool> toggleEmployeeStatus(int id) async {
    try {
      await _apiClient.post('product/api/v1/hrm/employees/$id/toggle-status');
      return true;
    } catch (e) {
      AppLogger.error('Failed to toggle employee status: $id', tag: 'HrmService', error: e);
      // Fallback to mock data
      final index = _mockEmployees.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        final currentStatus = _mockEmployees[index]['status'];
        _mockEmployees[index]['status'] = currentStatus == 'active' ? 'inactive' : 'active';
        return true;
      }
      return false;
    }
  }

  // Get departments
  Future<List<String>> getDepartments() async {
    try {
      final response = await _apiClient.get('product/api/v1/hrm/departments');
      return List<String>.from(response.data['data'] ?? []);
    } catch (e) {
      AppLogger.error('Failed to fetch departments', tag: 'HrmService', error: e);
      // Fallback to mock data
      return ['Satış', 'İnsan Kaynakları', 'IT', 'Muhasebe', 'Depo', 'Pazarlama', 'Lojistik'];
    }
  }

  // Get employee statistics
  Future<Map<String, dynamic>> getEmployeeStats() async {
    try {
      final response = await _apiClient.get('product/api/v1/hrm/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to fetch employee stats', tag: 'HrmService', error: e);
      // Fallback to mock data
      final activeCount = _mockEmployees.where((e) => e['status'] == 'active').length;
      final inactiveCount = _mockEmployees.where((e) => e['status'] == 'inactive').length;
      final totalSalary = _mockEmployees.fold<double>(
        0,
        (sum, e) => sum + (e['salary'] as num).toDouble(),
      );

      return {
        'totalEmployees': _mockEmployees.length,
        'activeEmployees': activeCount,
        'inactiveEmployees': inactiveCount,
        'totalSalary': totalSalary,
        'averageSalary': _mockEmployees.isNotEmpty ? totalSalary / _mockEmployees.length : 0,
        'departmentCount': getDepartments(),
      };
    }
  }
}
