import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';
import '../accounts/payment_record_modal.dart';

class SupplierAccountDetailScreen extends ConsumerStatefulWidget {
  final String supplierId;
  const SupplierAccountDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierAccountDetailScreen> createState() =>
      _SupplierAccountDetailScreenState();
}

class _SupplierAccountDetailScreenState
    extends ConsumerState<SupplierAccountDetailScreen> {
  Map<String, dynamic>? _supplier;
  Map<String, dynamic>? _account;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;
  String _txFilter = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final svc = ref.read(supplierServiceProvider);
      final results = await Future.wait([
        svc.getSupplierById(widget.supplierId),
        svc.getSupplierAccount(widget.supplierId),
        svc.getSupplierTransactions(widget.supplierId),
      ]);
      setState(() {
        _supplier = results[0] as Map<String, dynamic>?;
        _account = results[1] as Map<String, dynamic>?;
        _transactions = (results[2] as List<Map<String, dynamic>>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_txFilter == 'Tümü') return _transactions;
    if (_txFilter == 'Borc') {
      return _transactions
          .where((t) => (t['debitAmount'] ?? 0) > 0)
          .toList();
    }
    if (_txFilter == 'Alacak') {
      return _transactions
          .where((t) => (t['creditAmount'] ?? 0) > 0)
          .toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(title: const Text('Cari Hesap')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _supplier == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(title: const Text('Cari Hesap')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_error ?? 'Tedarikci bulunamadi',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _loadAll, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    final supplierName = _supplier!['name']?.toString() ?? '-';
    final balance = _toDouble(_account?['currentBalance']);
    final totalDebt = _toDouble(_account?['totalDebt']);
    final totalCredit = _toDouble(_account?['totalCredit']);
    final overdueAmount = _toDouble(_account?['overdueAmount']);
    final creditLimit = _toDouble(_account?['creditLimit'] ?? _supplier!['creditLimit']);
    final availableCredit = _toDouble(_account?['availableCreditLimit']);
    final isLimitExceeded = _account?['isCreditLimitExceeded'] == true;
    final txCount = _account?['totalTransactionCount'] ?? _transactions.length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(supplierName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Text('Cari Hesap Detayi',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bakiye Karti
            _buildBalanceCard(balance, isLimitExceeded),
            const SizedBox(height: 12),

            // Ozet Kartlari
            Row(
              children: [
                Expanded(
                    child: _summaryCard(
                        'Toplam Borc', totalDebt, AppColors.danger, Icons.arrow_upward)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard(
                        'Toplam Odeme', totalCredit, AppColors.success, Icons.arrow_downward)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _summaryCard('Vadesi Gecmis', overdueAmount,
                        AppColors.warning, Icons.warning_amber)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard('Kredi Limiti', creditLimit,
                        AppColors.info, Icons.credit_card)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _summaryCard('Kullanilabilir', availableCredit,
                        isLimitExceeded ? AppColors.danger : AppColors.success,
                        Icons.account_balance_wallet)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard('Hareket Sayisi', txCount.toDouble(),
                        AppColors.primary, Icons.receipt_long,
                        isCount: true)),
              ],
            ),
            const SizedBox(height: 16),

            // Aksiyon Butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(),
                    icon: const Icon(Icons.payment, color: Colors.white, size: 18),
                    label: const Text('Ödeme Yap',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditSupplierInfoDialog(),
                    icon: const Icon(Icons.business_outlined, color: Colors.white, size: 18),
                    label: const Text('Bilgileri Güncelle',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditAccountDialog(),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    label: const Text('Hesap Ayarları',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hareket Listesi Baslik
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hesap Hareketleri (${_filteredTransactions.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),

            // Filtre Chipleri
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['Tümü', 'Borc', 'Alacak'].map((f) {
                  final selected = _txFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f, style: TextStyle(fontSize: 12,
                          color: selected ? Colors.white : AppColors.textPrimary)),
                      selected: selected,
                      selectedColor: f == 'Borc'
                          ? AppColors.danger
                          : f == 'Alacak'
                              ? AppColors.success
                              : AppColors.primary,
                      backgroundColor: Colors.white,
                      onSelected: (_) => setState(() => _txFilter = f),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Hareket Listesi
            if (_filteredTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48,
                        color: AppColors.textMuted.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text('Henuz hareket kaydedilmemis',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              )
            else
              ..._filteredTransactions.map(_buildTransactionCard),
          ],
        ),
      ),
    );
  }

  // ─── Bakiye Karti ─────────────────────────────────────────────────

  Widget _buildBalanceCard(double balance, bool isExceeded) {
    final isPositive = balance > 0;
    final balanceColor = isPositive ? AppColors.danger : AppColors.success;
    final balanceLabel = isPositive ? 'Borcunuz Var' : balance < 0 ? 'Alacaginiz Var' : 'Hesap Kapali';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExceeded
              ? [AppColors.danger, AppColors.danger.withOpacity(0.8)]
              : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Guncel Bakiye',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              if (isExceeded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LIMIT ASILDI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatCurrency(balance.abs())} TL',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(balanceLabel,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ─── Ozet Karti ───────────────────────────────────────────────────

  Widget _summaryCard(
      String label, double value, Color color, IconData icon,
      {bool isCount = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isCount ? '${value.toInt()}' : '${_formatCurrency(value)} TL',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ─── Hareket Karti ────────────────────────────────────────────────

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final debit = _toDouble(tx['debitAmount']);
    final credit = _toDouble(tx['creditAmount']);
    final isDebit = debit > 0;
    final amount = isDebit ? debit : credit;
    final isCancelled = tx['isCancelled'] == true;

    final typeLabel = tx['transactionTypeLabel']?.toString() ??
        tx['transactionType']?.toString() ??
        '-';
    final refNumber = tx['referenceNumber']?.toString() ?? '';
    final description = tx['description']?.toString() ?? '';
    final txDate = tx['transactionDate']?.toString() ?? '';
    final dueDate = tx['dueDate']?.toString() ?? '';
    final isOverdue = tx['isOverdue'] == true;

    String displayDate = '';
    if (txDate.length >= 10) displayDate = txDate.substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCancelled ? AppColors.bgLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCancelled
              ? AppColors.textMuted.withOpacity(0.3)
              : isOverdue
                  ? AppColors.warning
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Ikon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCancelled
                  ? AppColors.textMuted.withOpacity(0.1)
                  : isDebit
                      ? AppColors.danger.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isCancelled
                  ? AppColors.textMuted
                  : isDebit
                      ? AppColors.danger
                      : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Detay
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (isOverdue && !isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('VADESI GECMIS',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning)),
                      ),
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('IPTAL',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (refNumber.isNotEmpty) ...[
                      Text(refNumber,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                    ],
                    Text(displayDate,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    if (dueDate.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('Vade: $dueDate',
                          style: TextStyle(
                              fontSize: 10,
                              color: isOverdue
                                  ? AppColors.warning
                                  : AppColors.textMuted)),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),

          // Tutar
          const SizedBox(width: 8),
          Text(
            '${isDebit ? '+' : '-'}${_formatCurrency(amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isCancelled
                  ? AppColors.textMuted
                  : isDebit
                      ? AppColors.danger
                      : AppColors.success,
              decoration:
                  isCancelled ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tedarikçi Temel Bilgileri Güncelleme Dialog ───────────────────

  void _showEditSupplierInfoDialog() {
    final nameCtrl =
        TextEditingController(text: _supplier?['name']?.toString() ?? '');
    final taxNumberCtrl =
        TextEditingController(text: _supplier?['taxNumber']?.toString() ?? '');
    final taxOfficeCtrl =
        TextEditingController(text: _supplier?['taxOffice']?.toString() ?? '');
    final contactNameCtrl =
        TextEditingController(text: _supplier?['contactName']?.toString() ?? '');
    final phoneCtrl =
        TextEditingController(text: _supplier?['phone']?.toString() ?? '');
    final emailCtrl =
        TextEditingController(text: _supplier?['email']?.toString() ?? '');
    final addressCtrl =
        TextEditingController(text: _supplier?['address']?.toString() ?? '');
    final notesCtrl =
        TextEditingController(text: _supplier?['notes']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.business_outlined, color: AppColors.info, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Tedarikçi Bilgileri', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Firma Bilgileri',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                // Firma Adı
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Firma Adı *',
                    prefixIcon:
                        const Icon(Icons.business, color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Vergi No
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: taxNumberCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Vergi No',
                          prefixIcon: const Icon(Icons.numbers,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: taxOfficeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Vergi Dairesi',
                          prefixIcon: const Icon(Icons.account_balance,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('İletişim Bilgileri',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                // Yetkili Kişi
                TextField(
                  controller: contactNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Yetkili Kişi',
                    prefixIcon:
                        const Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Telefon & E-posta
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Telefon',
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Adres
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Adres',
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                // Notlar
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notlar',
                    prefixIcon: const Icon(Icons.notes_outlined,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Firma adı zorunludur'),
                  backgroundColor: AppColors.danger,
                ));
                return;
              }
              Navigator.pop(ctx);
              await _updateSupplierBasicInfo(
                name: name,
                taxNumber: taxNumberCtrl.text.trim(),
                taxOffice: taxOfficeCtrl.text.trim(),
                contactName: contactNameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
            child:
                const Text('Güncelle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSupplierBasicInfo({
    required String name,
    required String taxNumber,
    required String taxOffice,
    required String contactName,
    required String phone,
    required String email,
    required String address,
    required String notes,
  }) async {
    try {
      final svc = ref.read(supplierServiceProvider);
      await svc.updateSupplier(widget.supplierId, {
        'name': name,
        'taxNumber': taxNumber,
        'taxOffice': taxOffice,
        'contactName': contactName,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tedarikçi bilgileri güncellendi'),
          backgroundColor: AppColors.success,
        ));
      }
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Güncelleme hatası: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  // ─── Hesap Bilgileri Düzenleme Dialog ──────────────────────────────

  void _showEditAccountDialog() {
    final creditLimitCtrl = TextEditingController(
        text: _toDouble(_account?['creditLimit'] ?? _supplier?['creditLimit'])
            .toStringAsFixed(0));
    final paymentTermCtrl = TextEditingController(
        text: (_supplier?['paymentTermDays'] ?? 30).toString());
    final contactNameCtrl =
        TextEditingController(text: _supplier?['contactName']?.toString() ?? '');
    final phoneCtrl =
        TextEditingController(text: _supplier?['phone']?.toString() ?? '');
    final emailCtrl =
        TextEditingController(text: _supplier?['email']?.toString() ?? '');
    final addressCtrl =
        TextEditingController(text: _supplier?['address']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Hesap Bilgileri', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kredi Limiti
              TextField(
                controller: creditLimitCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Kredi Limiti (TL)',
                  prefixIcon:
                      const Icon(Icons.credit_card, color: AppColors.info),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              // Vade Süresi
              TextField(
                controller: paymentTermCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ödeme Vadesi (gün)',
                  prefixIcon:
                      const Icon(Icons.schedule, color: AppColors.warning),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('İletişim Bilgileri',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 10),
              // İletişim Adı
              TextField(
                controller: contactNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Yetkili Kişi',
                  prefixIcon:
                      const Icon(Icons.person_outline, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              // Telefon
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon:
                      const Icon(Icons.phone_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              // E-posta
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              // Adres
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Adres',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateSupplierInfo(
                creditLimit:
                    double.tryParse(creditLimitCtrl.text) ?? 0,
                paymentTermDays:
                    int.tryParse(paymentTermCtrl.text) ?? 30,
                contactName: contactNameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              );
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Güncelle',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSupplierInfo({
    required double creditLimit,
    required int paymentTermDays,
    required String contactName,
    required String phone,
    required String email,
    required String address,
  }) async {
    try {
      final svc = ref.read(supplierServiceProvider);

      // Kredi limiti ayrı endpoint
      await svc.updateCreditLimit(widget.supplierId, creditLimit);

      // Tedarikçi bilgileri güncelle
      await svc.updateSupplier(widget.supplierId, {
        'paymentTermDays': paymentTermDays,
        'contactName': contactName,
        'phone': phone,
        'email': email,
        'address': address,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Hesap bilgileri güncellendi'),
          backgroundColor: AppColors.success,
        ));
      }
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Güncelleme hatası: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  // ─── Odeme Dialog ─────────────────────────────────────────────────

  Future<void> _showPaymentDialog() async {
    final supplierName = _supplier?['name']?.toString();
    final result = await PaymentRecordModal.show(
      context,
      isCustomer: false,
      accountName: supplierName,
    );
    if (result != null) {
      await _recordPayment(result);
    }
  }

  Future<void> _recordPayment(Map<String, dynamic> data) async {
    try {
      await ref.read(supplierServiceProvider).recordPayment(
        widget.supplierId,
        data,
      );
      if (mounted) {
        final amount = data['amount'] as double;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_formatCurrency(amount)} TL odeme kaydedildi'),
          backgroundColor: AppColors.success,
        ));
      }
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Odeme kaydedilemedi: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _formatCurrency(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}
