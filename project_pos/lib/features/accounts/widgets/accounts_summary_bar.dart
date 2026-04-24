import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/formatters.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/features/finance/di/finance_di.dart';

/// Üstte kompakt 4 metric bar — geniş ekranda tek sıra, dar ekranda horizontal scroll.
class AccountsSummaryBar extends ConsumerWidget {
  const AccountsSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final summary = ref.watch(accountSummaryProvider).summary;
    final payments = ref.watch(paymentListProvider).payments;

    final receivable = (summary?['totalCustomerReceivable'] ?? 0).toDouble();
    final payable = (summary?['totalSupplierPayable'] ?? 0).toDouble();
    final overdue = (summary?['totalOverdueAmount'] ?? 0).toDouble();
    final today = _todayCollection(payments);

    final tiles = [
      _Metric(
        label: t('accounts.total_customer_receivable'),
        value: appCurrencyFmt.format(receivable),
        icon: Icons.people_alt_outlined,
        color: AppColors.success,
      ),
      _Metric(
        label: t('accounts.total_supplier_payable'),
        value: appCurrencyFmt.format(payable),
        icon: Icons.business_outlined,
        color: AppColors.warning,
      ),
      _Metric(
        label: t('accounts.overdue'),
        value: appCurrencyFmt.format(overdue),
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
      ),
      _Metric(
        label: t('accounts.today_collection'),
        value: appCurrencyFmt.format(today),
        icon: Icons.today_outlined,
        color: AppColors.teal,
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final isWide = c.maxWidth >= 600;
          if (isWide) {
            return Row(
              children: tiles
                  .map((m) => Expanded(child: _MetricTile(m: m)))
                  .toList(),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tiles
                  .map((m) => SizedBox(width: 160, child: _MetricTile(m: m)))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  double _todayCollection(List<Map<String, dynamic>> payments) {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return payments
        .where((p) =>
            p['customerId'] != null &&
            (p['paymentDate']?.toString() ?? '').startsWith(todayKey) &&
            p['isCancelled'] != true)
        .fold<double>(
            0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));
  }
}

class _Metric {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricTile extends StatelessWidget {
  final _Metric m;
  const _MetricTile({required this.m});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: m.color.withValues(alpha: 0.08),
          borderRadius: AppConstants.borderRadiusSmall,
          border: Border.all(color: m.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(m.icon, size: 18, color: m.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.label,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(m.value,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: m.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
