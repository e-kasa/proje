import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';

class OverdueTrackingScreen extends ConsumerStatefulWidget {
  const OverdueTrackingScreen({super.key});

  @override
  ConsumerState<OverdueTrackingScreen> createState() =>
      _OverdueTrackingScreenState();
}

class _OverdueTrackingScreenState extends ConsumerState<OverdueTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _customerOverdue = [];
  List<Map<String, dynamic>> _supplierOverdue = [];
  bool _loadingCustomer = true;
  bool _loadingSupplier = true;
  String? _errorCustomer;
  String? _errorSupplier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomerOverdue();
    _loadSupplierOverdue();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerOverdue() async {
    setState(() {
      _loadingCustomer = true;
      _errorCustomer = null;
    });
    try {
      final accountService = ref.read(accountServiceProvider);
      final data =
          await accountService.getOverdueAccounts(accountType: 'CUSTOMER');
      data.sort((a, b) {
        final dateA = a['dueDate']?.toString() ?? '';
        final dateB = b['dueDate']?.toString() ?? '';
        return dateA.compareTo(dateB);
      });
      setState(() {
        _customerOverdue = data;
        _loadingCustomer = false;
      });
    } catch (e) {
      setState(() {
        _errorCustomer = e.toString();
        _loadingCustomer = false;
      });
    }
  }

  Future<void> _loadSupplierOverdue() async {
    setState(() {
      _loadingSupplier = true;
      _errorSupplier = null;
    });
    try {
      final accountService = ref.read(accountServiceProvider);
      final data =
          await accountService.getOverdueAccounts(accountType: 'SUPPLIER');
      data.sort((a, b) {
        final dateA = a['dueDate']?.toString() ?? '';
        final dateB = b['dueDate']?.toString() ?? '';
        return dateA.compareTo(dateB);
      });
      setState(() {
        _supplierOverdue = data;
        _loadingSupplier = false;
      });
    } catch (e) {
      setState(() {
        _errorSupplier = e.toString();
        _loadingSupplier = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.gradient(
        title: 'Vadesi Gecmis Hesaplar',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Musteriler'),
            Tab(text: 'Tedarikciler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(
            items: _customerOverdue,
            loading: _loadingCustomer,
            error: _errorCustomer,
            onRefresh: _loadCustomerOverdue,
            isCustomer: true,
          ),
          _buildTab(
            items: _supplierOverdue,
            loading: _loadingSupplier,
            error: _errorSupplier,
            onRefresh: _loadSupplierOverdue,
            isCustomer: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required List<Map<String, dynamic>> items,
    required bool loading,
    required String? error,
    required Future<void> Function() onRefresh,
    required bool isCustomer,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return AppEmptyState.error(
        title: 'Veri yuklenirken hata olustu',
        description: error,
        actionText: 'Tekrar Dene',
        onAction: onRefresh,
      );
    }
    if (items.isEmpty) {
      return AppEmptyState.noData(
        title: isCustomer
            ? 'Vadesi gecmis musteri hesabi yok'
            : 'Vadesi gecmis tedarikci hesabi yok',
        description: 'Tum hesaplar guncel durumda',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            _overdueItemCard(items[index], isCustomer),
      ),
    );
  }

  Widget _overdueItemCard(Map<String, dynamic> item, bool isCustomer) {
    final accountName = item['accountName']?.toString() ?? '-';
    final debitAmount = (item['debitAmount'] ?? 0).toDouble();
    final dueDate = item['dueDate']?.toString() ?? '-';
    final referenceNumber = item['referenceNumber']?.toString() ?? '';
    final accountType = item['accountType']?.toString() ?? '';
    final accountId = item['accountId']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        context.push('/accounts/statement', extra: {
          'accountType': accountType,
          'accountId': accountId,
          'accountName': accountName,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  (isCustomer ? AppColors.info : AppColors.orange)
                      .withOpacity(0.1),
              child: Icon(
                isCustomer ? Icons.person : Icons.business,
                color: isCustomer ? AppColors.info : AppColors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 13, color: AppColors.danger),
                      const SizedBox(width: 4),
                      Text(
                        dueDate.length >= 10
                            ? dueDate.substring(0, 10)
                            : dueDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (referenceNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.tag, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          referenceNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(debitAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
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
