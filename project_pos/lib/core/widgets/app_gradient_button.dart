import 'package:flutter/material.dart';
import '../theme/app_constants.dart';
import '../theme/app_gradients.dart';

/// Gradient Button - Renkli gradient butonlar
class AppGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final IconData? icon;
  final bool fullWidth;
  final double height;
  final bool isLoading;

  const AppGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient = AppGradients.primaryGradient,
    this.icon,
    this.fullWidth = false,
    this.height = AppConstants.buttonHeightMedium,
    this.isLoading = false,
  });

  factory AppGradientButton.primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return AppGradientButton(
      text: text,
      onPressed: onPressed,
      gradient: AppGradients.primaryGradient,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  factory AppGradientButton.success({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return AppGradientButton(
      text: text,
      onPressed: onPressed,
      gradient: AppGradients.successGradient,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  factory AppGradientButton.sunset({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return AppGradientButton(
      text: text,
      onPressed: onPressed,
      gradient: AppGradients.sunsetGradient,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppConstants.borderRadiusMedium,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing24,
              vertical: AppConstants.spacing12,
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: AppConstants.iconMedium),
                        const SizedBox(width: AppConstants.spacing8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}