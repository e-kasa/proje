import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/supplier_claims/di/supplier_claims_di.dart';
import 'package:project_pos/features/supplier_claims/models/supplier_claim.dart';

// ─── Liste State ────────────────────────────────────────────────────────────

class SupplierClaimsListState {
  final List<SupplierClaim> claims;
  final bool isLoading;
  final String? error;
  final ClaimStatus? statusFilter;

  const SupplierClaimsListState({
    this.claims = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
  });

  SupplierClaimsListState copyWith({
    List<SupplierClaim>? claims,
    bool? isLoading,
    String? error,
    Object? statusFilter = _sentinel,
  }) {
    return SupplierClaimsListState(
      claims: claims ?? this.claims,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter == _sentinel
          ? this.statusFilter
          : statusFilter as ClaimStatus?,
    );
  }
}

const _sentinel = Object();

class SupplierClaimsListNotifier extends StateNotifier<SupplierClaimsListState> {
  final Ref _ref;

  SupplierClaimsListNotifier(this._ref) : super(const SupplierClaimsListState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _ref
          .read(supplierClaimsServiceProvider)
          .list(status: state.statusFilter);
      state = state.copyWith(claims: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setStatusFilter(ClaimStatus? status) async {
    state = state.copyWith(statusFilter: status);
    await load();
  }
}

final supplierClaimsListProvider = StateNotifierProvider.autoDispose<
    SupplierClaimsListNotifier, SupplierClaimsListState>(
  (ref) => SupplierClaimsListNotifier(ref),
);

// ─── Detay ──────────────────────────────────────────────────────────────────

final supplierClaimDetailProvider =
    FutureProvider.autoDispose.family<SupplierClaim, String>((ref, id) async {
  return ref.read(supplierClaimsServiceProvider).getById(id);
});
