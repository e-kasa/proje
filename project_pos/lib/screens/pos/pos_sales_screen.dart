import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_aware_gradient.dart';
import '../../core/utils/app_logger.dart';
import '../../providers/theme_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/service_locator.dart';
import '../../core/widgets/widgets.dart';

class PosSalesScreen extends ConsumerStatefulWidget {
  const PosSalesScreen({super.key});

  @override
  ConsumerState<PosSalesScreen> createState() => _PosSalesScreenState();
}

class _PosSalesScreenState extends ConsumerState<PosSalesScreen> {
  final _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<CartItem> _cartItems = [];
  Map<String, dynamic>? _selectedCustomer;

  int? _selectedCategoryId;
  bool _isLoading = true;
  String _paymentMethod = 'cash';
  String _orderNumber = '';

  @override
  void initState() {
    super.initState();
    _orderNumber = 'ORD${DateTime.now().millisecondsSinceEpoch % 1000}';
    _loadData();
  }

  Future<void> _loadData() async {
    AppLogger.debug('POS: Veri yukleniyor...', tag: 'POS');

    try {
      final productService = ref.read(productServiceProvider);
      final categoryService = ref.read(categoryServiceProvider);

      final results = await Future.wait([
        categoryService.getCategories(),
        productService.getProducts(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0];
          _allProducts = results[1];
          _filteredProducts = results[1];
          _isLoading = false;
        });

        AppLogger.debug('POS: ${_categories.length} kategori, ${_allProducts.length} urun yuklendi', tag: 'POS');
      }
    } catch (e) {
      AppLogger.error('POS: Veri yuklenemedi: $e', tag: 'POS');
      if (mounted) {
        setState(() {
          _categories = [];
          _allProducts = [];
          _filteredProducts = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veri yuklenemedi'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _filterProducts() {
    var filtered = _allProducts;

    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((p) => p['categoryId'] == _selectedCategoryId)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        return p['name'].toLowerCase().contains(query) ||
            (p['sku']?.toLowerCase() ?? '').contains(query) ||
            (p['barcode']?.toLowerCase() ?? '').contains(query);
      }).toList();
    }

    setState(() => _filteredProducts = filtered);
  }

  void _addToCart(Map<String, dynamic> product) {
    final existingIndex =
        _cartItems.indexWhere((item) => item.product['id'] == product['id']);

    if (existingIndex >= 0) {
      final currentQty = _cartItems[existingIndex].quantity;
      final stock = product['stock'] as int;

      if (currentQty < stock) {
        setState(() {
          _cartItems[existingIndex] = CartItem(
            product: product,
            quantity: currentQty + 1,
          );
        });
      } else {
        _showSnackbar('⚠️ Stok yetersiz', AppColors.warning);
      }
    } else {
      setState(() {
        _cartItems.add(CartItem(product: product, quantity: 1));
      });
    }
  }

  void _updateCartItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
      return;
    }

    final stock = _cartItems[index].product['stock'] as int;
    if (newQuantity > stock) {
      _showSnackbar('⚠️ Stok yetersiz', AppColors.warning);
      return;
    }

    setState(() {
      _cartItems[index] = CartItem(
        product: _cartItems[index].product,
        quantity: newQuantity,
      );
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cartItems.removeAt(index));
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _selectedCustomer = null;
    });
  }

  double get _subtotal {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item.product['sellingPrice'] as double;
      return sum + (price * item.quantity);
    });
  }

  double get _taxAmount {
    return _cartItems.fold(0.0, (sum, item) {
      final price = item.product['sellingPrice'] as double;
      final taxRate = (item.product['taxRate'] as double?) ?? 0.0;
      return sum + (price * item.quantity * taxRate / 100);
    });
  }

  double get _total => _subtotal + _taxAmount;

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _completeSale() async {
    if (_cartItems.isEmpty) {
      _showSnackbar('Sepet bos', AppColors.danger);
      return;
    }

    try {
      final salesService = ref.read(salesServiceProvider);
      final saleData = {
        'items': _cartItems.map((item) => {
          'productId': item.product['id'],
          'quantity': item.quantity,
          'price': item.product['sellingPrice'],
        }).toList(),
        'paymentMethod': _paymentMethod,
        'customerId': _selectedCustomer?['id'],
        'orderNumber': _orderNumber,
      };

      final result = await salesService.createSale(saleData);
      final saleNumber = result['saleNumber'] ?? 'SAL-${DateTime.now().millisecondsSinceEpoch}';

      if (mounted) {
        _showReceiptDialog(saleNumber);
        _clearCart();
        _loadData(); // Refresh products from server
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Satis tamamlanamadi', AppColors.danger);
      }
    }
  }

  void _showReceiptDialog(String saleNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 12),
            Text('Satış Tamamlandı'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Satış No: $saleNumber',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '₺${_total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ödeme: ${_getPaymentMethodLabel()}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text(
              'Yazdır',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel() {
    switch (_paymentMethod) {
      case 'cash':
        return 'Nakit';
      case 'card':
        return 'Kredi Kartı';
      case 'transfer':
        return 'Havale';
      default:
        return _paymentMethod;
    }
  }

  Future<void> _selectCustomer() async {
    List<Map<String, dynamic>> customers = [];
    try {
      final customerService = ref.read(customerServiceProvider);
      customers = await customerService.getCustomers();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Musteriler yuklenemedi', AppColors.danger);
      }
      return;
    }

    if (!mounted) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Musteri Sec'),
        content: SizedBox(
          width: double.maxFinite,
          child: customers.isEmpty
              ? const Center(child: Text('Musteri bulunamadi'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(customer['name'].toString()[0].toUpperCase()),
                      ),
                      title: Text(customer['name'].toString()),
                      subtitle: Text(customer['phone']?.toString() ?? ''),
                      onTap: () => Navigator.pop(context, customer),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() => _selectedCustomer = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aynı menüye ikinci tıklanınca veriyi yenile
    ref.listen(navigationRefreshProvider, (prev, next) {
      if (next.route == '/pos') _loadData();
    });

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // SOL PANEL - ÜRÜNLER
                Expanded(
                  flex: 8,
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildCategorySlider(),
                      _buildSearchBar(),
                      Expanded(child: _buildProductGrid()),
                    ],
                  ),
                ),

                // SAĞ PANEL - SİPARİŞ
                SizedBox(
                  width: 400,
                  child: _buildOrderPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    // Basit tarih formatı - locale initialization gerektirmez
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final formattedDate = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hoşgeldiniz, Admin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.local_offer, size: 18),
            label: const Text('Markalar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.star, size: 18),
            label: const Text('Öne Çıkanlar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ref.watch(themeProvider).primaryColor.color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySlider() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryItem(
              'Tümü',
              Icons.apps,
              null,
              AppColors.primary,
            );
          }

          final category = _categories[index - 1];
          final colorValue = int.tryParse(
                  category['color']?.replaceFirst('#', '0xFF') ?? '0xFF2196F3') ??
              0xFF2196F3;

          return _buildCategoryItem(
            category['name'],
            _getCategoryIcon(category['icon']),
            category['id'],
            Color(colorValue),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(String name, IconData icon, int? categoryId, Color color) {
    final isSelected = _selectedCategoryId == categoryId;
    final gradient = ThemeAwareGradient.primary(ref);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryId = categoryId);
        _filterProducts();
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => _filterProducts(),
          decoration: InputDecoration(
            hintText: 'Ürün ara (isim, barkod, SKU...)',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                    onPressed: () {
                      _searchController.clear();
                      _filterProducts();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Ürün bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final isInCart =
            _cartItems.any((item) => item.product['id'] == product['id']);
        return _buildProductCard(product, isInCart);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isInCart) {
    final price = product['sellingPrice'] as double;
    final stock = product['stock'] as int;
    final cartItem =
        _cartItems.firstWhere((item) => item.product['id'] == product['id'],
            orElse: () => CartItem(product: product, quantity: 0));
    final primaryColor = ref.watch(themeProvider).primaryColor.color;

    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isInCart ? primaryColor : AppColors.border,
            width: isInCart ? 2 : 1,
          ),
          boxShadow: isInCart
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                ),
                if (isInCart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['categoryName'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '₺${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        if (cartItem.quantity > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${cartItem.quantity} adet',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$stock',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOrderHeader(),
          _buildCustomerSection(),
          Expanded(child: _buildOrderList()),
          _buildOrderSummary(),
          _buildPaymentMethods(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    final gradient = ThemeAwareGradient.primary(ref);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: gradient),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sipariş Listesi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '#$_orderNumber',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _clearCart,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Müşteri Bilgileri',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectCustomer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCustomer != null
                                ? _selectedCustomer!['name']
                                : 'Müşteri Seçin',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedCustomer != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_cartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'Sepet Boş',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ürün eklemek için\nürüne tıklayın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final product = item.product;
        final price = product['sellingPrice'] as double;
        final total = price * item.quantity;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₺${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeFromCart(index),
                    color: AppColors.danger,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () =>
                              _updateCartItemQuantity(index, item.quantity - 1),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.remove, size: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              _updateCartItemQuantity(index, item.quantity + 1),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.add, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₺${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Özeti',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Ara Toplam', _subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('KDV', _taxAmount),
          const Divider(height: 24),
          Row(
            children: [
              const Text(
                'TOPLAM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '₺${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          '₺${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Yöntemi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child:
                    _buildPaymentMethodButton('cash', 'Nakit', Icons.money),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentMethodButton(
                    'card', 'Kart', Icons.credit_card),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentMethodButton(
                    'transfer', 'Havale', Icons.account_balance),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(
      String method, String label, IconData icon) {
    final isSelected = _paymentMethod == method;
    final primaryColor = ref.watch(themeProvider).primaryColor.color;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.print),
              label: const Text('Yazdır'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.textSecondary),
              