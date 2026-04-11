import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/hrm_service.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/i18n_helper.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  String Function(String) get t => i18nOf(ref);
  late HrmService _hrmService;
  List<Map<String, dynamic>> _employees = [];
  List<String> _departments = [];
  bool _isLoading = false;
  String? _selectedDepartment;
  String? _selectedStatus;
  String _searchQuery = '';

  final _statusOptions = [
    {'value': null, 'label': 'Tümü'}, // TODO: i18n
    {'value': 'active', 'label': 'Aktif'}, // TODO: i18n
    {'value': 'inactive', 'label': 'Pasif'}, // TODO: i18n
  ];

  @override
  void initState() {
    super.initState();
    _hrmService = HrmService(ApiClient());
    _loadEmployees();
    _loadDepartments();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await _hrmService.getEmployees(
        department: _selectedDepartment,
        status: _selectedStatus,
        search: _searchQuery,
      );
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, t('common.error'));
      }
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _hrmService.getDepartments();
      setState(() => _departments = departments);
    } catch (e) {
      // Departments are optional
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> employee) async {
    try {
      await _hrmService.toggleEmployeeStatus(employee['id']);
      AppToast.success(context, t('common.saved'));
      _loadEmployees();
    } catch (e) {
      AppToast.error(context, t('common.error'));
    }
  }

  Future<void> _deleteEmployee(Map<String, dynamic> employee) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: t('hrm.title'), // TODO: i18n delete_employee key
      message: 'Bu çalışanı silmek istediğinizden emin misiniz?', // TODO: i18n
      itemName: '${employee['firstName']} ${employee['lastName']}',
    );

    if (!confirmed) return;

    try {
      await _hrmService.deleteEmployee(employee['id']);
      AppToast.success(context, t('common.saved'));
      _loadEmployees();
    } catch (e) {
      AppToast.error(context, t('common.error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('hrm.employees'),
        actions: [
          IconButton(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const AppSkeletonList(itemCount: 8)
          : Column(
              children: [
                // Stats
                _buildStatsSection(),
                const SizedBox(height: 16),
                // Filters
                _buildFiltersSection(isMobile),
                const SizedBox(height: 16),
                // Employee List
                Expanded(
                  child: _employees.isEmpty
                      ? AppEmptyState(
                          icon: Icons.people_outline,
                          title: t('hrm.employees'), // TODO: i18n no_employees key
                          actionText: 'Henüz hiç çalışan kaydı yok', // TODO: i18n
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _employees.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final employee = _employees[index];
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
      ),
    );
  }

  Widget _buildStatsSection() {
    final total = _employees.length;
    final active = _employees.where((e) => e['status'] == 'active').length;
    final inactive = _employees.where((e) => e['status'] == 'inactive').length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatCard('👥 Toplam', total.toString(), t('hrm.employees'), AppColors.primary), // TODO: i18n total key
          const SizedBox(width: 12),
          _buildStatCard('✅ Aktif', active.toString(), t('hrm.employees'), AppColors.success), // TODO: i18n active key
          const SizedBox(width: 12),
          _buildStatCard('⏸️ Pasif', inactive.toString(), t('hrm.employees'), AppColors.warning), // TODO: i18n inactive key
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _loadEmployees();
            },
            decoration: InputDecoration(
              hintText: t('common.search'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedDepartment,
                  decoration: InputDecoration(
                    labelText: 'Departman',
                    filled: true,
                    fillColor: AppColors.bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Tümü')),
                    ..._departments.map<DropdownMenuItem<String?>>((dept) {
                      return DropdownMenuItem<String?>(value: dept, child: Text(dept));
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDepartment = value);
                    _loadEmployees();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Durum',
                    filled: true,
                    fillColor: AppColors.bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _statusOptions.map<DropdownMenuItem<String>>((opt) {
                    return DropdownMenuItem<String>(
                      value: opt['value'],
                      child: Text(opt['label'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _loadEmployees();
                  },
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
              // Avatar
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
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${employee['firstName']} ${employee['lastName']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppBadge(
                          text: isActive ? 'Aktif' : 'Pasif', // TODO: i18n active/inactive keys
                          variant: isActive ? BadgeVariant.success : BadgeVariant.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee['position'],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee['department'],
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                employee['email'],
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                employee['phone'],
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'İşe giriş: ${DateFormat('dd.MM.yyyy').format(hireDate)}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: isActive ? AppColors.warning : AppColors.success,
                    ),
                    onPressed: () => _toggleStatus(employee),
                    tooltip: isActive ? 'Pasif Yap' : 'Aktif Yap', // TODO: i18n
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
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