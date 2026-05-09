import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

/// Merkezi Card Widget — tema ve dark mode uyumlu.
class AppCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool hasShadow;
  final bool hasBorder;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double? borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.onLongPress,
    this.hasShadow = false,
    this.hasBorder = true,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final effectiveBorderColor = borderColor ??
        (isDark ? const Color(0xFF2D2D4A) : AppColors.border);
    final effectiveBorderWidth = borderWidth ?? 1.0;
    final effectiveRadius = borderRadius ?? AppConstants.borderRadiusMedium;

    final card = Container(
      padding: padding ?? AppConstants.paddingMedium,
      decoration: BoxDecoration(
        color: color ?? surfaceColor,
        borderRadius: effectiveRadius,
        border: hasBorder
            ? Border.all(
                color: effectiveBorderColor, width: effectiveBorderWidth)
            : null,
        boxShadow: hasShadow
            ? (isDark ? null : AppConstants.shadowSmall)
            : null,
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

/// Stat Card — istatistik gösterimi için
class AppStatCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: AppConstants.borderRadiusMedium,
            ),
            child: Icon(icon, color: color, size: AppConstants.iconMedium),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Section Card — başlıklı bölüm kartı
class AppSectionCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = ref.watch(resolvedPrimaryColorProvider);
    final surfaceColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderC = isDark ? const Color(0xFF2D2D4A) : AppColors.border;
    final titleColor =
        isDark ? const Color(0xFFF1F5F9) : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppConstants.paddingMedium,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: primary, size: 18),
                  const SizedBox(width: AppConstants.spacing8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: borderC),
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
