import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/services/hrm_service.dart';

class EmployeeListState {
  final List<Map<String, dynamic>> employees;
  final List<String> departments;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedDepartment;
  final String? selectedStatus;

  const EmployeeListState({
    this.employees = const [],
    this.departments = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedDepartment,
    this.selectedStatus,
  });

  int get totalCount => employees.length;
  int get activeCount => employees.where((e) => e['status'] == 'active').length;
  int get inactiveCount =>
      employees.where((e) => e['status'] == 'inactive').length;

  EmployeeListState copyWith({
    List<Map<String, dynamic>>? employees,
    List<String>? departments,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Object? selectedDepartment = _sentinel,
    Object? selectedStatus = _sentinel,
  }) {
    return EmployeeListState(
      employees: employees ?? this.employees,
      departments: departments ?? this.departments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDepartment: selectedDepartment == _sentinel
          ? this.selectedDepartment
          : selectedDepartment as String?,
      selectedStatus: selectedStatus == _sentinel
          ? this.selectedStatus
          : selectedStatus as String?,
    );
  }
}

const _sentinel = Object();

class EmployeeListNotifier extends StateNotifier<EmployeeListState> {
  final HrmService _service;

  EmployeeListNotifier(this._service) : super(const EmployeeListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final employees = await _service.getEmployees(
        department: state.selectedDepartment,
        status: state.selectedStatus,
        search: state.searchQuery,
      );
      state = state.copyWith(employees: employees, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadDepartments() async {
    try {
      final departments = await _service.getDepartments();
      state = state.copyWith(departments: departments);
    } catch (_) {
      // Departments are optional
    }
  }

  void setSearch(String q) {
    state = state.copyWith(searchQuery: q);
    load();
  }

  void setDepartment(String? dept) {
    state = state.copyWith(selectedDepartment: dept);
    load();
  }

  void setStatus(String? status) {
    state = state.copyWith(selectedStatus: status);
    load();
  }

  Future<bool> toggleStatus(dynamic employeeId) async {
    try {
      await _service.toggleEmployeeStatus(employeeId is int
          ? employeeId
          : int.parse(employeeId.toString()));
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteEmployee(dynamic employeeId) async {
    try {
      await _service.deleteEmployee(employeeId is int
          ? employeeId
          : int.parse(employeeId.toString()));
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
