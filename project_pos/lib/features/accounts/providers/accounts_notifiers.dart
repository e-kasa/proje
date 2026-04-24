import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/accounts/services/account_service.dart';

// ─── Account Summary Dashboard ──────────────────────────────────────────────

class AccountSummaryState {
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>> overdueList;
  final bool isLoading;
  final String? error;

  const AccountSummaryState({
    this.summary,
    this.overdueList = const [],
    this.isLoading = true,
    this.error,
  });

  AccountSummaryState copyWith({
    Object? summary = _sentinel,
    List<Map<String, dynamic>>? overdueList,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return AccountSummaryState(
      summary: summary == _sentinel
          ? this.summary
          : summary as Map<String, dynamic>?,
      overdueList: overdueList ?? this.overdueList,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

class AccountSummaryNotifier extends StateNotifier<AccountSummaryState> {
  final AccountService _service;

  AccountSummaryNotifier(this._service) : super(const AccountSummaryState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _service.getAccountSummary(),
        _service.getOverdueAccounts(),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        summary: results[0] as Map<String, dynamic>?,
        overdueList: results[1] as List<Map<String, dynamic>>,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ─── Overdue Tracking (Customer + Supplier) ─────────────────────────────────

class OverdueTrackingState {
  final List<Map<String, dynamic>> customerOverdue;
  final List<Map<String, dynamic>> supplierOverdue;
  final bool loadingCustomer;
  final bool loadingSupplier;
  final String? errorCustomer;
  final String? errorSupplier;

  const OverdueTrackingState({
    this.customerOverdue = const [],
    this.supplierOverdue = const [],
    this.loadingCustomer = true,
    this.loadingSupplier = true,
    this.errorCustomer,
    this.errorSupplier,
  });

  OverdueTrackingState copyWith({
    List<Map<String, dynamic>>? customerOverdue,
    List<Map<String, dynamic>>? supplierOverdue,
    bool? loadingCustomer,
    bool? loadingSupplier,
    Object? errorCustomer = _sentinel,
    Object? errorSupplier = _sentinel,
  }) {
    return OverdueTrackingState(
      customerOverdue: customerOverdue ?? this.customerOverdue,
      supplierOverdue: supplierOverdue ?? this.supplierOverdue,
      loadingCustomer: loadingCustomer ?? this.loadingCustomer,
      loadingSupplier: loadingSupplier ?? this.loadingSupplier,
      errorCustomer: errorCustomer == _sentinel
          ? this.errorCustomer
          : errorCustomer as String?,
      errorSupplier: errorSupplier == _sentinel
          ? this.errorSupplier
          : errorSupplier as String?,
    );
  }
}

class OverdueTrackingNotifier extends StateNotifier<OverdueTrackingState> {
  final AccountService _service;

  OverdueTrackingNotifier(this._service) : super(const OverdueTrackingState());

  Future<void> loadCustomerOverdue() async {
    state = state.copyWith(loadingCustomer: true, errorCustomer: null);
    try {
      final data = await _service.getOverdueAccounts(accountType: 'CUSTOMER');
      if (!mounted) return;
      data.sort((a, b) {
        final dateA = a['dueDate']?.toString() ?? '';
        final dateB = b['dueDate']?.toString() ?? '';
        return dateA.compareTo(dateB);
      });
      state = state.copyWith(customerOverdue: data, loadingCustomer: false);
    } catch (e) {
      if (!mounted) return;
      state =
          state.copyWith(loadingCustomer: false, errorCustomer: e.toString());
    }
  }

  Future<void> loadSupplierOverdue() async {
    state = state.copyWith(loadingSupplier: true, errorSupplier: null);
    try {
      final data = await _service.getOverdueAccounts(accountType: 'SUPPLIER');
      if (!mounted) return;
      data.sort((a, b) {
        final dateA = a['dueDate']?.toString() ?? '';
        final dateB = b['dueDate']?.toString() ?? '';
        return dateA.compareTo(dateB);
      });
      state = state.copyWith(supplierOverdue: data, loadingSupplier: false);
    } catch (e) {
      if (!mounted) return;
      state =
          state.copyWith(loadingSupplier: false, errorSupplier: e.toString());
    }
  }

  Future<void> loadAll() async {
    await Future.wait([loadCustomerOverdue(), loadSupplierOverdue()]);
  }
}

// ─── Account Statement ──────────────────────────────────────────────────────

enum TxFilter { all, sales, payments, returns, adjustments }

const Map<TxFilter, Set<String>> _kTxFilterTypes = {
  TxFilter.all: {},
  TxFilter.sales: {'SALE', 'PURCHASE'},
  TxFilter.payments: {'PAYMENT', 'COLLECTION', 'SUPPLIER_PAYMENT'},
  TxFilter.returns: {'RETURN', 'SUPPLIER_RETURN', 'REFUND'},
  TxFilter.adjustments: {
    'ADJUSTMENT_DEBIT',
    'ADJUSTMENT_CREDIT',
    'DISCOUNT',
    'CANCEL',
    'LATE_FEE',
  },
};

class AccountStatementState {
  final String? accountType;
  final String? accountId;
  final String? accountName;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic>? statement;
  final bool isLoading;
  final String? error;
  final TxFilter filter;

  const AccountStatementState({
    this.accountType,
    this.accountId,
    this.accountName,
    required this.startDate,
    required this.endDate,
    this.statement,
    this.isLoading = false,
    this.error,
    this.filter = TxFilter.all,
  });

  bool get hasAccount => accountId != null && accountId!.isNotEmpty;

  List<Map<String, dynamic>> get visibleTransactions {
    final raw = statement?['transactions'];
    if (raw is! List) return const [];
    final all = List<Map<String, dynamic>>.from(raw);
    if (filter == TxFilter.all) return all;
    final allowed = _kTxFilterTypes[filter] ?? const <String>{};
    return all
        .where((tx) => allowed.contains(tx['transactionType']?.toString()))
        .toList();
  }

  AccountStatementState copyWith({
    Object? accountType = _sentinel,
    Object? accountId = _sentinel,
    Object? accountName = _sentinel,
    DateTime? startDate,
    DateTime? endDate,
    Object? statement = _sentinel,
    bool? isLoading,
    Object? error = _sentinel,
    TxFilter? filter,
  }) {
    return AccountStatementState(
      accountType: accountType == _sentinel
          ? this.accountType
          : accountType as String?,
      accountId:
          accountId == _sentinel ? this.accountId : accountId as String?,
      accountName: accountName == _sentinel
          ? this.accountName
          : accountName as String?,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statement: statement == _sentinel
          ? this.statement
          : statement as Map<String, dynamic>?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      filter: filter ?? this.filter,
    );
  }
}

class AccountStatementNotifier extends StateNotifier<AccountStatementState> {
  final AccountService _service;

  AccountStatementNotifier(
    this._service, {
    String? accountType,
    String? accountId,
    String? accountName,
  }) : super(AccountStatementState(
          accountType: accountType,
          accountId: accountId,
          accountName: accountName,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        )) {
    if (state.hasAccount) load();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    if (!state.hasAccount) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getAccountStatement(
        accountType: state.accountType!,
        accountId: state.accountId!,
        startDate: _fmt(state.startDate),
        endDate: _fmt(state.endDate),
      );
      if (!mounted) return;
      state = state.copyWith(statement: data, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setAccount({
    required String accountType,
    required String accountId,
    String? accountName,
  }) {
    state = state.copyWith(
      accountType: accountType,
      accountId: accountId,
      accountName: accountName,
    );
    load();
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }

  void setFilter(TxFilter f) {
    if (state.filter == f) return;
    state = state.copyWith(filter: f);
  }
}

const _sentinel = Object();
