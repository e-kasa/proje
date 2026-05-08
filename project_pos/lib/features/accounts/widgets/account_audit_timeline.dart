import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/app_empty_state.dart';
import 'package:project_pos/features/accounts/providers/account_audit_provider.dart';

/// Sprint 30 — issue P2.6: Cari audit-log timeline widget'ı.
///
/// Bottom sheet içinde kullanılır. Backend `GET /api/v1/audit/{type}/{id}`
/// kayıtlarını "X kullanıcısı creditLimit: 5000 → 10000" formatında listeler.
class AccountAuditTimeline extends ConsumerWidget {
  final String accountType;
  final String accountId;
  final String accountName;

  const AccountAuditTimeline({
    super.key,
    required this.accountType,
    required this.accountId,
    required this.accountName,
  });

  static Future<void> show(
    BuildContext context, {
    required String accountType,
    required String accountId,
    required String accountName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtl) => AccountAuditTimeline(
          accountType: accountType,
          accountId: accountId,
          accountName: accountName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target =
        AuditTarget(accountType: accountType, accountId: accountId);
    final asyncHistory = ref.watch(accountAuditHistoryProvider(target));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.history, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Değişiklik Geçmişi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      accountName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Yenile',
                onPressed: () =>
                    ref.invalidate(accountAuditHistoryProvider(target)),
                icon: const Icon(Icons.refresh, size: 20),
              ),
              IconButton(
                tooltip: 'Kapat',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: asyncHistory.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 36, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(
                      'Geçmiş yüklenemedi: $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .invalidate(accountAuditHistoryProvider(target)),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const AppEmptyState(
                  title: 'Henüz değişiklik kaydı yok',
                  description:
                      'Bu cari için yapılan ilk düzenleme burada görünecek.',
                  icon: Icons.history_toggle_off,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _AuditRow(item: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _AuditRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final action = (item['action'] as String?) ?? 'UPDATE';
    final field = item['fieldName'] as String?;
    final oldVal = item['oldValue'] as String?;
    final newVal = item['newValue'] as String?;
    final reason = item['reason'] as String?;
    final user = (item['createUser'] as String?) ?? 'sistem';
    final createTimeStr = item['createTime']?.toString() ?? '';

    final palette = _palette(action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.color.withValues(alpha: 0.05),
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(color: palette.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(palette.icon, size: 18, color: palette.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _summary(action, field, oldVal, newVal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$user · ${_formatTime(createTimeStr)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _summary(
      String action, String? field, String? oldVal, String? newVal) {
    switch (action) {
      case 'CREATE':
        return 'Cari oluşturuldu';
      case 'DELETE':
        return 'Cari silindi (soft delete)';
      case 'RESTORE':
        return 'Cari geri yüklendi';
      case 'UPDATE':
      default:
        if (field == null) return 'Güncelleme';
        final from = (oldVal == null || oldVal.isEmpty) ? '∅' : oldVal;
        final to = (newVal == null || newVal.isEmpty) ? '∅' : newVal;
        return '$field: $from → $to';
    }
  }

  static _ActionPalette _palette(String action) {
    switch (action) {
      case 'CREATE':
        return const _ActionPalette(Icons.add_circle_outline, AppColors.success);
      case 'DELETE':
        return const _ActionPalette(Icons.delete_outline, AppColors.danger);
      case 'RESTORE':
        return const _ActionPalette(Icons.restore, AppColors.info);
      case 'UPDATE':
      default:
        return const _ActionPalette(Icons.edit_note, AppColors.primary);
    }
  }

  static String _formatTime(String iso) {
    if (iso.isEmpty) return '—';
    // Backend ISO veya "yyyy-MM-dd'T'HH:mm:ss" gönderir; saniyeden sonrasını at
    try {
      final dt = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
          '${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return iso.substring(0, iso.length.clamp(0, 16));
    }
  }
}

class _ActionPalette {
  final IconData icon;
  final Color color;
  const _ActionPalette(this.icon, this.color);
}
