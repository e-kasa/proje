import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/app_logger.dart';
import 'package:project_pos/providers/auth_provider.dart';

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

  String get productId => product['productId']?.toString() ?? product['id'].toString();
  String get variantId => product['variantId']?.toString() ?? product['id'].toString();
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
  final String? selectedCategoryId;
  final String searchQuery;
  final bool isLoadingProducts;

  final List<ParkedOrder> parkedOrders;
  final String? lastSaleId;
  final Map<String, dynamic>? lastSaleData;

  /// Çapraz lokasyon stok uyarısı — null değilse PosScreen dialog gösterir.
  /// İçerik: {product, variant, productName, otherLocations}
  final Map<String, dynamic>? crossLocationAlert;

  /// Aktif lokasyon ID'si (Store.code veya Warehouse.code) — JWT'den veya kullanıcı seçiminden gelir.
  /// null ise PosScreen lokasyon seçici gösterir.
  final String? activeLocationId;

  /// Aktif lokasyon tipi: 'STORE' veya 'WAREHOUSE' — varsayılan 'STORE'
  final String activeLocationType;

  /// Ürünlerin inventories'inden çıkarılan benzersiz lokasyon listesi
  final List<String> availableLocationIds;

  /// ─── RECOMMENDATION SYSTEM ───
  /// Önerilecek ürünler (Hybrid: Frequently Bought Together + Similar Products)
  final List<Map<String, dynamic>> recommendations;

  /// Önerileri yükleniyor mu?
  final bool isLoadingRecommendations;

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
    this.crossLocationAlert,
    this.activeLocationId,
    this.activeLocationType = 'STORE',
    this.availableLocationIds = const [],
    this.recommendations = const [],
    this.isLoadingRecommendations = false,
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
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    bool? isLoadingProducts,
    List<ParkedOrder>? parkedOrders,
    String? lastSaleId,
    bool clearLastSale = false,
    Map<String, dynamic>? lastSaleData,
    Map<String, dynamic>? crossLocationAlert,
    bool clearCrossLocationAlert = false,
    String? activeLocationId,
    bool clearActiveLocationId = false,
    String? activeLocationType,
    List<String>? availableLocationIds,
    List<Map<String, dynamic>>? recommendations,
    bool? isLoadingRecommendations,
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
      crossLocationAlert: clearCrossLocationAlert
          ? null
          : (crossLocationAlert ?? this.crossLocationAlert),
      activeLocationId: clearActiveLocationId ? null : (activeLocationId ?? this.activeLocationId),
      activeLocationType: activeLocationType ?? this.activeLocationType,
      availableLocationIds: availableLocationIds ?? this.availableLocationIds,
      recommendations: recommendations ?? this.recommendations,
      isLoadingRecommendations: isLoadingRecommendations ?? this.isLoadingRecommendations,
    );
  }
}

class PosNotifier extends StateNotifier<PosState> {
  PosNotifier(this._ref) : super(const PosState()) {
    _loadInitialData();
  }

  final Ref _ref;
  int _recommendationToken = 0;

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoadingProducts: true);
    try {
      final products = await _ref.read(productServiceProvider).getProducts(size: 100);
      final rawCats = await _ref.read(companyCategoryServiceProvider).getMyCategoryList();
      // Firma kategorilerini id/name formatına normalize et
      final categories = rawCats.map((c) => <String, dynamic>{
        'id': c['categoryId']?.toString() ?? '',
        'name': c['categoryName']?.toString() ?? '',
        'level': c['categoryLevel'] ?? 0,
        'parentId': c['categoryParentId']?.toString(),
      }).toList();

      // Ürünlerin inventories'inden benzersiz lokasyon ID'lerini çıkar
      final locationIdSet = <String>{};
      for (final p in products) {
        for (final v in (p['variants'] as List?)?.cast<Map<String, dynamic>>() ?? []) {
          for (final inv in (v['inventories'] as List?)?.cast<Map<String, dynamic>>() ?? []) {
            final lid = inv['locationId'] as String?;
            if (lid != null && lid.isNotEmpty) locationIdSet.add(lid);
          }
        }
      }
      final availableLocations = locationIdSet.toList()..sort();

      // Lokasyon bazlı stok normalizasyonu:
      //   1. JWT'den gelen storeId (kasiyer kendi mağazasına atanmış)
      //   2. Mevcut activeLocationId (kullanıcı daha önce seçtiyse)
      //   3. Tek lokasyon varsa otomatik seç
      final jwtStoreId = _ref.read(authProvider).user?.storeId;
      final currentLocationId = state.activeLocationId;
      String? effectiveLocationId = jwtStoreId?.isNotEmpty == true
          ? jwtStoreId
          : (currentLocationId?.isNotEmpty == true
              ? currentLocationId
              : (availableLocations.length == 1 ? availableLocations.first : null));

      final normalizedProducts = (effectiveLocationId != null && effectiveLocationId.isNotEmpty)
          ? products.map((p) => _normalizeProductStock(p, effectiveLocationId)).toList()
          : products;

      state = state.copyWith(
        products: normalizedProducts,
        categories: categories,
        isLoadingProducts: false,
        activeLocationId: effectiveLocationId,
        availableLocationIds: availableLocations,
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

  void addToCart(Map<String, dynamic> product,
      {Map<String, dynamic>? variant, bool forceAdd = false}) {
    final items = List<CartItem>.from(state.cartItems);
    final productId = product['id']?.toString() ?? '';

    // Varyant ID: açık variant > product.variantId > productId
    final variantId = variant?['id']?.toString()
        ?? product['variantId']?.toString()
        ?? productId;

    // Toplam stok (tüm lokasyonlar — sepet miktarı sınırı için)
    final totalStock = variant != null
        ? _variantStock(variant)
        : (product['stock'] as num?)?.toInt() ?? 0;

    // Kendi mağaza stoğu (PosNotifier normalize ettiyse kullan, forceAdd ise atla)
    final myStoreStock = forceAdd
        ? totalStock
        : (variant != null
            ? (variant['myStoreStock'] as num?)?.toInt() ?? totalStock
            : (product['myStoreStock'] as num?)?.toInt() ?? totalStock);

    // Sepette aynı varyant var mı?
    final index = items.indexWhere((i) => i.variantId == variantId);

    if (index >= 0) {
      final currentQty = items[index].quantity;
      final newQty = currentQty + 1;
      if (newQty > totalStock && totalStock > 0) {
        state = state.copyWith(error: 'Stok yetersiz! Toplam stok: $totalStock');
        return;
      }
      items[index] = items[index].copyWith(quantity: newQty);
    } else {
      if (myStoreStock <= 0) {
        // Başka lokasyonda stok var mı?
        final availableElsewhere = variant != null
            ? variant['availableElsewhere'] == true
            : product['availableElsewhere'] == true;

        if (!forceAdd && availableElsewhere) {
          final otherLocations = ((variant != null
                      ? variant['otherLocations']
                      : product['otherLocations']) as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          state = state.copyWith(
            crossLocationAlert: {
              'product': product,
              'variant': variant,
              'productName': variant?['name']?.toString() ??
                  product['name']?.toString() ?? '',
              'otherLocations': otherLocations,
            },
          );
        } else {
          state = state.copyWith(error: 'Ürün stokta yok!');
        }
        return;
      }

      // Product + variant verilerini birleştir
      final basePrice = (product['basePrice'] as num?)?.toDouble()
          ?? (product['sellingPrice'] as num?)?.toDouble()
          ?? 0.0;
      final additionalPrice = variant != null
          ? (variant['additionalPrice'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      final finalPrice = basePrice + additionalPrice;

      final productData = <String, dynamic>{
        ...product,
        'id': variantId,              // sepet tekliği için variantId kullan
        'productId': productId,       // orijinal product ID (öneri sistemi için)
        'variantId': variantId,
        'sku': variant?['sku'] ?? product['sku'],
        'name': variant?['name'] ?? product['name'],
        'basePrice': finalPrice,
        'sellingPrice': finalPrice,
        'price': finalPrice,
        'stock': forceAdd ? totalStock : myStoreStock,
        'taxRate': product['taxRate'] ?? 18.0,
      };

      items.add(CartItem(product: productData));
    }
    state = state.copyWith(
        cartItems: items, clearError: true, clearCrossLocationAlert: true);
    loadRecommendations();
  }

  /// Lokasyon bazlı stok normalizasyonu — her varyanta myLocationStock/availableElsewhere ekler
  Map<String, dynamic> _normalizeProductStock(
      Map<String, dynamic> product, String locationId) {
    final variants =
        (product['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final updatedVariants = variants.map((v) {
      final vInventories =
          (v['inventories'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      int myStoreStock;
      bool availableElsewhere = false;
      List<Map<String, dynamic>> otherLocations = [];

      if (vInventories.isNotEmpty) {
        // Aktif lokasyonun stoğu
        myStoreStock = vInventories
            .where((inv) => inv['locationId'] == locationId)
            .fold(0,
                (sum, inv) => sum + ((inv['physicalQuantity'] as num?)?.toInt() ?? 0));
        // Diğer lokasyonlar (stoku > 0 olanlar)
        otherLocations = vInventories
            .where((inv) =>
                inv['locationId'] != locationId &&
                ((inv['physicalQuantity'] as num?)?.toInt() ?? 0) > 0)
            .toList();
        availableElsewhere = myStoreStock <= 0 && otherLocations.isNotEmpty;
      } else {
        myStoreStock = (v['stock'] as num?)?.toInt() ?? 0;
      }

      return <String, dynamic>{
        ...v,
        'myStoreStock': myStoreStock,
        'availableElsewhere': availableElsewhere,
        'otherLocations': otherLocations,
      };
    }).toList();

    // Ürün düzeyinde: tüm varyantların kendi mağaza stoku toplamı
    final totalMyStoreStock = updatedVariants.fold<int>(
        0, (sum, v) => sum + ((v['myStoreStock'] as num?)?.toInt() ?? 0));
    final anyAvailableElsewhere =
        updatedVariants.any((v) => v['availableElsewhere'] == true);
    final allOtherLocations = updatedVariants.length == 1
        ? (updatedVariants.first['otherLocations'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            []
        : <Map<String, dynamic>>[];

    return <String, dynamic>{
      ...product,
      'variants': updatedVariants,
      'myStoreStock': totalMyStoreStock,
      'availableElsewhere': anyAvailableElsewhere,
      'otherLocations': allOtherLocations,
    };
  }

  void clearCrossLocationAlert() {
    state = state.copyWith(clearCrossLocationAlert: true);
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
    state = state.copyWith(cartItems: state.cartItems.where((i) => i.variantId != productId).toList());
    loadRecommendations();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final items = List<CartItem>.from(state.cartItems);
    final index = items.indexWhere((i) => i.variantId == productId);
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
    state = state.copyWith(cartItems: [], clearCustomer: true, cashReceived: 0, cardAmount: 0, transferAmount: 0, clearNote: true, paymentMethod: PaymentMethod.cash, recommendations: []);
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
  void setNote(String? note) => state = note == null || note.isEmpty ? state.copyWith(clearNote: true) : state.copyWith(note: note);

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
        if (state.activeLocationId != null && state.activeLocationId!.isNotEmpty)
          'locationId': state.activeLocationId,
        if (state.activeLocationId != null && state.activeLocationId!.isNotEmpty)
          'locationType': state.activeLocationType,
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

  void selectCategory(String? categoryId) {
    if (categoryId == state.selectedCategoryId) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  Future<void> refreshProducts() async => _loadInitialData();

  /// Variant haritasından stok miktarını çıkarır.
  int _variantStock(Map<String, dynamic> variant) {
    final inv = variant['inventory'] as Map<String, dynamic>?;
    if (inv != null) {
      return (inv['physicalQuantity'] as num?)?.toInt() ?? 0;
    }
    return (variant['stock'] as num?)?.toInt() ?? 0;
  }
  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);

  /// Aktif lokasyonu değiştirir ve tüm ürünlerin stok bilgisini yeniden normalize eder.
  void setActiveLocation(String locationId, {String locationType = 'STORE'}) {
    if (locationId.isEmpty) return;
    final normalizedProducts = state.products.isNotEmpty
        ? state.products.map((p) => _normalizeProductStock(p, locationId)).toList()
        : state.products;
    state = state.copyWith(
      activeLocationId: locationId,
      activeLocationType: locationType,
      products: normalizedProducts,
    );
  }

  /// Geriye dönük uyumluluk — eski çağrılar için
  void setActiveStore(String storeId) => setActiveLocation(storeId, locationType: 'STORE');

  // ─── Recommendation System Methods ──────────────────────────────
  /// Sepetteki ürünlere göre akıllı öneriler yükle
  /// (Frequently Bought Together + Similar Products)
  Future<void> loadRecommendations() async {
    if (state.cartItems.isEmpty) {
      state = state.copyWith(recommendations: [], isLoadingRecommendations: false);
      return;
    }

    // Debounce: her çağrıda token artar, await sonrasında eski çağrılar iptal olur
    final token = ++_recommendationToken;

    state = state.copyWith(isLoadingRecommendations: true);
    try {
      final productIds = state.cartItems
          .map((item) => item.productId)
          .toSet().toList(); // dedupe

      final variantIds = state.cartItems
          .map((item) => item.variantId)
          .toSet().toList(); // dedupe

      final recommendations = await _ref.read(recommendationServiceProvider)
          .getHybridRecommendations(
            productIds: productIds,
            variantIds: variantIds,
            limit: 6,
            excludeIds: productIds,
          );

      // Eski çağrıysa (aradan yeni çağrı geldiyse) sonucu yok say
      if (token != _recommendationToken) return;

      state = state.copyWith(
        recommendations: recommendations,
        isLoadingRecommendations: false,
      );
    } catch (e) {
      if (token != _recommendationToken) return;
      state = state.copyWith(isLoadingRecommendations: false);
    }
  }

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
