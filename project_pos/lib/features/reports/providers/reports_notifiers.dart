import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/reports/services/report_service.dart';
import 'package:project_pos/features/sales/services/sales_report_service.dart';
import 'package:project_pos/services/finance_service.dart';
import 'package:project_pos/services/sales_service.dart';

const _sentinel = Object();

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ─── Reports Dashboard ──────────────────────────────────────────────────────

class ReportsDashboardState {
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;
  final bool isExporting;
  final String? error;

  final List<Map<String, dynamic>> sales;
  final double totalSalesAmount;
  final int totalSalesCount;
  final double averageSaleAmount;

  final List<Map<String, dynamic>> topCustomers;
  final int totalCustomers;
  final int activeCustomers;

  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double totalInventoryValue;

  const ReportsDashboardState({
    required this.startDate,
    required this.endDate,
    this.isLoading = true,
    this.isExporting = false,
    this.error,
    this.sales = const [],
    this.totalSalesAmount = 0,
    this.totalSalesCount = 0,
    this.averageSaleAmount = 0,
    this.topCustomers = const [],
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.totalProducts = 0,
    this.lowStockProducts = 0,
    this.outOfStockProducts = 0,
    this.totalInventoryValue = 0,
  });

  ReportsDashboardState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    bool? isExporting,
    Object? error = _sentinel,
    List<Map<String, dynamic>>? sales,
    double? totalSalesAmount,
    int? totalSalesCount,
    double? averageSaleAmount,
    List<Map<String, dynamic>>? topCustomers,
    int? totalCustomers,
    int? activeCustomers,
    int? totalProducts,
    int? lowStockProducts,
    int? outOfStockProducts,
    double? totalInventoryValue,
  }) {
    return ReportsDashboardState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      error: error == _sentinel ? this.error : error as String?,
      sales: sales ?? this.sales,
      totalSalesAmount: totalSalesAmount ?? this.totalSalesAmount,
      totalSalesCount: totalSalesCount ?? this.totalSalesCount,
      averageSaleAmount: averageSaleAmount ?? this.averageSaleAmount,
      topCustomers: topCustomers ?? this.topCustomers,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      totalProducts: totalProducts ?? this.totalProducts,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      outOfStockProducts: outOfStockProducts ?? this.outOfStockProducts,
      totalInventoryValue: totalInventoryValue ?? this.totalInventoryValue,
    );
  }
}

class ReportsDashboardNotifier extends StateNotifier<ReportsDashboardState> {
  final ReportService _service;

  ReportsDashboardNotifier(this._service)
      : super(ReportsDashboardState(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ));

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _loadSales(),
        _loadCustomers(),
        _loadInventory(),
      ]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadSales() async {
    try {
      final data = await _service.getSalesReport(
        startDate: state.startDate,
        endDate: state.endDate,
      );
      final salesList =
          (data['sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      double totalAmount = 0;
      for (final sale in salesList) {
        totalAmount += (sale['total'] as num?)?.toDouble() ?? 0;
      }
      state = state.copyWith(
        sales: salesList,
        totalSalesAmount: totalAmount,
        totalSalesCount: salesList.length,
        averageSaleAmount:
            salesList.isEmpty ? 0 : totalAmount / salesList.length,
      );
    } catch (_) {}
  }

  Future<void> _loadCustomers() async {
    try {
      final data = await _service.getCustomerReport(
        startDate: state.startDate,
        endDate: state.endDate,
      );
      state = state.copyWith(
        topCustomers:
            (data['topCustomers'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        totalCustomers: (data['totalCustomers'] as num?)?.toInt() ?? 0,
        activeCustomers: (data['activeCustomers'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {}
  }

  Future<void> _loadInventory() async {
    try {
      final data = await _service.getInventoryReport();
      state = state.copyWith(
        totalProducts: (data['totalProducts'] as num?)?.toInt() ?? 0,
        lowStockProducts: (data['lowStockProducts'] as num?)?.toInt() ?? 0,
        outOfStockProducts: (data['outOfStockProducts'] as num?)?.toInt() ?? 0,
        totalInventoryValue:
            (data['totalInventoryValue'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {}
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }

  Future<String?> exportReport(String reportType, String format) async {
    state = state.copyWith(isExporting: true);
    try {
      final url = await _service.exportReport(
        reportType: reportType,
        format: format,
        startDate: state.startDate,
        endDate: state.endDate,
      );
      return url;
    } finally {
      state = state.copyWith(isExporting: false);
    }
  }
}

// ─── Generic Date Range Report (summary / profit with Map data) ─────────────

class MapReportState {
  final DateTime startDate;
  final DateTime endDate;
  final int selectedPeriod;
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  const MapReportState({
    required this.startDate,
    required this.endDate,
    this.selectedPeriod = 0,
    this.isLoading = false,
    this.data,
    this.error,
  });

  MapReportState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? selectedPeriod,
    bool? isLoading,
    Object? data = _sentinel,
    Object? error = _sentinel,
  }) {
    return MapReportState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      data: data == _sentinel ? this.data : data as Map<String, dynamic>?,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

class SalesSummaryNotifier extends StateNotifier<MapReportState> {
  final SalesReportService _service;
  SalesSummaryNotifier(this._service)
      : super(MapReportState(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ));

  static const periods = ['day', 'week', 'month', 'year'];

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getSalesSummary(
        startDate: _ymd(state.startDate),
        endDate: _ymd(state.endDate),
        groupBy: periods[state.selectedPeriod],
      );
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }

  void setPeriod(int index) {
    state = state.copyWith(selectedPeriod: index);
    load();
  }
}

class ProfitOverviewNotifier extends StateNotifier<MapReportState> {
  final SalesReportService _service;
  ProfitOverviewNotifier(this._service)
      : super(MapReportState(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ));

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getProfitOverview(
        startDate: _ymd(state.startDate),
        endDate: _ymd(state.endDate),
      );
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }
}

// ─── Generic Date Range Report (list data) ──────────────────────────────────

class ListReportState {
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;
  final List<Map<String, dynamic>> items;
  final String? error;

  const ListReportState({
    required this.startDate,
    required this.endDate,
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  ListReportState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    List<Map<String, dynamic>>? items,
    Object? error = _sentinel,
  }) {
    return ListReportState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

class ProductSalesAnalysisNotifier extends StateNotifier<ListReportState> {
  final SalesReportService _service;
  ProductSalesAnalysisNotifier(this._service)
      : super(ListReportState(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ));

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getProductSalesAnalysis(
        startDate: _ymd(state.startDate),
        endDate: _ymd(state.endDate),
      );
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }
}

class CustomerSalesAnalysisNotifier extends StateNotifier<ListReportState> {
  final SalesReportService _service;
  CustomerSalesAnalysisNotifier(this._service)
      : super(ListReportState(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ));

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _service.getCustomerSalesAnalysis(
        startDate: _ymd(state.startDate),
        endDate: _ymd(state.endDate),
      );
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }
}

// ─── Daily Summary ──────────────────────────────────────────────────────────

class DailySummaryState {
  final DateTime selectedDate;
  final bool isLoading;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> dailySales;
  final double totalExpense;
  final String? error;

  const DailySummaryState({
    required this.selectedDate,
    this.isLoading = false,
    this.stats = const {},
    this.dailySales = const [],
    this.totalExpense = 0,
    this.error,
  });

  DailySummaryState copyWith({
    DateTime? selectedDate,
    bool? isLoading,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? dailySales,
    double? totalExpense,
    Object? error = _sentinel,
  }) {
    return DailySummaryState(
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      dailySales: dailySales ?? this.dailySales,
      totalExpense: totalExpense ?? this.totalExpense,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

class DailySummaryNotifier extends StateNotifier<DailySummaryState> {
  final SalesService _salesService;
  final FinanceService _financeService;

  DailySummaryNotifier(this._salesService, this._financeService)
      : super(DailySummaryState(selectedDate: DateTime.now()));

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _salesService.getSalesStats(
            startDate: state.selectedDate, endDate: state.selectedDate),
        _salesService.getDailySalesReport(date: state.selectedDate),
        _financeService.getExpenses(
            startDate: state.selectedDate, endDate: state.selectedDate),
      ]);
      final stats = results[0] as Map<String, dynamic>;
      final sales = results[1] as List<Map<String, dynamic>>;
      final expenses = results[2] as List<Map<String, dynamic>>;
      final totalExpense = expenses.fold<double>(
          0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));

      state = state.copyWith(
        stats: stats,
        dailySales: sales,
        totalExpense: totalExpense,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    load();
  }
}
