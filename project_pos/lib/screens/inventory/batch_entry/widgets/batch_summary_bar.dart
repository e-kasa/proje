import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';

class BatchSummaryBar extends ConsumerWidget {
  final int totalItems;
  final int newItems;
  final int existingItems;
  final double totalCost;
  final double totalSale;
  final double totalProfit;
  final bool isValid;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const BatchSummaryBar({
    super.key,
    required this.totalItems,
    required this.newItems,
    required this.existingItems,
    required this.totalCost,
    required this.totalSale,
    required this.totalProfit,
    required this.isValid,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onClear,
  });

  static final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isDesktop ? _desktopLayout(t) : _mobileLayout(t),
      ),
    );
  }

  Widget _desktopLayout(Function(String) t) {
    return Row(
      children: [
        // Left: stat chips
        _statChip('$totalItems', t('product.product'), AppColors.primary),
        const SizedBox(width: 8),
        _statChip('$newItems', t('batch.new'), AppColors.orange),
        const SizedBox(width: 8),
        _statChip('$existingItems', t('batch.existing'), AppColors.success),
        const Spacer(),
        // Center: amounts
        _amountText('${t('batch.purchase')}:', totalCost, AppColors.textSecondary),
        const SizedBox(width: 16),
        _amountText('${t('batch.sale')}:', totalSale, AppColors.textPrimary),
        const SizedBox(width: 16),
        _amountText('${t('batch.profit')}:', totalProfit,
            totalProfit >= 0 ? AppColors.success : AppColors.danger),
        const Spacer(),
        // Right: buttons
        OutlinedButton(
          onPressed: totalItems > 0 ? onClear : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: Text(t('batch.clear')),
        ),
        const SizedBox(width: 12),
        _saveButton(t),
      ],
    );
  }

  Widget _mobileLayout(Function(String) t) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalItems ${t('product.product').toLowerCase()}  \u2022  ${_fmt.format(totalSale)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '${t('batch.profit')}: ${_fmt.format(totalProfit)}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      totalProfit >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ),
        _saveButton(t),
      ],
    );
  }

  Widget _saveButton(Function(String) t) {
    return AppButton.primary(
      text: isSubmitting ? t('common.loading') : '${t('batch.save_all')} ($totalItems ${t('product.product').toLowerCase()})',
      icon: Icons.check,
      onPressed: isValid && !isSubmitting ? onSubmit : null,
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '[$count] $label',
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _amountText(String label, double amount, Color color) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          TextSpan(
            text: _fmt.format(amount),
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}