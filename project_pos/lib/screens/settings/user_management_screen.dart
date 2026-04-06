import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/widgets.dart';
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
      final results = await Future.wait([
        service.getUsers(search: _searchController.text, role: _selectedRoleFilter),
        service.getRoles(),
      ]);
      if (mounted) {
        setState(() {
          _users = results[0];
          _roles = results[1];
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
      AppToast.success(context, 'Kullanici durumu guncellendi');
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Kullanici Duzenle' : 'Yeni Kullanici'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isEdit) ...[
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Sifre',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      border: OutlineInputBorder(),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                if (name.isEmpty || email.isEmpty) {
                  AppToast.warning(context, 'Ad ve e-posta zorunludur');
                  return;
                }
                if (!isEdit && passwordController.text.trim().isEmpty) {
                  AppToast.warning(context, 'Sifre zorunludur');
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
                    AppToast.success(context, 'Kullanici guncellendi');
                  } else {
                    await service.createUser(data);
                    AppToast.success(context, 'Kullanici olusturuldu');
                  }
                  _loadData();
                } catch (e) {
                  AppToast.error(context, 'Islem basarisiz: $e');
                }
              },
              child: Text(isEdit ? 'Guncelle' : 'Olustur'),
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
        title: const Text('Kullanici Yonetimi'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Kullanici'),
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
                      hintText: 'Kullanici ara...',
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
                    const PopupMenuItem(value: null, child: Text('Tum Roller')),
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Kullanici bulunamadi',
                              style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                            ),
                          ],
                        ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
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
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.info,
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
    );
  }
}
