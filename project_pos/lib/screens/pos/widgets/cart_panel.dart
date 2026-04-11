import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/service_locator.dart';
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
            color: Colors.black.withValues(alpha: 0.05),
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
      color: AppColors.primary.withValues(alpha: 0.05),
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
      onTap: () => _showCustomerPicker(context, notifier, state.selectedCustomer),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
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
            _summaryRow('İndirim', '-${currencyFormat.format(state.totalDiscount)}', color: AppColors.bgDanger,
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

  void _showCustomerPicker(BuildContext context, PosNotifier notifier, Map<String, dynamic>? selectedCustomer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerPickerSheet(
        selected: selectedCustomer,
        onSelect: (c) {
          notifier.selectCustomer(c);
          Navigator.pop(context);
        },
        onClear: () {
          notifier.selectCustomer(null);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Müşteri Seçici Bottom Sheet ────────────────────────────────────────────
class _CustomerPickerSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onClear;

  const _CustomerPickerSheet({
    required this.selected,
    required this.onSelect,
    required this.onClear,
  });

  @override
  ConsumerState<_CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list =
          await ref.read(customerServiceProvider).getCustomers(isActive: true);
      if (mounted) setState(() { _customers = list; _filtered = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _customers
          : _customers.where((c) {
              final name  = (c['name'] as String? ?? '').toLowerCase();
              final phone = (c['phone'] as String? ?? '').toLowerCase();
              final email = (c['email'] as String? ?? '').toLowerCase();
              return name.contains(lower) ||
                  phone.contains(lower) ||
                  email.contains(lower);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Başlık
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            const Text('Müşteri Seç',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (widget.selected != null)
              TextButton.icon(
                onPressed: widget.onClear,
                icon: const Icon(Icons.person_remove, size: 16),
                label: const Text('Temizle', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.bgDanger,
              ),
          ]),
        ),
        // Arama
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Ad, telefon veya e-posta ile ara...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: AppColors.bgLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Liste
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Text('Müşteri bulunamadı',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final isSelected = widget.selected?['id'] == c['id'];
                        return ListTile(
                          dense: true,
                          onTap: () => widget.onSelect(c),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelected
                                ? AppColors.success
                                : AppColors.bgLight,
                            child: Text(
                              (c['name'] as String? ?? '?')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary),
                            ),
                          ),
                          title: Text(c['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            [
                              c['phone'],
                              c['email'],
                            ].where((v) => v != null && v.toString().isNotEmpty).join(' · '),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.success, size: 18)
                              : null,
                        );
                      },
                    ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
