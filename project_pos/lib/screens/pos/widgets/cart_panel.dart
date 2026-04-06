import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/src/intl/number_format.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/services/service_locator.dart';
import '../providers/pos_provider.dart';
import 'cart_item_row.dart';
import 'quick_customer_dialog.dart';
import 'package:project_pos/core/widgets/widgets.dart';

class CartPanel extends ConsumerWidget {
  final VoidCallback onPaymentPressed;

  const CartPanel({
    super.key,
    required this.onPaymentPressed, required NumberFormat currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context, posState, notifier),

          // Müşteri seçimi
          _buildCustomerSection(context, posState, notifier, ref),

          const Divider(height: 1),

          // Sepet listesi
          Expanded(
            child: posState.cartItems.isEmpty
                ? _buildEmptyCart()
                : _buildCartList(posState, notifier),
          ),

          const Divider(height: 1),

          // Toplam & Ödeme
          _buildTotalSection(posState, notifier),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, PosState posState, PosNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'Sepet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (posState.totalItems > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${posState.totalItems}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          const Spacer(),
          if (posState.cartItems.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () => _showParkDialog(context, notifier),
              icon: const Icon(Icons.pause_circle_outline,
                  size: 16, color: AppColors.primary),
              label: const Text(
                'Park',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => _confirmClearCart(context, notifier),
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.danger),
              label: const Text(
                'Temizle',
                style: TextStyle(fontSize: 12, color: AppColors.danger),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context, PosState posState,
      PosNotifier notifier, WidgetRef ref) {
    return InkWell(
      onTap: () => _showCustomerPicker(context, notifier, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: posState.selectedCustomer != null
            ? AppColors.bgInfo.withOpacity(0.3)
            : null,
        child: Row(
          children: [
            Icon(
              posState.selectedCustomer != null
                  ? Icons.person
                  : Icons.person_add_alt,
              size: 18,
              color: posState.selectedCustomer != null
                  ? AppColors.info
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                posState.selectedCustomer?['name']?.toString() ??
                    'Müşteri Seç (Opsiyonel)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: posState.selectedCustomer != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: posState.selectedCustomer != null
                      ? AppColors.info
                      : AppColors.textMuted,
                ),
              ),
            ),
            if (posState.selectedCustomer != null)
              InkWell(
                onTap: () => notifier.selectCustomer(null),
                child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              )
            else
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 56, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text(
            'Sepet Boş',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ürün eklemek için soldan seçin',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(PosState posState, PosNotifier notifier) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: posState.cartItems.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppColors.border.withOpacity(0.5),
        indent: 12,
        endIndent: 12,
      ),
      itemBuilder: (context, index) {
        final item = posState.cartItems[index];
        return CartItemRow(
          item: item,
          onRemove: () => notifier.removeFromCart(item.productId),
          onQuantityChanged: (qty) =>
              notifier.updateQuantity(item.productId, qty),
          onDiscountChanged: (disc) =>
              notifier.updateDiscount(item.productId, disc),
        );
      },
    );
  }

  Widget _buildTotalSection(PosState posState, PosNotifier notifier) {
    return Container(
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
      child: Column(
        children: [
          // Ara toplam
          _buildSummaryRow('Ara Toplam', posState.subtotal),
          if (posState.totalDiscount > 0)
            _buildSummaryRow(
              'İndirim',
              -posState.totalDiscount,
              color: AppColors.success,
            ),
          _buildSummaryRow('KDV', posState.totalTax),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Genel toplam
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOPLAM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${posState.grandTotal.toStringAsFixed(2)} \u20BA',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Ödeme butonu
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: posState.cartItems.isEmpty ? null : onPaymentPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.payment, size: 20),
              label: const Text(
                'Ödeme Yap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color}) {
    final isNegative = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${isNegative ? "-" : ""}${amount.abs().toStringAsFixed(2)} \u20BA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showParkDialog(BuildContext context, PosNotifier notifier) {
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siparişi Park Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bu siparişe bir etiket vermek istiyorsanız yazın (opsiyonel):'),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                hintText: 'Örn: Masa 5, VIP müşteri, vb...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLength: 50,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.parkCurrentOrder(label: labelController.text.isNotEmpty ? labelController.text : null);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Park Et'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context, PosNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sepeti Temizle'),
        content: const Text('Tüm ürünler sepetten kaldırılacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.clearCart();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showCustomerPicker(
      BuildContext context, PosNotifier notifier, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CustomerPickerSheet(
        onSelected: (customer) {
          notifier.selectCustomer(customer);
          Navigator.pop(ctx);
        },
        ref: ref,
      ),
    );
  }
}

// ─── Customer Picker Bottom Sheet ────────────────────────────────
class _CustomerPickerSheet extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onSelected;
  final WidgetRef ref;

  const _CustomerPickerSheet({
    required this.onSelected,
    required this.ref,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await widget.ref
          .read(customerServiceProvider)
          .getCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
          _filtered = customers;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _customers.where((c) {
        return (c['name']?.toString().toLowerCase() ?? '').contains(q) ||
            (c['phone']?.toString() ?? '').contains(q);
      }).toList();
    });
  }

  Future<void> _showQuickCustomerDialog() async {
    final newCustomer = await QuickCustomerDialog.show(
      context,
      onCustomerCreated: (customer) {
        // Add the new customer to the list and auto-select
        setState(() {
          _customers.insert(0, customer);
          _filtered = _customers;
        });
      },
    );

    if (newCustomer != null && mounted) {
      // Auto-select the newly created customer
      widget.onSelected(newCustomer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title with Create Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Müşteri Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: _showQuickCustomerDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text(
                        'Yeni Ekle',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'İsim veya telefon ile ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text('Müşteri bulunamadı',
                              style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final c = _filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  (c['name']?.toString() ?? '?')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              title: Text(c['name']?.toString() ?? ''),
                              subtitle: Text(
                                c['phone']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  size: 18, color: AppColors.textMuted),
                              onTap: () => widget.onSelected(c),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
  