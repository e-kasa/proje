import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/accounts/providers/accounts_list_settings.dart';
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

  /// Sprint 8 B0 — backend `/api/v1/accounts/list` cevabındaki item map'inden parse.
  factory AccountListItem.fromMap(Map<String, dynamic> m) {
    return AccountListItem(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '-',
      type: m['type']?.toString() ?? 'CUSTOMER',
      currentBalance: (m['currentBalance'] as num?)?.toDouble() ?? 0,
      hasOverdue: m['hasOverdue'] == true,
    );
  }
}

class AccountsListState {
  final List<AccountListItem> all;
  final AccountsFilter filter;
  final String query;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? nextCursor;
  final String? error;

  const AccountsListState({
    this.all = const [],
    this.filter = AccountsFilter.all,
    this.query = '',
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.nextCursor,
    this.error,
  });

  AccountsListState copyWith({
    List<AccountListItem>? all,
    AccountsFilter? filter,
    String? query,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    Object? nextCursor = _sentinel,
    Object? error = _sentinel,
  }) {
    return AccountsListState(
      all: all ?? this.all,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      nextCursor:
          nextCursor == _sentinel ? this.nextCursor : nextCursor as String?,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  /// Sprint 8 B0 — server-side filter+query sonrası backend tüm yetkili kayıtları döner.
  /// `visible` artık in-memory filter yapmaz; sadece `all` aynası — geriye uyum için tutuldu.
  List<AccountListItem> get visible => all;
}

const _sentinel = Object();

class AccountsListNotifier extends StateNotifier<AccountsListState> {
  final Ref _ref;
  Timer? _searchDebounce;

  AccountsListNotifier(this._ref) : super(const AccountsListState());

  static const String _endpoint = 'product/api/v1/accounts/list';
  // Sayfa boyutu Sprint 30'dan beri `accountsListPaginationProvider` üzerinden
  // dinamik (50/100/200, default 100). Backend Math.min(200, limit) ile clamp.

  /// Sprint 8 B0 — sayfanın ilk yüklenmesi (initial veya filter/query değişimi).
  ///
  /// Sprint 8 hot-fix v2: query boşsa auto-prefetch — initial load sonrası
  /// hâlâ hasMore varsa 1x daha loadMore otomatik tetiklenir. Bu, 100-200
  /// müşterili tenant'larda alfabetik sondaki kayıtların (örn. "Z" harfi)
  /// ilk açılışta görünmesini sağlar. 200+ müşterili tenant için kullanıcı
  /// scroll yapar (manuel loadMore).
  Future<void> loadFirst() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      all: const [],
      nextCursor: null,
      hasReachedEnd: false,
    );
    await _fetch(cursor: null, append: false);

    // Auto-prefetch: query yokken alfabetik sondakileri de getir (1 sayfa daha)
    if (state.query.isEmpty &&
        !state.hasReachedEnd &&
        state.nextCursor != null &&
        state.error == null) {
      await _fetch(cursor: state.nextCursor, append: true);
    }
  }

  /// Geriye uyum: Sprint 7 öncesi callsite'lar `load()` kullanıyordu (statement_detail_panel).
  Future<void> load() => loadFirst();

  /// Sayfa sonuna yaklaşınca infinite scroll. nextCursor null veya yükleme aktifse no-op.
  Future<void> loadMore() async {
    if (state.hasReachedEnd ||
        state.isLoadingMore ||
        state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, error: null);
    await _fetch(cursor: state.nextCursor, append: true);
  }

  /// Pull-to-refresh — loadFirst alias.
  Future<void> refresh() => loadFirst();

  void setFilter(AccountsFilter f) {
    if (state.filter == f) return;
    state = state.copyWith(filter: f);
    loadFirst();
  }

  /// 300ms debounced — kullanıcı her keystroke'ta backend tetiklemez.
  void setQuery(String q) {
    if (state.query == q) return;
    state = state.copyWith(query: q);
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 300), () => loadFirst());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetch({String? cursor, required bool append}) async {
    try {
      final pageLimit =
          _ref.read(accountsListPaginationProvider).pageLimit;
      final params = <String, dynamic>{
        'limit': pageLimit,
        'filter': _filterToString(state.filter),
      };
      if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;
      if (state.query.isNotEmpty) params['q'] = state.query;

      final response = await _ref
          .read(apiClientProvider)
          .get(_endpoint, queryParameters: params);

      final envelope = response.data is Map ? response.data as Map : {};
      final data = (envelope['data'] is Map)
          ? envelope['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final rawItems = (data['items'] as List?) ?? const [];
      final items = rawItems
          .whereType<Map>()
          .map((e) => AccountListItem.fromMap(e.cast<String, dynamic>()))
          .toList();
      final nextCursor = data['nextCursor'] as String?;

      state = state.copyWith(
        all: append ? [...state.all, ...items] : items,
        nextCursor: nextCursor,
        hasReachedEnd: nextCursor == null,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  static String _filterToString(AccountsFilter f) {
    switch (f) {
      case AccountsFilter.all:
        return 'all';
      case AccountsFilter.overdue:
        return 'overdue';
      case AccountsFilter.customer:
        return 'customer';
      case AccountsFilter.supplier:
        return 'supplier';
    }
  }
}

final accountsListProvider =
    StateNotifierProvider.autoDispose<AccountsListNotifier, AccountsListState>(
  (ref) {
    final n = AccountsListNotifier(ref);
    n.loadFirst();
    return n;
  },
);
