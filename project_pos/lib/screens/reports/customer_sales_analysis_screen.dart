import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';

class CustomerSalesAnalysisScreen extends ConsumerStatefulWidget {
  const CustomerSalesAnalysisScreen({super.key});

  @override
  ConsumerState<CustomerSalesAnalysisScreen> createState() =>
      _CustomerSalesAnalysisScreenState();
}

class _CustomerSalesAnalysisScreenState
    extends ConsumerState<CustomerSalesAnalysisScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _customers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(salesReportServiceProvider);
      final result = await service.getCustomerSalesAnalysis(
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
      );
      setState(() {
        _customers = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
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
      _loadData();
    }
  }

  String _formatCurrency(double v) {
    return '${v.toStringAsFixed(2)} TL';
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _formatApiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final d = DateTime.parse(dateStr);
      return _formatDate(d);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Musteri Satis Analizi',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range chip
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ActionChip(
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: _pickDateRange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_customers.length} musteri',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AppEmptyState.error(
                        description: _error!,
                        onAction: _loadData,
                      )
                    : _customers.isEmpty
                        ? AppEmptyState.noData(
                            title: 'Musteri Bulunamadi',
                            description: 'Musteri verisi bulunamadi',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _customers.length,
                              itemBuilder: (context, index) {
                                return _buildCustomerCard(_customers[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> item) {
    final customerId = item['customerId'];
    final customerName = item['customerName']?.toString() ?? '-';
    final customerType = item['customerType']?.toString() ?? '';
    final totalPurchases = (item['totalPurchases'] ?? 0).toString();
    final totalSpent = (item['totalSpent'] ?? 0).toDouble();
    final averageOrderValue = (item['averageOrderValue'] ?? 0).toDouble();
    final lastPurchaseDate = item['lastPurchaseDate']?.toString();
    final initial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';

    Color typeColor;
    String typeLabel;
    switch (customerType.toLowerCase()) {
      case 'vip':
        typeColor = AppColors.warning;
        typeLabel = 'VIP';
        break;
      case 'wholesale':
        typeColor = AppColors.purple;
        typeLabel = 'Toptan';
        break;
      case 'retail':
        typeColor = AppColors.info;
        typeLabel = 'Perakende';
        break;
      default:
        typeColor = AppColors.textMuted;
        typeLabel = customerType.isNotEmpty ? customerType : 'Standart';
    }

    return GestureDetector(
      onTap: () {
        if (customerId != null) {
          context.push('/customers/account/$customerId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle with initial
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Customer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoItem(
                          Icons.shopping_cart,
                          '$totalPurchases alis',
                          AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildInfoItem(
                          Icons.account_balance_wallet,
                          _formatCurrency(totalSpent),
                          AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildInfoItem(
                          Icons.analytics,
                          'Ort: ${_formatCurrency(averageOrderValue)}',
                          AppColors.info,
                        ),
                        const SizedBox(width: 16),
                        _buildInfoItem(
                          Icons.calendar_today,
                          _formatApiDate(lastPurchaseDate),
                          AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
