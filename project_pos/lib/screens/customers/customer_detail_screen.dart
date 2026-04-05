import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';
import '../accounts/payment_record_modal.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  Map<String, dynamic>? _customer;
  Map<String, dynamic>? _account;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;
  String _txFilter = 'Tumu';

  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');

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
    if (_txFilter == 'Tumu') return _transactions;
    if (_txFilter == 'Borc') {
      return _transactions.where((t) => (_toD(t['debitAmount'])) > 0).toList();
    }
    if (_txFilter == 'Alacak') {
      return _transactions
          .where((t) => (_toD(t['creditAmount'])) > 0)
          .toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(title: const Text('Musteri Detay')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _customer == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(title: const Text('Musteri Detay')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_error ?? 'Musteri bulunamadi',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _loadAll, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    final name = _customer!['name']?.toString() ?? '-';
    final balance = _toD(_account?['currentBalance']);
    final totalDebt = _toD(_account?['totalDebt']);
    final totalCredit = _toD(_account?['totalCredit']);

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
            Text(name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Text('Musteri Detay',
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
            _buildInfoCard(),
            const SizedBox(height: 12),
            _buildBalanceCard(balance),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _summaryTile(
                      'Toplam Borc', totalDebt, AppColors.danger,
                      Icons.arrow_upward)),
              const SizedBox(width: 10),
              Expanded(
                  child: _summaryTile(
                      'Toplam Odeme', totalCredit, AppColors.success,
                      Icons.arrow_downward)),
            ]),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildTransactionSection(),
          ],
        ),
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    final c = _customer!;
    final rows = <_InfoRow>[
      if (c['phone'] != null) _InfoRow(Icons.phone_outlined, c['phone']),
      if (c['email'] != null) _InfoRow(Icons.email_outlined, c['email']),
      if (c['address'] != null)
        _InfoRow(Icons.location_on_outlined, c['address']),
      if (c['taxNumber'] != null)
        _InfoRow(Icons.numbers, 'VKN: ${c['taxNumber']}'),
      if (c['taxOffice'] != null)
        _InfoRow(Icons.account_balance, 'VD: ${c['taxOffice']}'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                (c['name']?.toString() ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(c['name']?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(r.icon, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(r.value,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary))),
                ]),
              )),
        ],
      ),
    );
  }

  // ── Balance Card ───────────────────────────────────────────────────

  Widget _buildBalanceCard(double balance) {
    final isPositive = balance > 0;
    final label = isPositive
        ? 'Borcunuz Var'
        : balance < 0
            ? 'Alacaginiz Var'
            : 'Hesap Kapali';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Guncel Bakiye',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(_currencyFormat.format(balance.abs()),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child:
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ── Summary Tile ───────────────────────────────────────────────────

  Widget _summaryTile(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 10),
        Text(_currencyFormat.format(value),
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _showPaymentDialog,
          icon: const Icon(Icons.payment, color: Colors.white, size: 18),
          label: const Text('Odeme Kaydet',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () =>
              context.push('/customers/edit/${widget.customerId}'),
          icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
          label: const Text('Bilgileri Guncelle',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  // ── Transaction Section ────────────────────────────────────────────

  Widget _buildTransactionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hesap Hareketleri (${_filteredTransactions.length})',
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['Tumu', 'Borc', 'Alacak'].map((f) {
              final selected = _txFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              selected ? Colors.white : AppColors.textPrimary)),
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
        if (_filteredTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(children: [
              Icon(Icons.receipt_long,
                  size: 48, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 12),
              const Text('Henuz hareket kaydedilmemis',
                  style: TextStyle(color: AppColors.textMuted)),
            ]),
          )
        else
          ..._filteredTransactions.map(_buildTxCard),
      ],
    );
  }

  Widget _buildTxCard(Map<String, dynamic> tx) {
    final debit = _toD(tx['debitAmount']);
    final credit = _toD(tx['creditAmount']);
    final isDebit = debit > 0;
    final amount = isDebit ? debit : credit;
    final typeLabel =
        tx['transactionTypeLabel']?.toString() ??
        tx['transactionType']?.toString() ??
        '-';
    final refNumber = tx['referenceNumber']?.toString() ?? '';
    final txDate = tx['transactionDate']?.toString() ?? '';
    String displayDate = '';
    if (txDate.length >= 10) displayDate = txDate.substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDebit
                ? AppColors.danger.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
            color: isDebit ? AppColors.danger : AppColors.success,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(typeLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Row(children: [
                if (refNumber.isNotEmpty) ...[
                  Text(refNumber,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                ],
                Text(displayDate,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${isDebit ? '+' : '-'}${_currencyFormat.format(amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDebit ? AppColors.danger : AppColors.success,
          ),
        ),
      ]),
    );
  }

  // ── Payment Dialog ─────────────────────────────────────────────────

  Future<void> _showPaymentDialog() async {
    final customerName = _customer?['name']?.toString();
    final result = await PaymentRecordModal.show(
      context,
      isCustomer: true,
      accountName: customerName,
    );
    if (result != null) {
      try {
        await ref
            .read(accountServiceProvider)
            .recordCustomerPayment(widget.customerId, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Odeme kaydedildi'),
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
  }

  double _toD(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _InfoRow {
  final IconData icon;
  final String value;
  _InfoRow(this.icon, this.value);
}
