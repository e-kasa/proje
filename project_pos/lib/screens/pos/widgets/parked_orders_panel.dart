import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import '../providers/pos_provider.dart';

class ParkedOrdersPanel extends ConsumerWidget {
  const ParkedOrdersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                const Icon(Icons.pause_circle_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bekleyen Siparişler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${posState.parkedOrders.length} sipariş',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
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

          // Content
          Expanded(
            child: posState.parkedOrders.isEmpty
                ? _buildEmptyState()
                : _buildParkedOrdersList(context, posState, notifier, currencyFormat),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState.noData(
      title: 'Bekleyen sipariş yok',
      description: 'Siparişleri park etmek için "Park" butonunu kullanın',
    );
  }

  Widget _buildParkedOrdersList(
    BuildContext context,
    PosState posState,
    PosNotifier notifier,
    NumberFormat currencyFormat,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: posState.parkedOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final parked = posState.parkedOrders[index];
        return _buildParkedOrderCard(
          context,
          parked,
          index,
          notifier,
          currencyFormat,
          posState,
        );
      },
    );
  }

  Widget _buildParkedOrderCard(
    BuildContext context,
    ParkedOrder parked,
    int index,
    PosNotifier notifier,
    NumberFormat currencyFormat,
    PosState posState,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showRestoreDialog(context, parked, index, notifier, posState),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and delete button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parked.displayLabel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (parked.customer != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Müşteri: ${parked.customer?['name'] ?? 'Bilinmiyor'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(context, index, notifier),
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.bgDanger,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Items and time info
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${parked.items.length} ürün',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      parked.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Total and restore button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Toplam: ${parked.total.toStringAsFixed(2)} ₺',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.restore, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Geri Yükle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRestoreDialog(
    BuildContext context,
    ParkedOrder parked,
    int index,
    PosNotifier notifier,
    PosState posState,
  ) async {
    if (posState.cartItems.isEmpty) {
      notifier.restoreParkedOrder(index);
      Navigator.pop(context);
      return;
    }

    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Sepet Boş Değil',
      message: 'Aktif sepete ürün var. Bekleyen siparişi yüklemek için aktif sepeti temizlemek gerekir.\n\nDevam et?',
      confirmText: 'Devam Et',
    );
    if (confirmed) {
      notifier.restoreParkedOrder(index);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    int index,
    PosNotifier notifier,
  ) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      context: context,
      title: 'Siparişi Sil',
      message: 'Bu bekleyen sipariş kalıcı olarak silinecek. Emin misiniz?',
    );
    if (confirmed) {
      notifier.deleteParkedOrder(index);
    }
  }
}
