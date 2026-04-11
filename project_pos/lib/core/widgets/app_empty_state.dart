import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import 'app_button.dart';

/// Empty State Widget - Veri olmadığında gösterilecek
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  // Önceden tanımlı empty state'ler
  factory AppEmptyState.noData({
    String? title,
    String? description,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      icon: Icons.inbox_outlined,
      title: title ?? 'Henüz veri yok',
      description: description ?? 'Burası şu an boş görünüyor',
      actionText: actionText,
      onAction: onAction,
      iconColor: AppColors.textMuted,
    );
  }

  factory AppEmptyState.search({
    String? title,
    String? description,
  }) {
    return AppEmptyState(
      icon: Icons.search_off_outlined,
      title: title ?? 'Sonuç bulunamadı',
      description: description ?? 'Farklı anahtar kelimeler deneyin',
      iconColor: AppColors.warning,
    );
  }

  factory AppEmptyState.error({
    String? title,
    String? description,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      icon: Icons.error_outline,
      title: title ?? 'Bir hata oluştu',
      description: description ?? 'Lütfen daha sonra tekrar deneyin',
      actionText: actionText ?? 'Tekrar Dene',
      onAction: onAction,
      iconColor: AppColors.danger,
    );
  }

  factory AppEmptyState.offline({
    String? title,
    String? description,
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      icon: Icons.wifi_off_outlined,
      title: title ?? 'İnternet bağlantısı yok',
      description: description ?? 'Lütfen bağlantınızı kontrol edin',
      actionText: 'Tekrar Dene',
      onAction: onAction,
      iconColor: AppColors.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppConstants.paddingLarge,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppColors.textMuted).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 64,
                      color: iconColor ?? AppColors.textMuted,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppConstants.spacing24),

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

            if (description != null) ...[
              const SizedBox(height: AppConstants.spacing8),
              Text(
                description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppConstants.spacing24),
              AppButton.primary(
                text: actionText!,
                onPressed: onAction,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
