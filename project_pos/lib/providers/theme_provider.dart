import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum AppThemeMode { light, dark, system }

enum LayoutMode {
  default_('Varsayılan'),
  compact('Kompakt'),
  modern('Modern');

  final String label;
  const LayoutMode(this.label);
}

enum WidthMode {
  fluid('Akışkan'),
  boxed('Kutulu');

  final String label;
  const WidthMode(this.label);
}

enum SidebarAppearance {
  light('Açık'),
  dark('Koyu'),
  colored('Renkli');

  final String label;
  const SidebarAppearance(this.label);
}

enum TopbarAppearance {
  light('Açık'),
  dark('Koyu'),
  colored('Renkli');

  final String label;
  const TopbarAppearance(this.label);
}

/// Renk presetleri — her preset bir gradient çifti tanımlar.
/// [color] gradient başlangıcı / primary renk
/// [endColor] gradient bitişi
enum PrimaryColorOption {
  sedcore('Sedcore',       Color(0xFF667eea), Color(0xFF764ba2)),
  ocean('Okyanus',         Color(0xFF0ea5e9), Color(0xFF2563eb)),
  emerald('Zümrüt',        Color(0xFF10b981), Color(0xFF059669)),
  sunset('Gün Batımı',     Color(0xFFf59e0b), Color(0xFFef4444)),
  rose('Gül',              Color(0xFFec4899), Color(0xFFa855f7)),
  midnight('Gece Yarısı',  Color(0xFF374151), Color(0xFF1e293b)),
  coral('Mercan',          Color(0xFFf97316), Color(0xFFec4899)),
  forest('Orman',          Color(0xFF22c55e), Color(0xFF14b8a6));

  final String label;
  final Color color;     // gradient start / primary
  final Color endColor;  // gradient end
  const PrimaryColorOption(this.label, this.color, this.endColor);

  /// Gradient oluştur
  LinearGradient get gradient => LinearGradient(
        colors: [color, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

// ─── ThemeSettings ────────────────────────────────────────────────────────────

class ThemeSettings {
  final AppThemeMode themeMode;
  final PrimaryColorOption primaryColor;
  final LayoutMode layoutMode;
  final WidthMode widthMode;
  final SidebarAppearance sidebarAppearance;
  final TopbarAppearance topbarAppearance;
  final bool useMaterialYou;
  final bool isRTL;
  final Color? customSidebarColor;
  final Color? customTopbarColor;
  /// Özel birincil renk (preset dışında). Null ise primaryColor.color kullanılır.
  final Color? customPrimaryColor;
  /// Yazı boyutu çarpanı: 0.85 (küçük) – 1.0 (normal) – 1.15 (büyük)
  final double fontScale;

  const ThemeSettings({
    this.themeMode = AppThemeMode.light,
    this.primaryColor = PrimaryColorOption.sedcore,
    this.layoutMode = LayoutMode.default_,
    this.widthMode = WidthMode.fluid,
    this.sidebarAppearance = SidebarAppearance.light,
    this.topbarAppearance = TopbarAppearance.colored,
    this.useMaterialYou = false,
    this.isRTL = false,
    this.customSidebarColor,
    this.customTopbarColor,
    this.customPrimaryColor,
    this.fontScale = 1.0,
  });

  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    PrimaryColorOption? primaryColor,
    LayoutMode? layoutMode,
    WidthMode? widthMode,
    SidebarAppearance? sidebarAppearance,
    TopbarAppearance? topbarAppearance,
    bool? useMaterialYou,
    bool? isRTL,
    Color? customSidebarColor,
    Color? customTopbarColor,
    Color? customPrimaryColor,
    double? fontScale,
    bool clearCustomPrimary = false,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      layoutMode: layoutMode ?? this.layoutMode,
      widthMode: widthMode ?? this.widthMode,
      sidebarAppearance: sidebarAppearance ?? this.sidebarAppearance,
      topbarAppearance: topbarAppearance ?? this.topbarAppearance,
      useMaterialYou: useMaterialYou ?? this.useMaterialYou,
      isRTL: isRTL ?? this.isRTL,
      customSidebarColor: customSidebarColor ?? this.customSidebarColor,
      customTopbarColor: customTopbarColor ?? this.customTopbarColor,
      customPrimaryColor: clearCustomPrimary ? null : (customPrimaryColor ?? this.customPrimaryColor),
      fontScale: fontScale ?? this.fontScale,
    );
  }

  /// Çözümlenmiş birincil renk (custom varsa custom, yoksa preset)
  Color get resolvedPrimary => customPrimaryColor ?? primaryColor.color;

  /// Çözümlenmiş gradient sonu
  Color get resolvedEnd => customPrimaryColor != null
      ? _darken(customPrimaryColor!, 0.15)
      : primaryColor.endColor;

  /// Çözümlenmiş gradient
  LinearGradient get resolvedGradient => LinearGradient(
        colors: [resolvedPrimary, resolvedEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'primaryColor': primaryColor.name,
        'layoutMode': layoutMode.name,
        'widthMode': widthMode.name,
        'sidebarAppearance': sidebarAppearance.name,
        'topbarAppearance': topbarAppearance.name,
        'useMaterialYou': useMaterialYou,
        'isRTL': isRTL,
        'customSidebarColor': customSidebarColor?.value,
        'customTopbarColor': customTopbarColor?.value,
        'customPrimaryColor': customPrimaryColor?.value,
        'fontScale': fontScale,
      };

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.light,
      ),
      primaryColor: PrimaryColorOption.values.firstWhere(
        (e) => e.name == json['primaryColor'],
        orElse: () => PrimaryColorOption.sedcore,
      ),
      layoutMode: LayoutMode.values.firstWhere(
        (e) => e.name == json['layoutMode'],
        orElse: () => LayoutMode.default_,
      ),
      widthMode: WidthMode.values.firstWhere(
        (e) => e.name == json['widthMode'],
        orElse: () => WidthMode.fluid,
      ),
      sidebarAppearance: SidebarAppearance.values.firstWhere(
        (e) => e.name == json['sidebarAppearance'],
        orElse: () => SidebarAppearance.light,
      ),
      topbarAppearance: TopbarAppearance.values.firstWhere(
        (e) => e.name == json['topbarAppearance'],
        orElse: () => TopbarAppearance.colored,
      ),
      useMaterialYou: json['useMaterialYou'] ?? false,
      isRTL: json['isRTL'] ?? false,
      customSidebarColor: json['customSidebarColor'] != null
          ? Color(json['customSidebarColor'])
          : null,
      customTopbarColor: json['customTopbarColor'] != null
          ? Color(json['customTopbarColor'])
          : null,
      customPrimaryColor: json['customPrimaryColor'] != null
          ? Color(json['customPrimaryColor'])
          : null,
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

// ─── ThemeNotifier ────────────────────────────────────────────────────────────

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier() : super(const ThemeSettings()) {
    _loadSettings();
  }

  static const String _storageKey = 'theme_settings_v3';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey)
          ?? prefs.getString('theme_settings_v2'); // migration
      if (raw == null) return;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = ThemeSettings.fromJson(json);
      } catch (_) {}
    } catch (e) {
      AppLogger.error('Tema ayarları yüklenemedi', tag: 'Theme', error: e);
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      AppLogger.error('Tema ayarları kaydedilemedi', tag: 'Theme', error: e);
    }
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setPrimaryColor(PrimaryColorOption color) {
    state = state.copyWith(primaryColor: color, clearCustomPrimary: true);
    _save();
  }

  void setCustomPrimaryColor(Color color) {
    state = state.copyWith(customPrimaryColor: color);
    _save();
  }

  void clearCustomPrimaryColor() {
    state = state.copyWith(clearCustomPrimary: true);
    _save();
  }

  void setLayoutMode(LayoutMode mode) {
    state = state.copyWith(layoutMode: mode);
    _save();
  }

  void setWidthMode(WidthMode mode) {
    state = state.copyWith(widthMode: mode);
    _save();
  }

  void setSidebarAppearance(SidebarAppearance a) {
    state = state.copyWith(sidebarAppearance: a);
    _save();
  }

  void setTopbarAppearance(TopbarAppearance a) {
    state = state.copyWith(topbarAppearance: a);
    _save();
  }

  void toggleMaterialYou() {
    state = state.copyWith(useMaterialYou: !state.useMaterialYou);
    _save();
  }

  void toggleRTL() {
    state = state.copyWith(isRTL: !state.isRTL);
    _save();
  }

  void setCustomSidebarColor(Color color) {
    state = state.copyWith(customSidebarColor: color);
    _save();
  }

  void setCustomTopbarColor(Color color) {
    state = state.copyWith(customTopbarColor: color);
    _save();
  }

  void setFontScale(double scale) {
    state = state.copyWith(fontScale: scale.clamp(0.8, 1.3));
    _save();
  }

  void reset() {
    state = const ThemeSettings();
    _save();
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>(
  (ref) => ThemeNotifier(),
);

/// Çözümlenmiş birincil renk
final resolvedPrimaryColorProvider = Provider<Color>((ref) {
  return ref.watch(themeProvider).resolvedPrimary;
});

/// Çözümlenmiş gradient
final resolvedGradientProvider = Provider<LinearGradient>((ref) {
  return ref.watch(themeProvider).resolvedGradient;
});

/// ThemeMode (Material)
final themeModeProvider = Provider<ThemeMode>((ref) {
  switch (ref.watch(themeProvider).themeMode) {
    case AppThemeMode.light:  return ThemeMode.light;
    case AppThemeMode.dark:   return ThemeMode.dark;
    case AppThemeMode.system: return ThemeMode.system;
  }
});

/// Light ThemeData
final lightThemeProvider = Provider<ThemeData>((ref) {
  final s = ref.watch(themeProvider);
  final primary = s.resolvedPrimary;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _topbarColor(s, Brightness.light),
      foregroundColor: _topbarForeground(s, Brightness.light),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _sidebarColor(s, Brightness.light),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: primary,
        selectedForegroundColor: Colors.white,
      ),
    ),
  );
});

/// Dark ThemeData
final darkThemeProvider = Provider<ThemeData>((ref) {
  final s = ref.watch(themeProvider);
  final primary = s.resolvedPrimary;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0f0f23),
    cardColor: const Color(0xFF1a1a2e),
    appBarTheme: AppBarTheme(
      backgroundColor: _topbarColor(s, Brightness.dark),
      foregroundColor: _topbarForeground(s, Brightness.dark),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _sidebarColor(s, Brightness.dark),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
  );
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _sidebarColor(ThemeSettings s, Brightness brightness) {
  switch (s.sidebarAppearance) {
    case SidebarAppearance.light:   return Colors.white;
    case SidebarAppearance.dark:    return const Color(0xFF1E1E2E);
    case SidebarAppearance.colored: return s.customSidebarColor ?? s.resolvedPrimary;
  }
}

Color _topbarColor(ThemeSettings s, Brightness brightness) {
  switch (s.topbarAppearance) {
    case TopbarAppearance.light:   return Colors.white;
    case TopbarAppearance.dark:    return const Color(0xFF1E1E2E);
    case TopbarAppearance.colored: return s.customTopbarColor ?? s.resolvedPrimary;
  }
}

Color _topbarForeground(ThemeSettings s, Brightness brightness) {
  switch (s.topbarAppearance) {
    case TopbarAppearance.light: return Colors.black87;
    case TopbarAppearance.dark:  return Colors.white;
    case TopbarAppearance.colored:
      final bg = s.customTopbarColor ?? s.resolvedPrimary;
      return ThemeData.estimateBrightnessForColor(bg) == Brightness.light
          ? Colors.black87
          : Colors.white;
  }
}

Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}
