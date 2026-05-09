import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

enum ButtonVariant { primary, secondary, success, danger, warning, outline, ghost }

enum ButtonSize { small, medium, large }

/// Merkezi Buton Widget — tema değişikliklerine tam duyarlı.
/// ConsumerWidget olduğundan resolvedPrimaryColorProvider'ı dinler.
class AppButton extends ConsumerWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final bool iconRight;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.iconRight = false,
  });

  factory AppButton.primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) =>
      AppButton(
        text: text, onPressed: onPressed, variant: ButtonVariant.primary,
        size: size, icon: icon, isLoading: isLoading, fullWidth: fullWidth,
      );

  factory AppButton.success({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) =>
      AppButton(
        text: text, onPressed: onPressed, variant: ButtonVariant.success,
        size: size, icon: icon, isLoading: isLoading, fullWidth: fullWidth,
      );

  factory AppButton.danger({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) =>
      AppButton(
        text: text, onPressed: onPressed, variant: ButtonVariant.danger,
        size: size, icon: icon, isLoading: isLoading, fullWidth: fullWidth,
      );

  factory AppButton.outline({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) =>
      AppButton(
        text: text, onPressed: onPressed, variant: ButtonVariant.outline,
        size: size, icon: icon, isLoading: isLoading, fullWidth: fullWidth,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = ref.watch(resolvedPrimaryColorProvider);
    final height = _getHeight();
    final padding = _getPadding();
    final textColor = _getTextColor(primary);
    final buttonStyle = _getButtonStyle(primary);

    Widget content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: textColor,
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !iconRight) ...[
                Icon(icon, size: _getIconSize(), color: textColor),
                const SizedBox(width: AppConstants.spacing8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: _getFontSize(),
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (icon != null && iconRight) ...[
                const SizedBox(width: AppConstants.spacing8),
                Icon(icon, size: _getIconSize(), color: textColor),
              ],
            ],
          );

    if (variant == ButtonVariant.outline || variant == ButtonVariant.ghost) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: Padding(padding: padding, child: content),
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: Padding(padding: padding, child: content),
      ),
    );
  }

  Color _getTextColor(Color primary) {
    if (variant == ButtonVariant.outline || variant == ButtonVariant.ghost) {
      return primary;
    }
    return Colors.white;
  }

  ButtonStyle _getButtonStyle(Color primary) {
    final shape = RoundedRectangleBorder(
      borderRadius: AppConstants.borderRadiusMedium,
    );

    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: shape,
        );
      case ButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.textSecondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: shape,
        );
      case ButtonVariant.success:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: shape,
        );
      case ButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: shape,
        );
      case ButtonVariant.warning:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: shape,
        );
      case ButtonVariant.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: EdgeInsets.zero,
          shape: shape,
        );
      case ButtonVariant.ghost:
        return OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          shape: shape,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:  return AppConstants.buttonHeightSmall;
      case ButtonSize.medium: return AppConstants.buttonHeightMedium;
      case ButtonSize.large:  return AppConstants.buttonHeightLarge;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:  return const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
      case ButtonSize.medium: return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.large:  return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:  return 12;
      case ButtonSize.medium: return 13;
      case ButtonSize.large:  return 14;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:  return AppConstants.iconSmall;
      case ButtonSize.medium: return AppConstants.iconMedium;
      case ButtonSize.large:  return AppConstants.iconLarge;
    }
  }
}

// ─── AppIconButton ────────────────────────────────────────────────────────────

class AppIconButton extends ConsumerWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = ref.watch(resolvedPrimaryColorProvider);
    final iconSize = size == ButtonSize.small
        ? AppConstants.iconSmall
        : size == ButtonSize.medium
            ? AppConstants.iconMedium
            : AppConstants.iconLarge;

    final bgColor = variant == ButtonVariant.primary
        ? primary
        : variant == ButtonVariant.success
            ? AppColors.success
            : variant == ButtonVariant.danger
                ? AppColors.danger
                : AppColors.textSecondary;

    final isOutline = variant == ButtonVariant.outline;

    final button = Container(
      width: _getSize(),
      height: _getSize(),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : bgColor,
        borderRadius: AppConstants.borderRadiusMedium,
        border: isOutline ? Border.all(color: primary, width: 1.5) : null,
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize),
        onPressed: onPressed,
        color: isOutline ? primary : Colors.white,
        padding: EdgeInsets.zero,
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }

  double _getSize() {
    switch (size) {
      case ButtonSize.small:  return 28;
      case ButtonSize.medium: return 36;
      case ButtonSize.large:  return 40;
    }
  }
}
