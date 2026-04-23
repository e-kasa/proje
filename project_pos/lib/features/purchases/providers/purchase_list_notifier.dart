import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/purchase_service.dart';

class PurchaseListState {
  final List<Map<String, dynamic>> purchases;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final bool? isCancelledFilter;

  const PurchaseListState({
    this.purchases = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.isCancelledFilter,
  });

  List<Map<String, dynamic>> get filtered {
    var list = purchases;
    if (isCancelledFilter != null) {
      list = list.where((p) => p['isCancelled'] == isCancelledFilter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((p) =>
              (p['invoiceNumber']?.toString().toLowerCase().contains(q) ?? false) ||
              (p['supplierName']?.toString().toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  PurchaseListState copyWith({
    List<Map<String, dynamic>>? purchases,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Object? isCancelledFilter = _sentinel,
  }) {
    return PurchaseListState(
      purchases: purchases ?? this.purchases,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      isCancelledFilter:
          isCancelledFilter == _sentinel ? this.isCancelledFilter : isCancelledFilter as bool?,
    );
  }
}

const _sentinel = Object();

class PurchaseListNotifier extends StateNotifier<PurchaseListState> {
  final PurchaseService _service;

  PurchaseListNotifier(this._service) : super(const PurchaseListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getPurchases();
      state = state.copyWith(purchases: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void setFilter(bool? val) => state = state.copyWith(isCancelledFilter: val);

  Future<void> cancel(String id, BuildContext context, String Function(String) t) async {
    try {
      await _service.cancelPurchase(id);
      await load();
      if (context.mounted) {
        AppToast.warning(context, t('purchases.cancelled_success'));
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }
}
