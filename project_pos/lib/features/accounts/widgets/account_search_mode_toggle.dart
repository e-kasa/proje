import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// Sprint 11e — Cari adı / Plaka arama modu toggle.
///
/// AccountsList sol panelinde arama kutusunun üstünde gösterilir;
/// `AccountsListPanel` sektör autoParts kontrolü ile koşullu render eder.
/// Tasarım: mevcut filter chip stiliyle (beyaz arka, selected info rengi)
/// tutarlı 2 segment.
class AccountSearchModeToggle extends ConsumerWidget {
  /// 'name' | 'plate'
  final String current;
  final ValueChanged<String> onChange;

  const AccountSearchModeToggle({
    super.key,
    required this.current,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          _segment(
            label: t('accounts.search_mode_name'),
            icon: Icons.person_outline,
            value: 'name',
          ),
          const SizedBox(width: 6),
          _segment(
            label: t('accounts.search_mode_plate'),
            icon: Icons.directions_car_outlined,
            value: 'plate',
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final selected = current == value;
    final color = selected ? AppColors.info : AppColors.textPrimary;
    return InkWell(
      onTap: () => onChange(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.info.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.info : AppColors.border,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
