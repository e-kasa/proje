import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/hrm/providers/employee_list_notifier.dart';
import 'package:project_pos/services/service_locator.dart';

final employeeListProvider =
    StateNotifierProvider.autoDispose<EmployeeListNotifier, EmployeeListState>(
  (ref) {
    final notifier = EmployeeListNotifier(ref.read(hrmServiceProvider));
    notifier.load();
    notifier.loadDepartments();
    return notifier;
  },
);
