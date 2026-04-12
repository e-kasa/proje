import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import '../providers/pos_provider.dart';
import '../widgets/product_grid_item.dart';
import '../widgets/cart_panel.dart';
import '../widgets/payment_panel.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/variant_selection_dialog.dart';
import '../widgets/out_of_stock_location_dialog.dart';

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
  bool _storePickerShown = false;

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
    
    if (event.logicalKey == LogicalKeyboardKey.f1 && posState.cartItems.isNotEmpty) {
      _showPaymentDialog(context);
    }
    if (event.logicalKey == LogicalKeyboardKey.f5) {
      ref.read(posProvider.notifier).refreshProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ─── YAN ETKİ YÖNETİMİ (Çökmeyi Önleyen Kısım) ───
    ref.listen<PosState>(posProvider, (previous, next) {
      // 1. Hata Mesajları
      if (next.error != null && next.error!.isNotEmpty && next.error != previous?.error) {
        AppToast.error(context, next.error!);
        ref.read(posProvider.notifier).clearMessages();
      }

      // 2. Başarı Mesajları
      if (next.successMessage != null && next.successMessage!.isNotEmpty && next.successMessage != previous?.successMessage) {
        AppToast.success(context, next.successMessage!);
        ref.read(posProvider.notifier).clearMessages();
      }

      // 3. Mağaza Seçimi (Eğer mağaza atanmamışsa)
      if (!next.isLoadingProducts && next.activeStoreId == null && next.availableStoreIds.length > 1 && !_storePickerShown) {
        _showStorePicker(context, next.availableStoreIds);
      }

      // 4. Çapraz Lokasyon Stok Uyarısı
      if (next.crossLocationAlert != null && previous?.crossLocationAlert == null) {
        _showCrossLocationAlert(context, next.crossLocationAlert!);
      }
    });

    final posState = ref.watch(posProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: _buildAppBar(posState),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) return _buildDesktopLayout(posState);
            return _buildMobileLayout(posState);
          },
        ),
        floatingActionButton: !_isDesktop(context) && posState.totalItems > 0
            ? FloatingActionButton.extended(
                onPressed: () => _showMobileCart(context),
                backgroundColor: AppColors.primary,
                icon: Badge(label: Text('${posState.totalItems}'), child: const Icon(Icons.shopping_basket_rounded, color: Colors.white)),
                label: Text(_currencyFormat.format(posState.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(PosState posState) {
    final t = i18nOf(ref);
    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: GestureDetector(
        onTap: posState.availableStoreIds.length > 1
            ? () => _showStorePicker(context, posState.availableStoreIds)
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('pos.title'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                Row(
                  children: [
                    Icon(Icons.store_outlined, size: 11, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 3),
                    Text(
                      posState.activeStoreId ?? 'Mağaza Seçilmedi',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    if (posState.availableStoreIds.length > 1) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sync, color: Colors.white),
          tooltip: 'Yenile',
          onPressed: () => ref.read(posProvider.notifier).refreshProducts(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildDesktopLayout(PosState posState) {
    return Row(
      children: [
        Expanded(flex: 7, child: _buildProductPanel(posState)),
        const VerticalDivider(width: 1),
        Expanded(flex: 3, child: CartPanel(onPaymentPressed: () => _showPaymentDialog(context), currencyFormat: _currencyFormat)),
      ],
    );
  }

  Widget _buildMobileLayout(PosState posState) => _buildProductPanel(posState);

  Widget _buildProductPanel(PosState posState) {
    return Column(
      children: [
        _buildSearchBar(),
        if (posState.categories.isNotEmpty) 
          CategoryFilterBar(
            categories: posState.categories, 
            selectedCategoryId: posState.selectedCategoryId,
            onCategorySelected: (cat) => ref.read(posProvider.notifier).selectCategory(cat),
          ),
        Expanded(
          child: posState.isLoadingProducts 
            ? const Center(child: CircularProgressIndicator()) 
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _isDesktop(context) ? 4 : 2,
                  mainAxisSpacing: 16, crossAxisSpacing: 16, mainAxisExtent: 160
                ),
                itemCount: posState.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = posState.filteredProducts[index];
                  return ProductGridItem(
                    product: product, 
                    currencyFormat: _currencyFormat, 
                    onTap: () => _handleProductTap(product),
                  );
                },
              ),
        ),
      ],
    );
  }

  void _handleProductTap(Map<String, dynamic> product) {
    final variants = product['variants'] as List? ?? [];
    if (variants.length > 1) {
      showDialog(context: context, builder: (_) => VariantSelectionDialog(product: product, onVariantSelected: (v) => ref.read(posProvider.notifier).addToCart(product, variant: v)));
    } else {
      ref.read(posProvider.notifier).addToCart(product, variant: variants.isNotEmpty ? variants[0] : null);
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => ref.read(posProvider.notifier).setSearchQuery(val),
        decoration: InputDecoration(hintText: 'Ürün ara...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => const PaymentPanel());
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => CartPanel(onPaymentPressed: () => _showPaymentDialog(context), currencyFormat: _currencyFormat));
  }

  void _showStorePicker(BuildContext context, List<String> storeIds) {
    if (_storePickerShown) return;
    _storePickerShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Mağaza Seçin'),
        content: Column(mainAxisSize: MainAxisSize.min, children: storeIds.map((id) => ListTile(title: Text(id), onTap: () { ref.read(posProvider.notifier).setActiveStore(id); Navigator.pop(ctx); })).toList()),
      ),
    ).then((_) => _storePickerShown = false);
  }

  void _showCrossLocationAlert(BuildContext context, Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (_) => OutOfStockLocationDialog(
        alert: alert,
        onForceAdd: () {
          ref.read(posProvider.notifier).addToCart(alert['product'], variant: alert['variant'], forceAdd: true);
          Navigator.pop(context);
        },
        onCancel: () {
          ref.read(posProvider.notifier).clearCrossLocationAlert();
          Navigator.pop(context);
        },
      ),
    );
  }
}