import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/service_locator.dart';
import '../../../core/utils/app_logger.dart';

// ─── Parked Order Model ────────────────────────────────────────────
class ParkedOrder {
  final List<CartItem> items;
  final Map<String, dynamic>? customer;
  final DateTime parkedAt;
  final String? label;
  final double total;

  ParkedOrder({
    required this.items,
    this.customer,
    required this.parkedAt,
    this.label,
    required this.total,
  });

  String get displayLabel => label ?? 'Sipariş #${parkedAt.millisecondsSinceEpoch ~/ 1000}';

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(parkedAt);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s önce';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}dk önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}s önce';
    } else {
      return '${diff.inDays}g önce';
    }
  }
}

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
      case PaymentMethod.cash: return 'Nakit';
      case PaymentMethod.creditCard: return 'Kredi Kartı';
      case PaymentMethod.bankTransfer: return 'Havale/EFT';
      case PaymentMethod.mixed: return 'Karma Ödeme';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethod.cash: return 'cash';
      case PaymentMethod.creditCard: return 'credit_card';
      case PaymentMethod.bankTransfer: return 'bank_transfer';
      case PaymentMethod.mixed: return 'mixed';
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

  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;
  final String searchQuery;
  final bool isLoadingProducts;

  final List<ParkedOrder> parkedOrders;
  final String? lastSaleId;
  final Map<String, dynamic>? lastSaleData;

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
    this.parkedOrders = const [],
    this.lastSaleId,
    this.lastSaleData,
  });

  int get totalItems => cartItems.fold(0, (s, i) => s + i.quantity);
  double get subtotal => cartItems.fold(0.0, (s, i) => s + i.afterDiscount);
  double get totalTax => cartItems.fold(0.0, (s, i) => s + i.taxAmount);
  double get totalDiscount => cartItems.fold(0.0, (s, i) => s + i.discountAmount);
  double get grandTotal => cartItems.fold(0.0, (s, i) => s + i.totalWithTax);

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
      case PaymentMethod.cash: return cashReceived >= grandTotal;
      case PaymentMethod.creditCard:
      case PaymentMethod.bankTransfer: return true;
      case PaymentMethod.mixed: return (cashReceived + cardAmount + transferAmount) >= grandTotal;
    }
  }

  bool get canSubmit => cartItems.isNotEmpty && isPaymentSufficient && !isSubmitting;

  List<Map<String, dynamic>> get filteredProducts {
    var filtered = List<Map<String, dynamic>>.from(products);
    if (selectedCategoryId != null) {
      filtered = filtered.where((p) => p['categoryId']?.toString() == selectedCategoryId.toString()).toList();
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
    List<ParkedOrder>? parkedOrders,
    String? lastSaleId,
    bool clearLastSale = false,
    Map<String, dynamic>? lastSaleData,
  }) {
    return PosState(
      cartItems: cartItems ?? this.cartItems,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReceived: cashReceived ?? this.cashReceived,
      cardAmount: cardAmount ?? this.cardAmount,
      transferAmount: transferAmount ?? this.transferAmount,
      note: clearNote ? null : (note ?? this.note),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      parkedOrders: parkedOrders ?? this.parkedOrders,
      lastSaleId: clearLastSale ? null : (lastSaleId ?? this.lastSaleId),
      lastSaleData: clearLastSale ? null : (lastSaleData ?? this.lastSaleData),
    );
  }
}

class PosNotifier extends StateNotifier<PosState> {
  PosNotifier(this._ref) : super(const PosState()) {
    _loadInitialData();
  }

  final Ref _ref;

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoadingProducts: true);
    try {
      final results = await Future.wait([
        _ref.read(productServiceProvider).getProducts(size: 100),
        _ref.read(categoryServiceProvider).getCategories(),
      ]);
      state = state.copyWith(
        products: results[0] as List<Map<String, dynamic>>,
        categories: results[1] as List<Map<String, dynamic>>,
        isLoadingProducts: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingProducts: false, error: e.toString());
    }
  }

  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    if (query.length >= 3) {
      try {
        final apiProducts = await _ref.read(productServiceProvider).getProducts(search: query, size: 50);
        final List<Map<String, dynamic>> updatedProducts = List.from(state.products);
        for (var apiP in apiProducts) {
          if (!updatedProducts.any((p) => p['id'] == apiP['id'])) {
            updatedProducts.add(apiP);
          }
        }
        state = state.copyWith(products: updatedProducts);
      } catch (e) {
        AppLogger.error('API arama hatası', tag: 'POS', error: e);
      }
    }
  }

  void addToCart(Map<String, dynamic> product, {Map<String, dynamic>? variant}) {
    // Use variant if provided, otherwise use product
    final productData = variant ?? product;
    final stock = (productData['stock'] as num?)?.toInt() ?? 0;
    final items = List<CartItem>.from(state.cartItems);
    final productId = product['id'].toString();
    final variantId = variant?['id']?.toString() ?? productId;

    // Check if product/variant is already in cart
    final index = items.indexWhere((i) => i.variantId == variantId);

    if (index >= 0) {
      final currentQty = items[index].quantity;
      final newQty = currentQty + 1;

      // Check if new quantity exceeds stock
      if (newQty > stock) {
        state = state.copyWith(error: 'Stok yetersiz! Mevcut stok: $stock');
        return;
      }
      items[index] = items[index].copyWith(quantity: newQty);
    } else {
      // Check if stock is available for new item
      if (stock <= 0) {
        state = state.copyWith(error: 'Ürün stokta yok!');
        return;
      }
      items.add(CartItem(product: productData));
    }
    state = state.copyWith(cartItems: items, clearError: true);
  }

  Future<void> addToCartByBarcode(String barcode) async {
    final products = state.products;
    final found = products.firstWhere(
      (p) => p['barcode']?.toString() == barcode || p['sku']?.toString() == barcode,
      orElse: () => {},
    );
    if (found.isNotEmpty) {
      final variants = found['variants'] as List? ?? [];
      if (variants.length > 1) {
        // Multiple variants - cannot auto-add by barcode
        state = state.copyWith(error: 'Ürün birden fazla varyanta sahip. Lütfen manuel olarak seçin.');
      } else if (variants.length == 1) {
        addToCart(found, variant: variants[0]);
      } else {
        addToCart(found);
      }
    } else {
      // Barcode ile ürün bulunamadı — API'den ara
      try {
        final product = await _ref.read(productServiceProvider).getProducts(search: barcode);
        if (product.isNotEmpty) {
          final variants = product.first['variants'] as List? ?? [];
          if (variants.length > 1) {
            state = state.copyWith(error: 'Ürün birden fazla varyanta sahip. Lütfen manuel olarak seçin.');
          } else if (variants.length == 1) {
            addToCart(product.first, variant: variants[0]);
          } else {
            addToCart(product.first);
          }
          // Cache ürünü listeye ekle
          state = state.copyWith(products: [...state.products, product.first]);
        } else {
          state = state.copyWith(error: 'Barkod bulunamadı: $barcode');
        }
      } catch (e) {
        state = state.copyWith(error: 'Barkod arama hatası: $e');
      }
    }
  }

  void removeFromCart(String productId) {
    state = state.copyWith(cartItems: state.cartItems.where((i) => i.productId != productId).toList());
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
      final stock = item.stock;

      // Check if quantity exceeds available stock
      if (quantity > stock) {
        state = state.copyWith(error: 'Stok yetersiz! Mevcut stok: $stock');
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
      items[index] = items[index].copyWith(discount: discount.clamp(0, 100));
      state = state.copyWith(cartItems: items);
    }
  }

  void clearCart() {
    state = state.copyWith(cartItems: [], clearCustomer: true, cashReceived: 0, cardAmount: 0, transferAmount: 0, clearNote: true, paymentMethod: PaymentMethod.cash);
  }

  void selectCustomer(Map<String, dynamic>? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(selectedCustomer: customer);
    }
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setCashReceived(double amount) => state = state.copyWith(cashReceived: amount);
  void setCardAmount(double amount) => state = state.copyWith(cardAmount: amount);
  void setTransferAmount(double amount) => state = state.copyWith(transferAmount: amount);
  void setNote(String? note) => note == null || note.isEmpty ? state.copyWith(clearNote: true) : state.copyWith(note: note);

  Future<bool> submitSale() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      // Capture sale summary before clearing cart
      final saleSummary = {
        'customer': state.selectedCustomer,
        'paymentMethod': state.paymentMethod.label,
        'paymentMethodApi': state.paymentMethod.apiValue,
        'subtotal': state.subtotal,
        'totalDiscount': state.totalDiscount,
        'totalTax': state.totalTax,
        'grandTotal': state.grandTotal,
        'cashReceived': state.cashReceived,
        'changeAmount': state.changeAmount,
        'note': state.note,
        'items': state.cartItems.map((item) => {
          'name': item.name,
          'variantId': item.variantId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discountRate': item.discount,
          'lineTotal': item.totalWithTax,
          'sku': item.sku,
          'barcode': item.barcode,
        }).toList(),
        'totalItems': state.totalItems,
        'saleDate': DateTime.now().toIso8601String(),
      };

      final saleData = {
        'paidAmount': state.grandTotal,
        'customerId': state.selectedCustomer?['id']?.toString(),
        'paymentMethod': state.paymentMethod.apiValue,
        'notes': state.note,
        'items': state.cartItems.map((item) => {
          'variantId': item.variantId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discountRate': item.discount,
        }).toList(),
      };
      final result = await _ref.read(salesServiceProvider).createSale(saleData);
      final saleId = result['id']?.toString() ?? result['_id']?.toString();

      saleSummary['saleId'] = saleId;
      saleSummary['saleNumber'] = result['saleNumber']?.toString() ?? saleId;

      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Satış tamamlandı!',
        lastSaleId: saleId,
        lastSaleData: saleSummary,
      );
      clearCart();
      _loadInitialData();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> printLastReceipt() async {
    final saleId = state.lastSaleId;
    if (saleId == null) return false;
    try {
      await _ref.read(salesServiceProvider).printReceipt(saleId);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Fiş yazdırılamadı: $e');
      return false;
    }
  }

  void selectCategory(int? categoryId) {
    if (categoryId == state.selectedCategoryId) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  Future<void> refreshProducts() async => _loadInitialData();
  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);

  // ─── Parked Orders Methods ─────────────────────────────────────
  void parkCurrentOrder({String? label}) {
    if (state.cartItems.isEmpty) {
      state = state.copyWith(error: 'Sepet boş, park edilecek sipariş yok');
      return;
    }

    final parkedOrder = ParkedOrder(
      items: List<CartItem>.from(state.cartItems),
      customer: state.selectedCustomer,
      parkedAt: DateTime.now(),
      label: label,
      total: state.grandTotal,
    );

    final updatedParked = List<ParkedOrder>.from(state.parkedOrders);
    updatedParked.add(parkedOrder);

    state = state.copyWith(
      parkedOrders: updatedParked,
      clearError: true,
      successMessage: '${label ?? "Sipariş"} park edildi!',
    );

    clearCart();
  }

  void restoreParkedOrder(int index) {
    if (index < 0 || index >= state.parkedOrders.length) return;

    final parked = state.parkedOrders[index];

    state = state.copyWith(
      cartItems: List<CartItem>.from(parked.items),
      selectedCustomer: parked.customer,
      clearError: true,
    );

    // Remove from parked
    final updated = List<ParkedOrder>.from(state.parkedOrders);
    updated.removeAt(index);
    state = state.copyWith(parkedOrders: updated);
  }

  void deleteParkedOrder(int index) {
    if (index < 0 || index >= state.parkedOrders.length) return;

    final updated = List<ParkedOrder>.from(state.parkedOrders);
    updated.removeAt(index);
    state = state.copyWith(parkedOrders: updated);
  }
}

final posProvider = StateNotifierProvider.autoDispose<PosNotifier, PosState>((ref) => PosNotifier(ref));
