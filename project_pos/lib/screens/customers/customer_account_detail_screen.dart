import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import '../accounts/payment_record_modal.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class CustomerAccountDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerAccountDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerAccountDetailScreen> createState() =>
      _CustomerAccountDetailScreenState();
}

class _CustomerAccountDetailScreenState
    extends ConsumerState<CustomerAccountDetailScreen> {
  String Function(String) get t => i18nOf(ref);
  Map<String, dynamic>? _customer;
  Map<String, dynamic>? _account;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;
  String _txFilter = 'ALL'; // ALL | DEBIT | CREDIT

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
      final customerSvc = ref.read(customerServiceProvider);
      final accountSvc = ref.read(accountServiceProvider);
      final results = await Future.wait([
        customerSvc.getCustomerById(widget.customerId),
        accountSvc.getCustomerAccount(widget.customerId),
        accountSvc.getCustomerTransactions(widget.customerId),
      ]);
      setState(() {
        _customer = results[0] as Map<String, dynamic>?;
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
    if (_txFilter == 'ALL') return _transactions;
    if (_txFilter == 'DEBIT') {
      return _transactions
          .where((t) => (t['debitAmount'] ?? 0) > 0)
          .toList();
    }
    if (_txFilter == 'CREDIT') {
      return _transactions
          .where((t) => (t['creditAmount'] ?? 0) > 0)
          .toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        appBar: AppAppBar.standard(title: t('accounts.title')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _customer == null) {
      return AppScaffold(
        appBar: AppAppBar.standard(title: t('accounts.title')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_error ?? t('common.error'),
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              AppButton.primary(

                text: t('common.refresh'),

                onPressed: _loadAll,

              ),
            ],
          ),
        ),
      );
    }

    final customerName = _customer!['name']?.toString() ?? '-';
    final balance = _toDouble(_account?['currentBalance']);
    final totalDebt = _toDouble(_account?['totalDebt']);
    final totalCredit = _toDouble(_account?['totalCredit']);
    final overdueAmount = _toDouble(_account?['overdueAmount']);
    final creditLimit = _toDouble(_account?['creditLimit'] ?? _customer!['creditLimit']);
    final availableCredit = _toDouble(_account?['availableCreditLimit']);
    final isLimitExceeded = _account?['isCreditLimitExceeded'] == true;
    final txCount = _account?['totalTransactionCount'] ?? _transactions.length;

    return AppScaffold(
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: customerName,
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
                        'Toplam Borç', // TODO: i18n
                        totalDebt, AppColors.danger, Icons.arrow_upward)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard(
                        'Toplam Tahsilat', // TODO: i18n
                        totalCredit, AppColors.success, Icons.arrow_downward)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _summaryCard('Vadesi Geçmiş', // TODO: i18n
                        overdueAmount,
                        AppColors.warning, Icons.warning_amber)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard(t('customers.credit_limit'), creditLimit,
                        AppColors.info, Icons.credit_card)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _summaryCard('Kullanılabilir', // TODO: i18n
                        availableCredit,
                        isLimitExceeded ? AppColors.danger : AppColors.success,
                        Icons.account_balance_wallet)),
                const SizedBox(width: 10),
                Expanded(
                    child: _summaryCard('Hareket Sayısı', // TODO: i18n
                        txCount.toDouble(),
                        AppColors.primary, Icons.receipt_long,
                        isCount: true)),
              ],
            ),
            const SizedBox(height: 16),

            // Tahsilat Kaydet Butonu
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                text: t('accounts.payment'),
                icon: Icons.payments,
                size: ButtonSize.small,
                onPressed: () => _showPaymentDialog(),
              ),
            ),
            const SizedBox(height: 20),

            // Hareket Listesi Baslik
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t('accounts.transactions')} (${_filteredTransactions.length})',
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
                  {'key': 'ALL', 'label': t('common.all'), 'color': AppColors.primary},
                  {'key': 'DEBIT', 'label': 'Borç', 'color': AppColors.danger}, // TODO: i18n
                  {'key': 'CREDIT', 'label': 'Alacak', 'color': AppColors.success}, // TODO: i18n
                ].map((entry) {
                  final key = entry['key'] as String;
                  final label = entry['label'] as String;
                  final chipColor = entry['color'] as Color;
                  final selected = _txFilter == key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label, style: TextStyle(fontSize: 12,
                          color: selected ? Colors.white : AppColors.textPrimary)),
                      selected: selected,
                      selectedColor: chipColor,
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
                title: t('common.no_data'),
                description: t('common.no_records'),
              )
            else
              ..._filteredTransactions.map(_buildTransactionCard),
          ],
        ),
      ),
    );
  }

  // --- Bakiye Karti -------------------------------------------------------

  Widget _buildBalanceCard(double balance, bool isExceeded) {
    final isPositive = balance > 0;
    final balanceLabel = isPositive
        ? 'Borçlu' // TODO: i18n
        : balance < 0
            ? 'Alacaklı' // TODO: i18n
            : 'Hesap Kapalı'; // TODO: i18n

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
              Text(t('accounts.balance'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              if (isExceeded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LIMIT AŞILDI', // TODO: i18n
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

  // --- Ozet Karti ---------------------------------------------------------

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

  // --- Hareket Karti ------------------------------------------------------

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
                        child: const Text('VADESİ GEÇMİŞ', // TODO: i18n
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
                          color: AppColors.textMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('İPTAL', // TODO: i18n
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
                      Text('${t('accounts.overdue')}: $dueDate',
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

  // --- Tahsilat Dialog ----------------------------------------------------

  Future<void> _showPaymentDialog() async {
    final customerName = _customer?['name']?.toString();
    final result = await PaymentRecordModal.show(
      context,
      isCustomer: true,
      accountName: customerName,
    );
    if (result != null) {
      await _recordPayment(result);
    }
  }

  Future<void> _recordPayment(Map<String, dynamic> data) async {
    try {
      await ref.read(accountServiceProvider).recordCustomerPayment(
        widget.customerId,
        data,
      );
      if (mounted) {
        final amount = data['amount'] as double;
        AppToast.success(context, '${_formatCurrency(amount)} TL ${t('accounts.payment')}');
      }
      _loadAll();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  // --- Helpers ------------------------------------------------------------

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