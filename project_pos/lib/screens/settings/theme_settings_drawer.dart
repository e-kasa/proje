import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import 'theme_settings_drawer_advanced.dart';

class ThemeSettingsDrawer extends ConsumerWidget {
  const ThemeSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeSettings.primaryColor.color,
                  themeSettings.primaryColor.color.withOpacity(0.8),
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
                        'Temanızı ve renk şemanızı seçin',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
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
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Mode Section
                  _buildSectionTitle('Tema Modu', Icons.brightness_6),
                  const SizedBox(height: 12),
                  _buildThemeModeOptions(themeSettings, themeNotifier),

                  const SizedBox(height: 32),

                  // Primary Color Section
                  _buildSectionTitle('Ana Renk', Icons.color_lens),
                  const SizedBox(height: 12),
                  _buildPrimaryColorOptions(themeSettings, themeNotifier),

                  const SizedBox(height: 32),

                  // Material You Toggle
                  _buildMaterialYouToggle(themeSettings, themeNotifier),

                  const SizedBox(height: 32),

                  // Reset Button
                  _buildResetButton(themeNotifier, context),

                  const SizedBox(height: 20),

                  // Info Card
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildThemeModeOptions(ThemeSettings settings, ThemeNotifier notifier) {
    return Row(
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

  Widget _buildPrimaryColorOptions(ThemeSettings settings, ThemeNotifier notifier) {
    return Wrap(
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
    );
  }

  Widget _buildMaterialYouToggle(ThemeSettings settings, ThemeNotifier notifier) {
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
            child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Material You',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Dinamik renkler (Material 3)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.useMaterialYou,
            onChanged: (_) => notifier.toggleMaterialYou(),
            activeColor: settings.primaryColor.color,
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(ThemeNotifier notifier, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          notifier.reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Tema varsayılana sıfırlandı'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.refresh),
        label: const Text(
          'Varsayılana Sıfırla',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade400, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
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
          const Expanded(
            child: Text(
              'Ayarlarınız otomatik olarak kaydedilir ve uygulama yeniden başlatıldığında korunur.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Theme Button Widget
class FloatingThemeButton extends StatelessWidget {
  const FloatingThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 80,
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const ThemeSettingsDrawerAdvanced(),
          );
        },
        heroTag: 'theme_settings',
        backgroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.palette, color: Colors.blue),
      ),
    );
  }
}
