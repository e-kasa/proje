import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/features/accounts/screens/payment_record_modal.dart';

class SupplierAccountDetailScreen extends ConsumerStatefulWidget {
  final String supplierId;
  const SupplierAccountDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierAccountDetailScreen> createState() =>
      _SupplierAccountDetailScreenState();
}

class _SupplierAccountDetailScreenState
    extends ConsumerState<SupplierAccountDetailScreen> {
  String Function(String) get t => i18nOf(ref);

  Map<String, dynamic>? _supplier;
  Map<String, dynamic>? _account;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;

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

  String _txFilter = 'all';

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_txFilter == 'all') return _transactions;
    if (_txFilter == 'debt') {
      return _transactions
          .where((tx) => (tx['debitAmount'] ?? 0) > 0)
          .toList();
    }
    if (_txFilter == 'credit') {
      return _transactions
          .where((tx) => (tx['creditAmount'] ?? 0) > 0)
          .toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        appBar: AppAppBar.standard(title: t('suppliers.account')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _supplier == null) {
      return AppScaffold(
        appBar: AppAppBar.standard(title: t('suppliers.account')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_error ?? t('suppliers.not_found'),
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              AppButton.primary(
                text: t('common.retry'),
                onPressed: _loadAll,
              ),
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

    return AppScaffold(
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: supplierName,
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
                        t('suppliers.total_debt'), totalDebt, AppColors.danger, Icons.arrow_upward)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard(
                        t('suppliers.total_payment'), totalCredit, AppColors.success, Icons.arrow_downward)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _summaryCard(t('suppliers.overdue'), overdueAmount,
                        AppColors.warning, Icons.warning_amber)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard(t('suppliers.credit_limit'), creditLimit,
                        AppColors.info, Icons.credit_card)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _summaryCard(t('suppliers.available_limit'), availableCredit,
                        isLimitExceeded ? AppColors.danger : AppColors.success,
                        Icons.account_balance_wallet)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard(t('suppliers.movement_count'), txCount.toDouble(),
                        AppColors.primary, Icons.receipt_long,
                        isCount: true)),
              ],
            ),
            const SizedBox(height: 16),

            // Aksiyon Butonları
            Row(
              children: [
                Expanded(
                  child: AppButton.success(
                    text: t('suppliers.make_payment'),
                    icon: Icons.payment,
                    onPressed: () => _showPaymentDialog(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton.primary(
                    text: t('suppliers.update_info'),
                    icon: Icons.business_outlined,
                    onPressed: () => _showEditSupplierInfoDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    text: t('suppliers.account_settings'),
                    icon: Icons.edit_outlined,
                    onPressed: () => _showEditAccountDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hareket Listesi Baslik
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t('suppliers.account_movements')} (${_filteredTransactions.length})',
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
                children: [
                  ('all', t('common.all')),
                  ('debt', t('suppliers.debt')),
                  ('credit', t('suppliers.credit')),
                ].map((entry) {
                  final key = entry.$1;
                  final label = entry.$2;
                  final selected = _txFilter == key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label, style: TextStyle(fontSize: 12,
                          color: selected ? Colors.white : AppColors.textPrimary)),
                      selected: selected,
                      selectedColor: key == 'debt'
                          ? AppColors.danger
                          : key == 'credit'
                              ? AppColors.success
                              : AppColors.primary,
                      backgroundColor: Colors.white,
                      onSelected: (_) => setState(() => _txFilter = key),
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
              AppEmptyState.noData(
                title: t('suppliers.no_movements'),
                description: t('suppliers.no_movements_description'),
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
    final balanceLabel = isPositive ? t('suppliers.you_owe') : balance < 0 ? t('suppliers.you_are_owed') : t('suppliers.account_closed');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExceeded
              ? [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)]
              : [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
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
              Text(t('suppliers.current_balance'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              if (isExceeded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t('suppliers.limit_exceeded').toUpperCase(),
                      style: const TextStyle(
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
              color: Colors.white.withValues(alpha: 0.2),
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
                  color: color.withValues(alpha: 0.1),
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
              ? AppColors.textMuted.withValues(alpha: 0.3)
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
                  ? AppColors.textMuted.withValues(alpha: 0.1)
                  : isDebit
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
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
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(t('suppliers.overdue').toUpperCase(),
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning)),
                      ),
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(t('common.cancelled').toUpperCase(),
                            style: const TextStyle(
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
                      Text('${t('suppliers.due_date')}: $dueDate',
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
            Expanded(
              child: Text(t('suppliers.supplier_info'), style: const TextStyle(fontSize: 17)),
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
                Text(t('suppliers.company_info'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                // Firma Adı
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: t('suppliers.company_name'),
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
                          labelText: t('suppliers.tax_number'),
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
                          labelText: t('suppliers.tax_office'),
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
                Text(t('suppliers.contact_info'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                // Yetkili Kişi
                TextField(
                  controller: contactNameCtrl,
                  decoration: InputDecoration(
                    labelText: t('suppliers.contact_person'),
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
                          labelText: t('suppliers.phone'),
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
                          labelText: t('suppliers.email'),
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
                    labelText: t('suppliers.address'),
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
                    labelText: t('suppliers.notes'),
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
            child: Text(t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                AppToast.error(context, t('suppliers.company_name_required'));
                return;
              }
              Navigator.pop(ctx);
              await _updateSupplierBasicInfo(
                name: nameCtrl.text.trim(),
                taxNumber: taxNumberCtrl.text.trim(),
                taxOffice: taxOfficeCtrl.text.trim(),
                contactName: contactNameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
              _loadAll();
            },
            child: Text(t('common.save')),
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog() {
    // Implementation for account settings edit dialog
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
      await ref.read(supplierServiceProvider).updateSupplier(
        widget.supplierId,
        {
          'name': name,
          'taxNumber': taxNumber,
          'taxOffice': taxOffice,
          'contactName': contactName,
          'phone': phone,
          'email': email,
          'address': address,
          'notes': notes,
        },
      );
      if (mounted) {
        AppToast.success(context, t('common.saved'));
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  Future<void> _showPaymentDialog() async {
    final supplierName = _supplier?['name']?.toString();
    final result = await PaymentRecordModal.show(
      context,
      isCustomer: false,
      accountName: supplierName,
    );
    if (result != null && mounted) {
      try {
        await ref.read(supplierServiceProvider).recordSupplierPayment(
          widget.supplierId,
          result,
        );
        AppToast.success(context, t('suppliers.payment_recorded'));
        _loadAll();
      } catch (e) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }
}