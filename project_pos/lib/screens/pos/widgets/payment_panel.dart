import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../providers/pos_provider.dart';
import 'receipt_preview_dialog.dart';

class PaymentPanel extends ConsumerStatefulWidget {
  const PaymentPanel({super.key});

  @override
  ConsumerState<PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends ConsumerState<PaymentPanel> {
  final _cashController = TextEditingController();
  final _cardController = TextEditingController();
  final _transferController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _cashController.dispose();
    _cardController.dispose();
    _transferController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final t = i18nOf(ref);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.payment, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  t('pos.payment'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sipariş özeti
                  _buildOrderSummary(posState),

                  const SizedBox(height: 20),

                  // Ödeme yöntemi seçimi
                  Text(
                    t('pos.payment_method'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentMethodSelector(posState, notifier),

                  const SizedBox(height: 20),

                  // Ödeme girişi
                  _buildPaymentInput(posState, notifier),

                  const SizedBox(height: 16),

                  // Not
                  TextField(
                    controller: _noteController,
                    onChanged: notifier.setNote,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: t('pos.note_optional'),
                      hintText: t('pos.note_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Para üstü
                  if (posState.changeAmount > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgSuccess,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.currency_lira,
                                  color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                t('pos.change_amount'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${posState.changeAmount.toStringAsFixed(2)} \u20BA',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Hata mesajı
                  if (posState.error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgDanger,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              posState.error!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Ödeme butonu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: posState.canSubmit
                      ? () async {
                          final success = await notifier.submitSale();
                          if (success && mounted) {
                            Navigator.pop(context);
                            _showSuccessDialog(context);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  icon: posState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle, size: 22),
                  label: Text(
                    posState.isSubmitting
                        ? t('common.loading')
                        : '${t('pos.complete_sale')} (${posState.grandTotal.toStringAsFixed(2)} \u20BA)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(PosState posState) {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow(t('pos.item_count'), '${posState.totalItems} ${t('pos.pieces')}'),
          _summaryRow(
              t('pos.subtotal'), '${posState.subtotal.toStringAsFixed(2)} \u20BA'),
          if (posState.totalDiscount > 0)
            _summaryRow(
              t('pos.discount'),
              '-${posState.totalDiscount.toStringAsFixed(2)} \u20BA',
              valueColor: AppColors.success,
            ),
          _summaryRow(t('pos.tax'), '${posState.totalTax.toStringAsFixed(2)} \u20BA'),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('pos.grand_total'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${posState.grandTotal.toStringAsFixed(2)} \u20BA',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (posState.selectedCustomer != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Text(
                  posState.selectedCustomer!['name']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(
      PosState posState, PosNotifier notifier) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((method) {
        final isSelected = posState.paymentMethod == method;
        IconData icon;
        switch (method) {
          case PaymentMethod.cash:
            icon = Icons.money;
            break;
          case PaymentMethod.creditCard:
            icon = Icons.credit_card;
            break;
          case PaymentMethod.bankTransfer:
            icon = Icons.account_balance;
            break;
          case PaymentMethod.mixed:
            icon = Icons.swap_horiz;
            break;
        }

        return GestureDetector(
          onTap: () => notifier.setPaymentMethod(method),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  method.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentInput(PosState posState, PosNotifier notifier) {
    final t = i18nOf(ref);
    switch (posState.paymentMethod) {
      case PaymentMethod.cash:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountField(
              controller: _cashController,
              label: t('pos.cash_received'),
              icon: Icons.money,
              onChanged: (val) =>
                  notifier.setCashReceived(double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 8),
            _buildQuickAmounts(posState.grandTotal, notifier),
          ],
        );

      case PaymentMethod.creditCard:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.credit_card, size: 48, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  t('pos.credit_card_payment_info'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );

      case PaymentMethod.bankTransfer:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.account_balance,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  t('pos.bank_transfer_payment_info'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );

      case PaymentMethod.mixed:
        return Column(
          children: [
            _buildAmountField(
              controller: _cashController,
              label: t('pos.cash_amount'),
              icon: Icons.money,
              onChanged: (val) =>
                  notifier.setCashReceived(double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 12),
            _buildAmountField(
              controller: _cardController,
              label: t('pos.card_amount'),
              icon: Icons.credit_card,
              onChanged: (val) =>
                  notifier.setCardAmount(double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 12),
            _buildAmountField(
              controller: _transferController,
              label: t('pos.transfer_amount'),
              icon: Icons.account_balance,
              onChanged: (val) =>
                  notifier.setTransferAmount(double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 8),
            // Kalan tutar bilgisi
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgWarning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t('pos.remaining'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    '${(posState.grandTotal - posState.cashReceived - posState.cardAmount - posState.transferAmount).clamp(0, double.infinity).toStringAsFixed(2)} \u20BA',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixText: '\u20BA',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildQuickAmounts(double grandTotal, PosNotifier notifier) {
    final amounts = <double>[];
    if (grandTotal > 0) {
      // Tam tutar
      amounts.add(grandTotal);
      // Yuvarlak tutarlar
      final rounded = [50, 100, 200, 500, 1000, 2000, 5000];
      for (final r in rounded) {
        if (r.toDouble() >= grandTotal && !amounts.contains(r.toDouble())) {
          amounts.add(r.toDouble());
        }
        if (amounts.length >= 5) break;
      }
    }

    if (amounts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: amounts.map((amount) {
        final isExact = amount == grandTotal;
        return GestureDetector(
          onTap: () {
            _cashController.text = amount.toStringAsFixed(2);
            notifier.setCashReceived(amount);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isExact
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isExact ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              isExact
                  ? '${i18nOf(ref)('pos.exact')}: ${amount.toStringAsFixed(2)}'
                  : amount.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isExact ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    final posState = ref.read(posProvider);
    final saleData = posState.lastSaleData;
    final t = i18nOf(ref);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.bgSuccess,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('pos.sale_completed'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('pos.sale_saved'),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(t('common.close')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (saleData != null) {
                      showDialog(
                        context: context,
                        builder: (_) => ReceiptPreviewDialog(saleData: saleData),
                      );
                    }
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: Text(t('pos.view_receipt')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
