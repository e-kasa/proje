import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/services/service_locator.dart';

enum AccountsFilter { all, overdue, customer, supplier }

class AccountListItem {
  final String id;
  final String name;
  final String type; // 'CUSTOMER' | 'SUPPLIER'
  final double currentBalance;
  final bool hasOverdue;

  const AccountListItem({
    required this.id,
    required this.name,
    required this.type,
    this.currentBalance = 0,
    this.hasOverdue = false,
  });
}

class AccountsListState {
  final List<AccountListItem> all;
  final AccountsFilter filter;
  final String query;
  final bool isLoading;
  final String? error;

  const AccountsListState({
    this.all = const [],
    this.filter = AccountsFilter.all,
    this.query = '',
    this.isLoading = true,
    this.error,
  });

  AccountsListState copyWith({
    List<AccountListItem>? all,
    AccountsFilter? filter,
    String? query,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return AccountsListState(
      all: all ?? this.all,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  List<AccountListItem> get visible {
    Iterable<AccountListItem> list = all;
    switch (filter) {
      case AccountsFilter.customer:
        list = list.where((a) => a.type == 'CUSTOMER');
        break;
      case AccountsFilter.supplier:
        list = list.where((a) => a.type == 'SUPPLIER');
        break;
      case AccountsFilter.overdue:
        list = list.where((a) => a.hasOverdue);
        break;
      case AccountsFilter.all:
        break;
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((a) => a.name.toLowerCase().contains(q));
    }
    return list.toList();
  }
}

const _sentinel = Object();

class AccountsListNotifier extends StateNotifier<AccountsListState> {
  final Ref _ref;
  AccountsListNotifier(this._ref) : super(const AccountsListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _ref.read(customerServiceProvider).getCustomers(),
        _ref.read(supplierServiceProvider).getSuppliers(),
      ]);
      final customers = results[0];
      final suppliers = results[1];

      // Vadesi geçmiş hesap ID'lerini summary'den al (zaten yüklü)
      final overdueIds = _ref
          .read(accountSummaryProvider)
          .overdueList
          .map((o) => o['accountId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final merged = <AccountListItem>[
        ...customers.map((c) {
          final id = c['id']?.toString() ?? '';
          return AccountListItem(
            id: id,
            name: c['name']?.toString() ?? '-',
            type: 'CUSTOMER',
            currentBalance:
                (c['currentBalance'] as num?)?.toDouble() ?? 0,
            hasOverdue: overdueIds.contains(id),
          );
        }),
        ...suppliers.map((s) {
          final id = s['id']?.toString() ?? '';
          return AccountListItem(
            id: id,
            name: s['name']?.toString() ?? '-',
            type: 'SUPPLIER',
            currentBalance:
                (s['currentBalance'] as num?)?.toDouble() ?? 0,
            hasOverdue: overdueIds.contains(id),
          );
        }),
      ];
      merged.sort((a, b) => a.name.compareTo(b.name));

      state = state.copyWith(all: merged, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(AccountsFilter f) {
    state = state.copyWith(filter: f);
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }
}

final accountsListProvider =
    StateNotifierProvider.autoDispose<AccountsListNotifier, AccountsListState>(
  (ref) {
    final n = AccountsListNotifier(ref);
    n.load();
    return n;
  },
);
