import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';

class BatchSummaryBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        child: isDesktop ? _desktopLayout() : _mobileLayout(),
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        // Left: stat chips
        _statChip('$totalItems', 'Urun', AppColors.primary),
        const SizedBox(width: 8),
        _statChip('$newItems', 'Yeni', AppColors.orange),
        const SizedBox(width: 8),
        _statChip('$existingItems', 'Mevcut', AppColors.success),
        const Spacer(),
        // Center: amounts
        _amountText('Alis:', totalCost, AppColors.textSecondary),
        const SizedBox(width: 16),
        _amountText('Satis:', totalSale, AppColors.textPrimary),
        const SizedBox(width: 16),
        _amountText('Kar:', totalProfit,
            totalProfit >= 0 ? AppColors.success : AppColors.danger),
        const Spacer(),
        // Right: buttons
        OutlinedButton(
          onPressed: totalItems > 0 ? onClear : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: const Text('Temizle'),
        ),
        const SizedBox(width: 12),
        _saveButton(),
      ],
    );
  }

  Widget _mobileLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalItems urun  \u2022  ${_fmt.format(totalSale)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'Kar: ${_fmt.format(totalProfit)}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      totalProfit >= 0 ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ),
        _saveButton(),
      ],
    );
  }

  Widget _saveButton() {
    return AppButton.primary(
      text: isSubmitting ? 'Kaydediliyor...' : 'Tümünü Kaydet ($totalItems ürün)',
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
