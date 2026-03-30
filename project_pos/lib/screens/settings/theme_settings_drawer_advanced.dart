import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../providers/theme_provider.dart';

class ThemeSettingsDrawerAdvanced extends ConsumerStatefulWidget {
  const ThemeSettingsDrawerAdvanced({super.key});

  @override
  ConsumerState<ThemeSettingsDrawerAdvanced> createState() =>
      _ThemeSettingsDrawerAdvancedState();
}

class _ThemeSettingsDrawerAdvancedState
    extends ConsumerState<ThemeSettingsDrawerAdvanced> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(themeSettings),

          // Tab Bar
          _buildTabBar(),

          // Content
          Expanded(
            child: _buildContent(themeSettings, themeNotifier),
          ),

          // Footer
          _buildFooter(themeNotifier),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeSettings settings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            settings.primaryColor.color,
            settings.primaryColor.color.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.palette, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tema Özelleştirici',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tema, düzen ve renkleri özelleştirin',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Genel', 'Düzen', 'Renkler', 'Gelişmiş'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedSection == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedSection = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent(ThemeSettings settings, ThemeNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: IndexedStack(
        index: _selectedSection,
        children: [
          _buildGeneralSection(settings, notifier),
          _buildLayoutSection(settings, notifier),
          _buildColorsSection(settings, notifier),
          _buildAdvancedSection(settings, notifier),
        ],
      ),
    );
  }

  // GENEL SEKMESI
  Widget _buildGeneralSection(ThemeSettings settings, ThemeNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tema Modu', Icons.brightness_6),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemeModeCard(
                icon: Icons.light_mode,
                label: 'Açık',
                isSelected: settings.themeMode == AppThemeMode.light,
                onTap: () => notifier.setThemeMode(AppThemeMode.light),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemeModeCard(
                icon: Icons.dark_mode,
                label: 'Koyu',
                isSelected: settings.themeMode == AppThemeMode.dark,
                onTap: () => notifier.setThemeMode(AppThemeMode.dark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemeModeCard(
                icon: Icons.brightness_auto,
                label: 'Sistem',
                isSelected: settings.themeMode == AppThemeMode.system,
                onTap: () => notifier.setThemeMode(AppThemeMode.system),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        _buildSectionTitle('Ana Renk', Icons.color_lens),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: PrimaryColorOption.values.map((option) {
            final isSelected = settings.primaryColor == option;
            return InkWell(
              onTap: () => notifier.setPrimaryColor(option),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? option.color : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: option.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: option.color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: option.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // DÜZEN SEKMESI
  Widget _buildLayoutSection(ThemeSettings settings, ThemeNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Düzen Modu', Icons.view_quilt),
        const SizedBox(height: 12),
        Row(
          children: LayoutMode.values.map((mode) {
            final isSelected = settings.layoutMode == mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildOptionCard(
                  label: mode.label,
                  icon: _getLayoutIcon(mode),
                  isSelected: isSelected,
                  onTap: () => notifier.setLayoutMode(mode),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Genişlik', Icons.settings_overscan),
        const SizedBox(height: 12),
        Row(
          children: WidthMode.values.map((mode) {
            final isSelected = settings.widthMode == mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildOptionCard(
                  label: mode.label,
                  icon: mode == WidthMode.fluid
                      ? Icons.open_in_full
                      : Icons.crop_square,
                  isSelected: isSelected,
                  onTap: () => notifier.setWidthMode(mode),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // RENKLER SEKMESI
  Widget _buildColorsSection(ThemeSettings settings, ThemeNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ana Renk', Icons.color_lens),
        const SizedBox(height: 12),
        _buildColorPickerSection(
          'Ana renk seçin',
          settings.primaryColor.color,
          (color) {
            // Find closest preset or use custom
            final preset = _findClosestPreset(color);
            if (preset != null) {
              notifier.setPrimaryColor(preset);
            }
          },
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Sidebar Görünümü', Icons.menu),
        const SizedBox(height: 12),
        Row(
          children: SidebarAppearance.values.map((appearance) {
            final isSelected = settings.sidebarAppearance == appearance;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildOptionCard(
                  label: appearance.label,
                  icon: _getAppearanceIcon(appearance),
                  isSelected: isSelected,
                  onTap: () => notifier.setSidebarAppearance(appearance),
                ),
              ),
            );
          }).toList(),
        ),

        if (settings.sidebarAppearance == SidebarAppearance.colored) ...[
          const SizedBox(height: 12),
          _buildColorPickerSection(
            'Özel Sidebar rengi',
            settings.customSidebarColor ?? settings.primaryColor.color,
            (color) => notifier.setCustomSidebarColor(color),
          ),
        ],

        const SizedBox(height: 24),

        _buildSectionTitle('Topbar Görünümü', Icons.horizontal_rule),
        const SizedBox(height: 12),
        Row(
          children: TopbarAppearance.values.map((appearance) {
            final isSelected = settings.topbarAppearance == appearance;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildOptionCard(
                  label: appearance.label,
                  icon: _getAppearanceIcon(appearance),
                  isSelected: isSelected,
                  onTap: () => notifier.setTopbarAppearance(appearance),
                ),
              ),
            );
          }).toList(),
        ),

        if (settings.topbarAppearance == TopbarAppearance.colored) ...[
          const SizedBox(height: 12),
          _buildColorPickerSection(
            'Özel Topbar rengi',
            settings.customTopbarColor ?? settings.primaryColor.color,
            (color) => notifier.setCustomTopbarColor(color),
          ),
        ],
      ],
    );
  }

  Widget _buildColorPickerSection(
    String label,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    return InkWell(
      onTap: () => _showColorPickerDialog(currentColor, onColorChanged),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.color_lens, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorPickerDialog(
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) async {
    Color selectedColor = currentColor;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Renk Seçin'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: selectedColor,
              onColorChanged: (Color color) {
                selectedColor = color;
              },
              width: 40,
              height: 40,
              borderRadius: 8,
              spacing: 8,
              runSpacing: 8,
              wheelDiameter: 200,
              heading: const Text(
                'Hazır Renkler',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subheading: const Text(
                'Özel Renk',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              wheelSubheading: const Text(
                'Renk Tekeri',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              showMaterialName: false,
              showColorName: false,
              showColorCode: true,
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                longPressMenu: true,
              ),
              materialNameTextStyle: const TextStyle(fontSize: 12),
              colorNameTextStyle: const TextStyle(fontSize: 12),
              colorCodeTextStyle: const TextStyle(fontSize: 12),
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.bw: false,
                ColorPickerType.custom: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                onColorChanged(selectedColor);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Seç'),
            ),
          ],
        );
      },
    );
  }

  PrimaryColorOption? _findClosestPreset(Color color) {
    double minDistance = double.infinity;
    PrimaryColorOption? closest;

    for (var preset in PrimaryColorOption.values) {
      final distance = _colorDistance(color, preset.color);
      if (distance < minDistance) {
        minDistance = distance;
        closest = preset;
      }
    }

    // If color is very close to a preset (within 10% tolerance), use preset
    return minDistance < 30 ? closest : null;
  }

  double _colorDistance(Color c1, Color c2) {
    final r = c1.red - c2.red;
    final g = c1.green - c2.green;
    final b = c1.blue - c2.blue;
    return (r * r + g * g + b * b).toDouble();
  }

  // GELİŞMİŞ SEKMESI
  Widget _buildAdvancedSection(ThemeSettings settings, ThemeNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggleCard(
          icon: Icons.auto_awesome,
          title: 'Material You',
          subtitle: 'Dinamik renkler (Material 3)',
          value: settings.useMaterialYou,
          onChanged: (_) => notifier.toggleMaterialYou(),
          color: Colors.purple,
        ),

        const SizedBox(height: 16),

        _buildToggleCard(
          icon: Icons.format_textdirection_r_to_l,
          title: 'RTL Desteği',
          subtitle: 'Sağdan sola metin yönü',
          value: settings.isRTL,
          onChanged: (_) => notifier.toggleRTL(),
          color: Colors.orange,
        ),

        const SizedBox(height: 24),

        _buildInfoCard(
          'ℹ️ Gelişmiş Özellikler',
          'Bu ayarlar deneysel olabilir. Değişiklikler anında uygulanır.',
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                notifier.reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Varsayılana sıfırlandı')),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Sıfırla'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Tamam'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLayoutIcon(LayoutMode mode) {
    switch (mode) {
      case LayoutMode.default_:
        return Icons.view_sidebar;
      case LayoutMode.compact:
        return Icons.view_compact;
      case LayoutMode.modern:
        return Icons.auto_awesome;
    }
  }

  IconData _getAppearanceIcon(dynamic appearance) {
    if (appearance is SidebarAppearance || appearance is TopbarAppearance) {
      final name = appearance.toString().split('.').last;
      switch (name) {
        case 'light':
          return Icons.light_mode;
        case 'dark':
          return Icons.dark_mode;
        case 'colored':
          return Icons.palette;
        default:
          return Icons.settings;
      }
    }
    return Icons.settings;
  }
}
