import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';

/// Theme Mode (Light/Dark)
enum AppThemeMode { light, dark, system }

/// Layout Mode
enum LayoutMode {
  default_('Varsayılan'),
  compact('Kompakt'),
  modern('Modern');

  final String label;
  const LayoutMode(this.label);
}

/// Width Mode
enum WidthMode {
  fluid('Akışkan'),
  boxed('Kutulu');

  final String label;
  const WidthMode(this.label);
}

/// Sidebar Appearance
enum SidebarAppearance {
  light('Açık'),
  dark('Koyu'),
  colored('Renkli');

  final String label;
  const SidebarAppearance(this.label);
}

/// Topbar Appearance
enum TopbarAppearance {
  light('Açık'),
  dark('Koyu'),
  colored('Renkli');

  final String label;
  const TopbarAppearance(this.label);
}

/// Primary Color Options
enum PrimaryColorOption {
  blue('Mavi', Color(0xFF1976D2)),
  green('Yeşil', Color(0xFF4CAF50)),
  purple('Mor', Color(0xFF9C27B0)),
  orange('Turuncu', Color(0xFFFF9800)),
  red('Kırmızı', Color(0xFFF44336)),
  teal('Turkuaz', Color(0xFF009688)),
  pink('Pembe', Color(0xFFE91E63)),
  indigo('Lacivert', Color(0xFF3F51B5));

  final String label;
  final Color color;
  const PrimaryColorOption(this.label, this.color);
}

/// Tema ayarları durum nesnesi.
///
/// Tema modu, ana renk, layout, sidebar/topbar görünümü gibi
/// tüm UI konfigürasyonlarını tutar. JSON serialize/deserialize destekler.
class ThemeSettings {
  // Basic
  final AppThemeMode themeMode;
  final PrimaryColorOption primaryColor;

  // Layout
  final LayoutMode layoutMode;
  final WidthMode widthMode;

  // Appearance
  final SidebarAppearance sidebarAppearance;
  final TopbarAppearance topbarAppearance;

  // Advanced
  final bool useMaterialYou;
  final bool isRTL;
  final Color? customSidebarColor;
  final Color? customTopbarColor;

  const ThemeSettings({
    this.themeMode = AppThemeMode.light,
    this.primaryColor = PrimaryColorOption.blue,
    this.layoutMode = LayoutMode.default_,
    this.widthMode = WidthMode.fluid,
    this.sidebarAppearance = SidebarAppearance.light,
    this.topbarAppearance = TopbarAppearance.colored,
    this.useMaterialYou = true,
    this.isRTL = false,
    this.customSidebarColor,
    this.customTopbarColor,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.light,
      ),
      primaryColor: PrimaryColorOption.values.firstWhere(
        (e) => e.name == json['primaryColor'],
        orElse: () => PrimaryColorOption.blue,
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
      useMaterialYou: json['useMaterialYou'] ?? true,
      isRTL: json['isRTL'] ?? false,
      customSidebarColor: json['customSidebarColor'] != null
          ? Color(json['customSidebarColor'])
          : null,
      customTopbarColor: json['customTopbarColor'] != null
          ? Color(json['customTopbarColor'])
          : null,
    );
  }
}

/// Tema ayarları yöneticisi — dark/light mod, renkler ve layout tercihlerini yönetir.
///
/// Ayarlar [SharedPreferences] üzerinde JSON formatında saklanır.
/// Eski pipe-delimited (`|`) formattan JSON'a otomatik migrasyon destekler.
/// Her değişiklikte kalıcı depoya kaydeder.
class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier() : super(const ThemeSettings()) {
    _loadSettings();
  }

  static const String _storageKey = 'theme_settings_v2';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;

      // Try JSON first
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = ThemeSettings.fromJson(json);
        return;
      } catch (_) {}

      // Fallback: try pipe-delimited (migration from old format)
      try {
        final parts = raw.split('|');
        if (parts.length >= 8) {
          state = ThemeSettings(
            themeMode: AppThemeMode.values.firstWhere(
              (e) => e.name == parts[0],
              orElse: () => AppThemeMode.light,
            ),
            primaryColor: PrimaryColorOption.values.firstWhere(
              (e) => e.name == parts[1],
              orElse: () => PrimaryColorOption.blue,
            ),
            layoutMode: LayoutMode.values.firstWhere(
              (e) => e.name == parts[2],
              orElse: () => LayoutMode.default_,
            ),
            widthMode: WidthMode.values.firstWhere(
              (e) => e.name == parts[3],
              orElse: () => WidthMode.fluid,
            ),
            sidebarAppearance: SidebarAppearance.values.firstWhere(
              (e) => e.name == parts[4],
              orElse: () => SidebarAppearance.light,
            ),
            topbarAppearance: TopbarAppearance.values.firstWhere(
              (e) => e.name == parts[5],
              orElse: () => TopbarAppearance.colored,
            ),
            useMaterialYou: parts[6] == 'true',
            isRTL: parts[7] == 'true',
            customSidebarColor: parts.length > 8 && parts[8] != 'null'
                ? Color(int.parse(parts[8]))
                : null,
            customTopbarColor: parts.length > 9 && parts[9] != 'null'
                ? Color(int.parse(parts[9]))
                : null,
          );
          // Re-save as JSON for migration
          _saveSettings();
        }
      } catch (e) {
        AppLogger.warning('Tema ayarları okunamadı, varsayılana dönülüyor', tag: 'ThemeProvider');
      }
    } catch (e) {
      AppLogger.error('Tema ayarları yüklenemedi', tag: 'Theme', error: e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      AppLogger.error('Tema ayarları kaydedilemedi', tag: 'Theme', error: e);
    }
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveSettings();
  }

  void setPrimaryColor(PrimaryColorOption color) {
    state = state.copyWith(primaryColor: color);
    _saveSettings();
  }

  void setLayoutMode(LayoutMode mode) {
    state = state.copyWith(layoutMode: mode);
    _saveSettings();
  }

  void setWidthMode(WidthMode mode) {
    state = state.copyWith(widthMode: mode);
    _saveSettings();
  }

  void setSidebarAppearance(SidebarAppearance appearance) {
    state = state.copyWith(sidebarAppearance: appearance);
    _saveSettings();
  }

  void setTopbarAppearance(TopbarAppearance appearance) {
    state = state.copyWith(topbarAppearance: appearance);
    _saveSettings();
  }

  void toggleMaterialYou() {
    state = state.copyWith(useMaterialYou: !state.useMaterialYou);
    _saveSettings();
  }

  void toggleRTL() {
    state = state.copyWith(isRTL: !state.isRTL);
    _saveSettings();
  }

  void setCustomSidebarColor(Color color) {
    state = state.copyWith(customSidebarColor: color);
    _saveSettings();
  }

  void setCustomTopbarColor(Color color) {
    state = state.copyWith(customTopbarColor: color);
    _saveSettings();
  }

  void reset() {
    state = const ThemeSettings();
    _saveSettings();
  }
}

/// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  return ThemeNotifier();
});

/// Computed ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(themeProvider);
  switch (settings.themeMode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});

/// Light Theme Data
final lightThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeProvider);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: settings.primaryColor.color,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _getTopbarColor(settings, Brightness.light),
      foregroundColor: _getTopbarForeground(settings, Brightness.light),
      elevation: 0,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _getSidebarColor(settings, Brightness.light),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: settings.primaryColor.color,
    ),
  );
});

/// Dark Theme Data
final darkThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeProvider);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: settings.primaryColor.color,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _getTopbarColor(settings, Brightness.dark),
      foregroundColor: _getTopbarForeground(settings, Brightness.dark),
      elevation: 0,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _getSidebarColor(settings, Brightness.dark),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: settings.primaryColor.color,
    ),
  );
});

// Helper functions
Color _getSidebarColor(ThemeSettings settings, Brightness brightness) {
  switch (settings.sidebarAppearance) {
    case SidebarAppearance.light:
      return Colors.white;
    case SidebarAppearance.dark:
      return const Color(0xFF1E1E1E);
    case SidebarAppearance.colored:
      return settings.customSidebarColor ?? settings.primaryColor.color;
  }
}

Color _getTopbarColor(ThemeSettings settings, Brightness brightness) {
  switch (settings.topbarAppearance) {
    case TopbarAppearance.light:
      return Colors.white;
    case TopbarAppearance.dark:
      return const Color(0xFF1E1E1E);
    case TopbarAppearance.colored:
      return settings.customTopbarColor ?? settings.primaryColor.color;
  }
}

Color _getTopbarForeground(ThemeSettings settings, Brightness brightness) {
  switch (settings.topbarAppearance) {
    case TopbarAppearance.light:
      return Colors.black87;
    case TopbarAppearance.dark:
      return Colors.white;
    case TopbarAppearance.colored:
      // Use light or dark text based on background color brightness
      final bgColor = settings.customTopbarColor ?? settings.primaryColor.color;
      return ThemeData.estimateBrightnessForColor(bgColor) == Brightness.light
          ? Colors.black87
          : Colors.white;
  }
}