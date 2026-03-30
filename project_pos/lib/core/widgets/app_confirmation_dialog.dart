import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import 'app_button.dart';

/// Confirmation Dialog - Tutarlı onay dialog'ları için
class AppConfirmationDialog {
  /// Delete Confirmation Dialog
  static Future<bool> showDelete({
    required BuildContext context,
    required String title,
    required String message,
    String? itemName,
    String confirmText = 'Sil',
    String cancelText = 'İptal',
  }) async {
    return await _show(
      context: context,
      title: title,
      message: message,
      itemName: itemName,
      icon: Icons.delete_outline,
      iconColor: AppColors.danger,
      confirmText: confirmText,
      confirmColor: AppColors.danger,
      cancelText: cancelText,
    ) ?? false;
  }

  /// Generic Confirmation Dialog
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? itemName,
    IconData icon = Icons.help_outline,
    Color? iconColor,
    String confirmText = 'Onayla',
    Color? confirmColor,
    String cancelText = 'İptal',
  }) async {
    return await _show(
      context: context,
      title: title,
      message: message,
      itemName: itemName,
      icon: icon,
      iconColor: iconColor ?? AppColors.primary,
      confirmText: confirmText,
      confirmColor: confirmColor ?? AppColors.primary,
      cancelText: cancelText,
    ) ?? false;
  }

  /// Warning Confirmation Dialog
  static Future<bool> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String? itemName,
    String confirmText = 'Devam Et',
    String cancelText = 'İptal',
  }) async {
    return await _show(
      context: context,
      title: title,
      message: message,
      itemName: itemName,
      icon: Icons.warning_amber_outlined,
      iconColor: AppColors.warning,
      confirmText: confirmText,
      confirmColor: AppColors.warning,
      cancelText: cancelText,
    ) ?? false;
  }

  /// Success Confirmation Dialog
  static Future<bool> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? itemName,
    String confirmText = 'Tamam',
    String cancelText = 'İptal',
  }) async {
    return await _show(
      context: context,
      title: title,
      message: message,
      itemName: itemName,
      icon: Icons.check_circle_outline,
      iconColor: AppColors.success,
      confirmText: confirmText,
      confirmColor: AppColors.success,
      cancelText: cancelText,
    ) ?? false;
  }

  /// Base dialog implementation
  static Future<bool?> _show({
    required BuildContext context,
    required String title,
    required String message,
    String? itemName,
    required IconData icon,
    required Color iconColor,
    required String confirmText,
    required Color confirmColor,
    required String cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: AppConstants.paddingLarge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 32,
                  ),
                ),

                const SizedBox(height: AppConstants.spacing16),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.spacing12),

                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Item name (if provided)
                if (itemName != null) ...[
                  const SizedBox(height: AppConstants.spacing12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing12,
                      vertical: AppConstants.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: AppConstants.borderRadiusSmall,
                    ),
                    child: Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: AppConstants.spacing24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        text: cancelText,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: AppButton(
                        text: confirmText,
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        variant: _getVariantFromColor(confirmColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Simple Alert Dialog (only OK button)
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Tamam',
    IconData icon = Icons.info_outline,
    Color? iconColor,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: AppConstants.paddingLarge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.info).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.info,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacing12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacing24),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    text: buttonText,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper function to convert color to ButtonVariant
  static ButtonVariant _getVariantFromColor(Color color) {
    if (color == AppColors.danger) {
      return ButtonVariant.danger;
    } else if (color == AppColors.success) {
      return ButtonVariant.success;
    } else if (color == AppColors.warning) {
      return ButtonVariant.warning;
    } else {
      return ButtonVariant.primary;
    }
  }
}
