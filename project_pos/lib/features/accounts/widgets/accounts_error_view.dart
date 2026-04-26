import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';

/// Sprint 7 — I2 düzeltmesi: provider/async hatasını ekran patlatmadan,
/// kullanıcıya retry seçeneği ile gösterir.
///
/// Tipik kullanım `AsyncValue.when(error: ...)` icinde:
/// ```dart
/// salesAsync.when(
///   data: (...) => ...,
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => AccountsErrorView(
///     error: e,
///     onRetry: () => ref.invalidate(myProvider),
///   ),
/// )
/// ```
///
/// Sprint 8'de AccountsHubScreen + AccountsListPanel + StatementDetailPanel +
/// AccountsSummaryBar widget agaclarinda yaygin kullanim eklenecek.
class AccountsErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? message;
  final IconData icon;
  final bool compact;

  const AccountsErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.message,
    this.icon = Icons.error_outline,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding =
        compact ? const EdgeInsets.all(8) : const EdgeInsets.all(24);
    final iconSize = compact ? 24.0 : 48.0;
    final fontSize = compact ? 12.0 : 14.0;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: AppColors.danger),
          SizedBox(height: compact ? 6 : 12),
          Text(
            message ?? 'Bir hata oluştu',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: compact ? 8 : 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tekrar dene'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
