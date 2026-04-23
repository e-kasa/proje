import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/accounts/services/payment_service.dart';
import 'package:project_pos/features/finance/services/finance_service.dart';

const _sentinel = Object();

// ─── Finance Dashboard ──────────────────────────────────────────────────────

class FinanceDashboardState {
  final Map<String, dynamic> summary;
  final bool isLoading;
  final String? error;

  const FinanceDashboardState({
    this.summary = const {},
    this.isLoading = true,
    this.error,
  });

  FinanceDashboardState copyWith({
    Map<String, dynamic>? summary,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return FinanceDashboardState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

class FinanceDashboardNotifier extends StateNotifier<FinanceDashboardState> {
  final FinanceService _service;
  FinanceDashboardNotifier(this._service)
      : super(const FinanceDashboardState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await _service.getSummary();
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ─── Expense List ───────────────────────────────────────────────────────────

class ExpenseListState {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> categories;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final String? selectedStatus;
  final String searchQuery;

  const ExpenseListState({
    this.expenses = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.selectedStatus,
    this.searchQuery = '',
  });

  ExpenseListState copyWith({
    List<Map<String, dynamic>>? expenses,
    List<Map<String, dynamic>>? categories,
    bool? isLoading,
    Object? error = _sentinel,
    Object? selectedCategory = _sentinel,
    Object? selectedStatus = _sentinel,
    String? searchQuery,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      selectedCategory: selectedCategory == _sentinel
          ? this.selectedCategory
          : selectedCategory as String?,
      selectedStatus: selectedStatus == _sentinel
          ? this.selectedStatus
          : selectedStatus as String?,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ExpenseListNotifier extends StateNotifier<ExpenseListState> {
  final FinanceService _service;
  ExpenseListNotifier(this._service) : super(const ExpenseListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final expenses = await _service.getExpenses(
        category: state.selectedCategory,
        status: state.selectedStatus,
      );
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _service.getExpenseCategories();
      state = state.copyWith(categories: categories);
    } catch (_) {}
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
    load();
  }

  void setStatus(String? status) {
    state = state.copyWith(selectedStatus: status);
    load();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> deleteExpense(dynamic id) async {
    try {
      await _service.deleteExpense(id is int ? id : int.parse(id.toString()));
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ─── Payment List ───────────────────────────────────────────────────────────

class PaymentListState {
  final List<Map<String, dynamic>> payments;
  final bool isLoading;
  final String? error;
  final String selectedType; // 'all' | 'income' | 'expense'
  final String searchQuery;
  final double totalIncome;
  final double totalExpense;

  const PaymentListState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
    this.selectedType = 'all',
    this.searchQuery = '',
    this.totalIncome = 0,
    this.totalExpense = 0,
  });

  PaymentListState copyWith({
    List<Map<String, dynamic>>? payments,
    bool? isLoading,
    Object? error = _sentinel,
    String? selectedType,
    String? searchQuery,
    double? totalIncome,
    double? totalExpense,
  }) {
    return PaymentListState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      selectedType: selectedType ?? this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }
}

class PaymentListNotifier extends StateNotifier<PaymentListState> {
  final PaymentService _service;
  PaymentListNotifier(this._service) : super(const PaymentListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final type = state.selectedType == 'all' ? null : state.selectedType;
      final payments = await _service.getPayments(type: type);
      double income = 0;
      double expense = 0;
      for (final p in payments) {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0;
        final t = p['type']?.toString() ?? '';
        if (t == 'income') income += amount;
        if (t == 'expense') expense += amount;
      }
      state = state.copyWith(
        payments: payments,
        totalIncome: income,
        totalExpense: expense,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setType(String type) {
    state = state.copyWith(selectedType: type);
    load();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

// ─── Cash Flow ──────────────────────────────────────────────────────────────

class CashFlowState {
  final bool isLoading;
  final String? error;
  final String selectedPeriod; // 'daily' | 'weekly' | 'monthly'
  final double totalIncome;
  final double totalExpense;
  final double netFlow;
  final List<Map<String, dynamic>> periodData;

  const CashFlowState({
    this.isLoading = false,
    this.error,
    this.selectedPeriod = 'daily',
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.netFlow = 0,
    this.periodData = const [],
  });

  CashFlowState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    String? selectedPeriod,
    double? totalIncome,
    double? totalExpense,
    double? netFlow,
    List<Map<String, dynamic>>? periodData,
  }) {
    return CashFlowState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      netFlow: netFlow ?? this.netFlow,
      periodData: periodData ?? this.periodData,
    );
  }
}

class CashFlowNotifier extends StateNotifier<CashFlowState> {
  final PaymentService _service;
  CashFlowNotifier(this._service) : super(const CashFlowState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getCashFlowSummary(period: state.selectedPeriod);
      final income = (data['totalIncome'] as num?)?.toDouble() ?? 0;
      final expense = (data['totalExpense'] as num?)?.toDouble() ?? 0;
      final periodData =
          (data['periods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      state = state.copyWith(
        totalIncome: income,
        totalExpense: expense,
        netFlow: income - expense,
        periodData: periodData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setPeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
    load();
  }
}
