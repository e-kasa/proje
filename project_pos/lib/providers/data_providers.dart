import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/comprehensive_database.dart';
import '../services/service_locator.dart';

/// Category Provider - Optimized with caching
final categoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = ComprehensiveDatabase.instance;
  final database = await db.database;

  return await database.query(
    'categories',
    where: 'isActive = ?',
    whereArgs: [1],
    orderBy: 'sortOrder ASC, name ASC',
  );
});

/// Product Provider - Paginated
class ProductNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  ProductNotifier() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final _db = ComprehensiveDatabase.instance;
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
      final database = await _db.database;
      final products = await database.query(
        'products',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'createdAt DESC',
        limit: _limit,
        offset: _page * _limit,
      );

      _hasMore = products.length == _limit;

      if (refresh) {
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
  return ProductNotifier();
});

/// Customer Provider - Cached
final customerProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, filter) async {
  final db = ComprehensiveDatabase.instance;
  final database = await db.database;

  String? whereClause;
  List<dynamic>? whereArgs;

  if (filter == 'active') {
    whereClause = 'isActive = ?';
    whereArgs = [1];
  } else if (filter == 'vip') {
    whereClause = 'customerType = ?';
    whereArgs = ['vip'];
  }

  return await database.query(
    'customers',
    where: whereClause,
    whereArgs: whereArgs,
    orderBy: 'totalPurchases DESC',
  );
});

/// Search Provider - Debounced
final searchProvider = StateProvider.autoDispose<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(searchProvider);

  if (query.isEmpty) {
    return [];
  }

  // Debounce effect
  await Future.delayed(const Duration(milliseconds: 300));

  final db = ComprehensiveDatabase.instance;
  final database = await db.database;

  return await database.query(
    'products',
    where: 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?',
    whereArgs: ['%$query%', '%$query%', '%$query%'],
    limit: 20,
  );
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
            productId: int.tryParse(productId) ?? 0,
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
