import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';

enum ButtonVariant { primary, secondary, success, danger, warning, outline, ghost }

enum ButtonSize { small, medium, large }

/// Merkezi Buton Widget - React benzeri kullanım
class AppButton extends StatelessWidget {
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

  // Primary button
  factory AppButton.primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  // Success button
  factory AppButton.success({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.success,
      size: size,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  // Danger button
  factory AppButton.danger({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.danger,
      size: size,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  // Outline button
  factory AppButton.outline({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.outline,
      size: size,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final height = _getHeight();
    final padding = _getPadding();

    Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _getTextColor(),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !iconRight) ...[
                Icon(icon, size: _getIconSize(), color: _getTextColor()),
                const SizedBox(width: AppConstants.spacing8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: _getFontSize(),
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(),
                ),
              ),
              if (icon != null && iconRight) ...[
                const SizedBox(width: AppConstants.spacing8),
                Icon(icon, size: _getIconSize(), color: _getTextColor()),
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

  ButtonStyle _getButtonStyle() {
    final baseStyle = ElevatedButton.styleFrom(
      elevation: 0,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusMedium,
      ),
    );

    switch (variant) {
      case ButtonVariant.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(AppColors.primary),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
      case ButtonVariant.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(AppColors.textSecondary),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
      case ButtonVariant.success:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(AppColors.success),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
      case ButtonVariant.danger:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(AppColors.danger),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
      case ButtonVariant.warning:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(AppColors.warning),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        );
      case ButtonVariant.outline:
        return OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMedium,
          ),
        );
      case ButtonVariant.ghost:
        return OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMedium,
          ),
        );
    }
  }

  Color _getTextColor() {
    if (variant == ButtonVariant.outline || variant == ButtonVariant.ghost) {
      return AppColors.primary;
    }
    return Colors.white;
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppConstants.buttonHeightSmall;
      case ButtonSize.medium:
        return AppConstants.buttonHeightMedium;
      case ButtonSize.large:
        return AppConstants.buttonHeightLarge;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return AppConstants.iconSmall;
      case ButtonSize.medium:
        return AppConstants.iconMedium;
      case ButtonSize.large:
        return AppConstants.iconLarge;
    }
  }
}

/// Icon-only button
class AppIconButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final iconSize = size == ButtonSize.small
        ? AppConstants.iconSmall
        : size == ButtonSize.medium
            ? AppConstants.iconMedium
            : AppConstants.iconLarge;

    final bgColor = variant == ButtonVariant.primary
        ? AppColors.primary
        : variant == ButtonVariant.success
            ? AppColors.success
            : variant == ButtonVariant.danger
                ? AppColors.danger
                : AppColors.textSecondary;

    final button = Container(
      width: _getSize(),
      height: _getSize(),
      decoration: BoxDecoration(
        color: variant == ButtonVariant.outline ? Colors.transparent : bgColor,
        borderRadius: AppConstants.borderRadiusMedium,
        border: variant == ButtonVariant.outline
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize),
        onPressed: onPressed,
        color: variant == ButtonVariant.outline ? AppColors.primary : Colors.white,
        padding: EdgeInsets.zero,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }

  double _getSize() {
    switch (size) {
      case ButtonSize.small:
        return 32;
      case ButtonSize.medium:
        return 40;
      case ButtonSize.large:
        return 48;
    }
  }
}
