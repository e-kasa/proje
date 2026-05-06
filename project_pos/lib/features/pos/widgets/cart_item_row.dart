import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import '../providers/pos_provider.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'recommendation_bottom_sheet.dart';

class CartItemRow extends ConsumerWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<double> onDiscountChanged;

  const CartItemRow({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recCount = ref.watch(posProvider.select((s) => s.recommendations.length));
    final isLoadingRecs = ref.watch(posProvider.select((s) => s.isLoadingRecommendations));
    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.danger.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) => AppConfirmationDialog.showDelete(
        context: context,
        title: 'Sepetten çıkar',
        message: 'Ürün sepetten kaldırılacak.',
        itemName: item.name,
        confirmText: 'Çıkar',
      ),
      onDismissed: (_) => onRemove(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatPrice(item.unitPrice)} x ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.discount > 0)
                    Text(
                      '-%${item.discount.toStringAsFixed(0)} indirim',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Miktar kontrol
            _buildQuantityControls(),

            const SizedBox(width: 12),

            // Tutar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPrice(item.totalWithTax),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.discount > 0)
                  Text(
                    _formatPrice(item.lineTotal),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                // İndirim / Öneri / Silme butonları
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniButton(
                      icon: Icons.discount_outlined,
                      color: AppColors.warning,
                      onTap: () => _showDiscountDialog(context),
                    ),
                    const SizedBox(width: 4),
                    _buildRecommendationButton(context, recCount, isLoadingRecs),
                    const SizedBox(width: 4),
                    _buildMiniButton(
                      icon: Icons.close,
                      color: AppColors.danger,
                      onTap: onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQtyButton(
            icon: Icons.remove,
            onTap: () => onQuantityChanged(item.quantity - 1),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildQtyButton(
            icon: Icons.add,
            onTap: () => onQuantityChanged(item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }

  Widget _buildRecommendationButton(BuildContext context, int count, bool loading) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () => showRecommendationBottomSheet(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: loading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.info),
                    ),
                  )
                : Icon(
                    Icons.lightbulb_rounded,
                    size: 14,
                    color: count > 0 ? AppColors.info : AppColors.border,
                  ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 13, minHeight: 13),
              decoration: BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    final controller =
        TextEditingController(text: item.discount.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İndirim (%)'),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '0 - 100',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final val = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (val == null) return 'Sayı girin';
              if (val < 0 || val > 100) return '0 ile 100 arasında olmalı';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          AppButton.primary(
            text: 'Uygula',
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final val = double.parse(controller.text.replaceAll(',', '.'));
              onDiscountChanged(val);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} \u20BA';
  }
}