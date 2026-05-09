import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// Yeniden kullanilabilir odeme/tahsilat kayit dialog'u.
/// Hem musteri tahsilati hem tedarikci odemesi icin kullanilir.
///
/// Sprint 11d: plaka filtresi modal'dan kaldırıldı (ekstrede transaction
/// kartlarına chip + filter olarak taşındı).
class PaymentRecordModal {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required bool isCustomer,
    String? accountName,
  }) async {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => _PaymentRecordContent(
        isCustomer: isCustomer,
        accountName: accountName,
      ),
    );
  }
}

class _PaymentRecordContent extends ConsumerStatefulWidget {
  final bool isCustomer;
  final String? accountName;

  const _PaymentRecordContent({
    required this.isCustomer,
    this.accountName,
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

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _refCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
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

    Navigator.pop(context, {
      'amount': amount,
      'paymentType': _paymentType,
      if (_bankCtrl.text.isNotEmpty) 'bankName': _bankCtrl.text,
      if (_refCtrl.text.isNotEmpty) 'referenceNo': _refCtrl.text,
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text,
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

