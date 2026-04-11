import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/providers/theme_provider.dart';
import '../providers/pos_provider.dart';
import 'receipt_preview_dialog.dart';

class PaymentPanel extends ConsumerStatefulWidget {
  const PaymentPanel({super.key});

  @override
  ConsumerState<PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends ConsumerState<PaymentPanel>
    with SingleTickerProviderStateMixin {
  final _cashController = TextEditingController();
  final _cardController = TextEditingController();
  final _transferController = TextEditingController();
  final _noteController = TextEditingController();
  late final AnimationController _successAnimCtrl;
  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _successAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _cardController.dispose();
    _transferController.dispose();
    _noteController.dispose();
    _successAnimCtrl.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final gradient = ref.watch(resolvedGradientProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient Header ────────────────────────────────────────────────
          _buildHeader(context, posState, gradient),

          // ── Scrollable Body ────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sipariş özeti (collapsible)
                  _OrderSummaryCard(posState: posState, currency: _currency),
                  const SizedBox(height: 16),

                  // Ödeme yöntemi
                  _SectionLabel(label: 'Ödeme Yöntemi'),
                  const SizedBox(height: 8),
                  _buildPaymentMethodGrid(posState, notifier),
                  const SizedBox(height: 16),

                  // Ödeme girişi
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(posState.paymentMethod),
                      child: _buildPaymentInput(posState, notifier),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Not
                  _buildNoteField(),
                  const SizedBox(height: 12),

                  // Para üstü
                  if (posState.changeAmount > 0) ...[
                    _ChangeAmountBanner(
                      amount: posState.changeAmount,
                      currency: _currency,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Hata
                  if (posState.error != null)
                    _ErrorBanner(message: posState.error!),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Pay Button ─────────────────────────────────────────────────────
          _buildPayButton(posState, notifier, gradient),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, PosState posState, LinearGradient gradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle + close
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.point_of_sale_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ödeme',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (posState.selectedCustomer != null)
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  color: Colors.white70, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                posState.selectedCustomer!['name']?.toString() ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'Müşteri seçilmedi',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  // Grand total chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TOPLAM',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8),
                        ),
                        Text(
                          _currency.format(posState.grandTotal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
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
    );
  }

  // ─── Payment Method Grid ─────────────────────────────────────────────────────

  Widget _buildPaymentMethodGrid(PosState posState, PosNotifier notifier) {
    final methods = [
      _MethodConfig(
        method: PaymentMethod.cash,
        icon: Icons.money_rounded,
        label: 'Nakit',
        subtitle: 'Para üstü hesapla',
        color: AppColors.success,
      ),
      _MethodConfig(
        method: PaymentMethod.creditCard,
        icon: Icons.credit_card_rounded,
        label: 'Kart',
        subtitle: 'Kredi / Banka kartı',
        color: AppColors.primary,
      ),
      _MethodConfig(
        method: PaymentMethod.bankTransfer,
        icon: Icons.account_balance_rounded,
        label: 'Havale/EFT',
        subtitle: 'Banka transferi',
        color: const Color(0xFF7C3AED),
      ),
      _MethodConfig(
        method: PaymentMethod.mixed,
        icon: Icons.layers_rounded,
        label: 'Karma',
        subtitle: 'Birden fazla ödeme',
        color: AppColors.warning,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: methods.map((cfg) {
        final isSelected = posState.paymentMethod == cfg.method;
        return _MethodCard(
          config: cfg,
          isSelected: isSelected,
          onTap: () => notifier.setPaymentMethod(cfg.method),
        );
      }).toList(),
    );
  }

  // ─── Payment Input Area ──────────────────────────────────────────────────────

  Widget _buildPaymentInput(PosState posState, PosNotifier notifier) {
    final t = i18nOf(ref);
    switch (posState.paymentMethod) {
      case PaymentMethod.cash:
        return _CashInputSection(
          controller: _cashController,
          grandTotal: posState.grandTotal,
          currency: _currency,
          onChanged: (val) =>
              notifier.setCashReceived(double.tryParse(val) ?? 0),
          onQuickAmount: (amount) {
            _cashController.text = amount.toStringAsFixed(2);
            notifier.setCashReceived(amount);
            HapticFeedback.selectionClick();
          },
        );

      case PaymentMethod.creditCard:
        return _CardMethodInfo(
          icon: Icons.credit_card_rounded,
          title: t('pos.credit_card_payment_info'),
          subtitle: 'Kart okuyucuya kart takınız',
          color: AppColors.primary,
        );

      case PaymentMethod.bankTransfer:
        return _CardMethodInfo(
          icon: Icons.account_balance_rounded,
          title: t('pos.bank_transfer_payment_info'),
          subtitle: 'Transfer referans numarasını alın',
          color: const Color(0xFF7C3AED),
        );

      case PaymentMethod.mixed:
        return _MixedPaymentSection(
          cashCtrl: _cashController,
          cardCtrl: _cardController,
          transferCtrl: _transferController,
          posState: posState,
          currency: _currency,
          onCashChanged: (v) =>
              notifier.setCashReceived(double.tryParse(v) ?? 0),
          onCardChanged: (v) =>
              notifier.setCardAmount(double.tryParse(v) ?? 0),
          onTransferChanged: (v) =>
              notifier.setTransferAmount(double.tryParse(v) ?? 0),
        );
    }
  }

  // ─── Note Field ─────────────────────────────────────────────────────────────

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      onChanged: ref.read(posProvider.notifier).setNote,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Not (opsiyonel)',
        hintText: 'Satışa özel not ekleyin...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        prefixIcon: const Icon(Icons.note_alt_outlined, size: 20,
            color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: AppColors.bgLight,
      ),
    );
  }

  // ─── Pay Button ──────────────────────────────────────────────────────────────

  Widget _buildPayButton(
      PosState posState, PosNotifier notifier, LinearGradient gradient) {
    final canPay = posState.canSubmit;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: canPay ? gradient : null,
                color: canPay ? null : AppColors.border,
                borderRadius: BorderRadius.circular(14),
                boxShadow: canPay
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: canPay
                      ? () async {
                          HapticFeedback.mediumImpact();
                          final success = await notifier.submitSale();
                          if (success && mounted) {
                            Navigator.pop(context);
                            _showSuccessSheet(context);
                          }
                        }
                      : null,
                  child: Center(
                    child: posState.isSubmitting
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'İşlem yapılıyor...',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: canPay ? Colors.white : AppColors.textMuted,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                canPay
                                    ? 'Satışı Tamamla  ·  ${_currency.format(posState.grandTotal)}'
                                    : 'Ödeme Bilgilerini Giriniz',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: canPay
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Success Bottom Sheet ────────────────────────────────────────────────────

  void _showSuccessSheet(BuildContext context) {
    final posState = ref.read(posProvider);
    final saleData = posState.lastSaleData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _SuccessSheet(
        saleData: saleData,
        currency: _currency,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Subwidgets ──────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Order Summary Card ────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatefulWidget {
  final PosState posState;
  final NumberFormat currency;
  const _OrderSummaryCard({required this.posState, required this.currency});

  @override
  State<_OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends State<_OrderSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.posState;
    final c = widget.currency;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Summary header row (always visible)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.totalItems} ürün · ${s.cartItems.length} kalem',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        if (s.totalDiscount > 0)
                          Text(
                            '${c.format(s.totalDiscount)} indirim uygulandı',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.bgSuccess,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    c.format(s.grandTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  const Divider(height: 12),
                  // Item list
                  ...s.cartItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.quantity}x  ',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          c.format(item.totalWithTax),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 16),
                  _SummaryDetailRow('Ara Toplam', c.format(s.subtotal)),
                  if (s.totalDiscount > 0)
                    _SummaryDetailRow(
                        'İndirim', '-${c.format(s.totalDiscount)}',
                        color: AppColors.bgSuccess,
                  _SummaryDetailRow('KDV', c.format(s.totalTax)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOPLAM',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text(
                        c.format(s.grandTotal),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryDetailRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Method Card ───────────────────────────────────────────────────────────────

class _MethodConfig {
  final PaymentMethod method;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _MethodConfig({
    required this.method,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}

class _MethodCard extends StatelessWidget {
  final _MethodConfig config;
  final bool isSelected;
  final VoidCallback onTap;
  const _MethodCard(
      {required this.config, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = config.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? c.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? c : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: c.withValues(alpha: 0.2), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? c.withValues(alpha: 0.15) : AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(config.icon,
                  size: 18, color: isSelected ? c : AppColors.textMuted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    config.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? c : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    config.subtitle,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 16, color: c),
          ],
        ),
      ),
    );
  }
}

// ── Cash Input Section ────────────────────────────────────────────────────────

class _CashInputSection extends StatelessWidget {
  final TextEditingController controller;
  final double grandTotal;
  final NumberFormat currency;
  final ValueChanged<String> onChanged;
  final ValueChanged<double> onQuickAmount;

  const _CashInputSection({
    required this.controller,
    required this.grandTotal,
    required this.currency,
    required this.onChanged,
    required this.onQuickAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Build quick amounts
    final amounts = <double>[];
    amounts.add(grandTotal); // Exact
    for (final r in [50, 100, 200, 500, 1000, 2000, 5000]) {
      if (r.toDouble() > grandTotal && amounts.length < 5) {
        amounts.add(r.toDouble());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: 'Alınan Nakit',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.money_rounded,
                  color: AppColors.success, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixText: '₺',
            suffixStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.success, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),

        // Quick amount chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: amounts.map((amount) {
              final isExact = amount == grandTotal;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _QuickAmountChip(
                  amount: amount,
                  isExact: isExact,
                  currency: currency,
                  onTap: () => onQuickAmount(amount),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final double amount;
  final bool isExact;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.amount,
    required this.isExact,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isExact
              ? AppColors.success.withValues(alpha: 0.12)
              : AppColors.bgLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExact ? AppColors.success : AppColors.border,
            width: isExact ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExact) ...[
              const Icon(Icons.check_rounded,
                  size: 13, color: AppColors.bgSuccess,
              const SizedBox(width: 4),
            ],
            Text(
              isExact
                  ? 'Tam: ${currency.format(amount)}'
                  : '₺${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isExact ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card / Transfer Method Info ───────────────────────────────────────────────

class _CardMethodInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _CardMethodInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

// ── Mixed Payment Section ─────────────────────────────────────────────────────

class _MixedPaymentSection extends StatelessWidget {
  final TextEditingController cashCtrl;
  final TextEditingController cardCtrl;
  final TextEditingController transferCtrl;
  final PosState posState;
  final NumberFormat currency;
  final ValueChanged<String> onCashChanged;
  final ValueChanged<String> onCardChanged;
  final ValueChanged<String> onTransferChanged;

  const _MixedPaymentSection({
    required this.cashCtrl,
    required this.cardCtrl,
    required this.transferCtrl,
    required this.posState,
    required this.currency,
    required this.onCashChanged,
    required this.onCardChanged,
    required this.onTransferChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = posState.cashReceived + posState.cardAmount + posState.transferAmount;
    final remaining = (posState.grandTotal - total).clamp(0.0, double.infinity);
    final progress = posState.grandTotal > 0
        ? (total / posState.grandTotal).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Girilen: ${currency.format(total)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                  Text(
                    remaining > 0
                        ? 'Kalan: ${currency.format(remaining)}'
                        : 'Tamamlandı ✓',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: remaining > 0
                            ? AppColors.warning
                            : AppColors.bgSuccess,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    remaining <= 0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        _MixedInputField(
          controller: cashCtrl,
          label: 'Nakit',
          icon: Icons.money_rounded,
          color: AppColors.success,
          onChanged: onCashChanged,
        ),
        const SizedBox(height: 8),
        _MixedInputField(
          controller: cardCtrl,
          label: 'Kart',
          icon: Icons.credit_card_rounded,
          color: AppColors.primary,
          onChanged: onCardChanged,
        ),
        const SizedBox(height: 8),
        _MixedInputField(
          controller: transferCtrl,
          label: 'Havale/EFT',
          icon: Icons.account_balance_rounded,
          color: const Color(0xFF7C3AED),
          onChanged: onTransferChanged,
        ),
      ],
    );
  }
}

class _MixedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;

  const _MixedInputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, size: 20, color: color),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixText: '₺',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }
}

// ── Change Amount Banner ──────────────────────────────────────────────────────

class _ChangeAmountBanner extends StatelessWidget {
  final double amount;
  final NumberFormat currency;
  const _ChangeAmountBanner({required this.amount, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.12),
            AppColors.success.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_lira_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Para Üstü',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bgSuccess,
            ),
          ),
          Text(
            currency.format(amount),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDanger,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success Sheet ─────────────────────────────────────────────────────────────

class _SuccessSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? saleData;
  final NumberFormat currency;

  const _SuccessSheet({required this.saleData, required this.currency});

  @override
  ConsumerState<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends ConsumerState<_SuccessSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.saleData;
    final c = widget.currency;
    final gradient = ref.watch(resolvedGradientProvider);

    final saleNumber = s?['saleNumber']?.toString() ?? '-';
    final grandTotal = (s?['grandTotal'] as num?)?.toDouble() ?? 0.0;
    final customerName = s?['customerName']?.toString();
    final paymentMethod = s?['paymentMethod']?.toString() ?? '';
    final changeAmount = (s?['changeAmount'] as num?)?.toDouble() ?? 0.0;
    final itemCount = (s?['totalItems'] as num?)?.toInt() ?? 0;
    final saleDate = DateTime.tryParse(s?['saleDate']?.toString() ?? '');
    final dateStr = saleDate != null
        ? '${saleDate.day.toString().padLeft(2, '0')}.${saleDate.month.toString().padLeft(2, '0')}.${saleDate.year}  ${saleDate.hour.toString().padLeft(2, '0')}:${saleDate.minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated check icon
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 42),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Satış Tamamlandı!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sale info card
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _SuccessInfoRow(
                        icon: Icons.tag_rounded,
                        label: 'Fiş No',
                        value: '#$saleNumber',
                        valueStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                      const Divider(height: 16),
                      _SuccessInfoRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Ürün',
                        value: '$itemCount adet',
                      ),
                      if (customerName != null) ...[
                        const SizedBox(height: 8),
                        _SuccessInfoRow(
                          icon: Icons.person_outline,
                          label: 'Müşteri',
                          value: customerName,
                        ),
                      ],
                      if (paymentMethod.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SuccessInfoRow(
                          icon: Icons.payment_rounded,
                          label: 'Ödeme',
                          value: _paymentMethodLabel(paymentMethod),
                        ),
                      ],
                      if (changeAmount > 0) ...[
                        const SizedBox(height: 8),
                        _SuccessInfoRow(
                          icon: Icons.currency_lira_rounded,
                          label: 'Para Üstü',
                          value: c.format(changeAmount),
                          valueStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bgSuccess,
                        ),
                      ],
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TAHSIL EDİLEN',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5),
                          ),
                          Text(
                            c.format(grandTotal),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Yeni Satış'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: s != null
                            ? () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      ReceiptPreviewDialog(saleData: s),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.receipt_long_rounded, size: 18),
                        label: const Text('Fişi Görüntüle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi / Banka Kartı';
      case 'bank_transfer':
        return 'Havale / EFT';
      case 'mixed':
        return 'Karma Ödeme';
      default:
        return method;
    }
  }
}

class _SuccessInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SuccessInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
