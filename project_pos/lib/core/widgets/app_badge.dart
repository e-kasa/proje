import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

enum BadgeVariant { primary, success, warning, danger, info, secondary }

/// Merkezi Badge/Chip Widget
class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final IconData? icon;
  final bool outlined;
  /// Doğrudan renk belirtmek için (variant yerine kullanılır)
  final Color? color;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.primary,
    this.icon,
    this.outlined = false,
    this.color,
  });

  factory AppBadge.success(String text, {IconData? icon}) {
    return AppBadge(text: text, variant: BadgeVariant.success, icon: icon);
  }

  factory AppBadge.warning(String text, {IconData? icon}) {
    return AppBadge(text: text, variant: BadgeVariant.warning, icon: icon);
  }

  factory AppBadge.danger(String text, {IconData? icon}) {
    return AppBadge(text: text, variant: BadgeVariant.danger, icon: icon);
  }

  factory AppBadge.info(String text, {IconData? icon}) {
    return AppBadge(text: text, variant: BadgeVariant.info, icon: icon);
  }

  @override
  Widget build(BuildContext context) {
    final colors = color != null
        ? {'color': color!, 'bg': color!.withValues(alpha: 0.12)}
        : _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing8,
        vertical: AppConstants.spacing4,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : colors['bg'],
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: outlined ? Border.all(color: colors['color']!, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: colors['color']),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors['color'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColors() {
    switch (variant) {
      case BadgeVariant.primary:
        return {'color': AppColors.primary, 'bg': AppColors.primary.withValues(alpha: 0.1)};
      case BadgeVariant.success:
        return {'color': AppColors.success, 'bg': AppColors.bgSuccess};
      case BadgeVariant.warning:
        return {'color': AppColors.warning, 'bg': AppColors.bgWarning};
      case BadgeVariant.danger:
        return {'color': AppColors.danger, 'bg': AppColors.bgDanger};
      case BadgeVariant.info:
        return {'color': AppColors.info, 'bg': AppColors.bgInfo};
      case BadgeVariant.secondary:
        return {'color': AppColors.textSecondary, 'bg': AppColors.bgLight};
    }
  }
}

/// Status Badge - Aktif/Pasif gösterimi
class AppStatusBadge extends StatelessWidget {
  final bool isActive;
  final String? activeText;
  final String? inactiveText;

  const AppStatusBadge({
    super.key,
    required this.isActive,
    this.activeText,
    this.inactiveText,
  });

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      text: isActive ? (activeText ?? 'Aktif') : (inactiveText ?? 'Pasif'),
      variant: isActive ? BadgeVariant.success : BadgeVariant.danger,
      icon: isActive ? Icons.check_circle : Icons.cancel,
    );
  }
}

/// Count Badge - Sayı gösterimi
class AppCountBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const AppCountBadge({
    super.key,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? AppColors.danger,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}