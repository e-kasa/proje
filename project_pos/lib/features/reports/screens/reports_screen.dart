import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/reports/di/reports_di.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  String Function(String) get t => i18nOf(ref);

  late TabController _tabController;

  bool get _isExporting => ref.watch(reportsDashboardProvider).isExporting;
  bool get _isLoading => ref.watch(reportsDashboardProvider).isLoading;
  String? get _error => ref.watch(reportsDashboardProvider).error;
  DateTime get _startDate => ref.watch(reportsDashboardProvider).startDate;
  DateTime get _endDate => ref.watch(reportsDashboardProvider).endDate;

  List<Map<String, dynamic>> get _sales =>
      ref.watch(reportsDashboardProvider).sales;
  double get _totalSalesAmount =>
      ref.watch(reportsDashboardProvider).totalSalesAmount;
  int get _totalSalesCount =>
      ref.watch(reportsDashboardProvider).totalSalesCount;
  double get _averageSaleAmount =>
      ref.watch(reportsDashboardProvider).averageSaleAmount;

  List<Map<String, dynamic>> get _topCustomers =>
      ref.watch(reportsDashboardProvider).topCustomers;
  int get _totalCustomers =>
      ref.watch(reportsDashboardProvider).totalCustomers;
  int get _activeCustomers =>
      ref.watch(reportsDashboardProvider).activeCustomers;

  int get _totalProducts => ref.watch(reportsDashboardProvider).totalProducts;
  int get _lowStockProducts =>
      ref.watch(reportsDashboardProvider).lowStockProducts;
  int get _outOfStockProducts =>
      ref.watch(reportsDashboardProvider).outOfStockProducts;
  double get _totalInventoryValue =>
      ref.watch(reportsDashboardProvider).totalInventoryValue;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadReportData() =>
      ref.read(reportsDashboardProvider.notifier).load();

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      ref
          .read(reportsDashboardProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _showExportDialog() async {
    final reportTypes = ['sales', 'inventory', 'customers'];
    final tabIndex = _tabController.index;
    final reportType = reportTypes[tabIndex];

    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('reports.export_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.danger),
              title: Text(t('reports.export_pdf')),
              shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusSmall),
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.success),
              title: Text(t('reports.export_excel')),
              shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusSmall),
              onTap: () => Navigator.of(ctx).pop('excel'),
            ),
          ],
        ),
        actions: [
          AppButton.outline(
            text: t('common.cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );

    if (format == null || !mounted) return;

    try {
      await ref
          .read(reportsDashboardProvider.notifier)
          .exportReport(reportType, format);
      if (!mounted) return;
      AppToast.success(context, t('reports.export_success'));
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, '${t('reports.export_error')}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('reports.title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: t('reports.date_range'),
          ),
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.file_download),
                  onPressed: _showExportDialog,
                  tooltip: t('reports.download'), // TODO: i18n key: reports.download
                ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('menu.sales'), icon: const Icon(Icons.shopping_cart)),
            Tab(text: t('reports.customers'), icon: const Icon(Icons.people)), // TODO: i18n key: reports.customers
            Tab(text: t('reports.inventory'), icon: const Icon(Icons.inventory_2)), // TODO: i18n key: reports.inventory
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppEmptyState.error(
                  description: t('common.error'),
                  onAction: _loadReportData,
                )
              : Column(
                  children: [
                    Container(
                      padding: AppConstants.pagePadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${_startDate.day}.${_startDate.month}.${_startDate.year} - ${_endDate.day}.${_endDate.month}.${_endDate.year}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    // ── Detaylı Rapor Kısayolları ─────────────────────────
                    _buildAdvancedReportLinks(),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSalesReport(),
                          _buildCustomerReport(),
                          _buildInventoryReport(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Detaylı Rapor Kısayolları ──────────────────────────────────────────────

  Widget _buildAdvancedReportLinks() {
    final links = [
      _ReportLink(t('reports.sales_summary'),    Icons.show_chart,          AppColors.info,      '/reports/sales-summary'),
      _ReportLink(t('reports.product_analysis'), Icons.bar_chart_rounded,   AppColors.success,   '/reports/product-analysis'),
      _ReportLink(t('reports.customer_analysis'),Icons.people_alt_outlined,  AppColors.secondary, '/reports/customer-analysis'),
      _ReportLink(t('reports.profit_overview'),  Icons.trending_up_rounded,  AppColors.teal,      '/reports/profit-overview'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  t('reports.detailed_analyses'), // TODO: i18n key: reports.detailed_analyses
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.textMuted, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          Row(
            children: links.map((l) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _advancedLinkCard(l),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _advancedLinkCard(_ReportLink link) {
    return InkWell(
      onTap: () => context.push(link.route),
      borderRadius: AppConstants.borderRadiusSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: link.color.withValues(alpha: 0.07),
          borderRadius: AppConstants.borderRadiusSmall,
          border: Border.all(color: link.color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(link.icon, color: link.color, size: 20),
            const SizedBox(height: 4),
            Text(
              link.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: link.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesReport() {
    return ListView(
      padding: AppConstants.pagePadding,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(t('reports.total_sales'), _totalSalesCount.toString(), Icons.receipt_long, AppColors.primary)), // TODO: i18n key: reports.total_sales
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(t('sales.total'), '₺${_totalSalesAmount.toStringAsFixed(0)}', Icons.attach_money, AppColors.success)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(t('reports.average'), '₺${_averageSaleAmount.toStringAsFixed(0)}', Icons.analytics, AppColors.warning)), // TODO: i18n key: reports.average
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                t('reports.today'), // TODO: i18n key: reports.today
                _sales.where((s) {
                  final d = DateTime.tryParse(s['saleDate']?.toString() ?? '');
                  if (d == null) return false;
                  final today = DateTime.now();
                  return d.year == today.year && d.month == today.month && d.day == today.day;
                }).length.toString(),
                Icons.today,
                AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(t('reports.recent_sales'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), // TODO: i18n key: reports.recent_sales
              const Divider(height: 1),
              if (_sales.isEmpty)
                AppEmptyState.noData(description: t('common.no_data'))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sales.length > 10 ? 10 : _sales.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sale = _sales[index];
                    final total = (sale['total'] as num?)?.toDouble() ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.bgSuccess,
                        child: const Icon(Icons.receipt, color: AppColors.success, size: 20),
                      ),
                      title: Text(sale['saleNumber']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        (sale['saleDate']?.toString() ?? '').length > 16
                            ? sale['saleDate'].toString().substring(0, 16)
                            : sale['saleDate']?.toString() ?? '-',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₺${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                          Text(sale['paymentMethod']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerReport() {
    return ListView(
      padding: AppConstants.pagePadding,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(t('reports.total_customers'), _totalCustomers.toString(), Icons.people, AppColors.primary)), // TODO: i18n key: reports.total_customers
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(t('common.active'), _activeCustomers.toString(), Icons.person_outline, AppColors.success)), // TODO: i18n key: common.active
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('VIP', _topCustomers.where((c) => c['customerType'] == 'vip').length.toString(), Icons.star, AppColors.warning)),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(t('reports.top_customers'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), // TODO: i18n key: reports.top_customers
              const Divider(height: 1),
              if (_topCustomers.isEmpty)
                AppEmptyState.noData(description: t('common.no_data'))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topCustomers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = _topCustomers[index];
                    final isVip = customer['customerType'] == 'vip';
                    final totalPurchases = (customer['totalPurchases'] as num?)?.toDouble() ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isVip ? AppColors.warning.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                        child: isVip
                            ? const Icon(Icons.star, color: AppColors.warning)
                            : Text(
                                (customer['name']?.toString() ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                      ),
                      title: Text(customer['name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${customer['loyaltyPoints'] ?? 0} Puan', style: const TextStyle(fontSize: 12)),
                      trailing: Text('₺${totalPurchases.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryReport() {
    return ListView(
      padding: AppConstants.pagePadding,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(t('reports.total_products'), _totalProducts.toString(), Icons.inventory_2, AppColors.primary)), // TODO: i18n key: reports.total_products
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(t('reports.low_stock'), _lowStockProducts.toString(), Icons.warning, AppColors.warning)), // TODO: i18n key: reports.low_stock
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(t('reports.out_of_stock'), _outOfStockProducts.toString(), Icons.error, AppColors.danger)), // TODO: i18n key: reports.out_of_stock
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(t('reports.total_value'), '₺${_totalInventoryValue.toStringAsFixed(0)}', Icons.attach_money, AppColors.success)), // TODO: i18n key: reports.total_value
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Padding(
            padding: AppConstants.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('reports.stock_status'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // TODO: i18n key: reports.stock_status
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(value: (_totalProducts - _lowStockProducts - _outOfStockProducts).toDouble(), title: t('reports.normal'), color: AppColors.success, radius: 80), // TODO: i18n key: reports.normal
                        PieChartSectionData(value: _lowStockProducts.toDouble(), title: t('reports.low'), color: AppColors.warning, radius: 80), // TODO: i18n key: reports.low
                        PieChartSectionData(value: _outOfStockProducts.toDouble(), title: t('reports.none'), color: AppColors.danger, radius: 80), // TODO: i18n key: reports.none
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return AppCard(
      child: Padding(
        padding: AppConstants.pagePadding,
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _ReportLink {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _ReportLink(this.label, this.icon, this.color, this.route);
}