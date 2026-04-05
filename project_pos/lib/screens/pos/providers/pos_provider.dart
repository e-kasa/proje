import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/service_locator.dart';
import '../../../core/utils/app_logger.dart';

// ─── Cart Item Model ───────────────────────────────────────────────
class CartItem {
  final Map<String, dynamic> product;
  int quantity;
  double discount; // yüzde (0-100)

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
  });

  String get productId => product['id'].toString();
  String get variantId => product['variantId']?.toString() ?? productId;
  String get name => product['name']?.toString() ?? '';
  double get unitPrice =>
      (product['sellingPrice'] as num?)?.toDouble() ??
      (product['basePrice'] as num?)?.toDouble() ??
      (product['price'] as num?)?.toDouble() ??
      0;
  double get taxRate => (product['taxRate'] as num?)?.toDouble() ?? 18.0;
  int get stock => (product['stock'] as num?)?.toInt() ?? 0;
  String? get barcode => product['barcode']?.toString();
  String? get sku => product['sku']?.toString();

  double get lineTotal => unitPrice * quantity;
  double get discountAmount => lineTotal * discount / 100;
  double get afterDiscount => lineTotal - discountAmount;
  double get taxAmount => afterDiscount * taxRate / 100;
  double get totalWithTax => afterDiscount + taxAmount;

  CartItem copyWith({int? quantity, double? discount}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}

// ─── Payment Method ────────────────────────────────────────────────
enum PaymentMethod { cash, creditCard, bankTransfer, mixed }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Nakit';
      case PaymentMethod.creditCard:
        return 'Kredi Kartı';
      case PaymentMethod.bankTransfer:
        return 'Havale/EFT';
      case PaymentMethod.mixed:
        return 'Karma Ödeme';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.mixed:
        return 'mixed';
    }
  }
}

// ─── POS State ─────────────────────────────────────────────────────
class PosState {
  final List<CartItem> cartItems;
  final Map<String, dynamic>? selectedCustomer;
  final PaymentMethod paymentMethod;
  final double cashReceived;
  final double cardAmount;
  final double transferAmount;
  final String? note;
  final bool isSubmitting;
  final String? error;
  final String? successMessage;

  // Product search
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;
  final String searchQuery;
  final bool isLoadingProducts;

  const PosState({
    this.cartItems = const [],
    this.selectedCustomer,
    this.paymentMethod = PaymentMethod.cash,
    this.cashReceived = 0,
    this.cardAmount = 0,
    this.transferAmount = 0,
    this.note,
    this.isSubmitting = false,
    this.error,
    this.successMessage,
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
    this.isLoadingProducts = false,
  });

  // ─── Computed ──────────────────────────────────────────────────
  int get totalItems => cartItems.fold(0, (s, i) => s + i.quantity);

  double get subtotal =>
      cartItems.fold(0.0, (s, i) => s + i.afterDiscount);

  double get totalTax =>
      cartItems.fold(0.0, (s, i) => s + i.taxAmount);

  double get totalDiscount =>
      cartItems.fold(0.0, (s, i) => s + i.discountAmount);

  double get grandTotal =>
      cartItems.fold(0.0, (s, i) => s + i.totalWithTax);

  double get changeAmount {
    if (paymentMethod == PaymentMethod.cash) {
      return (cashReceived - grandTotal).clamp(0, double.infinity);
    }
    if (paymentMethod == PaymentMethod.mixed) {
      final total = cashReceived + cardAmount + transferAmount;
      return (total - grandTotal).clamp(0, double.infinity);
    }
    return 0;
  }

  bool get isPaymentSufficient {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return cashReceived >= grandTotal;
      case PaymentMethod.creditCard:
      case PaymentMethod.bankTransfer:
        return true;
      case PaymentMethod.mixed:
        return (cashReceived + cardAmount + transferAmount) >= grandTotal;
    }
  }

  bool get canSubmit =>
      cartItems.isNotEmpty && isPaymentSufficient && !isSubmitting;

  List<Map<String, dynamic>> get filteredProducts {
    var filtered = List<Map<String, dynamic>>.from(products);

    if (selectedCategoryId != null) {
      filtered = filtered
          .where((p) => p['categoryId']?.toString() == selectedCategoryId.toString())
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return (p['name']?.toString().toLowerCase() ?? '').contains(q) ||
            (p['sku']?.toString().toLowerCase() ?? '').contains(q) ||
            (p['barcode']?.toString().toLowerCase() ?? '').contains(q);
      }).toList();
    }

    return filtered;
  }

  PosState copyWith({
    List<CartItem>? cartItems,
    Map<String, dynamic>? selectedCustomer,
    bool clearCustomer = false,
    PaymentMethod? paymentMethod,
    double? cashReceived,
    double? cardAmount,
    double? transferAmount,
    String? note,
    bool clearNote = false,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    bool? isLoadingProducts,
  }) {
    return PosState(
      cartItems: cartItems ?? this.cartItems,
      selectedCustomer:
          clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReceived: cashReceived ?? this.cashReceived,
      cardAmount: cardAmount ?? this.cardAmount,
      transferAmount: transferAmount ?? this.transferAmount,
      note: clearNote ? null : (note ?? this.note),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
    );
  }
}

// ─── POS Notifier ──────────────────────────────────────────────────
class PosNotifier extends StateNotifier<PosState> {
  PosNotifier(this._ref) : super(const PosState()) {
    _loadProducts();
    _loadCategories();
  }

  final Ref _ref;

  // ─── Data Loading ────────────────────────────────────────────
  Future<void> _loadProducts() async {
    state = state.copyWith(isLoadingProducts: true);
    try {
      final products =
          await _ref.read(productServiceProvider).getProducts(size: 200);
      state = state.copyWith(products: products, isLoadingProducts: false);
    } catch (e) {
      AppLogger.error('Ürünler yüklenemedi', tag: 'POS', error: e);
      state = state.copyWith(isLoadingProducts: false, error: e.toString());
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await _ref.read(categoryServiceProvider).getCategories();
      state = state.copyWith(categories: categories);
    } catch (e) {
      AppLogger.warning('Kategoriler yüklenemedi, devam ediliyor',
          tag: 'POS');
    }
  }

  Future<void> refreshProducts() async {
    await _loadProducts();
  }

  // ─── Search & Filter ─────────────────────────────────────────
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCategory(int? categoryId) {
    if (categoryId == state.selectedCategoryId) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  // ─── Cart Operations ─────────────────────────────────────────
  void addToCart(Map<String, dynamic> product) {
    final items = List<CartItem>.from(state.cartItems);
    final productId = product['id'].toString();
    final index = items.indexWhere((i) => i.productId == productId);

    if (index >= 0) {
      final item = items[index];
      final newQty = item.quantity + 1;
      if (newQty > item.stock && item.stock > 0) {
        state = state.copyWith(error: 'Stok yetersiz! Mevcut: ${item.stock}');
        return;
      }
      items[index] = item.copyWith(quantity: newQty);
    } else {
      items.add(CartItem(product: product));
    }

    state = state.copyWith(cartItems: items, clearError: true);
  }

  void addToCartByBarcode(String barcode) {
    final product = state.products.firstWhere(
      (p) =>
          p['barcode']?.toString() == barcode ||
          p['sku']?.toString() == barcode,
      orElse: () => <String, dynamic>{},
    );

    if (product.isEmpty) {
      state = state.copyWith(error: 'Barkod bulunamadı: $barcode');
      return;
    }

    addToCart(product);
  }

  void removeFromCart(String productId) {
    final items = state.cartItems
        .where((i) => i.productId != productId)
        .toList();
    state = state.copyWith(cartItems: items);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final items = List<CartItem>.from(state.cartItems);
    final index = items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      final item = items[index];
      if (quantity > item.stock && item.stock > 0) {
        state = state.copyWith(error: 'Stok yetersiz! Mevcut: ${item.stock}');
        return;
      }
      items[index] = item.copyWith(quantity: quantity);
      state = state.copyWith(cartItems: items, clearError: true);
    }
  }

  void updateDiscount(String productId, double discount) {
    final items = List<CartItem>.from(state.cartItems);
    final index = items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      items[index] =
          items[index].copyWith(discount: discount.clamp(0, 100));
      state = state.copyWith(cartItems: items);
    }
  }

  void clearCart() {
    state = state.copyWith(
      cartItems: [],
      clearCustomer: true,
      cashReceived: 0,
      cardAmount: 0,
      transferAmount: 0,
      clearNote: true,
      paymentMethod: PaymentMethod.cash,
    );
  }

  // ─── Customer ─────────────────────────────────────────────────
  void selectCustomer(Map<String, dynamic>? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(selectedCustomer: customer);
    }
  }

  // ─── Payment ──────────────────────────────────────────────────
  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method, cashReceived: 0, cardAmount: 0, transferAmount: 0);
  }

  void setCashReceived(double amount) {
    state = state.copyWith(cashReceived: amount);
  }

  void setCardAmount(double amount) {
    state = state.copyWith(cardAmount: amount);
  }

  void setTransferAmount(double amount) {
    state = state.copyWith(transferAmount: amount);
  }

  void setNote(String? note) {
    if (note == null || note.isEmpty) {
      state = state.copyWith(clearNote: true);
    } else {
      state = state.copyWith(note: note);
    }
  }

  // ─── Submit Sale ──────────────────────────────────────────────
  Future<bool> submitSale() async {
    if (!state.canSubmit) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final saleData = _buildSalePayload();
      await _ref.read(salesServiceProvider).createSale(saleData);

      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Satış başarıyla tamamlandı!',
      );

      // Satış sonrası sepeti temizle
      clearCart();
      // Stok güncellemesi için ürünleri yeniden yükle
      _loadProducts();

      return true;
    } catch (e) {
      AppLogger.error('Satış kaydedilemedi', tag: 'POS', error: e);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Satış kaydedilemedi: $e',
      );
      return false;
    }
  }

  Map<String, dynamic> _buildSalePayload() {
    // Otomatik satış numarası: SLS-yyyyMMdd-HHmmss
    final now = DateTime.now();
    final saleNumber =
        'SLS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    // İlk ürünün depo/mağaza bilgisini varsayılan olarak al
    final firstItem = state.cartItems.first;
    final defaultWarehouseId =
        firstItem.product['warehouseId']?.toString() ?? '';
    final defaultStoreId =
        firstItem.product['storeId']?.toString() ?? '';

    return {
      // Backend zorunlu alanlar
      'saleNumber': saleNumber,
      'storeId': defaultStoreId,
      'warehouseId': defaultWarehouseId,
      'paidAmount': state.grandTotal,
      'customerId': state.selectedCustomer?['id']?.toString(),
      'paymentMethod': state.paymentMethod.apiValue,
      'notes': state.note,
      'items': state.cartItems.map((item) {
        return {
          'variantId': item.variantId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discountRate': item.discount,
          'notes': '',
        };
      }).toList(),
    };
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ─── Provider ──────────────────────────────────────────────────────
final posProvider = StateNotifierProvider.autoDispose<PosNotifier, PosState>(
  (ref) => PosNotifier(ref),
);
