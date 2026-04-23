import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/settings/providers/user_management_notifier.dart';
import 'package:project_pos/services/service_locator.dart';

final userManagementProvider = StateNotifierProvider.autoDispose<
    UserManagementNotifier, UserManagementState>(
  (ref) {
    final n = UserManagementNotifier(
      ref.read(userServiceProvider),
      ref.read(storeServiceProvider),
    );
    n.load();
    return n;
  },
);
