import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/sales_service.dart';

class SaleListState {
  final List<Map<String, dynamic>> sales;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? statusFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const SaleListState({
    this.sales = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.startDate,
    this.endDate,
  });

  List<Map<String, dynamic>> get filtered {
    var list = sales;

    if (statusFilter != null) {
      list = list.where((s) {
        final status = s['status']?.toString().toLowerCase() ??
            s['paymentStatus']?.toString().toLowerCase() ??
            '';
        if (statusFilter == 'cancelled') {
          return status == 'cancelled' || s['isCancelled'] == true;
        }
        if (statusFilter == 'paid') {
          return status == 'paid' || status == 'completed';
        }
        if (statusFilter == 'pending') {
          return status == 'pending' || status == 'unpaid';
        }
        return true;
      }).toList();
    }

    if (startDate != null || endDate != null) {
      list = list.where((s) {
        final dateStr = s['createdAt']?.toString() ??
            s['saleDate']?.toString() ??
            s['date']?.toString();
        if (dateStr == null) return true;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return true;
        if (startDate != null && date.isBefore(startDate!)) return false;
        if (endDate != null &&
            date.isAfter(endDate!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((s) =>
              (s['id']?.toString().toLowerCase().contains(q) ?? false) ||
              (s['saleNumber']?.toString().toLowerCase().contains(q) ?? false) ||
              (s['customerName']?.toString().toLowerCase().contains(q) ?? false))
          .toList();
    }

    return list;
  }

  SaleListState copyWith({
    List<Map<String, dynamic>>? sales,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Object? statusFilter = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
  }) {
    return SaleListState(
      sales: sales ?? this.sales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter == _sentinel
          ? this.statusFilter
          : statusFilter as String?,
      startDate:
          startDate == _sentinel ? this.startDate : startDate as DateTime?,
      endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
    );
  }
}

const _sentinel = Object();

class SaleListNotifier extends StateNotifier<SaleListState> {
  final SalesService _service;

  SaleListNotifier(this._service) : super(const SaleListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.getSales(
        startDate: state.startDate,
        endDate: state.endDate,
        paymentStatus: state.statusFilter,
      );
      state = state.copyWith(sales: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void setStatusFilter(String? val) =>
      state = state.copyWith(statusFilter: val);

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
    load();
  }

  void clearDateRange() {
    state = state.copyWith(
      startDate: null,
      endDate: null,
    );
    load();
  }

  Future<void> cancel(String id, String reason, BuildContext context) async {
    try {
      await _service.cancelSale(id, reason);
      await load();
      if (context.mounted) {
        AppToast.warning(context, 'Satış iptal edildi');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'İptal hatası: $e');
      }
    }
  }
}
