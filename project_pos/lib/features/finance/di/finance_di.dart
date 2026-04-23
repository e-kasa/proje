import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/finance/providers/finance_notifiers.dart';
import 'package:project_pos/services/service_locator.dart';

final financeDashboardProvider = StateNotifierProvider.autoDispose<
    FinanceDashboardNotifier, FinanceDashboardState>(
  (ref) {
    final n = FinanceDashboardNotifier(ref.read(financeServiceProvider));
    n.load();
    return n;
  },
);

final expenseListProvider = StateNotifierProvider.autoDispose<
    ExpenseListNotifier, ExpenseListState>(
  (ref) {
    final n = ExpenseListNotifier(ref.read(financeServiceProvider));
    n.load();
    n.loadCategories();
    return n;
  },
);

final paymentListProvider = StateNotifierProvider.autoDispose<
    PaymentListNotifier, PaymentListState>(
  (ref) {
    final n = PaymentListNotifier(ref.read(paymentServiceProvider));
    n.load();
    return n;
  },
);

final cashFlowProvider =
    StateNotifierProvider.autoDispose<CashFlowNotifier, CashFlowState>(
  (ref) {
    final n = CashFlowNotifier(ref.read(paymentServiceProvider));
    n.load();
    return n;
  },
);
