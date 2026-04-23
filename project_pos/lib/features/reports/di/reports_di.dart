import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/reports/providers/reports_notifiers.dart';
import 'package:project_pos/services/service_locator.dart';

final reportsDashboardProvider = StateNotifierProvider.autoDispose<
    ReportsDashboardNotifier, ReportsDashboardState>(
  (ref) {
    final n = ReportsDashboardNotifier(ref.read(reportServiceProvider));
    n.load();
    return n;
  },
);

final salesSummaryProvider =
    StateNotifierProvider.autoDispose<SalesSummaryNotifier, MapReportState>(
  (ref) {
    final n = SalesSummaryNotifier(ref.read(salesReportServiceProvider));
    n.load();
    return n;
  },
);

final profitOverviewProvider =
    StateNotifierProvider.autoDispose<ProfitOverviewNotifier, MapReportState>(
  (ref) {
    final n = ProfitOverviewNotifier(ref.read(salesReportServiceProvider));
    n.load();
    return n;
  },
);

final productSalesAnalysisProvider = StateNotifierProvider.autoDispose<
    ProductSalesAnalysisNotifier, ListReportState>(
  (ref) {
    final n =
        ProductSalesAnalysisNotifier(ref.read(salesReportServiceProvider));
    n.load();
    return n;
  },
);

final customerSalesAnalysisProvider = StateNotifierProvider.autoDispose<
    CustomerSalesAnalysisNotifier, ListReportState>(
  (ref) {
    final n =
        CustomerSalesAnalysisNotifier(ref.read(salesReportServiceProvider));
    n.load();
    return n;
  },
);

final dailySummaryProvider =
    StateNotifierProvider.autoDispose<DailySummaryNotifier, DailySummaryState>(
  (ref) {
    final n = DailySummaryNotifier(
      ref.read(salesServiceProvider),
      ref.read(financeServiceProvider),
    );
    n.load();
    return n;
  },
);
