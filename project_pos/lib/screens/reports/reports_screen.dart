import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/comprehensive_database.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _db = ComprehensiveDatabase.instance;
  late TabController _tabController;

  bool _isLoading = true;
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
    setState(() => _isLoading = true);

    await Future.wait([
      _loadSalesReport(),
      _loadCustomerReport(),
      _loadInventoryReport(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadSalesReport() async {
    final db = await _db.database;

    // Get sales within date range
    final sales = await db.query(
      'sales',
      where: 'saleDate BETWEEN ? AND ?',
      whereArgs: [
        _startDate.toIso8601String(),
        _endDate.toIso8601String(),
      ],
      orderBy: 'saleDate DESC',
    );

    double totalAmount = 0;
    for (final sale in sales) {
      totalAmount += sale['total'] as double;
    }

    setState(() {
      _sales = sales;
      _totalSalesAmount = totalAmount;
      _totalSalesCount = sales.length;
      _averageSaleAmount = sales.isEmpty ? 0 : totalAmount / sales.length;
    });
  }

  Future<void> _loadCustomerReport() async {
    final db = await _db.database;

    // Get top customers by total purchases
    final topCustomers = await db.rawQuery('''
      SELECT * FROM customers
      WHERE totalPurchases > 0
      ORDER BY totalPurchases DESC
      LIMIT 10
    ''');

    final allCustomers = await db.query('customers');
    final activeCustomers = await db.query(
      'customers',
      where: 'isActive = ?',
      whereArgs: [1],
    );

    setState(() {
      _topCustomers = topCustomers;
      _totalCustomers = allCustomers.length;
      _activeCustomers = activeCustomers.length;
    });
  }

  Future<void> _loadInventoryReport() async {
    final db = await _db.database;

    final allProducts = await db.query('products', where: 'isActive = ?', whereArgs: [1]);
    final lowStock = await db.rawQuery(
      'SELECT * FROM products WHERE stock <= minStock AND stock > 0',
    );
    final outOfStock = await db.query('products', where: 'stock = ?', whereArgs: [0]);

    double totalValue = 0;
    for (final product in allProducts) {
      final stock = product['stock'] as int;
      final price = product['sellingPrice'] as double;
      totalValue += stock * price;
    }

    setState(() {
      _totalProducts = allProducts.length;
      _lowStockProducts = lowStock.length;
      _outOfStockProducts = outOfStock.length;
      _totalInventoryValue = totalValue;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Raporlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Tarih Aralığı Seç',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              // TODO: Export report
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rapor dışa aktarma özelliği yakında...'),
                ),
              );
            },
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
          : Column(
              children: [
                // Date Range Display
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${_startDate.day}.${_startDate.month}.${_startDate.year} - ${_endDate.day}.${_endDate.month}.${_endDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

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

  Widget _buildSalesReport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Satış',
                _totalSalesCount.toString(),
                Icons.receipt_long,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Toplam Tutar',
                '₺${_totalSalesAmount.toStringAsFixed(0)}',
                Icons.attach_money,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ortalama',
                '₺${_averageSaleAmount.toStringAsFixed(0)}',
                Icons.analytics,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Bugün',
                _sales
                    .where((s) {
                      final saleDate = DateTime.parse(s['saleDate'] as String);
                      final today = DateTime.now();
                      return saleDate.year == today.year &&
                          saleDate.month == today.month &&
                          saleDate.day == today.day;
                    })
                    .length
                    .toString(),
                Icons.today,
                AppColors.info,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Recent Sales List
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Son Satışlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              if (_sales.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Satış kaydı yok')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sales.length > 10 ? 10 : _sales.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sale = _sales[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.bgSuccess,
                        child: const Icon(
                          Icons.receipt,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        sale['saleNumber'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateTime.parse(sale['saleDate'] as String)
                            .toString()
                            .substring(0, 16),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₺${(sale['total'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            sale['paymentMethod'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
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
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Müşteri',
                _totalCustomers.toString(),
                Icons.people,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Aktif',
                _activeCustomers.toString(),
                Icons.person_outline,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'VIP',
                _topCustomers
                    .where((c) => c['customerType'] == 'vip')
                    .length
                    .toString(),
                Icons.star,
                AppColors.warning,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Top Customers List
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'En İyi Müşteriler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              if (_topCustomers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Müşteri kaydı yok')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topCustomers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = _topCustomers[index];
                    final isVip = customer['customerType'] == 'vip';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isVip
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        child: isVip
                            ? const Icon(Icons.star, color: AppColors.warning)
                            : Text(
                                customer['name'].toString()[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      title: Text(
                        customer['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${customer['loyaltyPoints'] ?? 0} Puan',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₺${(customer['totalPurchases'] as double).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
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

  Widget _buildInventoryReport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam Ürün',
                _totalProducts.toString(),
                Icons.inventory_2,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Düşük Stok',
                _lowStockProducts.toString(),
                Icons.warning,
                AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tükenen',
                _outOfStockProducts.toString(),
                Icons.error,
                AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Toplam Değer',
                '₺${_totalInventoryValue.toStringAsFixed(0)}',
                Icons.attach_money,
                AppColors.success,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Inventory Summary Chart
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stok Durumu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: (_totalProducts - _lowStockProducts - _outOfStockProducts).toDouble(),
                        title: 'Normal',
                        color: AppColors.success,
                        radius: 80,
                      ),
                      PieChartSectionData(
                        value: _lowStockProducts.toDouble(),
                        title: 'Düşük',
                        color: AppColors.warning,
                        radius: 80,
                      ),
                      PieChartSectionData(
                        value: _outOfStockProducts.toDouble(),
                        title: 'Yok',
                        color: AppColors.danger,
                        radius: 80,
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
