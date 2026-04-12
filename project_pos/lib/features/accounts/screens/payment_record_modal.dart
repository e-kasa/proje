import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// Yeniden kullanilabilir odeme/tahsilat kayit dialog'u.
/// Hem musteri tahsilati hem tedarikci odemesi icin kullanilir.
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
    Navigator.pop(context, {
      'amount': double.parse(_amountCtrl.text),
      'paymentType': _paymentType,
      'bankName': _bankCtrl.text.isNotEmpty ? _bankCtrl.text : null,
      'referenceNo': _refCtrl.text.isNotEmpty ? _refCtrl.text : null,
      'description': _descCtrl.text.isNotEmpty ? _descCtrl.text : null,
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

/// Hesap secim dialog'u.
class AccountSelectDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Future<List<Map<String, dynamic>>> Function() loadCustomers,
    required Future<List<Map<String, dynamic>>> Function() loadSuppliers,
  }) {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => _AccountSelectContent(
        loadCustomers: loadCustomers,
        loadSuppliers: loadSuppliers,
      ),
    );
  }
}

class _AccountSelectContent extends ConsumerStatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() loadCustomers;
  final Future<List<Map<String, dynamic>>> Function() loadSuppliers;

  const _AccountSelectContent(
      {required this.loadCustomers, required this.loadSuppliers});

  @override
  ConsumerState<_AccountSelectContent> createState() =>
      _AccountSelectContentState();
}

class _AccountSelectContentState extends ConsumerState<_AccountSelectContent>
    with SingleTickerProviderStateMixin {
  String Function(String) get t => i18nOf(ref);

  late TabController _tabCtrl;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredC = [];
  List<Map<String, dynamic>> _filteredS = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait(
          [widget.loadCustomers(), widget.loadSuppliers()]);
      setState(() {
        _customers = r[0];
        _suppliers = r[1];
        _filteredC = _customers;
        _filteredS = _suppliers;
        _loading = false;
      });
    } catch (e) {
      debugPrint('AccountSelectDialog load hata: $e');
      setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredC = _customers
          .where((c) =>
              (c['name'] ?? '').toString().toLowerCase().contains(q))
          .toList();
      _filteredS = _suppliers
          .where((s) =>
              (s['name'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(t('accounts.select_account'),
          style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: t('common.search'),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: '${t('menu.customers')} (${_filteredC.length})'),
                Tab(
                    text:
                        '${t('menu.suppliers')} (${_filteredS.length})'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _list(_filteredC, 'CUSTOMER'),
                        _list(_filteredS, 'SUPPLIER'),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('common.cancel')),
        ),
      ],
    );
  }

  Widget _list(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Text(t('common.no_records'),
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = items[i];
        final isCust = type == 'CUSTOMER';
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor:
                (isCust ? AppColors.info : AppColors.primary)
                    .withValues(alpha: 0.1),
            child: Icon(
              isCust ? Icons.person : Icons.business,
              size: 18,
              color: isCust ? AppColors.info : AppColors.primary,
            ),
          ),
          title: Text(
            item['name']?.toString() ?? '-',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: (item['phone']?.toString() ?? '').isNotEmpty
              ? Text(item['phone'].toString(),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted))
              : null,
          trailing: const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textMuted),
          onTap: () => Navigator.pop(context, {
            'accountType': type,
            'accountId': item['id']?.toString() ?? '',
            'accountName': item['name']?.toString() ?? '',
          }),
        );
      },
    );
  }
}
