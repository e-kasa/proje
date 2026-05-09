import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/templates/detail_screen_template.dart';
import 'package:project_pos/providers/theme_provider.dart';
import 'package:project_pos/providers/auth_provider.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'theme_settings_drawer_advanced.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Sprint 15 W2: TabController self-management → DetailScreenTemplate'a delege.
  String Function(String) get t => i18nOf(ref);

  @override
  Widget build(BuildContext context) {
    return DetailScreenTemplate(
      title: t('settings.title'),
      tabs: [
        DetailTab(
          label: t('profile.title'),
          icon: Icons.person_outline,
          builder: (_) => _buildProfileTab(),
        ),
        DetailTab(
          label: t('settings.theme'),
          icon: Icons.palette_outlined,
          builder: (_) => _buildAppearanceTab(),
        ),
        DetailTab(
          label: t('settings.company'),
          icon: Icons.store_outlined,
          builder: (_) => _buildBusinessTab(),
        ),
        DetailTab(
          label: t('settings.title'),
          icon: Icons.settings_outlined,
          builder: (_) => _buildSystemTab(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // PROFIL
  // ═══════════════════════════════════════════════════════

  Widget _buildProfileTab() {
    final primary = Theme.of(context).colorScheme.primary;
    final user = ref.watch(authProvider).user;
    final displayName = user?.displayName ?? user?.username ?? '-';
    final email = user?.email ?? '-';
    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: AppColors.textMuted)),
                if (user?.roles.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: user!.roles.map((r) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(r,
                          style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(t('profile.title'), [
            _item(Icons.person_outline, t('common.full_name'), displayName, // TODO: i18n key common.full_name
                onTap: () => _showEditDialog(t('common.full_name'), displayName)),
            _item(Icons.email_outlined, t('auth.email'), email, // TODO: i18n key auth.email
                onTap: () => _showEditDialog(t('auth.email'), email)),
            _item(Icons.badge_outlined, t('auth.username'), user?.username ?? '-'),
            if (user?.selectedCompanyCode != null)
              _item(Icons.business_outlined, t('auth.company_code'), user!.selectedCompanyCode),
            if (user?.storeId != null)
              _item(Icons.store_outlined, 'Mağaza ID', user!.storeId!), // TODO: i18n
          ]),
          const SizedBox(height: 16),
          _section('Güvenlik', [
            _item(Icons.lock_outline, 'Şifre Değiştir', 'Son değiştirme: 30 gün önce',
                onTap: _showPasswordDialog),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Canlı Önizleme ──────────────────────────────
          _buildThemePreview(s),
          const SizedBox(height: 20),

          // ── Mod Seçimi ──────────────────────────────────
          _sectionTitle(t('settings.theme')), // TODO: i18n theme_mode key
          const SizedBox(height: 10),
          _buildModeSelector(s, notifier, isDark),
          const SizedBox(height: 20),

          // ── Renk Teması ─────────────────────────────────
          _sectionTitle('Renk Teması'), // TODO: i18n color_theme key
          const SizedBox(height: 10),
          _buildColorPalette(s, notifier, isDark),
          const SizedBox(height: 20),

          // ── Yazı Boyutu ─────────────────────────────────
          _sectionTitle('Yazı Boyutu'), // TODO: i18n
          const SizedBox(height: 10),
          _buildFontScale(s, notifier, isDark),
          const SizedBox(height: 20),

          // ── Düzen Modu ──────────────────────────────────
          _sectionTitle('Düzen Modu'), // TODO: i18n
          const SizedBox(height: 10),
          _buildLayoutMode(s, notifier, isDark),
          const SizedBox(height: 20),

          // ── Renk Çubuğu ─────────────────────────────────
          _sectionTitle('Kenar Çubuğu & Üst Çubuk'), // TODO: i18n
          const SizedBox(height: 10),
          _buildBarAppearance(s, notifier, isDark),
          const SizedBox(height: 20),

          // ── Gelişmiş ────────────────────────────────────
          _sectionTitle('Gelişmiş'), // TODO: i18n
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
                      color: s.resolvedPrimary),
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
                      color: s.resolvedPrimary),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Gelişmiş Tema Özelleştirici ─────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.tune, color: s.resolvedPrimary),
              label: Text('Gelişmiş Özelleştirici',
                  style: TextStyle(color: s.resolvedPrimary)),
              onPressed: () => AppBottomSheet.show(
                context: context,
                child: const ThemeSettingsDrawerAdvanced(),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: s.resolvedPrimary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),

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

  // ─── Canlı Önizleme ─────────────────────────────────────────────────────────
  Widget _buildThemePreview(ThemeSettings s) {
    final gradient = s.resolvedGradient;
    final primary  = s.resolvedPrimary;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0f0f23) : AppColors.bgLight;
    final cardBg   = isDark ? const Color(0xFF1a1a2e) : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AppBar
          Container(
            height: 44,
            decoration: BoxDecoration(gradient: gradient),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              const Icon(Icons.menu, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(child: Text('Önizleme',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 13))),
              Container(width: 26, height: 26,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_none,
                      color: Colors.white, size: 15)),
              const SizedBox(width: 6),
              Container(width: 26, height: 26,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 15)),
            ]),
          ),
          // Body
          Container(
            color: bg,
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              // KPI row
              Row(children: [
                _previewCard(cardBg, primary, '₺12,4K', 'Satış', Icons.trending_up),
                const SizedBox(width: 8),
                _previewCard(cardBg, primary, '48', 'Sipariş', Icons.receipt_outlined),
                const SizedBox(width: 8),
                _previewCard(cardBg, primary, '%4.2', 'İade', Icons.keyboard_return),
              ]),
              const SizedBox(height: 8),
              // List item row
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: cardBg, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Container(width: 28, height: 28,
                      decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(6))),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 7, width: 80,
                            decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 4),
                        Container(height: 5, width: 50,
                            decoration: BoxDecoration(
                                color: AppColors.textMuted.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4))),
                      ])),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('Ekle',
                          style: TextStyle(color: Colors.white,
                              fontSize: 9, fontWeight: FontWeight.w600))),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _previewCard(Color bg, Color primary, String value, String label,
      IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 12, color: primary),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
          Text(label,
              style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  // ─── Mod Seçici ─────────────────────────────────────────────────────────────
  Widget _buildModeSelector(
      ThemeSettings s, ThemeNotifier notifier, bool isDark) {
    final primary = s.resolvedPrimary;
    final unselBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final unselBorder = isDark ? const Color(0xFF2E2E3E) : AppColors.border;

    final options = [
      (AppThemeMode.light,  Icons.light_mode_outlined,  'Açık'),
      (AppThemeMode.dark,   Icons.dark_mode_outlined,   'Koyu'),
      (AppThemeMode.system, Icons.brightness_auto,      'Sistem'),
    ];
    return Row(
      children: options.asMap().entries.map((entry) {
        final i   = entry.key;
        final opt = entry.value;
        final selected = s.themeMode == opt.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => notifier.setThemeMode(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: isDark ? 0.2 : 0.08)
                      : unselBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? primary : unselBorder,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(opt.$2,
                      color: selected ? primary : AppColors.textMuted,
                      size: 20),
                  const SizedBox(height: 5),
                  Text(opt.$3,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? primary
                              : AppColors.textSecondary)),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Renk Paleti ────────────────────────────────────────────────────────────
  Widget _buildColorPalette(
      ThemeSettings s, ThemeNotifier notifier, bool isDark) {
    final cardBg   = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderC  = isDark ? const Color(0xFF2E2E3E) : AppColors.border;
    final items    = PrimaryColorOption.values;

    Widget chip(PrimaryColorOption opt) {
      final isSel = s.primaryColor == opt && s.customPrimaryColor == null;
      return Expanded(
        child: GestureDetector(
          onTap: () => notifier.setPrimaryColor(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            decoration: BoxDecoration(
              color: isSel
                  ? opt.color.withValues(alpha: isDark ? 0.22 : 0.08)
                  : cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel ? opt.color : borderC,
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              const SizedBox(width: 10),
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  gradient: opt.gradient,
                  shape: BoxShape.circle,
                  boxShadow: isSel
                      ? [BoxShadow(
                          color: opt.color.withValues(alpha: 0.4),
                          blurRadius: 6)]
                      : [],
                ),
                child: isSel
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(opt.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                        color: isSel
                            ? opt.color
                            : (isDark ? Colors.white70 : AppColors.textPrimary))),
              ),
              Container(
                width: 3, height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: opt.gradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    // 2 sütun, 4 satır — manuel Row/Column (shrinkWrap sorununu önler)
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(Row(children: [
        chip(items[i]),
        const SizedBox(width: 8),
        if (i + 1 < items.length) chip(items[i + 1])
        else const Expanded(child: SizedBox()),
      ]));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }

  // ─── Yazı Boyutu ────────────────────────────────────────────────────────────
  Widget _buildFontScale(
      ThemeSettings s, ThemeNotifier notifier, bool isDark) {
    final primary = s.resolvedPrimary;
    final steps = [
      (0.8, 'XS'), (0.9, 'S'), (1.0, 'M'),
      (1.1, 'L'),  (1.2, 'XL'), (1.3, 'XXL'),
    ];
    final current = steps.firstWhere(
        (e) => (s.fontScale - e.$1).abs() < 0.01,
        orElse: () => (s.fontScale, '${(s.fontScale * 100).round()}%'));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('A',
              style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.textMuted)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(current.$2,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primary)),
          ),
          Text('A',
              style: TextStyle(fontSize: 20,
                  color: isDark ? Colors.white38 : AppColors.textMuted)),
        ]),
        Slider(
          value: s.fontScale,
          min: 0.8, max: 1.3,
          divisions: 5,
          activeColor: primary,
          inactiveColor: primary.withValues(alpha: 0.2),
          onChanged: (v) => notifier.setFontScale(v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((e) {
            final active = (s.fontScale - e.$1).abs() < 0.01;
            return Text(e.$2,
                style: TextStyle(
                    fontSize: 10,
                    color: active ? primary : AppColors.textMuted,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.w400));
          }).toList(),
        ),
      ]),
    );
  }

  // ─── Düzen Modu ─────────────────────────────────────────────────────────────
  Widget _buildLayoutMode(
      ThemeSettings s, ThemeNotifier notifier, bool isDark) {
    final primary    = s.resolvedPrimary;
    final unselBg    = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final unselBorder = isDark ? const Color(0xFF2E2E3E) : AppColors.border;
    final options = [
      (LayoutMode.default_, Icons.view_agenda_outlined, 'Varsayılan', 'Geniş boşluk'),
      (LayoutMode.compact,  Icons.density_small,        'Kompakt',    'Daha fazla içerik'),
      (LayoutMode.modern,   Icons.auto_awesome_mosaic,  'Modern',     'Kart görünüm'),
    ];
    return Column(
      children: options.map((opt) {
        final selected = s.layoutMode == opt.$1;
        return GestureDetector(
          onTap: () => notifier.setLayoutMode(opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: isDark ? 0.2 : 0.07)
                  : unselBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? primary : unselBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.bgLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(opt.$2,
                    size: 18,
                    color: selected ? primary : AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.$3,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? primary
                                : (isDark
                                    ? Colors.white70
                                    : AppColors.textPrimary))),
                    const SizedBox(height: 2),
                    Text(opt.$4,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted)),
                  ])),
              if (selected)
                Icon(Icons.check_circle, color: primary, size: 18),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ─── Kenar & Üst Çubuk Görünümü ─────────────────────────────────────────────
  Widget _buildBarAppearance(
      ThemeSettings s, ThemeNotifier notifier, bool isDark) {
    final primary    = s.resolvedPrimary;
    final cardBg     = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    Widget appearanceRow(
      String label,
      IconData icon,
      List<(String, IconData, bool)> opts,
      Function(int) onSelect,
    ) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E3E) : AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.textPrimary))),
          Row(
            children: opts.asMap().entries.map((oe) { final o = oe.value; return GestureDetector(
              onTap: () => onSelect(oe.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: o.$3
                      ? primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: o.$3 ? primary : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(o.$2, size: 12,
                      color: o.$3 ? primary : AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(o.$1,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: o.$3
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: o.$3 ? primary : AppColors.textMuted)),
                ]),
              ),
            );}).toList(),
          ),
        ]),
      );
    }

    return Column(children: [
      appearanceRow(
        'Kenar Çubuğu',
        Icons.vertical_split_outlined,
        [
          ('Açık', Icons.light_mode, s.sidebarAppearance == SidebarAppearance.light),
          ('Koyu', Icons.dark_mode,  s.sidebarAppearance == SidebarAppearance.dark),
          ('Renkli', Icons.palette,  s.sidebarAppearance == SidebarAppearance.colored),
        ],
        (i) => notifier.setSidebarAppearance(SidebarAppearance.values[i]),
      ),
      const SizedBox(height: 8),
      appearanceRow(
        'Üst Çubuk',
        Icons.horizontal_split_outlined,
        [
          ('Açık',  Icons.light_mode, s.topbarAppearance == TopbarAppearance.light),
          ('Koyu',  Icons.dark_mode,  s.topbarAppearance == TopbarAppearance.dark),
          ('Renkli',Icons.palette,    s.topbarAppearance == TopbarAppearance.colored),
        ],
        (i) => notifier.setTopbarAppearance(TopbarAppearance.values[i]),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════
  // İŞLETME
  // ═══════════════════════════════════════════════════════

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: AppConstants.pagePadding,
      child: Column(
        children: [
          _section(t('settings.company'), [
            _item(Icons.business, 'Şirket Adı', 'E-Kasa Teknoloji A.Ş.', // TODO: i18n
                onTap: () => _showEditDialog('Şirket Adı', 'E-Kasa Teknoloji A.Ş.')),
            _item(Icons.numbers, 'Vergi No', '1234567890', // TODO: i18n
                onTap: () => _showEditDialog('Vergi No', '1234567890')),
            _item(Icons.location_on_outlined, 'Adres', 'İstanbul, Türkiye', // TODO: i18n
                onTap: () => _showEditDialog('Adres', 'İstanbul, Türkiye')),
          ]),
          const SizedBox(height: 16),
          _section('Mağaza Ayarları', [
            _item(Icons.receipt_long, 'Fatura Öneki', 'INV-',
                onTap: () => _showEditDialog('Fatura Öneki', 'INV-')),
          ]),
          const SizedBox(height: 16),
          _section('Yönetim', [ // TODO: i18n
            _item(Icons.people_outline, t('settings.users'),
                'Kullanıcıları ve rolleri yönet', // TODO: i18n
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/users')),
            _item(Icons.business_center_outlined, t('settings.company'),
                'Firma bilgileri ve fatura ayarları', // TODO: i18n
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/company')),
            _item(Icons.category_outlined, t('settings.sector'),
                'Ürün formu alanlarını özelleştirin', // TODO: i18n
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/sector')),
            // Sprint 33 #7: Firma kategori seçimi — global havuzdan firmanın
            // kullandığı kategorileri belirler. Daha önce route vardı ama
            // menüde link yoktu (audit gap).
            _item(Icons.account_tree_outlined, t('categories.title'),
                t('categories.company_setup_subtitle'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/categories/company-setup')),
          ]),
          // Sprint 23: Bildirimler section'ı (dummy switch'ler) Cihazlar &
          // Entegrasyonlar hub'ına taşındı. Hub: System tab > Cihazlar.
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
          // Sprint 23: Tek hub — yazıcı, e-posta, SMS, terazi, etiket yazıcı,
          // cash drawer, barkod tarayıcı, push, stok uyarısı hepsi burada.
          _section(t('integrations.title'), [
            _item(Icons.dashboard_customize, t('integrations.menu_label'),
                t('integrations.menu_subtitle'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/integrations')),
          ]),
          const SizedBox(height: 16),
          _section('Veri & Gizlilik', [
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
          ]),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tehlikeli Alan', // TODO: i18n
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                        fontSize: 15)),
                const SizedBox(height: 12),
                _item(Icons.logout, t('settings.logout'), '',
                    textColor: AppColors.danger,
                    onTap: () async {
                  final ok = await AppConfirmationDialog.show(
                    context: context,
                    title: t('settings.logout'),
                    message: 'Çıkış yapmak istediğinizden emin misiniz?', // TODO: i18n
                    icon: Icons.logout,
                    confirmText: t('settings.logout'),
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
    // Sprint 11o P0 — items arasına ince divider; nefes alanı + görsel
    // hierarşi.
    final List<Widget> spacedItems = [];
    for (int i = 0; i < items.length; i++) {
      spacedItems.add(items[i]);
      if (i < items.length - 1) {
        spacedItems.add(Divider(
          height: 1,
          thickness: 1,
          color: AppColors.border.withValues(alpha: 0.5),
          indent: 8,
          endIndent: 8,
        ));
      }
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          const Divider(height: 16, thickness: 1, color: AppColors.border),
          ...spacedItems,
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
    // Sprint 11n — sidebar/menu paterniyle uyumlu hover + tap state'i için
    // ayrı _SettingsItem widget'ına delege ediyoruz. Tema primary reactive
    // (ref.watch(themeProvider).resolvedPrimary) — kullanıcı tema rengini
    // değiştirdiğinde tüm settings item'ları anında güncellenir.
    return _SettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      textColor: textColor,
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

/// Sprint 11n — Ayarlar tab'ları için belirgin hover + tap pressed state'li
/// liste item'ı. Tema primary reactive (themeProvider.resolvedPrimary).
/// Sidebar/menu kart paterniyle aynı dil:
///   normal  → şeffaf bg, primary tonlu icon container
///   hover   → primary @8% bg + 3px sol primary accent + cursor pointer
///   pressed → primary @14% bg + scale 0.98 (mobile/touch geri bildirim)
class _SettingsItem extends ConsumerStatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
  });

  @override
  ConsumerState<_SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends ConsumerState<_SettingsItem> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.textColor ?? ref.watch(themeProvider).resolvedPrimary;
    final tappable = widget.onTap != null;
    final active = (_hovered || _pressed) && tappable;

    final Color bgColor;
    if (_pressed && tappable) {
      bgColor = accent.withValues(alpha: 0.14);
    } else if (_hovered && tappable) {
      bgColor = accent.withValues(alpha: 0.08);
    } else {
      bgColor = Colors.transparent;
    }

    // Sprint 11o P0 — Material + InkWell zinciri kaldırıldı (Windows pointer
    // çakışmasında InkWell hover event'ini emiyordu). Sidebar pattern:
    // MouseRegion + GestureDetector + AnimatedContainer. Splash/ripple Windows
    // desktop'ta gerek yok; manuel scale + bg yeterli geri bildirim.
    return MouseRegion(
      cursor: tappable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (tappable) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (tappable) setState(() => _hovered = false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: tappable
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: tappable
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: tappable
            ? () => setState(() => _pressed = false)
            : null,
        child: AnimatedScale(
          scale: _pressed && tappable ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                if (active)
                  Positioned(
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 3,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 8),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: active
                              ? accent
                              : accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          color: active
                              ? Colors.white
                              : (widget.textColor ?? accent),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 160),
                              style: TextStyle(
                                fontWeight:
                                    active ? FontWeight.w600 : FontWeight.w500,
                                color: active
                                    ? accent
                                    : (widget.textColor ??
                                        AppColors.textPrimary),
                                fontSize: 14,
                              ),
                              child: Text(widget.title),
                            ),
                            if (widget.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(widget.subtitle,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                            ],
                          ],
                        ),
                      ),
                      if (widget.trailing != null) widget.trailing!,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
