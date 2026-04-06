import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import 'payment_record_modal.dart';

class AccountSummaryDashboardScreen extends ConsumerStatefulWidget {
  const AccountSummaryDashboardScreen({super.key});

  @override
  ConsumerState<AccountSummaryDashboardScreen> createState() =>
      _AccountSummaryDashboardScreenState();
}

class _AccountSummaryDashboardScreenState
    extends ConsumerState<AccountSummaryDashboardScreen> {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _overdueList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accountService = ref.read(accountServiceProvider);
      final results = await Future.wait([
        accountService.getAccountSummary(),
        accountService.getOverdueAccounts(),
      ]);
      setState(() {
        _summary = results[0] as Map<String, dynamic>?;
        _overdueList = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.gradient(
        title: 'Cari Hesap Ozeti',
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text('Veri yuklenirken hata olustu',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_error ?? '', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          AppButton.primary(
                        text: 'Tekrar Dene',
                        icon: Icons.refresh,
                        onPressed: _loadData,
                      ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCards(),
        const SizedBox(height: 20),
        _buildQuickActions(),
        const SizedBox(height: 20),
        _buildOverdueSection(),
      ],
    );
  }

  Widget _buildStatCards() {
    final totalReceivable =
        (_summary?['totalCustomerReceivable'] ?? 0).toDouble();
    final totalPayable =
        (_summary?['totalSupplierPayable'] ?? 0).toDouble();
    final overdueAmount =
        (_summary?['totalOverdueAmount'] ?? 0).toDouble();
    final totalTransactions =
        (_summary?['totalTransactionCount'] ?? 0);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(
          'Toplam Musteri Alacagi',
          _formatCurrency(totalReceivable),
          Icons.people_alt,
          AppColors.primary,
          AppColors.indigo,
        ),
        _statCard(
          'Toplam Tedarikci Borcu',
          _formatCurrency(totalPayable),
          Icons.business,
          AppColors.orange,
          AppColors.pink,
        ),
        _statCard(
          'Vadesi Gecmis Tutar',
          _formatCurrency(overdueAmount),
          Icons.warning_amber_rounded,
          AppColors.danger,
          AppColors.orange,
        ),
        _statCard(
          'Toplam Hareket',
          totalTransactions.toString(),
          Icons.swap_horiz,
          AppColors.teal,
          AppColors.cyan,
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color startColor,
    Color endColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickActionButton(
            icon: Icons.receipt_long,
            label: 'Ekstre Goruntule',
            color: AppColors.primary,
            onTap: () async {
              final result = await AccountSelectDialog.show(
                context,
                loadCustomers: () =>
                    ref.read(customerServiceProvider).getCustomers(),
                loadSuppliers: () =>
                    ref.read(supplierServiceProvider).getSuppliers(),
              );
              if (result != null && mounted) {
                context.push('/accounts/statement', extra: result);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionButton(
            icon: Icons.schedule,
            label: 'Vadesi Gecmis',
            color: AppColors.danger,
            onTap: () => context.push('/accounts/overdue'),
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueSection() {
    final top5 = _overdueList.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vadesi Gecmis Hesaplar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (_overdueList.length > 5)
              TextButton(
                onPressed: () => context.push('/accounts/overdue'),
                child: const Text('Tumunu Gor'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (top5.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 40, color: AppColors.success),
                const SizedBox(height: 8),
                Text(
                  'Vadesi gecmis hesap bulunmuyor',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else
          ...top5.map((item) => _overdueCard(item)),
      ],
    );
  }

  Widget _overdueCard(Map<String, dynamic> item) {
    final accountName = item['accountName']?.toString() ?? '-';
    final accountType = item['accountType']?.toString() ?? '';
    final isCustomer = accountType == 'CUSTOMER';
    final amount = (item['debitAmount'] ?? 0).toDouble();
    final dueDate = item['dueDate']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                (isCustomer ? AppColors.info : AppColors.orange)
                    .withOpacity(0.1),
            child: Icon(
              isCustomer ? Icons.person : Icons.business,
              color: isCustomer ? AppColors.info : AppColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isCustomer
                                ? AppColors.info
                                : AppColors.orange)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCustomer ? 'MUSTERI' : 'TEDARIKCI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isCustomer
                              ? AppColors.info
                              : AppColors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_today,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      dueDate.length >= 10 ? dueDate.substring(0, 10) : dueDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted TL';
  }
}
