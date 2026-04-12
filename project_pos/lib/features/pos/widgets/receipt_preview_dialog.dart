import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import '../providers/pos_provider.dart';

class ReceiptPreviewDialog extends ConsumerWidget {
  final Map<String, dynamic> saleData;

  const ReceiptPreviewDialog({super.key, required this.saleData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
    final items = saleData['items'] as List? ?? [];
    final saleDate = DateTime.tryParse(saleData['saleDate']?.toString() ?? '') ?? DateTime.now();
    final customer = saleData['customer'] as Map<String, dynamic>?;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Satış Fişi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${saleData['saleNumber'] ?? '—'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            // Receipt content (scrollable)
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(saleDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            'Terminal #01',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),

                      if (customer != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 16, color: AppColors.info),
                              const SizedBox(width: 6),
                              Text(
                                customer['name']?.toString() ?? 'Müşteri',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Column headers
                      Row(
                        children: const [
                          Expanded(
                            flex: 4,
                            child: Text('Ürün', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('Adet', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Tutar', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Items
                      ...items.map((item) {
                        final name = item['name']?.toString() ?? '';
                        final qty = item['quantity'] ?? 1;
                        final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
                        final lineTotal = (item['lineTotal'] as num?)?.toDouble() ?? (unitPrice * qty);
                        final discount = (item['discountRate'] as num?)?.toDouble() ?? 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (discount > 0)
                                          Text(
                                            '${currencyFormat.format(unitPrice)} x $qty  -%${discount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          )
                                        else
                                          Text(
                                            '${currencyFormat.format(unitPrice)} x $qty',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '$qty',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      currencyFormat.format(lineTotal),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Totals
                      _totalRow('Ara Toplam', currencyFormat.format(saleData['subtotal'] ?? 0)),
                      if ((saleData['totalDiscount'] as num?)?.toDouble() != null &&
                          (saleData['totalDiscount'] as num).toDouble() > 0)
                        _totalRow(
                          'İndirim',
                          '-${currencyFormat.format(saleData['totalDiscount'])}',
                          valueColor: AppColors.success,
                        ),
                      _totalRow('KDV', currencyFormat.format(saleData['totalTax'] ?? 0)),

                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOPLAM',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              currencyFormat.format(saleData['grandTotal'] ?? 0),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Payment info
                      _totalRow('Ödeme Yöntemi', saleData['paymentMethod']?.toString() ?? ''),

                      if ((saleData['cashReceived'] as num?)?.toDouble() != null &&
                          (saleData['cashReceived'] as num).toDouble() > 0)
                        _totalRow('Alınan', currencyFormat.format(saleData['cashReceived'])),

                      if ((saleData['changeAmount'] as num?)?.toDouble() != null &&
                          (saleData['changeAmount'] as num).toDouble() > 0)
                        _totalRow(
                          'Para Üstü',
                          currencyFormat.format(saleData['changeAmount']),
                          valueColor: AppColors.success,
                        ),

                      if (saleData['note'] != null && saleData['note'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Not: ${saleData['note']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  // Close
                  Expanded(
                    child: AppButton.outline(
                      text: 'Kapat',
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Print
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      text: 'Fiş Yazdır',
                      icon: Icons.print_rounded,
                      onPressed: () async {
                        final notifier = ref.read(posProvider.notifier);
                        final success = await notifier.printLastReceipt();
                        if (context.mounted) {
                          if (success) {
                            AppToast.success(context, 'Fiş yazdırma komutu gönderildi');
                          } else {
                            AppToast.error(context, 'Fiş yazdırılamadı');
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
}