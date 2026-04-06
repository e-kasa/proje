import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final String supplierId;
  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  Map<String, dynamic>? _supplier;
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;
  String? _error;

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
      final supplierSvc = ref.read(supplierServiceProvider);
      final purchaseSvc = ref.read(purchaseServiceProvider);
      final results = await Future.wait([
        supplierSvc.getSupplierById(widget.supplierId),
        purchaseSvc.getPurchases(supplierId: widget.supplierId),
      ]);
      setState(() {
        _supplier = results[0] as Map<String, dynamic>?;
        _purchases = (results[1] as List<Map<String, dynamic>>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppAppBar.standard(title: 'Tedarikci Detay'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _supplier == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppAppBar.standard(title: 'Tedarikci Detay'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(_error ?? 'Tedarikci bulunamadi',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              AppButton.primary(
                text: 'Tekrar Dene',
                onPressed: _loadAll,
              ),
            ],
          ),
        ),
      );
    }

    final s = _supplier!;
    final name = s['name']?.toString() ?? '-';
    final activePurchases =
        _purchases.where((p) => p['isCancelled'] != true).length;
    final totalSpent = _purchases.fold<double>(
        0, (sum, p) => sum + _toD(p['totalAmount']));

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        title: name,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
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
          padding: AppConstants.pagePadding,
          children: [
            _buildInfoCard(s),
            const SizedBox(height: 12),
            _buildStatsRow(activePurchases, totalSpent),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildPurchaseList(),
          ],
        ),
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────────────

  Widget _buildInfoCard(Map<String, dynamic> s) {
    final rows = <_InfoRow>[
      if (s['contactName'] != null)
        _InfoRow(Icons.person_outline, s['contactName']),
      if (s['phone'] != null) _InfoRow(Icons.phone_outlined, s['phone']),
      if (s['email'] != null) _InfoRow(Icons.email_outlined, s['email']),
      if (s['address'] != null)
        _InfoRow(Icons.location_on_outlined, s['address']),
      if (s['taxNumber'] != null)
        _InfoRow(Icons.numbers, 'VKN: ${s['taxNumber']}'),
      if (s['taxOffice'] != null)
        _InfoRow(Icons.account_balance, 'VD: ${s['taxOffice']}'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.business, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s['name']?.toString() ?? '-',
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

  // ── Stats Row ──────────────────────────────────────────────────────

  Widget _buildStatsRow(int activePurchases, double totalSpent) {
    return Row(children: [
      Expanded(
          child: _statCard('Toplam Alis', _purchases.length.toString(),
              AppColors.primary, Icons.receipt_long)),
      const SizedBox(width: 10),
      Expanded(
          child: _statCard('Aktif Alis', activePurchases.toString(),
              AppColors.success, Icons.check_circle_outline)),
      const SizedBox(width: 10),
      Expanded(
          child: _statCard('Toplam Tutar', _currencyFormat.format(totalSpent),
              AppColors.warning, Icons.attach_money)),
    ]);
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusSmall,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
    );
  }

  // ── Action Buttons ─────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: AppButton.primary(
          text: 'Cari Hesap',
          icon: Icons.account_balance_wallet,
          onPressed: () =>
              context.push('/suppliers/account/${widget.supplierId}'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: AppButton.success(
          text: 'Siparis Olustur',
          icon: Icons.add_shopping_cart,
          onPressed: () => context.push('/purchases/create'),
        ),
      ),
    ]);
  }

  // ── Purchase List ──────────────────────────────────────────────────

  Widget _buildPurchaseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Satin Alma Gecmisi (${_purchases.length})',
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_purchases.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(children: [
              Icon(Icons.receipt_long,
                  size: 48, color: AppColors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 12),
              const Text('Henuz satin alma kaydedilmemis',
                  style: TextStyle(color: AppColors.textMuted)),
            ]),
          )
        else
          ..._purchases.map(_buildPurchaseCard),
      ],
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> p) {
    final invoiceNo = p['invoiceNumber']?.toString() ?? '-';
    final total = _toD(p['totalAmount']);
    final isCancelled = p['isCancelled'] == true;
    final dateStr = p['purchaseDate']?.toString() ?? '';
    String displayDate = '';
    if (dateStr.length >= 10) displayDate = dateStr.substring(0, 10);

    return GestureDetector(
      onTap: () {
        final id = p['id']?.toString();
        if (id != null) context.push('/purchases/detail/$id');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCancelled ? AppColors.bgLight : Colors.white,
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCancelled
                  ? AppColors.textMuted.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(Icons.receipt,
                size: 20,
                color:
                    isCancelled ? AppColors.textMuted : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(invoiceNo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                        )),
                  ),
                  if (isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.15),
                        borderRadius: AppConstants.borderRadiusSmall,
                      ),
                      child: const Text('IPTAL',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger)),
                    ),
                ]),
                const SizedBox(height: 3),
                Text(displayDate,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_currencyFormat.format(total),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color:
                    isCancelled ? AppColors.textMuted : AppColors.textPrimary,
              )),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
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
