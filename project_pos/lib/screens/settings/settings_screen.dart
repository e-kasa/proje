import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final primary = Theme.of(context).colorScheme.primary;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Ayarlar',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isMobile,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Profil'),
            Tab(icon: Icon(Icons.palette_outlined), text: 'Görünüm'),
            Tab(icon: Icon(Icons.store_outlined), text: 'İşletme'),
            Tab(icon: Icon(Icons.settings_outlined), text: 'Sistem'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildAppearanceTab(),
          _buildBusinessTab(),
          _buildSystemTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PROFIL
  // ═══════════════════════════════════════════════════════

  Widget _buildProfileTab() {
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, size: 50, color: primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          onPressed: () => AppToast.info(context, 'Fotoğraf değiştirme yakında!'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Admin Kullanıcı',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('admin@example.com',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section('Kişisel Bilgiler', [
            _item(Icons.person_outline, 'Ad Soyad', 'Admin Kullanıcı',
                onTap: () => _showEditDialog('İsim', 'Admin Kullanıcı')),
            _item(Icons.email_outlined, 'E-posta', 'admin@example.com',
                onTap: () => _showEditDialog('E-posta', 'admin@example.com')),
            _item(Icons.phone_outlined, 'Telefon', '+90 555 123 4567',
                onTap: () => _showEditDialog('Telefon', '+90 555 123 4567')),
          ]),
          const SizedBox(height: 16),
          _section('Güvenlik', [
            _item(Icons.lock_outline, 'Şifre Değiştir', 'Son değiştirme: 30 gün önce',
                onTap: _showPasswordDialog),
            _item(Icons.security, 'İki Faktörlü Doğrulama', 'Kapalı',
                trailing: Switch(value: false, onChanged: (v) =>
                    AppToast.info(context, '2FA yakında!'))),
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // GÖRÜNÜM — tam işlevsel tema merkezi
  // ═══════════════════════════════════════════════════════

  Widget _buildAppearanceTab() {
    final s = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Canlı Önizleme ──────────────────────────────
          _buildThemePreview(s),
          const SizedBox(height: 20),

          // ── Mod Seçimi ──────────────────────────────────
          _sectionTitle('Tema Modu'),
          const SizedBox(height: 10),
          _buildModeSelector(s, notifier),
          const SizedBox(height: 20),

          // ── Renk Teması ─────────────────────────────────
          _sectionTitle('Renk Teması'),
          const SizedBox(height: 10),
          _buildColorPalette(s, notifier),
          const SizedBox(height: 20),

          // ── Yazı Boyutu ─────────────────────────────────
          _sectionTitle('Yazı Boyutu'),
          const SizedBox(height: 10),
          _buildFontScale(s, notifier),
          const SizedBox(height: 20),

          // ── Düzen Modu ──────────────────────────────────
          _sectionTitle('Düzen Modu'),
          const SizedBox(height: 10),
          _buildLayoutMode(s, notifier),
          const SizedBox(height: 20),

          // ── Gelişmiş ────────────────────────────────────
          _sectionTitle('Gelişmiş'),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: s.useMaterialYou,
                  onChanged: (_) => notifier.toggleMaterialYou(),
                  title: const Text('Material You',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Sistem renklerini kullan'),
                  secondary: Icon(Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: s.isRTL,
                  onChanged: (_) => notifier.toggleRTL(),
                  title: const Text('Sağdan Sola (RTL)',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Arapça/İbranice için'),
                  secondary: Icon(Icons.format_textdirection_r_to_l,
                      color: Theme.of(context).colorScheme.primary),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Sıfırla ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Varsayılana Sıfırla'),
              onPressed: () async {
                final ok = await AppConfirmationDialog.showWarning(
                  context: context,
                  title: 'Temayı Sıfırla',
                  message: 'Tüm tema ayarları varsayılana döndürülecek.',
                );
                if (ok && mounted) {
                  notifier.reset();
                  AppToast.success(context, 'Tema sıfırlandı');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Canlı Önizleme Kartı
  Widget _buildThemePreview(ThemeSettings s) {
    final gradient = s.resolvedGradient;
    final primary = s.resolvedPrimary;
    final isDark = s.themeMode == AppThemeMode.dark ||
        (s.themeMode == AppThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mini AppBar
          Container(
            height: 48,
            decoration: BoxDecoration(gradient: gradient),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('Önizleme',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const Spacer(),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          // Mini içerik
          Container(
            color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Mini kart
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF252540)
                          : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 8, width: 60,
                            decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 6),
                        Container(height: 6, width: 40,
                            decoration: BoxDecoration(
                                color: AppColors.textMuted.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Mini buton
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      s.primaryColor.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tema Modu Seçici
  Widget _buildModeSelector(ThemeSettings s, ThemeNotifier notifier) {
    final options = [
      (AppThemeMode.light, Icons.light_mode_outlined, 'Açık'),
      (AppThemeMode.dark,  Icons.dark_mode_outlined,  'Koyu'),
      (AppThemeMode.system, Icons.brightness_auto,    'Sistem'),
    ];
    return Row(
      children: options.map((opt) {
        final selected = s.themeMode == opt.$1;
        final primary = s.resolvedPrimary;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => notifier.setThemeMode(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? primary.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? primary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.$2,
                        color: selected ? primary : AppColors.textMuted,
                        size: 22),
                    const SizedBox(height: 6),
                    Text(opt.$3,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected ? primary : AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Renk Paleti Seçici
  Widget _buildColorPalette(ThemeSettings s, ThemeNotifier notifier) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemCount: PrimaryColorOption.values.length,
      itemBuilder: (_, i) {
        final option = PrimaryColorOption.values[i];
        final isSelected = s.primaryColor == option && s.customPrimaryColor == null;
        return GestureDetector(
          onTap: () => notifier.setPrimaryColor(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: option.gradient,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: option.color.withValues(alpha: 0.45),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 11),
                  )
                else
                  const SizedBox(height: 18),
                const SizedBox(height: 3),
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black38)],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Yazı Boyutu Slider
  Widget _buildFontScale(ThemeSettings s, ThemeNotifier notifier) {
    final primary = s.resolvedPrimary;
    final labels = {0.8: 'XS', 0.9: 'S', 1.0: 'M', 1.1: 'L', 1.2: 'XL', 1.3: 'XXL'};
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('A', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text(
                labels[s.fontScale] ??
                    '${(s.fontScale * 100).round()}%',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary),
              ),
              const Text('A', style: TextStyle(fontSize: 20, color: AppColors.textMuted)),
            ],
          ),
          Slider(
            value: s.fontScale,
            min: 0.8, max: 1.3,
            divisions: 5,
            activeColor: primary,
            label: labels[s.fontScale] ?? '${(s.fontScale * 100).round()}%',
            onChanged: (v) => notifier.setFontScale(v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.entries.map((e) => Text(
              e.value,
              style: TextStyle(
                  fontSize: 10,
                  color: (s.fontScale - e.key).abs() < 0.01
                      ? primary
                      : AppColors.textMuted,
                  fontWeight: (s.fontScale - e.key).abs() < 0.01
                      ? FontWeight.w700
                      : FontWeight.w400),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Düzen Modu Seçici
  Widget _buildLayoutMode(ThemeSettings s, ThemeNotifier notifier) {
    final primary = s.resolvedPrimary;
    final options = [
      (LayoutMode.default_, Icons.view_agenda_outlined, 'Varsayılan'),
      (LayoutMode.compact,  Icons.density_small,        'Kompakt'),
      (LayoutMode.modern,   Icons.auto_awesome_mosaic,  'Modern'),
    ];
    return Row(
      children: options.map((opt) {
        final selected = s.layoutMode == opt.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => notifier.setLayoutMode(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? primary.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? primary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.$2,
                        color: selected ? primary : AppColors.textMuted,
                        size: 22),
                    const SizedBox(height: 6),
                    Text(opt.$3,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected ? primary : AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════
  // İŞLETME
  // ═══════════════════════════════════════════════════════

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          _section('Şirket Bilgileri', [
            _item(Icons.business, 'Şirket Adı', 'E-Kasa Teknoloji A.Ş.',
                onTap: () => _showEditDialog('Şirket Adı', 'E-Kasa Teknoloji A.Ş.')),
            _item(Icons.numbers, 'Vergi No', '1234567890',
                onTap: () => _showEditDialog('Vergi No', '1234567890')),
            _item(Icons.location_on_outlined, 'Adres', 'İstanbul, Türkiye',
                onTap: () => _showEditDialog('Adres', 'İstanbul, Türkiye')),
          ]),
          const SizedBox(height: 16),
          _section('Mağaza Ayarları', [
            _item(Icons.store, 'Varsayılan Mağaza', 'Merkez Mağaza',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AppToast.info(context, 'Mağaza seçimi yakında!')),
            _item(Icons.warehouse, 'Varsayılan Depo', 'Ana Depo',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AppToast.info(context, 'Depo seçimi yakında!')),
            _item(Icons.receipt_long, 'Fatura Öneki', 'INV-',
                onTap: () => _showEditDialog('Fatura Öneki', 'INV-')),
          ]),
          const SizedBox(height: 16),
          _section('Yönetim', [
            _item(Icons.people_outline, 'Kullanıcı Yönetimi',
                'Kullanıcıları ve rolleri yönet',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/users')),
            _item(Icons.business_center_outlined, 'Firma Ayarları',
                'Firma bilgileri ve fatura ayarları',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/company')),
            _item(Icons.category_outlined, 'Sektör Ayarları',
                'Ürün formu alanlarını özelleştirin',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/sector')),
          ]),
          const SizedBox(height: 16),
          _section('Bildirimler', [
            _item(Icons.email_outlined, 'E-posta Bildirimleri', 'Günlük raporlar',
                trailing: Switch(value: true, onChanged: (v) {})),
            _item(Icons.inventory_outlined, 'Stok Uyarıları', 'Düşük stok bildir',
                trailing: Switch(value: true, onChanged: (v) {})),
            _item(Icons.trending_down, 'Satış Uyarıları', 'Satış düşüşlerini bildir',
                trailing: Switch(value: false, onChanged: (v) {})),
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SİSTEM
  // ═══════════════════════════════════════════════════════

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          _section('Veri & Gizlilik', [
            _item(Icons.backup_outlined, 'Yedekleme', 'Son: Bugün 03:00',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AppToast.info(context, 'Yedekleme ayarları yakında!')),
            _item(Icons.sync, 'Senkronizasyon', 'Otomatik açık',
                trailing: Switch(value: true, onChanged: (v) {})),
            _item(Icons.delete_outline, 'Önbelleği Temizle', '128 MB',
                onTap: () async {
              final ok = await AppConfirmationDialog.showWarning(
                context: context,
                title: 'Önbelleği Temizle',
                message: 'Tüm önbellek verileri silinecek.',
              );
              if (ok && mounted) AppToast.success(context, 'Önbellek temizlendi');
            }),
          ]),
          const SizedBox(height: 16),
          _section('Hakkında', [
            _item(Icons.info_outline, 'Versiyon', '1.0.0 (Build 100)'),
            _item(Icons.description_outlined, 'Gizlilik Politikası', '',
                trailing: const Icon(Icons.open_in_new),
                onTap: () => AppToast.info(context, 'Yakında!')),
            _item(Icons.article_outlined, 'Kullanım Koşulları', '',
                trailing: const Icon(Icons.open_in_new),
                onTap: () => AppToast.info(context, 'Yakında!')),
          ]),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tehlikeli Alan',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                        fontSize: 15)),
                const SizedBox(height: 12),
                _item(Icons.logout, 'Çıkış Yap', '',
                    textColor: AppColors.danger,
                    onTap: () async {
                  final ok = await AppConfirmationDialog.show(
                    context: context,
                    title: 'Çıkış Yap',
                    message: 'Çıkış yapmak istediğinizden emin misiniz?',
                    icon: Icons.logout,
                    confirmText: 'Çıkış Yap',
                    confirmColor: AppColors.danger,
                  );
                  if (ok && mounted) ref.read(authProvider.notifier).logout();
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // YARDIMCI WIDGET'LAR
  // ═══════════════════════════════════════════════════════

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5));
  }

  Widget _section(String title, List<Widget> items) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const Divider(height: 20),
          ...items,
        ],
      ),
    );
  }

  Widget _item(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMedium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (textColor ?? primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: textColor ?? primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textColor ?? AppColors.textPrimary,
                          fontSize: 14)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
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

  void _showEditDialog(String label, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label Düzenle'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          AppButton.outline(
              text: 'İptal', onPressed: () => Navigator.pop(ctx)),
          AppButton.primary(
              text: 'Kaydet',
              onPressed: () {
                Navigator.pop(ctx);
                AppToast.success(context, '$label güncellendi');
              }),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(obscureText: true,
                decoration: InputDecoration(labelText: 'Mevcut Şifre')),
            SizedBox(height: 12),
            TextField(obscureText: true,
                decoration: InputDecoration(labelText: 'Yeni Şifre')),
            SizedBox(height: 12),
            TextField(obscureText: true,
                decoration: InputDecoration(labelText: 'Şifreyi Onayla')),
          ],
        ),
        actions: [
          AppButton.outline(
              text: 'İptal', onPressed: () => Navigator.pop(ctx)),
          AppButton.primary(
              text: 'Kaydet',
              onPressed: () {
                Navigator.pop(ctx);
                AppToast.success(context, 'Şifre değiştirildi');
              }),
        ],
      ),
    );
  }
}
