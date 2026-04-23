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
  String _txFilter = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    var list = _transactions;
    if (_txFilter == 'debt') {
      list = list.where((tx) => (tx['debitAmount'] ?? 0) > 0).toList();
    } else if (_txFilter == 'credit') {
      list = list.where((tx) => (tx['creditAmount'] ?? 0) > 0).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((tx) {
        final type = (tx['transactionTypeLabel'] ?? tx['transactionType'] ?? '').toString().toLowerCase();
        final ref = (tx['referenceNumber'] ?? '').toString().toLowerCase();
        final desc = (tx['description'] ?? '').toString().toLowerCase();
        return type.contains(q) || ref.contains(q) || desc.contains(q);
      }).toList();
    }
    return list;
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
              AppButton.primary(text: t('common.retry'), onPressed: _loadAll),
            ],
          ),
        ),
      );
    }

    final supplierName   = _supplier!['name']?.toString() ?? '-';
    final balance        = _toDouble(_account?['currentBalance']);
    final totalDebt      = _toDouble(_account?['totalDebt']);
    final totalCredit    = _toDouble(_account?['totalCredit']);
    final overdueAmount  = _toDouble(_account?['overdueAmount']);
    final creditLimit    = _toDouble(_account?['creditLimit'] ?? _supplier!['creditLimit']);
    final availableCredit = _toDouble(_account?['availableCreditLimit']);
    final isLimitExceeded = _account?['isCreditLimitExceeded'] == true;
    final txCount        = (_account?['totalTransactionCount'] ?? _transactions.length) as num;
    final phone          = _supplier!['phone']?.toString() ?? '';
    final contactName    = _supplier!['contactName']?.toString() ?? '';

    final creditUsageRatio = creditLimit > 0 ? (totalDebt / creditLimit).clamp(0.0, 1.0) : 0.0;

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
            tooltip: t('common.refresh'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Bakiye Kartı ───────────────────────────────────────────
            _buildBalanceCard(balance, isLimitExceeded, creditUsageRatio, creditLimit),
            const SizedBox(height: 8),

            // ── İletişim Bandı ─────────────────────────────────────────
            if (phone.isNotEmpty || contactName.isNotEmpty)
              _buildContactStrip(contactName, phone),

            // ── Vadesi Geçmiş Uyarı ────────────────────────────────────
            if (overdueAmount > 0) ...[
              const SizedBox(height: 8),
              _buildOverdueBanner(overdueAmount),
            ],
            const SizedBox(height: 12),

            // ── Özet Kartlar (2×2) ─────────────────────────────────────
            Row(children: [
              Expanded(child: _summaryCard(t('suppliers.total_debt'),    totalDebt,    AppColors.danger,  Icons.arrow_upward)),
              const SizedBox(width: 10),
              Expanded(child: _summaryCard(t('suppliers.total_payment'), totalCredit,  AppColors.success, Icons.arrow_downward)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _summaryCard(t('suppliers.credit_limit'),    creditLimit,    AppColors.info,    Icons.credit_card)),
              const SizedBox(width: 10),
              Expanded(child: _summaryCard(t('suppliers.available_limit'), availableCredit,
                  isLimitExceeded ? AppColors.danger : AppColors.success,
                  Icons.account_balance_wallet)),
            ]),
            const SizedBox(height: 16),

            // ── Aksiyon Butonları ──────────────────────────────────────
            AppButton.success(
              text: t('suppliers.make_payment'),
              icon: Icons.payment,
              onPressed: _showPaymentDialog,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: AppButton.primary(
                text: t('suppliers.update_info'),
                icon: Icons.business_outlined,
                onPressed: _showEditSupplierInfoDialog,
              )),
              const SizedBox(width: 10),
              Expanded(child: AppButton.primary(
                text: t('suppliers.account_settings'),
                icon: Icons.tune_outlined,
                onPressed: _showEditAccountDialog,
              )),
            ]),
            const SizedBox(height: 20),

            // ── Hareket Listesi ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${t('suppliers.account_movements')} (${_filteredTransactions.length}/${txCount.toInt()})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Arama
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: t('common.search'),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Filtre Chipleri
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ('all',    t('common.all'),        AppColors.primary),
                  ('debt',   t('suppliers.debt'),    AppColors.danger),
                  ('credit', t('suppliers.credit'),  AppColors.success),
                ].map((entry) {
                  final (key, label, color) = entry;
                  final selected = _txFilter == key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              color: selected ? Colors.white : AppColors.textPrimary)),
                      selected: selected,
                      selectedColor: color,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: selected ? color : AppColors.border),
                      onSelected: (_) => setState(() => _txFilter = key),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // İşlem Listesi
            if (_filteredTransactions.isEmpty)
              AppEmptyState.noData(
                title: t('suppliers.no_movements'),
                description: t('suppliers.no_movements_description'),
              )
            else
              ..._filteredTransactions.map(
                (tx) => _buildTransactionCard(tx, onTap: () => _showTransactionDetail(tx)),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Bakiye Kartı ──────────────────────────────────────────────────────────

  Widget _buildBalanceCard(double balance, bool isExceeded, double usageRatio, double creditLimit) {
    final isPositive = balance > 0;
    final balanceLabel = isPositive
        ? t('suppliers.you_owe')
        : balance < 0
            ? t('suppliers.you_are_owed')
            : t('suppliers.account_closed');

    final gradientColors = isExceeded
        ? [const Color(0xFFE53935), const Color(0xFFC62828)]
        : [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors,
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5)),
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
                _badge(t('suppliers.limit_exceeded').toUpperCase(),
                    Colors.white.withValues(alpha: 0.25), Colors.white),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatCurrency(balance.abs())} TL',
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _badge(balanceLabel, Colors.white.withValues(alpha: 0.2), Colors.white),

          // Kredi kullanım çubuğu
          if (creditLimit > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t('suppliers.credit_usage'),
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text('%${(usageRatio * 100).toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usageRatio,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation<Color>(
                  usageRatio > 0.9 ? Colors.red.shade200 : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── İletişim Bandı ────────────────────────────────────────────────────────

  Widget _buildContactStrip(String contactName, String phone) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          if (contactName.isNotEmpty)
            Expanded(
              child: Text(contactName,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
          if (phone.isNotEmpty) ...[
            const Spacer(),
            const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(phone,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  // ─── Vadesi Geçmiş Banner ──────────────────────────────────────────────────

  Widget _buildOverdueBanner(double overdueAmount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${t('suppliers.overdue_alert')}: ${_formatCurrency(overdueAmount)} TL',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Özet Kart ─────────────────────────────────────────────────────────────

  Widget _summaryCard(String label, double value, Color color, IconData icon,
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            isCount ? '${value.toInt()}' : '${_formatCurrency(value)} TL',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ─── İşlem Kartı ───────────────────────────────────────────────────────────

  Widget _buildTransactionCard(Map<String, dynamic> tx, {VoidCallback? onTap}) {
    final debit  = _toDouble(tx['debitAmount']);
    final credit = _toDouble(tx['creditAmount']);
    final isDebit = debit > 0;
    final amount = isDebit ? debit : credit;
    final isCancelled = tx['isCancelled'] == true;
    final isOverdue   = tx['isOverdue'] == true;

    final typeLabel   = tx['transactionTypeLabel']?.toString() ?? tx['transactionType']?.toString() ?? '-';
    final refNumber   = tx['referenceNumber']?.toString() ?? '';
    final description = tx['description']?.toString() ?? '';
    final txDate      = tx['transactionDate']?.toString() ?? '';
    final dueDate     = tx['dueDate']?.toString() ?? '';
    final runBal      = tx['runningBalance'];

    final displayDate = txDate.length >= 10 ? txDate.substring(0, 10) : txDate;
    final displayDue  = dueDate.length >= 10 ? dueDate.substring(0, 10) : dueDate;

    final amountColor = isCancelled
        ? AppColors.textMuted
        : isDebit
            ? AppColors.danger
            : AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCancelled ? AppColors.bgLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCancelled
                ? AppColors.textMuted.withValues(alpha: 0.3)
                : isOverdue
                    ? AppColors.warning.withValues(alpha: 0.6)
                    : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // İkon
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
                color: isCancelled ? AppColors.textMuted : amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Detay
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(typeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isCancelled ? AppColors.textMuted : AppColors.textPrimary,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                          )),
                    ),
                    if (isOverdue && !isCancelled) ...[
                      const SizedBox(width: 6),
                      _badge(t('suppliers.overdue').toUpperCase(),
                          AppColors.warning.withValues(alpha: 0.15), AppColors.warning),
                    ],
                    if (isCancelled) ...[
                      const SizedBox(width: 6),
                      _badge(t('common.cancelled').toUpperCase(),
                          AppColors.textMuted.withValues(alpha: 0.15), AppColors.textMuted),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    if (refNumber.isNotEmpty) ...[
                      const Icon(Icons.tag, size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Text(refNumber,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(displayDate,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    if (displayDue.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('→ $displayDue',
                          style: TextStyle(
                              fontSize: 10,
                              color: isOverdue ? AppColors.warning : AppColors.textMuted)),
                    ],
                  ]),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),

            // Tutar + Bakiye
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDebit ? '+' : '-'}${_formatCurrency(amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (runBal != null)
                  Text(
                    '${_formatCurrency(_toDouble(runBal))} TL',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── İşlem Detay Bottom Sheet ──────────────────────────────────────────────

  void _showTransactionDetail(Map<String, dynamic> tx) {
    final debit  = _toDouble(tx['debitAmount']);
    final credit = _toDouble(tx['creditAmount']);
    final isDebit = debit > 0;
    final amount = isDebit ? debit : credit;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                tx['transactionTypeLabel']?.toString() ?? tx['transactionType']?.toString() ?? '-',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ]),
            const Divider(),
            _detailRow(Icons.monetization_on_outlined,
                isDebit ? t('suppliers.debt') : t('suppliers.credit'),
                '${_formatCurrency(amount)} TL',
                isDebit ? AppColors.danger : AppColors.success),
            if (tx['referenceNumber'] != null)
              _detailRow(Icons.tag, t('common.reference'), tx['referenceNumber'].toString(), AppColors.textPrimary),
            if (tx['transactionDate'] != null)
              _detailRow(Icons.calendar_today_outlined, t('common.date'), tx['transactionDate'].toString().substring(0, 10), AppColors.textPrimary),
            if (tx['dueDate'] != null)
              _detailRow(Icons.event_outlined, t('suppliers.due_date'), tx['dueDate'].toString(), AppColors.textPrimary),
            if (tx['description'] != null && tx['description'].toString().isNotEmpty)
              _detailRow(Icons.notes_outlined, t('common.description'), tx['description'].toString(), AppColors.textPrimary),
            if (tx['runningBalance'] != null)
              _detailRow(Icons.account_balance_wallet_outlined, t('suppliers.running_balance'),
                  '${_formatCurrency(_toDouble(tx['runningBalance']))} TL', AppColors.info),
            if (tx['isCancelled'] == true)
              _detailRow(Icons.cancel_outlined, t('common.status'), t('common.cancelled'), AppColors.textMuted),
            if (tx['isOverdue'] == true)
              _detailRow(Icons.warning_amber_outlined, t('common.status'), t('suppliers.overdue'), AppColors.warning),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text('$label:', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ─── Tedarikçi Bilgileri Dialog ────────────────────────────────────────────

  void _showEditSupplierInfoDialog() {
    final nameCtrl        = TextEditingController(text: _supplier?['name']?.toString() ?? '');
    final taxNumberCtrl   = TextEditingController(text: _supplier?['taxNumber']?.toString() ?? '');
    final taxOfficeCtrl   = TextEditingController(text: _supplier?['taxOffice']?.toString() ?? '');
    final contactNameCtrl = TextEditingController(text: _supplier?['contactName']?.toString() ?? '');
    final phoneCtrl       = TextEditingController(text: _supplier?['phone']?.toString() ?? '');
    final emailCtrl       = TextEditingController(text: _supplier?['email']?.toString() ?? '');
    final addressCtrl     = TextEditingController(text: _supplier?['address']?.toString() ?? '');
    final notesCtrl       = TextEditingController(text: _supplier?['notes']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.business_outlined, color: AppColors.info, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(t('suppliers.supplier_info'),
              style: const TextStyle(fontSize: 17))),
        ]),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(t('suppliers.company_info')),
                const SizedBox(height: 10),
                _dialogField(nameCtrl, t('suppliers.company_name'), Icons.business),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dialogField(taxNumberCtrl, t('suppliers.tax_number'), Icons.numbers,
                      keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _dialogField(taxOfficeCtrl, t('suppliers.tax_office'), Icons.account_balance)),
                ]),
                const SizedBox(height: 16),
                _sectionLabel(t('suppliers.contact_info')),
                const SizedBox(height: 10),
                _dialogField(contactNameCtrl, t('suppliers.contact_person'), Icons.person_outline),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dialogField(phoneCtrl, t('suppliers.phone'), Icons.phone_outlined,
                      keyboardType: TextInputType.phone)),
                  const SizedBox(width: 10),
                  Expanded(child: _dialogField(emailCtrl, t('suppliers.email'), Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress)),
                ]),
                const SizedBox(height: 12),
                _dialogField(addressCtrl, t('suppliers.address'), Icons.location_on_outlined, maxLines: 2),
                const SizedBox(height: 12),
                _dialogField(notesCtrl, t('suppliers.notes'), Icons.notes_outlined, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                AppToast.error(context, t('suppliers.company_name_required'));
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
              _loadAll();
            },
            child: Text(t('common.save')),
          ),
        ],
      ),
    );
  }

  // ─── Hesap Ayarları Dialog ─────────────────────────────────────────────────

  void _showEditAccountDialog() {
    final currentLimit = _toDouble(_account?['creditLimit'] ?? _supplier?['creditLimit']);
    final currentTermDays = _supplier?['paymentTermDays']?.toString() ?? '';

    final limitCtrl    = TextEditingController(text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');
    final termDaysCtrl = TextEditingController(text: currentTermDays);
    final notesCtrl    = TextEditingController(text: _account?['notes']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.tune_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(t('suppliers.account_settings'),
              style: const TextStyle(fontSize: 17))),
        ]),
        content: SizedBox(
          width: MediaQuery.of(ctx).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(t('suppliers.credit_settings')),
                const SizedBox(height: 10),
                _dialogField(limitCtrl, t('suppliers.credit_limit'), Icons.credit_card,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    suffix: 'TL'),
                const SizedBox(height: 12),
                _dialogField(termDaysCtrl, t('suppliers.payment_term_days'), Icons.event_repeat_outlined,
                    keyboardType: TextInputType.number,
                    suffix: t('common.days')),
                const SizedBox(height: 16),
                _sectionLabel(t('common.notes')),
                const SizedBox(height: 10),
                _dialogField(notesCtrl, t('suppliers.account_notes'), Icons.notes_outlined, maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('common.cancel'))),
          ElevatedButton(
            onPressed: () async {
              final limitVal = double.tryParse(limitCtrl.text.trim().replaceAll(',', '.'));
              final termDays = int.tryParse(termDaysCtrl.text.trim());
              Navigator.pop(ctx);
              await _updateAccountSettings(
                creditLimit: limitVal,
                paymentTermDays: termDays,
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

  // ─── API Çağrıları ─────────────────────────────────────────────────────────

  Future<void> _updateSupplierBasicInfo({
    required String name, required String taxNumber, required String taxOffice,
    required String contactName, required String phone, required String email,
    required String address, required String notes,
  }) async {
    try {
      await ref.read(supplierServiceProvider).updateSupplier(widget.supplierId, {
        'name': name, 'taxNumber': taxNumber, 'taxOffice': taxOffice,
        'contactName': contactName, 'phone': phone, 'email': email,
        'address': address, 'notes': notes,
      });
      if (mounted) AppToast.success(context, t('common.saved'));
    } catch (e) {
      if (mounted) AppToast.error(context, '${t('common.error')}: $e');
    }
  }

  Future<void> _updateAccountSettings({
    double? creditLimit, int? paymentTermDays, required String notes,
  }) async {
    try {
      final svc = ref.read(supplierServiceProvider);
      if (creditLimit != null) {
        await svc.updateCreditLimit(widget.supplierId, creditLimit);
      }
      if (mounted) AppToast.success(context, t('common.saved'));
    } catch (e) {
      if (mounted) AppToast.error(context, '${t('common.error')}: $e');
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
        await ref.read(supplierServiceProvider).recordSupplierPayment(widget.supplierId, result);
        if (mounted) AppToast.success(context, t('suppliers.payment_recorded'));
        _loadAll();
      } catch (e) {
        if (mounted) AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  // ─── Yardımcı Widget'lar ───────────────────────────────────────────────────

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, String? suffix}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixText: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  // ─── Veri Dönüşüm ─────────────────────────────────────────────────────────

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _formatCurrency(double value) {
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()},${decPart}';
  }
}
