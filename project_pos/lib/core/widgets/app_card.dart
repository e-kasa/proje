import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Merkezi Card Widget - React benzeri
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool hasShadow;
  final bool hasBorder;
  final BorderRadius? borderRadius;
  /// Override border color (örn. seçim modu için AppColors.primary)
  final Color? borderColor;
  /// Override border width (örn. seçim modu için 2)
  final double? borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.onLongPress,
    this.hasShadow = true,
    this.hasBorder = true,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppColors.border;
    final effectiveBorderWidth = borderWidth ?? 1.0;
    final effectiveRadius = borderRadius ?? AppConstants.borderRadiusMedium;

    final card = Container(
      padding: padding ?? AppConstants.paddingMedium,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: effectiveRadius,
        border: hasBorder
            ? Border.all(color: effectiveBorderColor, width: effectiveBorderWidth)
            : null,
        boxShadow: hasShadow ? AppConstants.shadowSmall : null,
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveRadius,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Stat Card - İstatistik gösterimi için
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMedium,
            ),
            child: Icon(icon, color: color, size: AppConstants.iconLarge),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppConstants.spacing4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Section Card - Başlıklı bölüm kartı
class AppSectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final Widget? trailing;

  const AppSectionCard({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppConstants.paddingMedium,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppConstants.spacing8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: AppConstants.paddingMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
