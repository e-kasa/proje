import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:project_pos/providers/theme_provider.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// Gelişmiş tema özelleştirici — bottom sheet olarak açılır.
/// Settings ekranındaki temel ayarlara ek olarak özel renk seçimi sunar.
class ThemeSettingsDrawerAdvanced extends ConsumerStatefulWidget {
  const ThemeSettingsDrawerAdvanced({super.key});

  @override
  ConsumerState<ThemeSettingsDrawerAdvanced> createState() =>
      _ThemeSettingsDrawerAdvancedState();
}

class _ThemeSettingsDrawerAdvancedState
    extends ConsumerState<ThemeSettingsDrawerAdvanced>
    with SingleTickerProviderStateMixin {
  String Function(String) get t => i18nOf(ref);
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s        = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final primary  = s.resolvedPrimary;
    final gradient = s.resolvedGradient;
    final bg       = isDark ? const Color(0xFF0f0f23) : AppColors.bgLight;
    final cardBg   = isDark ? const Color(0xFF1a1a2e) : Colors.white;
    final tabBg    = isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade100;
    final borderC  = isDark ? const Color(0xFF2E2E3E) : AppColors.border;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.palette_outlined, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('settings.theme'), // TODO: i18n theme_customizer key
                    style: const TextStyle(color: Colors.white,
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('Renk, düzen ve özel renkler', // TODO: i18n
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ]),
        ),

        // ── Tab Bar ─────────────────────────────────────────────────────────
        Container(
          color: tabBg,
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(text: t('settings.theme')),
              Tab(text: 'Düzen'), // TODO: i18n
              Tab(text: 'Özel Renk'), // TODO: i18n
            ],
          ),
        ),

        // ── Content ─────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildThemeTab(s, notifier, isDark, primary, cardBg, borderC),
              _buildLayoutTab(s, notifier, isDark, primary, cardBg, borderC),
              _buildCustomColorTab(s, notifier, isDark, primary, cardBg, borderC),
            ],
          ),
        ),

        // ── Footer ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(top: BorderSide(color: borderC)),
          ),
          child: Row(children: [
            Expanded(
              child: AppButton.outline(
                text: t('common.reset'), // TODO: i18n key common.reset
                icon: Icons.restart_alt,
                onPressed: () {
                  notifier.reset();
                  AppToast.success(context, t('settings.theme')); // TODO: i18n theme_reset key
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.primary(
                text: t('common.ok'), // TODO: i18n key common.ok
                icon: Icons.check,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TEMA SEKMESİ
  // ═══════════════════════════════════════════════════════
  Widget _buildThemeTab(ThemeSettings s, ThemeNotifier notifier, bool isDark,
      Color primary, Color cardBg, Color borderC) {
    final unselBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tabTitle('Tema Modu', Icons.brightness_6),
        const SizedBox(height: 10),
        Row(
          children: [
            (AppThemeMode.light,  Icons.light_mode_outlined,  'Açık'),
            (AppThemeMode.dark,   Icons.dark_mode_outlined,   'Koyu'),
            (AppThemeMode.system, Icons.brightness_auto,      'Sistem'),
          ].asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            final sel = s.themeMode == opt.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => notifier.setThemeMode(opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? primary.withValues(alpha: isDark ? 0.2 : 0.08)
                          : unselBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? primary : borderC,
                          width: sel ? 2 : 1),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(opt.$2,
                          size: 22,
                          color: sel ? primary : AppColors.textMuted),
                      const SizedBox(height: 5),
                      Text(opt.$3,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: sel
                                  ? primary
                                  : AppColors.textSecondary)),
                    ]),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        _tabTitle('Ana Renk', Icons.color_lens_outlined),
        const SizedBox(height: 10),

        ..._colorChipRows(s, notifier, isDark, cardBg, borderC),
      ]),
    );
  }

  List<Widget> _colorChipRows(ThemeSettings s, ThemeNotifier notifier,
      bool isDark, Color cardBg, Color borderC) {
    final items = PrimaryColorOption.values;
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
                  width: isSel ? 1.5 : 1),
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
    return rows;
  }

  // ═══════════════════════════════════════════════════════
  // DÜZEN SEKMESİ
  // ═══════════════════════════════════════════════════════
  Widget _buildLayoutTab(ThemeSettings s, ThemeNotifier notifier, bool isDark,
      Color primary, Color cardBg, Color borderC) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tabTitle('Düzen Modu', Icons.view_quilt_outlined),
        const SizedBox(height: 10),
        ...[
          (LayoutMode.default_, Icons.view_agenda_outlined,
              'Varsayılan', 'Standart boşluk ve boyutlar'),
          (LayoutMode.compact, Icons.density_small,
              'Kompakt', 'Daha fazla içerik, daha az boşluk'),
          (LayoutMode.modern, Icons.auto_awesome_mosaic,
              'Modern', 'Kart tabanlı düzen'),
        ].map((opt) {
          final sel = s.layoutMode == opt.$1;
          return GestureDetector(
            onTap: () => notifier.setLayoutMode(opt.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: sel
                    ? primary.withValues(alpha: isDark ? 0.2 : 0.07)
                    : cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? primary : borderC,
                    width: sel ? 1.5 : 1),
              ),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: sel
                        ? primary.withValues(alpha: 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.bgLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(opt.$2, size: 17,
                      color: sel ? primary : AppColors.textMuted),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.$3,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: sel
                                  ? primary
                                  : (isDark
                                      ? Colors.white70
                                      : AppColors.textPrimary))),
                      const SizedBox(height: 1),
                      Text(opt.$4,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted)),
                    ])),
                if (sel)
                  Icon(Icons.check_circle, color: primary, size: 17),
              ]),
            ),
          );
        }),

        const SizedBox(height: 20),
        _tabTitle('Genişlik Modu', Icons.settings_overscan_outlined),
        const SizedBox(height: 10),
        Row(children: WidthMode.values.asMap().entries.map((e) {
          final i   = e.key;
          final mode = e.value;
          final sel  = s.widthMode == mode;
          final icon = mode == WidthMode.fluid
              ? Icons.open_in_full
              : Icons.crop_square;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < WidthMode.values.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => notifier.setWidthMode(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: sel
                        ? primary.withValues(alpha: isDark ? 0.2 : 0.07)
                        : cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? primary : borderC,
                        width: sel ? 1.5 : 1),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 20,
                        color: sel ? primary : AppColors.textMuted),
                    const SizedBox(height: 5),
                    Text(mode.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: sel
                                ? primary
                                : AppColors.textSecondary)),
                  ]),
                ),
              ),
            ),
          );
        }).toList()),

        const SizedBox(height: 20),
        _tabTitle('Kenar & Üst Çubuk', Icons.dashboard_customize_outlined),
        const SizedBox(height: 10),
        _barRow('Kenar Çubuğu', Icons.vertical_split_outlined,
            SidebarAppearance.values.map((a) => a.label).toList(),
            s.sidebarAppearance.index,
            (i) => notifier.setSidebarAppearance(SidebarAppearance.values[i]),
            isDark, primary, cardBg, borderC),
        const SizedBox(height: 8),
        _barRow('Üst Çubuk', Icons.horizontal_split_outlined,
            TopbarAppearance.values.map((a) => a.label).toList(),
            s.topbarAppearance.index,
            (i) => notifier.setTopbarAppearance(TopbarAppearance.values[i]),
            isDark, primary, cardBg, borderC),
      ]),
    );
  }

  Widget _barRow(String label, IconData icon, List<String> opts, int selectedIdx,
      Function(int) onSelect, bool isDark, Color primary,
      Color cardBg, Color borderC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textPrimary))),
        Row(children: opts.asMap().entries.map((e) {
          final sel = selectedIdx == e.key;
          return GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sel
                    ? primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: sel ? primary : borderC, width: 1),
              ),
              child: Text(e.value,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: sel
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: sel ? primary : AppColors.textMuted)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ÖZEL RENK SEKMESİ
  // ═══════════════════════════════════════════════════════
  Widget _buildCustomColorTab(ThemeSettings s, ThemeNotifier notifier,
      bool isDark, Color primary, Color cardBg, Color borderC) {
    final currentCustom = s.customPrimaryColor ?? s.resolvedPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tabTitle('Özel Ana Renk', Icons.color_lens_outlined),
        const SizedBox(height: 8),
        Text('Hazır renk presetleri dışında istediğiniz rengi seçin.',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 14),

        // Mevcut renk göstergesi
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderC),
          ),
          child: Row(children: [
            // Gradient preview
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: s.resolvedGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(
                    color: s.resolvedPrimary.withValues(alpha: 0.4),
                    blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.customPrimaryColor != null
                        ? 'Özel Renk'
                        : s.primaryColor.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#${(s.resolvedPrimary.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontFamily: 'monospace'),
                  ),
                ])),
            if (s.customPrimaryColor != null)
              TextButton(
                onPressed: () {
                  notifier.clearCustomPrimaryColor();
                  AppToast.info(context, 'Özel renk kaldırıldı');
                },
                child: const Text('Sıfırla', style: TextStyle(fontSize: 12)),
              ),
          ]),
        ),
        const SizedBox(height: 16),

        // Renk seçici
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderC),
          ),
          padding: const EdgeInsets.all(12),
          child: ColorPicker(
            color: currentCustom,
            onColorChanged: (color) => notifier.setCustomPrimaryColor(color),
            width: 36,
            height: 36,
            borderRadius: 8,
            spacing: 6,
            runSpacing: 6,
            wheelDiameter: 220,
            heading: Text('Hazır Renkler',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary)),
            subheading: Text('Ton Seçimi',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary)),
            wheelSubheading: Text('Renk Tekeri',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary)),
            showMaterialName: false,
            showColorName: false,
            showColorCode: true,
            colorCodeHasColor: true,
            copyPasteBehavior: const ColorPickerCopyPasteBehavior(
              longPressMenu: true,
              copyButton: true,
              pasteButton: true,
            ),
            pickersEnabled: const {
              ColorPickerType.both:    false,
              ColorPickerType.primary: true,
              ColorPickerType.accent:  true,
              ColorPickerType.bw:      false,
              ColorPickerType.custom:  false,
              ColorPickerType.wheel:   true,
            },
          ),
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: isDark ? 0.15 : 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: primary.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 16,
                color: primary.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Seçilen renk otomatik olarak tüm AppBar, Scaffold ve butonlara uygulanır.',
                style: TextStyle(fontSize: 11,
                    color: isDark ? Colors.white60 : AppColors.textSecondary),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─── Helper ─────────────────────────────────────────────────────────────────
  Widget _tabTitle(String text, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 6),
      Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3)),
    ]);
  }
}
