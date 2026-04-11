import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/pos_provider.dart';
import 'cart_item_row.dart';

class CartPanel extends ConsumerWidget {
  final VoidCallback onPaymentPressed;
  final NumberFormat currencyFormat;

  const CartPanel({
    super.key,
    required this.onPaymentPressed,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, notifier, posState),
          _buildCustomerSection(context, notifier, posState),
          Expanded(child: _buildItemList(posState, notifier)),
          _buildSummary(posState),
          _buildActionButtons(posState),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PosNotifier notifier, PosState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.shopping_basket_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text('Satış Sepeti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          if (state.cartItems.isNotEmpty)
            AppButton.danger(
              text: 'Temizle',
              onPressed: () => notifier.clearCart(),
              size: ButtonSize.small,
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context, PosNotifier notifier, PosState state) {
    return InkWell(
      onTap: () => _showCustomerPicker(context, notifier),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: state.selectedCustomer != null ? AppColors.success : AppColors.bgLight,
              child: Icon(
                state.selectedCustomer != null ? Icons.person : Icons.person_add_alt_1,
                size: 16,
                color: state.selectedCustomer != null ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.selectedCustomer != null ? state.selectedCustomer!['name'] : 'Müşteri Seçin',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: state.selectedCustomer != null ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                  if (state.selectedCustomer != null)
                    Text(state.selectedCustomer!['phone'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(PosState state, PosNotifier notifier) {
    if (state.cartItems.isEmpty) {
      return AppEmptyState.noData(
        title: 'Sepetiniz Boş',
        description: 'Ürün eklemek için listeden seçim yapın',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.cartItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = state.cartItems[index];
        return CartItemRow(
          item: item,
          onQuantityChanged: (qty) => notifier.updateQuantity(item.productId, qty),
          onDiscountChanged: (disc) => notifier.updateDiscount(item.productId, disc),
          onRemove: () => notifier.removeFromCart(item.productId),
        );
      },
    );
  }

  Widget _buildSummary(PosState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _summaryRow('Ara Toplam', currencyFormat.format(state.subtotal)),
          if (state.totalDiscount > 0)
            _summaryRow('İndirim', '-${currencyFormat.format(state.totalDiscount)}', color: AppColors.danger),
          _summaryRow('KDV', currencyFormat.format(state.totalTax)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOPLAM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              Text(currencyFormat.format(state.grandTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PosState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: AppButton.primary(
              text: 'ÖDEME YAP',
              icon: Icons.payments_rounded,
              onPressed: state.cartItems.isEmpty ? null : onPaymentPressed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _showCustomerPicker(BuildContext context, PosNotifier notifier) {
    // Burada müşteri seçici dialog açılacak
  }
}
