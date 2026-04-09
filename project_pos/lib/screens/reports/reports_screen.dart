import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_constants.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExporting = false;

  bool _isLoading = true;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Sales Data
  List<Map<String, dynamic>> _sales = [];
  double _totalSalesAmount = 0;
  int _totalSalesCount = 0;
  double _averageSaleAmount = 0;

  // Customer Data
  List<Map<String, dynamic>> _topCustomers = [];
  int _totalCustomers = 0;
  int _activeCustomers = 0;

  // Inventory Data
  int _totalProducts = 0;
  int _lowStockProducts = 0;
  int _outOfStockProducts = 0;
  double _totalInventoryValue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await Future.wait([
        _loadSalesReport(),
        _loadCustomerReport(),
        _loadInventoryReport(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSalesReport() async {
    try {
      final service = ref.read(reportServiceProvider);
      final data = await service.getSalesReport(
        startDate: _startDate,
        endDate: _endDate,
      );

      final salesList = (data['sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      double totalAmount = 0;
      for (final sale in salesList) {
        totalAmount += (sale['total'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          _sales = salesList;
          _totalSalesAmount = totalAmount;
          _totalSalesCount = salesList.length;
          _averageSaleAmount = salesList.isEmpty ? 0 : totalAmount / salesList.length;
        });
      }
    } catch (e) {
      debugPrint('Sales report error: $e');
    }
  }

  Future<void> _loadCustomerReport() async {
    try {
      final service = ref.read(reportServiceProvider);
      final data = await service.getCustomerReport(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _topCustomers = (data['topCustomers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _totalCustomers = (data['totalCustomers'] as num?)?.toInt() ?? 0;
          _activeCustomers = (data['activeCustomers'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Customer report error: $e');
    }
  }

  Future<void> _loadInventoryReport() async {
    try {
      final service = ref.read(reportServiceProvider);
      final data = await service.getInventoryReport();

      if (mounted) {
        setState(() {
          _totalProducts = (data['totalProducts'] as num?)?.toInt() ?? 0;
          _lowStockProducts = (data['lowStockProducts'] as num?)?.toInt() ?? 0;
          _outOfStockProducts = (data['outOfStockProducts'] as num?)?.toInt() ?? 0;
          _totalInventoryValue = (data['totalInventoryValue'] as num?)?.toDouble() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Inventory report error: $e');
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportData();
    }
  }

  Future<void> _showExportDialog() async {
    final reportTypes = ['sales', 'inventory', 'customers'];
    final tabIndex = _tabController.index;
    final reportType = reportTypes[tabIndex];

    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rapor Dışa Aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.danger),
              title: const Text('PDF olarak dışa aktar'),
              shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusSmall),
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.success),
              title: const Text('Excel olarak dışa aktar'),
              shape: RoundedRectangleBorder(borderRadius: AppConstants.borderRadiusSmall),
              onTap: () => Navigator.of(ctx).pop('excel'),
            ),
          ],
        ),
        actions: [
          AppButton.outline(
            text: 'İptal',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );

    if (format == null || !mounted) return;

    setState(() => _isExporting = true);
    try {
      final service = ref.read(reportServiceProvider);
      await service.exportReport(
        reportType: reportType,
        format: format,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      AppToast.success(context, 'Rapor dışa aktarıldı');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Dışa aktarma hatası: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.standard(
        title: 'Raporlar',
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Tarih Aralığı Seç',
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
                  tooltip: 'Raporu İndir',
                ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Satışlar', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Müşteriler', icon: Icon(Icons.people)),
            Tab(text: 'Envanter', icon: Icon(Icons.inventory_2)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppEmptyState.error(
                  description: 'Veri yüklenemedi',
                  onAction: _loadReportData,
                )
              : Column(
                  children: [
                    Container(
                      padding: AppConstants.pagePadding,
                      color: Colors.white,
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
      _ReportLink('Satış Özeti',    Icons.show_chart,          Colors.blue,       '/reports/sales-summary'),
      _ReportLink('Ürün Analizi',   Icons.bar_chart_rounded,   Colors.green,      '/reports/product-analysis'),
      _ReportLink('Müşteri Analizi',Icons.people_alt_outlined,  Colors.purple,     '/reports/customer-analysis'),
      _ReportLink('Kar Analizi',    Icons.trending_up_rounded,  Colors.teal,       '/reports/profit-overview'),
    ];

    return Container(
      color: Colors.white,
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
                const Text(
                  'Detaylı Analizler',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
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
          color: link.color.withOpacity(0.07),
          borderRadius: AppConstants.borderRadiusSmall,
          border: Border.all(color: link.color.withOpacity(0.18)),
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
            Expanded(child: _buildStatCard('Toplam Satış', _totalSalesCount.toString(), Icons.receipt_long, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Toplam Tutar', '₺${_totalSalesAmount.toStringAsFixed(0)}', Icons.attach_money, AppColors.success)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Ortalama', '₺${_averageSaleAmount.toStringAsFixed(0)}', Icons.analytics, AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Bugün',
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
              const Padding(padding: EdgeInsets.all(16), child: Text('Son Satışlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              const Divider(height: 1),
              if (_sales.isEmpty)
                AppEmptyState.noData(description: 'Satış kaydı yok')
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
            Expanded(child: _buildStatCard('Toplam Müşteri', _totalCustomers.toString(), Icons.people, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Aktif', _activeCustomers.toString(), Icons.person_outline, AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('VIP', _topCustomers.where((c) => c['customerType'] == 'vip').length.toString(), Icons.star, AppColors.warning)),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.all(16), child: Text('En İyi Müşteriler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              const Divider(height: 1),
              if (_topCustomers.isEmpty)
                AppEmptyState.noData(description: 'Müşteri kaydı yok')
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
            Expanded(child: _buildStatCard('Toplam Ürün', _totalProducts.toString(), Icons.inventory_2, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Düşük Stok', _lowStockProducts.toString(), Icons.warning, AppColors.warning)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Tükenen', _outOfStockProducts.toString(), Icons.error, AppColors.danger)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Toplam Değer', '₺${_totalInventoryValue.toStringAsFixed(0)}', Icons.attach_money, AppColors.success)),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Padding(
            padding: AppConstants.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stok Durumu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(value: (_totalProducts - _lowStockProducts - _outOfStockProducts).toDouble(), title: 'Normal', color: AppColors.success, radius: 80),
                        PieChartSectionData(value: _lowStockProducts.toDouble(), title: 'Düşük', color: AppColors.warning, radius: 80),
                        PieChartSectionData(value: _outOfStockProducts.toDouble(), title: 'Yok', color: AppColors.danger, radius: 80),
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
