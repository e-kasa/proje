import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/sector_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/i18n_helper.dart';

/// Şirket sektörünü manuel olarak ayarlama ekranı.
/// Backend'den otomatik gelmeyen durumlarda veya demo/test için kullanılır.
class SectorSettingsScreen extends ConsumerWidget {
  const SectorSettingsScreen({super.key});

  static const _prefKey = 'override_sector_type';

  Future<void> _selectSector(
      BuildContext context, WidgetRef ref, SectorType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, type.apiValue);

    // Kullanıcı modelini güncelle — sectorType alanını set et
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(authProvider.notifier).updateUser(
            user.copyWith(sectorType: type.apiValue),
          );
    }

    if (context.mounted) {
      final t = i18nOf(ref);
      AppToast.success(context, '${t('settings.sector')}: ${type.displayName}'); // TODO: i18n better message key
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final user = ref.watch(authProvider).user;
    final currentSector =
        SectorTypeExt.fromApi(user?.sectorType);

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('settings.sector'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.infoGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sektör seçimi; ürün ekleme formlarındaki alanları, '
                      'etiketleri ve zorunlu alanları otomatik olarak düzenler. '
                      'Normalde backend\'den otomatik gelir.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t('settings.sector'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...SectorType.values.map(
              (type) => _SectorCard(
                type: type,
                isSelected: type == currentSector,
                onTap: () => _selectSector(context, ref, type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  final SectorType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectorCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  (IconData, Gradient, List<String>) get _meta => switch (type) {
        SectorType.autoParts => (
            Icons.car_repair,
            AppGradients.primaryGradient,
            ['OEM numarası', 'Raf kodu (zorunlu)', 'Araç uyumu', 'Çapraz referans', 'Marka (zorunlu)'],
          ),
        SectorType.general => (
            Icons.storefront_outlined,
            AppGradients.successGradient,
            ['Temel ürün bilgileri', 'Barkod', 'Depo konumu', 'Kategori'],
          ),
        SectorType.technology => (
            Icons.devices_outlined,
            AppGradients.infoGradient,
            ['Seri numarası / IMEI', 'Garanti süresi', 'Renk varyantı', 'Marka (zorunlu)'],
          ),
        SectorType.footwear => (
            Icons.checkroom_outlined,
            AppGradients.sunsetGradient,
            ['Numara / Beden varyantı', 'Renk varyantı', 'Koleksiyon', 'Marka (zorunlu)'],
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, gradient, features) = _meta;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isSelected ? gradient : null,
                  color: isSelected
                      ? null
                      : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textMuted,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: features
                          .map((f) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  f,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color:
                                        AppColors.textSecondary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              // Check
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 22)
                    : const Icon(Icons.radio_button_unchecked,
                        color: AppColors.border, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
