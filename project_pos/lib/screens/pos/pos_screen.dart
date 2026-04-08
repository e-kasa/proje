import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'providers/pos_provider.dart';
import 'widgets/product_grid_item.dart';
import 'widgets/cart_panel.dart';
import 'widgets/payment_panel.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/variant_selection_dialog.dart';
import 'widgets/parked_orders_panel.dart';
import 'widgets/out_of_stock_location_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) => MediaQuery.of(context).size.width > 900;

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final posState = ref.read(posProvider);
    final posNotifier = ref.read(posProvider.notifier);

    // F1 or Ctrl+P: Open Payment
    if (event.logicalKey == LogicalKeyboardKey.f1 ||
        (HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyP)) {
      if (posState.cartItems.isNotEmpty) {
        _showPaymentDialog(context);
      }
      return;
    }

    // F2: Open Customer picker
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      // This will be triggered from cart panel instead
      return;
    }

    // F5: Refresh products
    if (event.logicalKey == LogicalKeyboardKey.f5) {
      posNotifier.refreshProducts();
      return;
    }

    // Escape: Clear search / Close dialogs
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        posNotifier.setSearchQuery('');
      }
      return;
    }

    // Ctrl+Delete: Clear cart
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.delete) {
      if (posState.cartItems.isNotEmpty) {
        _confirmClearCart();
      }
      return;
    }
  }

  void _confirmClearCart() {
    final t = i18nOf(ref);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('pos.clear_cart')),
        content: Text(t('pos.clear_cart_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(posProvider.notifier).clearCart();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: Text(t('common.clear')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);

    // Show error message if present
    if (posState.error != null && posState.error!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(posState.error!),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        ref.read(posProvider.notifier).clearMessages();
      });
    }

    // Show success message if present
    if (posState.successMessage != null && posState.successMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(posState.successMessage!),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        ref.read(posProvider.notifier).clearMessages();
      });
    }

    // Mağaza seçici — activeStoreId yoksa ve birden fazla mağaza varsa göster
    if (!posState.isLoadingProducts &&
        posState.activeStoreId == null &&
        posState.availableStoreIds.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showStorePicker(context, posState.availableStoreIds, posState.activeStoreId);
      });
    }

    // Çapraz lokasyon stok uyarısı — başka mağazada stok var ama kasiyerin mağazasında yok
    if (posState.crossLocationAlert != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final alert = posState.crossLocationAlert!;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => OutOfStockLocationDialog(
            alert: alert,
            onForceAdd: () {
              ref.read(posProvider.notifier).addToCart(
                alert['product'] as Map<String, dynamic>,
                variant: alert['variant'] as Map<String, dynamic>?,
                forceAdd: true,
              );
            },
            onCancel: () {
              ref.read(posProvider.notifier).clearCrossLocationAlert();
            },
          ),
        );
      });
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: _buildAppBar(posState),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout(posState);
            }
            return _buildMobileLayout(posState);
          },
        ),
        floatingActionButton: !_isDesktop(context) && posState.totalItems > 0
            ? FadeInUp(
                child: FloatingActionButton.extended(
                  onPressed: () => _showMobileCart(context),
                  backgroundColor: AppColors.primary,
                  icon: Badge(
                    label: Text('${posState.totalItems}'),
                    backgroundColor: AppColors.danger,
                    child: const Icon(Icons.shopping_basket_rounded, color: Colors.white),
                  ),
                  label: Text(
                    _currencyFormat.format(posState.grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(PosState posState) {
    final t = i18nOf(ref);
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('pos.title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          GestureDetector(
            onTap: posState.availableStoreIds.length > 1
                ? () => _showStorePicker(context, posState.availableStoreIds, posState.activeStoreId)
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  posState.activeStoreId != null
                      ? Icons.store_rounded
                      : Icons.store_mall_directory_outlined,
                  size: 11,
                  color: posState.activeStoreId != null ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  posState.activeStoreId != null
                      ? '${t('pos.store')}: ${posState.activeStoreId}'
                      : t('pos.no_store'),
                  style: TextStyle(
                    fontSize: 11,
                    color: posState.activeStoreId != null ? AppColors.textMuted : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (posState.availableStoreIds.length > 1) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down_rounded, size: 14, color: AppColors.textMuted),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (posState.parkedOrders.isNotEmpty)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => _showParkedOrdersPanel(context),
                icon: const Icon(Icons.pause_circle_outline, color: AppColors.primary),
                tooltip: t('pos.parked_orders'),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${posState.parkedOrders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        IconButton(
          onPressed: () => ref.read(posProvider.notifier).refreshProducts(),
          icon: Icon(Icons.sync_rounded, color: posState.isLoadingProducts ? AppColors.primary : AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopLayout(PosState posState) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: _buildProductPanel(posState),
        ),
        VerticalDivider(width: 1, color: AppColors.border.withOpacity(0.5)),
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.white,
            child: CartPanel(
              onPaymentPressed: () => _showPaymentDialog(context),
              currencyFormat: _currencyFormat,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(PosState posState) {
    return _buildProductPanel(posState);
  }

  Widget _buildProductPanel(PosState posState) {
    return Column(
      children: [
        // Arama ve Filtreleme Bölümü
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.white,
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              if (posState.categories.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: CategoryFilterBar(
                    categories: posState.categories,
                    selectedCategoryId: posState.selectedCategoryId,
                    onCategorySelected: (category) {
                      ref.read(posProvider.notifier).selectCategory(category);
                    },
                  ),
                ),
            ],
          ),
        ),

        // Ürün Izgarası (Grid)
        Expanded(
          child: posState.isLoadingProducts
              ? const Center(child: CircularProgressIndicator.adaptive())
              : FadeIn(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _isDesktop(context) ? 4 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 160,
                    ),
                    itemCount: posState.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = posState.filteredProducts[index];
                      return ProductGridItem(
                        product: product,
                        currencyFormat: _currencyFormat,
                        onTap: () {
                          final variants = product['variants'] as List? ?? [];
                          if (variants.length > 1) {
                            showDialog(
                              context: context,
                              builder: (_) => VariantSelectionDialog(
                                product: product,
                                onVariantSelected: (variant) {
                                  ref.read(posProvider.notifier).addToCart(product, variant: variant);
                                },
                              ),
                            );
                          } else if (variants.length == 1) {
                            // Single variant, use it directly
                            ref.read(posProvider.notifier).addToCart(product, variant: variants[0]);
                          } else {
                            // No variants, add product as is
                            ref.read(posProvider.notifier).addToCart(product);
                          }
                        },
                      );
                    },
                  ),
                ),
        ),

        // Keyboard shortcuts hint bar
        if (_isDesktop(context))
          _buildShortcutBar(),
      ],
    );
  }

  Widget _buildShortcutBar() {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _shortcutHint('F1', t('pos.payment')),
            const SizedBox(width: 24),
            _shortcutHint('F5', t('common.refresh')),
            const SizedBox(width: 24),
            _shortcutHint('ESC', t('common.clear')),
            const SizedBox(width: 24),
            _shortcutHint('Ctrl+Delete', t('pos.clear_cart')),
          ],
        ),
      ),
    );
  }

  Widget _shortcutHint(String key, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final t = i18nOf(ref);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => ref.read(posProvider.notifier).setSearchQuery(value),
        decoration: InputDecoration(
          hintText: t('pos.search_product'),
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(posProvider.notifier).setSearchQuery('');
                  },
                )
              : const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: CartPanel(
                onPaymentPressed: () {
                  Navigator.pop(context);
                  _showPaymentDialog(context);
                },
                currencyFormat: _currencyFormat,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentPanel(),
    );
  }

  void _showParkedOrdersPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ParkedOrdersPanel(),
    );
  }

  bool _storePickerShown = false;

  /// Mağaza seçici dialog — birden fazla mağaza varken kasiyerin hangi mağazada
  /// çalıştığını seçmesini sağlar.
  void _showStorePicker(
      BuildContext context, List<String> storeIds, String? currentStoreId) {
    if (_storePickerShown) return;
    _storePickerShown = true;

    final t = i18nOf(ref);
    showDialog(
      context: context,
      barrierDismissible: currentStoreId != null, // seçim yapılmışsa kapatılabilir
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.store_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(t('pos.select_store')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('pos.select_store_desc'),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...storeIds.map((id) {
              final isSelected = id == currentStoreId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(posProvider.notifier).setActiveStore(id);
                    _storePickerShown = false;
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : AppColors.bgLight,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.store_rounded,
                          size: 20,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            id,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        actions: currentStoreId != null
            ? [
                TextButton(
                  onPressed: () {
                    _storePickerShown = false;
                    Navigator.pop(ctx);
                  },
                  child: Text(t('common.cancel')),
                ),
              ]
            : null,
      ),
    ).then((_) => _storePickerShown = false);
  }
}