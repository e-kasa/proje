import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/hrm/di/hrm_di.dart';
import 'package:project_pos/features/hrm/providers/employee_list_notifier.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  String Function(String) get t => i18nOf(ref);
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(Map<String, dynamic> employee) async {
    final ok = await ref
        .read(employeeListProvider.notifier)
        .toggleStatus(employee['id']);
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, t('common.saved'));
    } else {
      AppToast.error(context, t('common.error'));
    }
  }

  Future<void> _deleteEmployee(Map<String, dynamic> employee) async {
    final fullName = '${employee['firstName']} ${employee['lastName']}';
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('hrm.delete_employee'),
      message: t('hrm.delete_employee_confirm'),
      itemName: fullName,
    );

    if (!confirmed) return;

    final ok = await ref
        .read(employeeListProvider.notifier)
        .deleteEmployee(employee['id']);
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, t('common.saved'));
    } else {
      AppToast.error(context, t('common.error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final state = ref.watch(employeeListProvider);
    final notifier = ref.read(employeeListProvider.notifier);

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('hrm.employees'),
        actions: [
          IconButton(
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh),
            tooltip: t('common.refresh'),
          ),
        ],
      ),
      body: state.isLoading
          ? const AppSkeletonList(itemCount: 8)
          : Column(
              children: [
                _buildStatsSection(state),
                const SizedBox(height: 16),
                _buildFiltersSection(state, notifier, isMobile),
                const SizedBox(height: 16),
                Expanded(
                  child: state.employees.isEmpty
                      ? AppEmptyState(
                          icon: Icons.people_outline,
                          title: t('hrm.no_employees'),
                          description: t('hrm.no_employees_hint'),
                        )
                      : ListView.separated(
                          padding: AppConstants.pagePadding,
                          itemCount: state.employees.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final employee = state.employees[index];
                            return _buildEmployeeCard(employee, isMobile);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/hrm/employees/add'),
        icon: const Icon(Icons.person_add),
        label: Text(t('hrm.add_employee')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatsSection(EmployeeListState state) {
    final total = state.totalCount;
    final active = state.activeCount;
    final inactive = state.inactiveCount;

    return Container(
      padding: AppConstants.pagePadding,
      color: Colors.white,
      child: Row(
        children: [
          _buildStatCard(
            t('common.total'),
            total.toString(),
            Icons.people_outline,
            AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            t('common.active'),
            active.toString(),
            Icons.check_circle_outline,
            AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            t('common.passive'),
            inactive.toString(),
            Icons.pause_circle_outline,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _filterDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: AppConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppConstants.borderRadiusMedium,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildFiltersSection(
      EmployeeListState state, EmployeeListNotifier notifier, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 12),
          AppSearchInput(
            controller: _searchController,
            hint: t('common.search'),
            onChanged: notifier.setSearch,
            onClear: () {
              _searchController.clear();
              notifier.setSearch('');
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: state.selectedDepartment,
                  decoration: _filterDecoration(
                    t('hrm.department'),
                    Icons.business_outlined,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(t('common.all')),
                    ),
                    ...state.departments
                        .map<DropdownMenuItem<String?>>((dept) {
                      return DropdownMenuItem<String?>(
                        value: dept,
                        child: Text(dept),
                      );
                    }),
                  ],
                  onChanged: notifier.setDepartment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: state.selectedStatus,
                  decoration: _filterDecoration(
                    t('common.status'),
                    Icons.flag_outlined,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(t('common.all')),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'active',
                      child: Text(t('common.active')),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'inactive',
                      child: Text(t('common.passive')),
                    ),
                  ],
                  onChanged: notifier.setStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee, bool isMobile) {
    final status = employee['status'] as String;
    final isActive = status == 'active';
    final hireDate = DateTime.parse(employee['hireDate']);

    return AppCard(
      onTap: () => context.go('/hrm/employees/edit/${employee['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  '${employee['firstName'][0]}${employee['lastName'][0]}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${employee['firstName']} ${employee['lastName']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppBadge(
                          text: isActive ? t('common.active') : t('common.passive'),
                          variant: isActive
                              ? BadgeVariant.success
                              : BadgeVariant.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee['position'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee['department'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  employee['email'] ?? '',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                employee['phone'] ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${t('hrm.hire_date')}: ${DateFormat('dd.MM.yyyy').format(hireDate)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      color: isActive ? AppColors.warning : AppColors.success,
                    ),
                    onPressed: () => _toggleStatus(employee),
                    tooltip: isActive
                        ? t('inventory.deactivate')
                        : t('inventory.activate'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger),
                    onPressed: () => _deleteEmployee(employee),
                    tooltip: t('common.delete'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
