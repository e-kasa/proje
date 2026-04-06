import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';

/// Yeniden kullanilabilir odeme/tahsilat kayit dialog'u.
/// Hem musteri tahsilati hem tedarikci odemesi icin kullanilir.
class PaymentRecordModal {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required bool isCustomer,
    String? accountName,
  }) async {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    String paymentType = 'CASH';

    final title = isCustomer
        ? 'Tahsilat Kaydet${accountName != null ? ' - $accountName' : ''}'
        : 'Odeme Kaydet${accountName != null ? ' - $accountName' : ''}';
    final buttonLabel = isCustomer ? 'Tahsilati Kaydet' : 'Odemeyi Kaydet';
    final accentColor = isCustomer ? AppColors.success : AppColors.primary;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCustomer ? Icons.payments : Icons.payment,
                  color: accentColor, size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Tutar (TL) *',
                    prefixIcon: Icon(Icons.attach_money, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: paymentType,
                  decoration: InputDecoration(
                    labelText: 'Odeme Tipi',
                    prefixIcon: const Icon(Icons.credit_card, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CASH', child: Text('Nakit')),
                    DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Havale/EFT')),
                    DropdownMenuItem(value: 'CREDIT_CARD', child: Text('Kredi Karti')),
                    DropdownMenuItem(value: 'CHECK', child: Text('Cek')),
                    DropdownMenuItem(value: 'PROMISSORY_NOTE', child: Text('Senet')),
                    DropdownMenuItem(value: 'MOBILE_PAYMENT', child: Text('Mobil Odeme')),
                  ],
                  onChanged: (v) => setDialogState(() => paymentType = v ?? 'CASH'),
                ),
                const SizedBox(height: 14),
                if (['BANK_TRANSFER', 'CREDIT_CARD', 'CHECK'].contains(paymentType)) ...[
                  TextField(
                    controller: bankCtrl,
                    decoration: InputDecoration(
                      labelText: 'Banka Adi',
                      prefixIcon: const Icon(Icons.account_balance, color: AppColors.info),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(
                    labelText: 'Referans No (opsiyonel)',
                    hintText: paymentType == 'CHECK' ? 'Cek no...'
                        : paymentType == 'BANK_TRANSFER' ? 'Dekont no...'
                        : 'Referans no...',
                    prefixIcon: const Icon(Icons.tag, color: AppColors.info),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Aciklama (opsiyonel)',
                    prefixIcon: const Icon(Icons.notes, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton.icon(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gecerli bir tutar girin'), backgroundColor: AppColors.danger),
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'amount': amount,
                  'paymentType': paymentType,
                  if (descCtrl.text.isNotEmpty) 'description': descCtrl.text,
                  if (refCtrl.text.isNotEmpty) 'referenceNumber': refCtrl.text,
                  if (bankCtrl.text.isNotEmpty) 'bankName': bankCtrl.text,
                });
              },
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: Text(buttonLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
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

class _AccountSelectContent extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() loadCustomers;
  final Future<List<Map<String, dynamic>>> Function() loadSuppliers;
  const _AccountSelectContent({required this.loadCustomers, required this.loadSuppliers});

  @override
  State<_AccountSelectContent> createState() => _AccountSelectContentState();
}

class _AccountSelectContentState extends State<_AccountSelectContent> with SingleTickerProviderStateMixin {
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
      final r = await Future.wait([widget.loadCustomers(), widget.loadSuppliers()]);
      setState(() {
        _customers = r[0]; _suppliers = r[1];
        _filteredC = _customers; _filteredS = _suppliers;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredC = _customers.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(q)).toList();
      _filteredS = _suppliers.where((s) => (s['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Hesap Sec', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: double.maxFinite, height: 420,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Ara...', prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary, unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Musteriler (${_filteredC.length})'),
                Tab(text: 'Tedarikciler (${_filteredS.length})'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(controller: _tabCtrl, children: [
                      _list(_filteredC, 'CUSTOMER'),
                      _list(_filteredS, 'SUPPLIER'),
                    ]),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Iptal'))],
    );
  }

  Widget _list(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) return const Center(child: Text('Kayit bulunamadi', style: TextStyle(color: AppColors.textMuted)));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = items[i];
        final isCust = type == 'CUSTOMER';
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: (isCust ? AppColors.info : AppColors.primary).withOpacity(0.1),
            child: Icon(isCust ? Icons.person : Icons.business, size: 18, color: isCust ? AppColors.info : AppColors.primary),
          ),
          title: Text(item['name']?.toString() ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: (item['phone']?.toString() ?? '').isNotEmpty
              ? Text(item['phone'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
              : null,
          trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
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
