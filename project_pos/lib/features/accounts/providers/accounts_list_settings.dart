import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 30 — Cari liste sayfa boyutu kullanıcı tercihi (Issue P1.3 kalan).
///
/// Sprint 8'de `_pageLimit=100` sabitlenmişti; KOBİ tenant'larında uygun ama
/// 200+ müşterili daha büyük tenant'larda kullanıcı 50 (hızlı first paint) ya
/// da 200 (daha az scroll) tercih edebilir. SharedPreferences ile kalıcı.
class AccountsListPagination {
  final int pageLimit;

  const AccountsListPagination({this.pageLimit = 100});

  /// İzin verilen değerler. UI seçici bu listeyi gösterir.
  static const List<int> allowed = [50, 100, 200];

  AccountsListPagination copyWith({int? pageLimit}) =>
      AccountsListPagination(pageLimit: pageLimit ?? this.pageLimit);
}

class AccountsListPaginationNotifier
    extends StateNotifier<AccountsListPagination> {
  AccountsListPaginationNotifier() : super(const AccountsListPagination());

  static const _kPageLimit = 'accounts_list.page_limit';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_kPageLimit);
    if (stored != null && AccountsListPagination.allowed.contains(stored)) {
      state = AccountsListPagination(pageLimit: stored);
    }
  }

  Future<void> setPageLimit(int limit) async {
    if (!AccountsListPagination.allowed.contains(limit)) return;
    if (state.pageLimit == limit) return;
    state = state.copyWith(pageLimit: limit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPageLimit, limit);
  }
}

final accountsListPaginationProvider = StateNotifierProvider<
    AccountsListPaginationNotifier, AccountsListPagination>(
  (ref) => AccountsListPaginationNotifier()..load(),
);
