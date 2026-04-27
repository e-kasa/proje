import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/widgets/quick_add_product_modal.dart';

/// Sprint 12 W4.1 — "Ürün Ekle" disambiguation modal.
///
/// Inventory list FAB → bu sheet → kullanıcı 4 yöntemden birini seçer:
/// Hızlı Ekle / Tam Sihirbaz / Toplu Tablo / PDF-Görsel.
///
/// Eski davranış: FAB doğrudan Quick Add'a gidiyordu — kullanıcının diğer
/// yöntemleri (wizard, batch, bulk-import) keşfetmesi zordu.
class ProductAddMethodSheet {
  /// `result` bool: en az bir ürün eklendiyse true (ana ekran reload tetikler).
  static Future<bool> show(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductAddMethodSheetContent(parentRef: ref),
    );
    return result ?? false;
  }
}

class _ProductAddMethodSheetContent extends ConsumerWidget {
  final WidgetRef parentRef;

  const _ProductAddMethodSheetContent({required this.parentRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tutaç
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Başlık
          Text(
            t('product.add_method_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('product.add_method_subtitle'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          _MethodTile(
            icon: Icons.flash_on_rounded,
            iconColor: AppColors.success,
            title: t('product.add_quick'),
            subtitle: t('product.add_quick_desc'),
            onTap: () async {
              Navigator.of(context).pop();
              final result = await showQuickAddProductModal(context);
              if (result == true) {
                // Sheet kapandı — caller bool true alacak.
              }
            },
          ),
          const SizedBox(height: 8),
          _MethodTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.primary,
            title: t('product.add_full'),
            subtitle: t('product.add_full_desc'),
            onTap: () {
              Navigator.of(context).pop(true);
              context.push('/inventory/add-product');
            },
          ),
          const SizedBox(height: 8),
          _MethodTile(
            icon: Icons.table_rows_rounded,
            iconColor: AppColors.info,
            title: t('product.add_batch'),
            subtitle: t('product.add_batch_desc'),
            onTap: () {
              Navigator.of(context).pop(true);
              context.push('/inventory/batch-entry');
            },
          ),
          const SizedBox(height: 8),
          _MethodTile(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: AppColors.warning,
            title: t('product.add_pdf'),
            subtitle: t('product.add_pdf_desc'),
            onTap: () {
              Navigator.of(context).pop(true);
              context.push('/bulk-import');
            },
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
