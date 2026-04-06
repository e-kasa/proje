import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        title: 'Ayarlar',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isMobile,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profil'),
            Tab(icon: Icon(Icons.palette), text: 'Görünüm'),
            Tab(icon: Icon(Icons.store), text: 'İşletme'),
            Tab(icon: Icon(Icons.settings), text: 'Sistem'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileSettings(),
          _buildAppearanceSettings(),
          _buildBusinessSettings(),
          _buildSystemSettings(),
        ],
      ),
    );
  }

  // PROFILE SETTINGS
  Widget _buildProfileSettings() {
    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          // Profile Picture
          AppCard(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          onPressed: () {
                            AppToast.info(context, 'Fotoğraf değiştirme özelliği yakında!');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Admin Kullanıcı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'admin@example.com',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Personal Information
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kişisel Bilgiler',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: 'Ad Soyad',
                  subtitle: 'Admin Kullanıcı',
                  onTap: () => _showEditDialog('İsim', 'Admin Kullanıcı'),
                ),
                _buildSettingItem(
                  icon: Icons.email_outlined,
                  title: 'E-posta',
                  subtitle: 'admin@example.com',
                  onTap: () => _showEditDialog('E-posta', 'admin@example.com'),
                ),
                _buildSettingItem(
                  icon: Icons.phone_outlined,
                  title: 'Telefon',
                  subtitle: '+90 555 123 4567',
                  onTap: () => _showEditDialog('Telefon', '+90 555 123 4567'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Security
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Güvenlik',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: 'Şifre Değiştir',
                  subtitle: 'Son değiştirme: 30 gün önce',
                  onTap: () => _showPasswordDialog(),
                ),
                _buildSettingItem(
                  icon: Icons.security,
                  title: 'İki Faktörlü Doğrulama',
                  subtitle: 'Kapalı',
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      AppToast.info(context, 'İki faktörlü doğrulama yakında!');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // APPEARANCE SETTINGS
  Widget _buildAppearanceSettings() {
    final themeSettings = ref.watch(themeProvider);
    final currentThemeMode = themeSettings.themeMode;

    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          // Theme
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                RadioListTile<AppThemeMode>(
                  title: const Text('Açık Tema'),
                  subtitle: const Text('Her zaman açık tema kullan'),
                  value: AppThemeMode.light,
                  groupValue: currentThemeMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).setThemeMode(value!);
                  },
                ),
                RadioListTile<AppThemeMode>(
                  title: const Text('Koyu Tema'),
                  subtitle: const Text('Her zaman koyu tema kullan'),
                  value: AppThemeMode.dark,
                  groupValue: currentThemeMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).setThemeMode(value!);
                  },
                ),
                RadioListTile<AppThemeMode>(
                  title: const Text('Sistem'),
                  subtitle: const Text('Sistem ayarını takip et'),
                  value: AppThemeMode.system,
                  groupValue: currentThemeMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).setThemeMode(value!);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Display
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Görünüm',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.language,
                  title: 'Dil',
                  subtitle: 'Türkçe',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AppToast.info(context, 'Dil değiştirme yakında!');
                  },
                ),
                _buildSettingItem(
                  icon: Icons.text_fields,
                  title: 'Yazı Boyutu',
                  subtitle: 'Orta',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AppToast.info(context, 'Yazı boyutu ayarı yakında!');
                  },
                ),
                _buildSettingItem(
                  icon: Icons.palette_outlined,
                  title: 'Renk Teması',
                  subtitle: 'Mavi',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AppToast.info(context, 'Renk teması değiştirme yakında!');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // BUSINESS SETTINGS
  Widget _buildBusinessSettings() {
    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          // Company Info
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şirket Bilgileri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.business,
                  title: 'Şirket Adı',
                  subtitle: 'E-Kasa Teknoloji A.Ş.',
                  onTap: () => _showEditDialog('Şirket Adı', 'E-Kasa Teknoloji A.Ş.'),
                ),
                _buildSettingItem(
                  icon: Icons.numbers,
                  title: 'Vergi No',
                  subtitle: '1234567890',
                  onTap: () => _showEditDialog('Vergi No', '1234567890'),
                ),
                _buildSettingItem(
                  icon: Icons.location_on_outlined,
                  title: 'Adres',
                  subtitle: 'İstanbul, Türkiye',
                  onTap: () => _showEditDialog('Adres', 'İstanbul, Türkiye'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Store Settings
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mağaza Ayarları',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.store,
                  title: 'Varsayılan Mağaza',
                  subtitle: 'Merkez Mağaza',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AppToast.info(context, 'Mağaza seçimi yakında!');
                  },
                ),
                _buildSettingItem(
                  icon: Icons.warehouse,
                  title: 'Varsayılan Depo',
                  subtitle: 'Ana Depo',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AppToast.info(context, 'Depo seçimi yakında!');
                  },
                ),
                _buildSettingItem(
                  icon: Icons.receipt_long,
                  title: 'Fatura Öneki',
                  subtitle: 'INV-',
                  onTap: () => _showEditDialog('Fatura Öneki', 'INV-'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Yonetim
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yonetim',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.people_outline,
                  title: 'Kullanici Yonetimi',
                  subtitle: 'Kullanicilari ve rolleri yonet',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/users'),
                ),
                _buildSettingItem(
                  icon: Icons.business_center_outlined,
                  title: 'Firma Ayarlari',
                  subtitle: 'Firma bilgileri, fatura ve sistem ayarlari',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/company'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notification Settings
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bildirimler',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.email_outlined,
                  title: 'E-posta Bildirimleri',
                  subtitle: 'Günlük raporlar al',
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
                _buildSettingItem(
                  icon: Icons.inventory_outlined,
                  title: 'Stok Uyarıları',
                  subtitle: 'Düşük stok bildir',
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
                _buildSettingItem(
                  icon: Icons.trending_down,
                  title: 'Satış Uyarıları',
                  subtitle: 'Satış düşüşlerini bildir',
                  trailing: Switch(value: false, onChanged: (value) {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SYSTEM SETTINGS
  Widget _buildSystemSettings() {
    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          // Data & Privacy
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veri & Gizlilik',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.backup_outlined,
                  title: 'Yedekleme',
                  subtitle: 'Son: Bugün 03:00',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    AppToast.info(context, 'Yedekleme ayarları yakında!');
                  },
                ),
                _buildSettingItem(
                  icon: Icons.sync,
                  title: 'Senkronizasyon',
                  subtitle: 'Otomatik senkronizasyon açık',
                  trailing: Switch(value: true, onChanged: (value) {}),
                ),
                _buildSettingItem(
                  icon: Icons.delete_outline,
                  title: 'Önbelleği Temizle',
                  subtitle: '128 MB',
                  onTap: () async {
                    final confirmed = await AppConfirmationDialog.showWarning(
                      context: context,
                      title: 'Önbelleği Temizle',
                      message: 'Tüm önbellek verileri silinecek. Devam etmek istiyor musunuz?',
                    );
                    if (confirmed) {
                      AppToast.success(context, 'Önbellek temizlendi');
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // About
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hakkında',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'Versiyon',
                  subtitle: '1.0.0 (Build 100)',
                ),
                _buildSettingItem(
                  icon: Icons.description_outlined,
                  title: 'Gizlilik Politikası',
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    AppToast.info(context, 'Gizlilik politikası yakında!');
                  },
                ),
                _buildSettingItem(
                  icon: Icons.article_outlined,
                  title: 'Kullanım Koşulları',
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    AppToast.info(context, 'Kullanım koşulları yakında!');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Danger Zone
          AppCard(
            color: AppColors.danger.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tehlikeli Alan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  icon: Icons.logout,
                  title: 'Çıkış Yap',
                  textColor: AppColors.danger,
                  onTap: () async {
                    final confirmed = await AppConfirmationDialog.show(
                      context: context,
                      title: 'Çıkış Yap',
                      message: 'Çıkış yapmak istediğinizden emin misiniz?',
                      icon: Icons.logout,
                      confirmText: 'Çıkış Yap',
                      confirmColor: AppColors.danger,
                    );
                    if (confirmed) {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
                _buildSettingItem(
                  icon: Icons.delete_forever,
                  title: 'Hesabı Sil',
                  textColor: AppColors.danger,
                  subtitle: 'Tüm verileriniz kalıcı olarak silinecek',
                  onTap: () async {
                    final confirmed = await AppConfirmationDialog.showDelete(
                      context: context,
                      title: 'Hesabı Sil',
                      message: 'Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz!',
                    );
                    if (confirmed) {
                      AppToast.error(context, 'Hesap silme özelliği yakında!');
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMedium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String label, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label Düzenle'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          AppButton.text(
            label: 'Kaydet',
            onPressed: () {
              Navigator.pop(context);
              AppToast.success(this.context, '$label güncellendi');
            },
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Şifre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifreyi Onayla'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          AppButton.text(
            label: 'Kaydet',
            onPressed: () {
              Navigator.pop(context);
              AppToast.success(context, 'Şifre değiştirildi');
            },
          ),
        ],
      ),
    );
  }
}
