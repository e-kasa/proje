import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/service_locator.dart';

/// Yönetici, Kasiyer, Depo Sorumlusu gibi kullanıcıları oluşturma/düzenleme ekranı.
///
/// Hiyerarşi:
///   ADMIN       → tüm kullanıcı tipleri oluşturabilir, tüm mağazaları görebilir
///   STORE_ADMIN → mağaza bazlı çalışanlar oluşturabilir
///   CASHIER     → storeId zorunlu (hangi kasaya bağlı)
///   WAREHOUSE   → storeId opsiyonel
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  String? _selectedRoleFilter;

  // Roller için ikon ve renk eşlemeleri (kod bazlı)
  static const Map<String, Color> _roleColors = {
    'ADMIN':       AppColors.purple,
    'SUPER_ADMIN': AppColors.secondary,
    'STORE_ADMIN': AppColors.indigo,
    'CASHIER':     AppColors.success,
    'WAREHOUSE':   AppColors.warning,
    'USER':        AppColors.textSecondary,
  };

  static const Map<String, IconData> _roleIcons = {
    'ADMIN':       Icons.admin_panel_settings,
    'SUPER_ADMIN': Icons.security,
    'STORE_ADMIN': Icons.store,
    'CASHIER':     Icons.point_of_sale,
    'WAREHOUSE':   Icons.warehouse,
    'USER':        Icons.person,
  };

  // Mağaza gerektiren roller
  static const _storeRequiredRoles = {'CASHIER', 'STORE_ADMIN'};

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
      final userSvc  = ref.read(userServiceProvider);
      final storeSvc = ref.read(storeServiceProvider);

      final results = await Future.wait([
        userSvc.getUsers(search: _searchController.text, role: _selectedRoleFilter),
        userSvc.getRoles(),
        storeSvc.getStores(isActive: true),
      ]);

      if (mounted) {
        setState(() {
          _users  = results[0];
          _roles  = results[1];
          _stores = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, 'Veriler yuklenemedi: $e');
      }
    }
  }

  Future<void> _toggleStatus(String userId) async {
    try {
      await ref.read(userServiceProvider).toggleUserStatus(userId);
      if (!mounted) return;
      AppToast.success(context, i18nOf(ref)('settings.status_updated'));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Durum degistirilemedi: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Kullanıcı Oluştur / Düzenle Dialog
  // ─────────────────────────────────────────────────────────────────

  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final t = i18nOf(ref);

    // UserResponse alanları: userName, displayName, storeId, languageVal, roles (List)
    final nameCtrl     = TextEditingController(text: user?['displayName']?.toString() ?? '');
    final userNameCtrl = TextEditingController(text: user?['userName']?.toString() ?? '');
    final passwordCtrl = TextEditingController();

    final userRoles = (user?['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
    String? selectedRoleCode = userRoles.isNotEmpty ? userRoles.first : null;
    String? selectedStoreId  = user?['storeId']?.toString();
    String  selectedLang     = user?['languageVal']?.toString().toUpperCase() == 'EN' ? 'EN' : 'TR';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final needsStore = selectedRoleCode != null &&
              _storeRequiredRoles.contains(selectedRoleCode!.toUpperCase());

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_outlined : Icons.person_add_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(isEdit ? t('settings.edit_user') : t('settings.new_user')),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Rol Seçimi ──────────────────────────────
                    _sectionLabel('Rol'),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRoleCode,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'Rol seçin',
                      ),
                      items: _roles.map((role) {
                        final code = role['code']?.toString() ?? '';
                        final name = role['name']?.toString() ?? code;
                        final color = _roleColors[code.toUpperCase()] ?? AppColors.info;
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Row(
                            children: [
                              Icon(
                                _roleIcons[code.toUpperCase()] ?? Icons.person,
                                size: 18,
                                color: color,
                              ),
                              const SizedBox(width: 8),
                              Text(name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setDialogState(() {
                        selectedRoleCode = value;
                        // Rol değişince mağaza gerekliliğini sıfırla
                        if (value != null &&
                            !_storeRequiredRoles.contains(value.toUpperCase())) {
                          selectedStoreId = null;
                        }
                      }),
                    ),
                    const SizedBox(height: 16),

                    // ── Ad Soyad ────────────────────────────────
                    _sectionLabel('Ad Soyad'),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        hintText: 'Ahmet Yılmaz',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Kullanıcı Adı ───────────────────────────
                    _sectionLabel('Kullanıcı Adı'),
                    TextField(
                      controller: userNameCtrl,
                      readOnly: isEdit,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: const OutlineInputBorder(),
                        hintText: 'kasiyer01 veya kasiyer@firma.com',
                        filled: isEdit,
                        fillColor: isEdit ? AppColors.bgLight : null,
                        helperText: isEdit
                            ? 'Kullanıcı adı değiştirilemez'
                            : 'Min 3, maks 40 karakter — platform geneli benzersiz',
                        helperStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Şifre (sadece oluşturmada) ──────────────
                    if (!isEdit) ...[
                      _sectionLabel('Şifre'),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                          hintText: 'Min 6 karakter',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Mağaza (Kasiyer ve Mağaza Yöneticisi) ──
                    if (needsStore) ...[
                      _sectionLabel(
                        'Mağaza',
                        subtitle: selectedRoleCode?.toUpperCase() == 'CASHIER'
                            ? 'Kasiyer yalnızca bu mağazada işlem yapabilir'
                            : null,
                        isRequired: true,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStoreId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.store_outlined),
                          border: OutlineInputBorder(),
                          hintText: 'Mağaza seçin',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'Tüm mağazalar (sınırsız)',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                          ..._stores.map((store) => DropdownMenuItem<String>(
                                value: store['code']?.toString() ?? store['storeCode']?.toString(),
                                child: Text(store['name']?.toString() ??
                                    store['storeName']?.toString() ??
                                    ''),
                              )),
                        ],
                        onChanged: (v) => setDialogState(() => selectedStoreId = v),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Dil ─────────────────────────────────────
                    _sectionLabel('Arayüz Dili'),
                    Row(
                      children: [
                        _langChip(
                          label: '🇹🇷  Türkçe',
                          value: 'TR',
                          selected: selectedLang == 'TR',
                          onTap: () => setDialogState(() => selectedLang = 'TR'),
                        ),
                        const SizedBox(width: 12),
                        _langChip(
                          label: '🇬🇧  English',
                          value: 'EN',
                          selected: selectedLang == 'EN',
                          onTap: () => setDialogState(() => selectedLang = 'EN'),
                        ),
                      ],
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
                onPressed: () => _submitUser(
                  ctx: ctx,
                  isEdit: isEdit,
                  user: user,
                  displayName:     nameCtrl.text.trim(),
                  userName:        userNameCtrl.text.trim(),
                  password:        passwordCtrl.text.trim(),
                  roleCode:        selectedRoleCode,
                  storeId:         selectedStoreId,
                  languageVal:     selectedLang,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Şifre Sıfırlama Dialog (Admin)
  // ─────────────────────────────────────────────────────────────────

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    final t = i18nOf(ref);
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Şifre Sıfırla: ${user['displayName'] ?? user['userName'] ?? ''}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kullanıcı bir sonraki girişte şifresini değiştirmek zorunda kalacak.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
                hintText: 'Min 6 karakter',
              ),
            ),
          ],
        ),
        actions: [
          AppButton.outline(
            text: t('common.cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton.primary(
            text: 'Sıfırla',
            onPressed: () async {
              final newPass = passwordCtrl.text.trim();
              if (newPass.length < 6) {
                AppToast.warning(context, 'Şifre en az 6 karakter olmalı');
                return;
              }
              Navigator.pop(ctx);
              try {
                await ref
                    .read(userServiceProvider)
                    .resetPassword(user['id'].toString(), newPass);
                if (!mounted) return;
                AppToast.success(context, 'Şifre sıfırlandı — kullanıcı bir sonraki girişte değiştirecek');
              } catch (e) {
                if (!mounted) return;
                AppToast.error(context, 'Şifre sıfırlanamadı: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Kullanıcı Oluştur / Güncelle — Backend Çağrısı
  // ─────────────────────────────────────────────────────────────────

  Future<void> _submitUser({
    required BuildContext ctx,
    required bool isEdit,
    required Map<String, dynamic>? user,
    required String displayName,
    required String userName,
    required String password,
    required String? roleCode,
    required String? storeId,
    required String languageVal,
  }) async {
    final t = i18nOf(ref);

    if (displayName.isEmpty || userName.isEmpty) {
      AppToast.warning(context, 'Ad Soyad ve Kullanıcı Adı zorunludur');
      return;
    }
    if (!isEdit && password.isEmpty) {
      AppToast.warning(context, t('settings.password_required'));
      return;
    }
    if (!isEdit && password.length < 6) {
      AppToast.warning(context, 'Şifre en az 6 karakter olmalı');
      return;
    }

    Navigator.pop(ctx);

    try {
      final service = ref.read(userServiceProvider);

      if (isEdit) {
        // Profil güncelle
        await service.updateUser(user!['id'].toString(), {
          'displayName': displayName,
          'languageVal': languageVal,
          if (storeId != null) 'storeId': storeId,
        });
        // Rol değiştiyse yeni rol ata
        final oldRole = (user['roles'] as List?)?.isNotEmpty == true
            ? (user['roles'] as List).first.toString()
            : null;
        if (roleCode != null && roleCode != oldRole) {
          if (oldRole != null) {
            await service.removeRole(user['id'].toString(), oldRole);
          }
          await service.assignRole(user['id'].toString(), roleCode);
        }
        if (!mounted) return;
        AppToast.success(context, t('settings.user_updated'));
      } else {
        // Yeni kullanıcı oluştur
        await service.createUser({
          'userName':    userName,
          'displayName': displayName,
          'password':    password,
          'languageVal': languageVal,
          if (storeId != null) 'storeId': storeId,
          if (roleCode != null) 'roles': [roleCode],
        });
        if (!mounted) return;
        AppToast.success(context, t('settings.user_created'));
      }
      _loadData();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Islem basarisiz: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    return AppScaffold(
      appBar: AppAppBar.standard(title: t('settings.user_management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(t('settings.new_user')),
      ),
      body: Column(
        children: [
          // ── Arama ve Filtre ──────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: t('settings.search_user'),
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
                  tooltip: 'Role göre filtrele',
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedRoleFilter != null
                            ? AppColors.primary
                            : AppColors.border,
                        width: _selectedRoleFilter != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: _selectedRoleFilter != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                  onSelected: (value) {
                    setState(() => _selectedRoleFilter = value);
                    _loadData();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: null,
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(t('settings.all_roles')),
                        ],
                      ),
                    ),
                    ..._roles.map((role) {
                      final code  = role['code']?.toString() ?? '';
                      final color = _roleColors[code.toUpperCase()] ?? AppColors.info;
                      return PopupMenuItem<String>(
                        value: code,
                        child: Row(
                          children: [
                            Icon(
                              _roleIcons[code.toUpperCase()] ?? Icons.person,
                              size: 18,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Text(role['name']?.toString() ?? code),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // ── Hiyerarşi Açıklama Kartı ─────────────────────────
          if (_users.isEmpty && !_isLoading)
            _buildRoleHierarchyCard(),

          // ── Kullanıcı Listesi ────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? AppEmptyState.noData(
                        title: t('settings.no_users'),
                        description: 'Yeni kullanıcı eklemek için + butonuna basın',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (_, i) => _buildUserCard(_users[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Widgets
  // ─────────────────────────────────────────────────────────────────

  Widget _buildUserCard(Map<String, dynamic> user) {
    final displayName = user['displayName']?.toString() ?? '';
    final userName    = user['userName']?.toString()    ?? '';
    final storeId     = user['storeId']?.toString();
    final isActive    = user['isActive'] == true;
    final roles       = (user['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final firstRole   = roles.isNotEmpty ? roles.first : '';
    final color       = _roleColors[firstRole.toUpperCase()] ?? AppColors.info;
    final icon        = _roleIcons[firstRole.toUpperCase()] ?? Icons.person;
    final firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    // Mağaza adını bul
    String? storeName;
    if (storeId != null) {
      final store = _stores.firstWhere(
        (s) => s['code']?.toString() == storeId || s['storeCode']?.toString() == storeId,
        orElse: () => {},
      );
      storeName = store['name']?.toString() ?? store['storeName']?.toString();
    }

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
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$userName',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Rol badge
                        if (firstRole.isNotEmpty)
                          _badge(
                            icon: icon,
                            label: _roleTr(firstRole),
                            color: color,
                          ),
                        // Mağaza badge
                        if (storeName != null)
                          _badge(
                            icon: Icons.store_outlined,
                            label: storeName,
                            color: AppColors.info,
                          )
                        else if (_storeRequiredRoles.contains(firstRole.toUpperCase()))
                          _badge(
                            icon: Icons.warning_amber_rounded,
                            label: 'Mağaza atanmamış',
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Aktif / Pasif Toggle
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

              // İşlemler
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                onSelected: (action) {
                  if (action == 'edit') {
                    _showUserDialog(user: user);
                  } else if (action == 'reset_password') {
                    _showResetPasswordDialog(user);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset_password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, size: 18, color: AppColors.warning),
                        SizedBox(width: 8),
                        Text('Şifre Sıfırla'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// İlk açılışta hiyerarşiyi anlatan kart
  Widget _buildRoleHierarchyCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Kullanıcı Hiyerarşisi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...[
                ('ADMIN',       Icons.admin_panel_settings, AppColors.purple,  'Tüm firma yetkisi — kullanıcı oluşturabilir'),
                ('STORE_ADMIN', Icons.store,                AppColors.indigo,  'Mağaza yöneticisi — raporlar ve satış yetkisi'),
                ('CASHIER',     Icons.point_of_sale,        AppColors.success, 'Kasiyer — mağaza atanması gerekir'),
                ('WAREHOUSE',   Icons.warehouse,            AppColors.warning, 'Depo sorumlusu — stok ve transfer yetkisi'),
              ].map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(item.$2, size: 20, color: item.$3),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.$3.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.$3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$4,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Yardımcı widget'lar ──────────────────────────────────────────

  Widget _sectionLabel(String label, {String? subtitle, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (isRequired)
            const Text(' *', style: TextStyle(color: AppColors.danger, fontSize: 13)),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              '— $subtitle',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _langChip({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _roleTr(String code) => switch (code.toUpperCase()) {
        'ADMIN'       => 'Yönetici',
        'SUPER_ADMIN' => 'Süper Admin',
        'STORE_ADMIN' => 'Mağaza Yöneticisi',
        'CASHIER'     => 'Kasiyer',
        'WAREHOUSE'   => 'Depo Sorumlusu',
        'USER'        => 'Kullanıcı',
        _             => code,
      };
}
