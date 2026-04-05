import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/service_locator.dart';

/// Category Provider - API-based
final categoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final categories = await ref.read(categoryServiceProvider).getCategories();
  return categories;
});

/// Product Provider - Paginated (API-based)
class ProductNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  ProductNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final Ref _ref;
  int _page = 0;
  final int _limit = 20;
  bool _hasMore = true;

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    try {
      final products = await _ref.read(productServiceProvider).getProducts(
        page: _page,
        size: _limit,
      );
      _hasMore = products.length == _limit;
      if (refresh || _page == 0) {
        state = AsyncValue.data(products);
      } else {
        state.whenData((current) {
          state = AsyncValue.data([...current, ...products]);
        });
      }
      _page++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    await loadProducts();
  }

  void invalidate() {
    loadProducts(refresh: true);
  }
}

final productProvider = StateNotifierProvider.autoDispose<ProductNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ProductNotifier(ref);
});

/// Customer Provider - API-based
final customerProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, filter) async {
  final customers = await ref.read(customerServiceProvider).getCustomers();
  if (filter == 'active') {
    return customers.where((c) => c['isActive'] == true).toList();
  }
  return customers;
});

/// Search Provider - Debounced (API-based)
final searchProvider = StateProvider.autoDispose<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(searchProvider);
  if (query.isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 300));
  final results = await ref.read(productServiceProvider).getProducts(search: query);
  return results;
});

// ============================================================
// Stock Provider
// ============================================================

class StockState {
  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final bool isAdjusting;
  final String? error;

  const StockState({
    this.products = const [],
    this.isLoading = false,
    this.isAdjusting = false,
    this.error,
  });

  // Ekranın eşik değerleriyle hesaplanan istatistikler
  int get totalCount => products.length;
  int get outCount => products.where((p) => (p['stock'] as num? ?? 0) == 0).length;
  int get criticalCount => products.where((p) {
        final s = p['stock'] as num? ?? 0;
        return s > 0 && s <= 5;
      }).length;
  int get lowCount => products.where((p) {
        final s = p['stock'] as num? ?? 0;
        return s > 5 && s <= 20;
      }).length;

  StockState copyWith({
    List<Map<String, dynamic>>? products,
    bool? isLoading,
    bool? isAdjusting,
    String? error,
  }) {
    return StockState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isAdjusting: isAdjusting ?? this.isAdjusting,
      error: error,
    );
  }
}

class StockNotifier extends StateNotifier<StockState> {
  StockNotifier(this._ref) : super(const StockState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await _ref.read(productServiceProvider).getProducts();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Stok miktarını günceller; başarılıysa listeyi lokalde de günceller.
  /// productId: backend UUID (String)
  Future<bool> adjustStock({
    required String productId,
    required int newQuantity,
    required String reason,
  }) async {
    state = state.copyWith(isAdjusting: true, error: null);
    try {
      await _ref.read(stockServiceProvider).adjustStock(
            productId: productId,
            quantity: newQuantity,
            reason: reason,
          );
      // Listeyi API'ye tekrar gitmeden lokalde güncelle
      final updated = state.products.map((p) {
        if (p['id']?.toString() == productId) {
          return Map<String, dynamic>.from(p)..['stock'] = newQuantity;
        }
        return p;
      }).toList();
      state = state.copyWith(products: updated, isAdjusting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isAdjusting: false, error: e.toString());
      return false;
    }
  }
}

final stockProvider = StateNotifierProvider<StockNotifier, StockState>((ref) {
  return StockNotifier(ref);
});

// ============================================================
// Vehicle Provider - Arac Listesi
// ============================================================

final vehicleListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final vehicles = await ref.read(vehicleServiceProvider).getActiveVehicles();
  return vehicles;
});

// ============================================================
// OEM Search Provider
// ============================================================

final oemSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final oemSearchResultsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(oemSearchQueryProvider);
  if (query.length < 3) return [];
  await Future.delayed(const Duration(milliseconds: 300));
  final results = await ref.read(oemServiceProvider).search(query);
  return results;
});

// ============================================================
// Part Search Provider
// ============================================================

final partSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final partSearchMakeProvider = StateProvider.autoDispose<String?>((ref) => null);
final partSearchModelProvider = StateProvider.autoDispose<String?>((ref) => null);
final partSearchYearProvider = StateProvider.autoDispose<int?>((ref) => null);

final partSearchResultsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(partSearchQueryProvider);
  final make = ref.watch(partSearchMakeProvider);
  final model = ref.watch(partSearchModelProvider);
  final year = ref.watch(partSearchYearProvider);

  if (query.isEmpty && make == null) return [];
  await Future.delayed(const Duration(milliseconds: 400));

  final results = await ref.read(partSearchServiceProvider).search(
    keyword: query.isNotEmpty ? query : null,
    make: make,
    model: model,
    year: year,
  );
  return results;
});

// ============================================================
// Vehicle Makes Provider (for dropdowns)
// ============================================================

final vehicleMakesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return await ref.read(vehicleServiceProvider).getDistinctMakes();
});
