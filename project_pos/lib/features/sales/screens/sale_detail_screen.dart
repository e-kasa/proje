import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/service_locator.dart';

class SaleDetailScreen extends ConsumerStatefulWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _sale = {};
  List<Map<String, dynamic>> _items = [];

  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(salesServiceProvider);
      final data = await service.getSaleById(widget.saleId);
      final items = (data['items'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      setState(() {
        _sale = data;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = i18nOf(ref);
    final cancelled = _sale['status']?.toString().toLowerCase() == 'cancelled' ||
        _sale['isCancelled'] == true;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('sales.detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: t('common.refresh'),
          ),
          if (!_isLoading && _error == null && !cancelled)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'cancel') _confirmCancel(context);
                if (val == 'return') {
                  context.push('/sales/return/${widget.saleId}').then((result) {
                    if (result == true && mounted) _load();
                  });
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'return',
                  child: Row(
                    children: [
                      Icon(Icons.assignment_return_outlined,
                          size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(t('sales.return'),
                          style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined,
                          size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(t('sales.cancel_sale'),
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBanner(cancelled, theme),
                        const SizedBox(height: 16),
                        _buildHeaderCard(theme),
                        const SizedBox(height: 16),
                        _buildAmountCard(theme),
                        const SizedBox(height: 16),
                        _buildPaymentInfoCard(theme),
                        const SizedBox(height: 16),
                        _buildItemsSection(theme),
                        if ((_sale['note'] ?? _sale['notes'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildNotesCard(theme),
                        ],
                        if (!cancelled) ...[
                          const SizedBox(height: 24),
                          _buildActionButtons(theme),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  // ─── Status Banner ────────────────────────────────────────────────────────

  Widget _buildStatusBanner(bool cancelled, ThemeData theme) {
    final t = i18nOf(ref);
    final status = _sale['status']?.toString().toLowerCase() ??
        _sale['paymentStatus']?.toString().toLowerCase() ??
        '';
    final isPending = status == 'pending' || status == 'unpaid';
    final hasReturn = _sale['hasReturn'] == true;

    if (cancelled) {
      final cancelDateStr = _sale['cancelDate']?.toString();
      final cancelDateDisplay = cancelDateStr != null
          ? _dateTimeFmt.format(
              DateTime.tryParse(cancelDateStr) ?? DateTime.now())
          : null;
      final cancelReasonDisplay = _sale['cancelReason']?.toString();
      final cancelDetail = [
        if (cancelDateDisplay != null) 'Tarih: $cancelDateDisplay',
        if (cancelReasonDisplay != null && cancelReasonDisplay.isNotEmpty)
          'Sebep: $cancelReasonDisplay',
      ].join('  •  ');
      return _statusContainer(
        icon: Icons.cancel_outlined,
        text: t('sales.sale_cancelled_message'),
        color: Colors.red,
        reason: cancelDetail.isNotEmpty ? cancelDetail : null,
        theme: theme,
      );
    }

    if (isPending) {
      return Column(
        children: [
          _statusContainer(
            icon: Icons.schedule,
            text: t('sales.pending_payment'),
            color: Colors.orange,
            theme: theme,
          ),
          if (hasReturn) ...[
            const SizedBox(height: 8),
            _statusContainer(
              icon: Icons.assignment_return_outlined,
              text: t('sales.has_return_record'),
              color: Colors.deepOrange,
              theme: theme,
            ),
          ],
        ],
      );
    }

    if (hasReturn) {
      return Column(
        children: [
          _statusContainer(
            icon: Icons.check_circle_outline,
            text: t('sales.sale_completed'),
            color: Colors.green,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _statusContainer(
            icon: Icons.assignment_return_outlined,
            text: t('sales.has_return_record'),
            color: Colors.deepOrange,
            theme: theme,
          ),
        ],
      );
    }

    return _statusContainer(
      icon: Icons.check_circle_outline,
      text: t('sales.sale_completed'),
      color: Colors.green,
      theme: theme,
    );
  }

  Widget _statusContainer({
    required IconData icon,
    required String text,
    required Color color,
    required ThemeData theme,
    String? reason,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                'Sebep: $reason',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Header Card ──────────────────────────────────────────────────────────

  Widget _buildHeaderCard(ThemeData theme) {
    final t = i18nOf(ref);
    final saleNo =
        _sale['saleNumber']?.toString() ?? _sale['id']?.toString() ?? '-';
    final customerName = _sale['name']?.toString() ??
        _sale['customer']?.toString();
    final dateStr = _sale['createdAt']?.toString() ??
        _sale['saleDate']?.toString() ??
        _sale['date']?.toString();
    final dateDisplay = dateStr != null
        ? _dateTimeFmt.format(DateTime.tryParse(dateStr) ?? DateTime.now())
        : '-';
    final paymentMethod =
        _paymentMethodLabel(_sale['paymentMethod']?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppConstants.borderRadiusMedium,
                ),
                child: const Icon(Icons.point_of_sale,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName ?? t('sales.retail_sale'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName != null ? t('sales.customer') : t('sales.anonymous_sale'),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _infoRow(Icons.tag, t('sales.receipt_no'), '#$saleNo', theme),
          const SizedBox(height: 10),
          _infoRow(
              Icons.calendar_today_outlined, t('common.date'), dateDisplay, theme),
          const SizedBox(height: 10),
          _infoRow(Icons.payment, t('sales.payment_method'),
              paymentMethod.isNotEmpty ? paymentMethod : '-', theme),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ─── Amount Card ──────────────────────────────────────────────────────────

  Widget _buildAmountCard(ThemeData theme) {
    final t = i18nOf(ref);
    final subtotal = (_sale['subtotal'] as num?)?.toDouble() ?? 0;
    final totalDiscount =
        (_sale['totalDiscount'] as num?)?.toDouble() ?? 0;
    final totalTax = (_sale['totalTax'] as num?)?.toDouble() ?? 0;
    final grandTotal = (_sale['grandTotal'] as num?)?.toDouble() ??
        (_sale['totalAmount'] as num?)?.toDouble() ??
        0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                t('sales.amount_info'),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _amountRow(t('sales.subtotal'), subtotal, theme),
          if (totalDiscount > 0) ...[
            const SizedBox(height: 6),
            _amountRow(t('sales.discount'), -totalDiscount, theme,
                color: AppColors.success),
          ],
          if (totalTax > 0) ...[
            const SizedBox(height: 6),
            _amountRow(t('sales.vat'), totalTax, theme),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('sales.grand_total'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _fmt.format(grandTotal),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount, ThemeData theme,
      {Color? color}) {
    final isNegative = amount < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          '${isNegative ? "-" : ""}${_fmt.format(amount.abs())}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── Payment Info Card ────────────────────────────────────────────────────

  Widget _buildPaymentInfoCard(ThemeData theme) {
    final t = i18nOf(ref);
    final cashReceived =
        (_sale['cashReceived'] as num?)?.toDouble() ?? 0;
    final cardAmount = (_sale['cardAmount'] as num?)?.toDouble() ?? 0;
    final transferAmount =
        (_sale['transferAmount'] as num?)?.toDouble() ?? 0;
    final changeAmount =
        (_sale['changeAmount'] as num?)?.toDouble() ?? 0;

    final hasCash = cashReceived > 0;
    final hasCard = cardAmount > 0;
    final hasTransfer = transferAmount > 0;

    if (!hasCash && !hasCard && !hasTransfer) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                t('sales.payment_detail'),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasCash)
            _paymentDetailRow(Icons.money, t('sales.payment_cash'), cashReceived, theme),
          if (hasCard) ...[
            const SizedBox(height: 8),
            _paymentDetailRow(
                Icons.credit_card, t('sales.payment_credit_card'), cardAmount, theme),
          ],
          if (hasTransfer) ...[
            const SizedBox(height: 8),
            _paymentDetailRow(
                Icons.account_balance, t('sales.payment_bank_transfer'), transferAmount, theme),
          ],
          if (changeAmount > 0) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.currency_lira,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      t('sales.change_amount'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                Text(
                  _fmt.format(changeAmount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentDetailRow(
      IconData icon, String label, double amount, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
        Text(
          _fmt.format(amount),
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ─── Items Section ────────────────────────────────────────────────────────

  Widget _buildItemsSection(ThemeData theme) {
    final t = i18nOf(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              t('sales.sale_items'),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusMedium,
              ),
              child: Text(
                '${_items.length} ${t('sales.items_unit')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: AppConstants.borderRadiusMedium,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  t('sales.no_items_found'),
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ..._items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _buildItemCard(item, idx, theme);
          }),
      ],
    );
  }

  Widget _buildItemCard(
      Map<String, dynamic> item, int index, ThemeData theme) {
    final t = i18nOf(ref);
    final qty = (item['quantity'] as num?)?.toInt() ?? 0;
    final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
    final discount = (item['discount'] as num?)?.toDouble() ?? 0;
    final taxRate = (item['taxRate'] as num?)?.toDouble() ?? 0;
    final lineTotal = (item['total'] as num?)?.toDouble() ??
        (item['lineTotal'] as num?)?.toDouble() ??
        (unitPrice * qty);
    final productName = item['productName']?.toString() ??
        item['name']?.toString() ??
        'Ürün';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sıra no
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ürün bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _itemTag('$qty ${t('common.quantity_unit')}', Icons.inventory_2_outlined,
                        AppColors.primary, theme),
                    _itemTag('${_fmt.format(unitPrice)} /br',
                        Icons.sell_outlined, Colors.teal, theme),
                    if (discount > 0)
                      _itemTag(
                          '%${discount.toStringAsFixed(0)} ind.',
                          Icons.discount_outlined,
                          AppColors.success,
                          theme),
                    if (taxRate > 0)
                      _itemTag(
                          '%${taxRate.toStringAsFixed(0)} KDV',
                          Icons.percent,
                          Colors.blue,
                          theme),
                  ],
                ),
              ],
            ),
          ),
          // Satır toplamı
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt.format(lineTotal),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t('common.total'),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemTag(
      String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppConstants.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Notes Card ───────────────────────────────────────────────────────────

  Widget _buildNotesCard(ThemeData theme) {
    final t = i18nOf(ref);
    final notes = _sale['note']?.toString() ??
        _sale['notes']?.toString() ??
        '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                t('common.note'),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons(ThemeData theme) {
    final t = i18nOf(ref);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.push('/sales/return/${widget.saleId}').then((result) {
                if (result == true && mounted) _load();
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AppConstants.borderRadiusMedium,
              ),
            ),
            icon: const Icon(Icons.assignment_return_outlined, size: 18),
            label: Text(t('sales.return')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmCancel(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AppConstants.borderRadiusMedium,
              ),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(t('sales.cancel_sale')),
          ),
        ),
      ],
    );
  }

  // ─── Cancel Confirmation ──────────────────────────────────────────────────

  Future<void> _confirmCancel(BuildContext context) async {
    final t = i18nOf(ref);
    final reasonCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('sales.cancel_sale')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('common.are_you_sure')),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t('sales.cancel_reason'),
                hintText: t('sales.cancel_reason_hint'),
                border: OutlineInputBorder(
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('sales.do_cancel'),
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final reason =
          reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : t('sales.not_specified');
      try {
        await ref.read(salesServiceProvider).cancelSale(widget.saleId, reason);
        if (mounted) {
          AppToast.warning(context, t('sales.sale_cancelled_success'));
          _load();
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, '${t('sales.cancel_error')}: $e');
        }
      }
    }
  }

  // ─── Error ────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? 'Hata', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          AppButton.primary(
                        text: 'Tekrar Dene',
                        icon: Icons.refresh,
                        onPressed: _load,
                      ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _paymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Kartı';
      case 'bank_transfer':
        return 'Havale/EFT';
      case 'mixed':
        return 'Karma Ödeme';
      default:
        return '';
    }
  }
}