import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/i18n_helper.dart';
import '../../services/service_locator.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;
  String? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(userServiceProvider);
      final usersResult = await service.getUsers(search: _searchController.text, role: _selectedRoleFilter);
      final rolesResult = await service.getRoles();
      if (mounted) {
        setState(() {
          _users = usersResult;
          _roles = rolesResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Kullanicilar yuklenemedi: $e');
      }
    }
  }

  Future<void> _toggleStatus(String userId) async {
    try {
      final service = ref.read(userServiceProvider);
      await service.toggleUserStatus(userId);
      AppToast.success(context, i18nOf(ref)('settings.status_updated'));
      _loadData();
    } catch (e) {
      AppToast.error(context, 'Durum degistirilemedi: $e');
    }
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final passwordController = TextEditingController();
    String? selectedRoleId = user?['roleId']?.toString();

    final t = i18nOf(ref);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? t('settings.edit_user') : t('settings.new_user')),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: t('form.full_name'),
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: t('form.email'),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isEdit) ...[
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: t('form.password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: selectedRoleId,
                    decoration: InputDecoration(
                      labelText: t('form.role'),
                      prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role['id']?.toString(),
                        child: Text(role['name']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedRoleId = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            AppButton.outline(
              text: t('common.cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            AppButton.primary(
              text: isEdit ? t('common.update') : t('common.create'),
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                if (name.isEmpty || email.isEmpty) {
                  AppToast.warning(context, t('settings.name_email_required'));
                  return;
                }
                if (!isEdit && passwordController.text.trim().isEmpty) {
                  AppToast.warning(context, t('settings.password_required'));
                  return;
                }

                Navigator.pop(ctx);

                final data = <String, dynamic>{
                  'name': name,
                  'email': email,
                  if (!isEdit) 'password': passwordController.text.trim(),
                  if (selectedRoleId != null) 'roleId': selectedRoleId,
                };

                try {
                  final service = ref.read(userServiceProvider);
                  if (isEdit) {
                    await service.updateUser(user['id'].toString(), data);
                    if (selectedRoleId != null && selectedRoleId != user['roleId']?.toString()) {
                      await service.assignRole(user['id'].toString(), selectedRoleId!);
                    }
                    AppToast.success(context, t('settings.user_updated'));
                  } else {
                    await service.createUser(data);
                    AppToast.success(context, t('settings.user_created'));
                  }
                  _loadData();
                } catch (e) {
                  AppToast.error(context, 'Islem basarisiz: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        title: i18nOf(ref)('settings.user_management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(i18nOf(ref)('settings.new_user')),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: i18nOf(ref)('settings.search_user'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadData();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _loadData(),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String?>(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.filter_list, color: AppColors.primary),
                  ),
                  onSelected: (value) {
                    setState(() => _selectedRoleFilter = value);
                    _loadData();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: null, child: Text(i18nOf(ref)('settings.all_roles'))),
                    ..._roles.map((role) => PopupMenuItem(
                          value: role['id']?.toString(),
                          child: Text(role['name']?.toString() ?? ''),
                        )),
                  ],
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? AppEmptyState.noData(
                        title: i18nOf(ref)('settings.no_users'),
                        description: '',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) => _buildUserCard(_users[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final roleName = user['roleName']?.toString() ?? user['role']?.toString() ?? 'Belirsiz';
    final isActive = user['isActive'] == true || user['active'] == true;
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleBadgeColor(roleName).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getRoleBadgeColor(roleName),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status Toggle
            Column(
              children: [
                Switch(
                  value: isActive,
                  activeThumbColor: AppColors.success,
                  onChanged: (_) => _toggleStatus(user['id'].toString()),
                ),
                Text(
                  isActive ? 'Aktif' : 'Pasif',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? AppColors.success : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),

            // Edit Button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => _showUserDialog(user: user),
              tooltip: 'Duzenle',
            ),
          ],
        ),
      ),
      ),
    );
  }

  Color _getRoleBadgeColor(String roleName) {
    final lower = roleName.toLowerCase();
    if (lower.contains('yönetici') || lower.contains('admin')) return Colors.purple;
    if (lower.contains('kasiyer') || lower.contains('cashier')) return AppColors.success;
    if (lower.contains('depo') || lower.contains('warehouse')) return Colors.orange;
    if (lower.contains('mağaza') || lower.contains('store')) return AppColors.primary;
    return AppColors.info;
  }
}
