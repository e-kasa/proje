import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/providers/customer_open_sales_provider.dart';

/// Yeniden kullanilabilir odeme/tahsilat kayit dialog'u.
/// Hem musteri tahsilati hem tedarikci odemesi icin kullanilir.
///
/// Sprint 7: alisveris bazli odeme — `customerId` doluysa modal acik
/// satislari listeler, kullanici belirli bir satisa odeme yapabilir.
/// Tedarikci tarafinda (`!isCustomer`) picker gosterilmez.
///
/// Sprint 11d: plaka filtresi modal'dan kaldırıldı (ekstrede transaction
/// kartlarına chip + filter olarak taşındı). Modal artık sadece allocation
/// modu (GENERAL/SPECIFIC) ile çalışır; SPECIFIC seçildiğinde tüm açık
/// satışlar listelenir.
///
/// Sprint 11f: `saleId` parametresi geçirildiğinde (SaleDetailPanel'den
/// çağrı) allocation toggle/picker tamamen gizlenir, modal sadece tutar +
/// ödeme tipi alır. `prefillAmount` set edilmişse amount controller'ı
/// otomatik dolar (kalan tutar).
class PaymentRecordModal {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required bool isCustomer,
    String? accountName,
    String? customerId,
    String? saleId,
    double? prefillAmount,
  }) async {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => _PaymentRecordContent(
        isCustomer: isCustomer,
        accountName: accountName,
        customerId: customerId,
        saleId: saleId,
        prefillAmount: prefillAmount,
      ),
    );
  }
}

class _PaymentRecordContent extends ConsumerStatefulWidget {
  final bool isCustomer;
  final String? accountName;
  final String? customerId;
  final String? saleId;
  final double? prefillAmount;

  const _PaymentRecordContent({
    required this.isCustomer,
    this.accountName,
    this.customerId,
    this.saleId,
    this.prefillAmount,
  });

  @override
  ConsumerState<_PaymentRecordContent> createState() =>
      _PaymentRecordContentState();
}

class _PaymentRecordContentState extends ConsumerState<_PaymentRecordContent> {
  String Function(String) get t => i18nOf(ref);

  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  String _paymentType = 'CASH';

  // Sprint 7 — Sale-Payment allocation
  String _allocationMode = 'GENERAL'; // 'GENERAL' | 'SPECIFIC'
  String? _selectedSaleId;

  @override
  void initState() {
    super.initState();
    // Sprint 11f — SaleDetailPanel'den çağrıldığında satış zaten dışarıda
    // seçili; modal'a saleId iletilince allocation otomatik SPECIFIC + amount
    // pre-fill (kalan tutar). Toggle/picker gizli kalır.
    if (widget.saleId != null) {
      _allocationMode = 'SPECIFIC';
      _selectedSaleId = widget.saleId;
    }
    if (widget.prefillAmount != null && widget.prefillAmount! > 0) {
      _amountCtrl.text = widget.prefillAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _refCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  /// Sprint 7 — Açık satışlar listesi (SPECIFIC modunda gösterilir).
  /// Kullanıcı bir satış seçince tutar otomatik dolar (kalan bakiye).
  Widget _buildOpenSalesPicker() {
    final salesAsync = ref.watch(customerOpenSalesProvider(
      CustomerOpenSalesKey(widget.customerId!),
    ));
    return salesAsync.when(
      data: (sales) {
        if (sales.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              t('accounts.no_open_sales'),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: SingleChildScrollView(
            child: Column(
              children: sales.map((s) {
                final saleId = s['id']?.toString() ?? '';
                final saleNumber = s['saleNumber']?.toString() ?? '';
                final remaining =
                    (s['remainingAmount'] as num?)?.toDouble() ?? 0.0;
                final dateRaw = s['saleDate']?.toString() ?? '';
                final dateShort =
                    dateRaw.length >= 10 ? dateRaw.substring(0, 10) : dateRaw;
                return RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: saleId,
                  groupValue: _selectedSaleId,
                  title: Text(
                    '#$saleNumber',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '$dateShort · ${remaining.toStringAsFixed(2)} ${t('accounts.sale_remaining')}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                  onChanged: (v) => setState(() {
                    _selectedSaleId = v;
                    _amountCtrl.text = remaining.toStringAsFixed(2);
                  }),
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Hata: $e',
          style: const TextStyle(color: AppColors.danger, fontSize: 11),
        ),
      ),
    );
  }

  void _submit() {
    if (_amountCtrl.text.isEmpty) {
      AppToast.warning(context, t('accounts.amount_required'));
      return;
    }

    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      AppToast.warning(context, t('accounts.amount_required'));
      return;
    }

    // Sprint 7: Belirli alışverişe seçildi ama satış henüz seçilmediyse uyar
    if (_allocationMode == 'SPECIFIC' && _selectedSaleId == null) {
      AppToast.warning(context, t('accounts.specific_sale_payment'));
      return;
    }

    // Sprint 7 — allocations: tek-allocation (Sale ↔ Payment many-to-many).
    // SPECIFIC + saleId → tek allocation (saleId, amount)
    // GENERAL → tek allocation (saleId=null, amount) — backend "genel ödeme" işler
    final effectiveSaleId =
        (_allocationMode == 'SPECIFIC') ? _selectedSaleId : null;
    final allocations = [
      {'saleId': effectiveSaleId, 'amount': amount}
    ];

    Navigator.pop(context, {
      'amount': amount,
      'paymentType': _paymentType,
      if (_bankCtrl.text.isNotEmpty) 'bankName': _bankCtrl.text,
      if (_refCtrl.text.isNotEmpty) 'referenceNo': _refCtrl.text,
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text,
      'allocations': allocations,
      // Geriye uyum: backend deprecated saleId field'ı hâlâ kabul ediyor
      if (effectiveSaleId != null) 'saleId': effectiveSaleId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isCustomer ? AppColors.success : AppColors.primary;

    final titleKey = widget.isCustomer
        ? 'accounts.collect_payment'
        : 'accounts.record_payment';
    final title = widget.accountName != null
        ? '${t(titleKey)} - ${widget.accountName}'
        : t(titleKey);

    final buttonLabel = widget.isCustomer
        ? t('accounts.save_collection')
        : t('accounts.save_payment');

    final refHint = _paymentType == 'CHECK'
        ? t('accounts.check_no_hint')
        : _paymentType == 'BANK_TRANSFER'
            ? t('accounts.receipt_no_hint')
            : t('accounts.reference_hint');

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.isCustomer ? Icons.payments : Icons.payment,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: t('accounts.amount_label'),
                prefixIcon: Icon(Icons.attach_money, color: accentColor),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            InputDecorator(
              decoration: InputDecoration(
                labelText: t('accounts.payment_type'),
                prefixIcon: const Icon(Icons.credit_card,
                    color: AppColors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButton<String>(
                value: _paymentType,
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                      value: 'CASH', child: Text(t('finance.cash'))),
                  DropdownMenuItem(
                      value: 'BANK_TRANSFER',
                      child: Text(t('finance.bank_transfer'))),
                  DropdownMenuItem(
                      value: 'CREDIT_CARD',
                      child: Text(t('finance.credit_card'))),
                  DropdownMenuItem(
                      value: 'CHECK', child: Text(t('accounts.check'))),
                  DropdownMenuItem(
                      value: 'PROMISSORY_NOTE',
                      child: Text(t('accounts.promissory_note'))),
                  DropdownMenuItem(
                      value: 'MOBILE_PAYMENT',
                      child: Text(t('accounts.mobile_payment'))),
                ],
                onChanged: (v) =>
                    setState(() => _paymentType = v ?? 'CASH'),
              ),
            ),
            const SizedBox(height: 14),
            if (['BANK_TRANSFER', 'CREDIT_CARD', 'CHECK']
                .contains(_paymentType)) ...[
              TextField(
                controller: _bankCtrl,
                decoration: InputDecoration(
                  labelText: t('accounts.bank_name'),
                  prefixIcon: const Icon(Icons.account_balance,
                      color: AppColors.info),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _refCtrl,
              decoration: InputDecoration(
                labelText: t('accounts.reference_no_label'),
                hintText: refHint,
                prefixIcon:
                    const Icon(Icons.tag, color: AppColors.info),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            // Sprint 7 — Alışveriş bazlı ödeme picker (sadece müşteri + customerId varsa)
            // Sprint 11f — saleId varsa satış zaten dışarıda seçili, allocation
            // toggle/picker tamamen gizlenir; modal sadece tutar + ödeme tipi alır.
            if (widget.isCustomer &&
                widget.customerId != null &&
                widget.saleId == null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t('accounts.payment_target'),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: 'GENERAL',
                groupValue: _allocationMode,
                title: Text(t('accounts.general_payment'),
                    style: const TextStyle(fontSize: 13)),
                onChanged: (v) => setState(() {
                  _allocationMode = v ?? 'GENERAL';
                  _selectedSaleId = null;
                }),
              ),
              RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: 'SPECIFIC',
                groupValue: _allocationMode,
                title: Text(t('accounts.specific_sale_payment'),
                    style: const TextStyle(fontSize: 13)),
                onChanged: (v) =>
                    setState(() => _allocationMode = v ?? 'GENERAL'),
              ),
              if (_allocationMode == 'SPECIFIC') _buildOpenSalesPicker(),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t('accounts.description_label'),
                prefixIcon: const Icon(Icons.notes,
                    color: AppColors.textMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('common.cancel')),
        ),
        AppButton.danger(
          text: buttonLabel,
          icon: Icons.check,
          onPressed: _submit,
        ),
      ],
    );
  }
}

