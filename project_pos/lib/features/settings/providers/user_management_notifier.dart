import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/services/store_service.dart';
import 'package:project_pos/services/user_service.dart';

const _sentinel = Object();

class UserManagementState {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> stores;
  final bool isLoading;
  final String? error;
  final String? selectedRoleFilter;
  final String searchQuery;

  const UserManagementState({
    this.users = const [],
    this.roles = const [],
    this.stores = const [],
    this.isLoading = true,
    this.error,
    this.selectedRoleFilter,
    this.searchQuery = '',
  });

  UserManagementState copyWith({
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? roles,
    List<Map<String, dynamic>>? stores,
    bool? isLoading,
    Object? error = _sentinel,
    Object? selectedRoleFilter = _sentinel,
    String? searchQuery,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      stores: stores ?? this.stores,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      selectedRoleFilter: selectedRoleFilter == _sentinel
          ? this.selectedRoleFilter
          : selectedRoleFilter as String?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final UserService _userService;
  final StoreService _storeService;

  UserManagementNotifier(this._userService, this._storeService)
      : super(const UserManagementState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _userService.getUsers(
            search: state.searchQuery, role: state.selectedRoleFilter),
        _userService.getRoles(),
        _storeService.getStores(isActive: true),
      ]);
      state = state.copyWith(
        users: results[0],
        roles: results[1],
        stores: results[2],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String q) {
    state = state.copyWith(searchQuery: q);
    load();
  }

  void setRoleFilter(String? role) {
    state = state.copyWith(selectedRoleFilter: role);
    load();
  }

  Future<bool> toggleStatus(String userId) async {
    try {
      await _userService.toggleUserStatus(userId);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
