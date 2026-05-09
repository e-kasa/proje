import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/formatters.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/features/accounts/providers/accounts_list_provider.dart';
import 'package:project_pos/features/accounts/providers/open_plated_sales_provider.dart';
import 'package:project_pos/features/accounts/providers/selected_sale_provider.dart';
import 'package:project_pos/features/accounts/screens/payment_record_modal.dart';
import 'package:project_pos/features/finance/di/finance_di.dart';
import 'package:project_pos/services/service_locator.dart';

/// Sprint 11f — AccountsHub sağ paneli için satış detay görünümü.
///
/// `selectedSaleProvider` saleId set edildiğinde [StatementDetailPanel]
/// yerine bu widget render edilir. Header: cari + plaka + sale#; metrik
/// blok (toplam/ödenen/kalan); ürün listesi; "Bu satışa öde" CTA.
///
/// "Öde" → [PaymentRecordModal] tutar pre-fill (kalan) + saleId iletilir →
/// payload `allocations: [{saleId, amount}]` ile backend Sprint 7 PaymentAllocation
/// patterni satışa ödeme düşer.
class SaleDetailPanel extends ConsumerStatefulWidget {
  final String saleId;
  const SaleDetailPanel({super.key, required this.saleId});

  @override
  ConsumerState<SaleDetailPanel> createState() => _SaleDetailPanelState();
}

class _SaleDetailPanelState extends ConsumerState<SaleDetailPanel> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _sale = {};
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant SaleDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saleId != widget.saleId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data =
          await ref.read(salesServiceProvider).getSaleById(widget.saleId);
      final items = (data['items'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _sale = data;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handlePayment() async {
    final t = i18nOf(ref);
    final remaining =
        (_sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    if (remaining <= 0) {
      AppToast.warning(context, t('accounts.no_open_sales'));
      return;
    }
    final result = await PaymentRecordModal.show(
      context,
      isCustomer: true,
      accountName: _sale['customerName']?.toString(),
      saleId: widget.saleId,
      prefillAmount: remaining,
    );
    if (result == null || !context.mounted) return;

    final customerId = _sale['customerId']?.toString();
    if (customerId == null || customerId.isEmpty) {
      AppToast.error(context, t('common.error'));
      return;
    }

    final amount = (result['amount'] as num).toDouble();
    final payload = <String, dynamic>{
      'amount': amount,
      'paymentType': result['paymentType'],
      'customerId': customerId,
      if (result['bankName'] != null) 'bankName': result['bankName'],
      if (result['referenceNo'] != null)
        'referenceNumber': result['referenceNo'],
      if (result['description'] != null) 'description': result['description'],
      // Sprint 11f — tek-allocation: bu satışa ödeme düşer.
      'allocations': [
        {'saleId': widget.saleId, 'amount': amount}
      ],
      // Geriye uyum: backend deprecated saleId field'ı hâlâ kabul ediyor
      'saleId': widget.saleId,
    };
    try {
      await ref.read(paymentServiceProvider).createPayment(payload);
      if (!context.mounted) return;
      AppToast.success(context, t('ac.payment_saved'));
      // Refresh: sale detayını + ekstre + cari listesi + plakali liste
      await _load();
      ref.invalidate(accountsListProvider);
      ref.invalidate(openPlatedSalesProvider);
      await Future.wait([
        ref.read(accountStatementProvider.notifier).load(),
        ref.read(accountSummaryProvider.notifier).load(),
        ref.read(paymentListProvider.notifier).load(),
      ]);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, '${t('common.error')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 32),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 12),
              AppButton.primary(
                  text: t('common.retry'),
                  icon: Icons.refresh,
                  onPressed: _load),
            ],
          ),
        ),
      );
    }

    final cancelled = _sale['isCancelled'] == true;
    final remaining = (_sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: AppConstants.pagePadding,
        children: [
          _Header(
            sale: _sale,
            onBack: () =>
                ref.read(selectedSaleProvider.notifier).state = null,
          ),
          const SizedBox(height: 12),
          _AmountGrid(sale: _sale),
          const SizedBox(height: 12),
          if (!cancelled && remaining > 0)
            AppButton.danger(
              text: t('accounts.pay_this_sale'),
              icon: Icons.payments_outlined,
              onPressed: _handlePayment,
            ),
          if (cancelled) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusSmall,
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('sales.sale_cancelled_message'),
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.shopping_basket_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(t('accounts.sale_items'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('${_items.length}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            AppEmptyState.noData(
                title: t('common.no_records'), description: '')
          else
            ..._items.map((item) => _ItemRow(item: item)),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final Map<String, dynamic> sale;
  final VoidCallback onBack;
  const _Header({required this.sale, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');
    final saleNumber = sale['saleNumber']?.toString() ?? '-';
    final customerName = sale['customerName']?.toString() ?? '-';
    final plate = sale['vehiclePlate']?.toString();
    final hasPlate = plate != null && plate.isNotEmpty;
    final dateRaw = sale['saleDate']?.toString();
    final dateText = dateRaw != null
        ? dateFmt.format(DateTime.tryParse(dateRaw) ?? DateTime.now())
        : '-';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.textPrimary),
                tooltip: t('accounts.back_to_statement'),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
                child: const Icon(Icons.receipt_long,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#$saleNumber',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(t('accounts.sale_detail'),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(customerName,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
              if (hasPlate)
                AppBadge.info(plate, icon: Icons.directions_car_outlined),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(dateText,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountGrid extends ConsumerWidget {
  final Map<String, dynamic> sale;
  const _AmountGrid({required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final total = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paid = (sale['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remaining = (sale['remainingAmount'] as num?)?.toDouble() ?? 0.0;

    final tiles = [
      _AmountTile(
        label: t('accounts.total_label'),
        value: appCurrencyFmt.format(total),
        icon: Icons.summarize_outlined,
        color: AppColors.primary,
      ),
      _AmountTile(
        label: t('accounts.paid_label'),
        value: appCurrencyFmt.format(paid),
        icon: Icons.arrow_downward,
        color: AppColors.success,
      ),
      _AmountTile(
        label: t('accounts.sale_remaining'),
        value: appCurrencyFmt.format(remaining),
        icon: Icons.warning_amber_rounded,
        color: remaining > 0 ? AppColors.danger : AppColors.success,
      ),
    ];
    return LayoutBuilder(
      builder: (ctx, c) {
        final isWide = c.maxWidth >= 480;
        final cols = isWide ? 3 : 1;
        const sp = 10.0;
        final w = (c.maxWidth - sp * (cols - 1)) / cols;
        return Wrap(
          spacing: sp,
          runSpacing: sp,
          children: tiles
              .map((tile) => SizedBox(width: w, height: 96, child: tile))
              .toList(),
        );
      },
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AmountTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['variantName']?.toString() ??
        item['productName']?.toString() ??
        '-';
    final sku = item['variantSku']?.toString();
    final qty = (item['quantity'] as num?)?.toInt() ?? 0;
    final unit = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final lineTotal = (item['lineTotal'] as num?)?.toDouble() ?? (unit * qty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusSmall,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      if (sku != null && sku.isNotEmpty)
                        Text(sku,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      Text('$qty × ${appCurrencyFmt.format(unit)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              appCurrencyFmt.format(lineTotal),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
