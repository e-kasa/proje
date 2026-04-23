import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/features/accounts/models/statement_args.dart';
import 'package:project_pos/core/utils/formatters.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class OverdueTrackingScreen extends ConsumerStatefulWidget {
  const OverdueTrackingScreen({super.key});

  @override
  ConsumerState<OverdueTrackingScreen> createState() =>
      _OverdueTrackingScreenState();
}

class _OverdueTrackingScreenState extends ConsumerState<OverdueTrackingScreen>
    with SingleTickerProviderStateMixin {
  String Function(String) get t => i18nOf(ref);
  late TabController _tabController;

  List<Map<String, dynamic>> get _customerOverdue =>
      ref.watch(overdueTrackingProvider).customerOverdue;
  List<Map<String, dynamic>> get _supplierOverdue =>
      ref.watch(overdueTrackingProvider).supplierOverdue;
  bool get _loadingCustomer => ref.watch(overdueTrackingProvider).loadingCustomer;
  bool get _loadingSupplier => ref.watch(overdueTrackingProvider).loadingSupplier;
  String? get _errorCustomer => ref.watch(overdueTrackingProvider).errorCustomer;
  String? get _errorSupplier => ref.watch(overdueTrackingProvider).errorSupplier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerOverdue() =>
      ref.read(overdueTrackingProvider.notifier).loadCustomerOverdue();

  Future<void> _loadSupplierOverdue() =>
      ref.read(overdueTrackingProvider.notifier).loadSupplierOverdue();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.gradient(
        title: t('accounts.overdue'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: t('menu.customers')),
            Tab(text: 'Tedarikçiler'), // TODO: i18n menu.suppliers
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
        title: t('common.error'),
        description: error,
        actionText: t('common.refresh'),
        onAction: onRefresh,
      );
    }
    if (items.isEmpty) {
      return AppEmptyState.noData(
        title: t('accounts.overdue'),
        description: t('common.no_data'),
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
        context.push(
          '/accounts/statement',
          extra: StatementArgs(
            accountType: accountType,
            accountId: accountId,
            accountName: accountName,
          ),
        );
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
              color: Colors.black.withValues(alpha: 0.04),
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
                      .withValues(alpha: 0.1),
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
                        shortDateString(dueDate),
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
                  appCurrencyFmt.format(debitAmount),
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
}