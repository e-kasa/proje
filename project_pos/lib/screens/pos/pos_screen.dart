import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import 'providers/pos_provider.dart';
import 'widgets/product_grid_item.dart';
import 'widgets/cart_panel.dart';
import 'widgets/payment_panel.dart';
import 'widgets/category_filter_bar.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) => MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);

    return Scaffold(
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
    );
  }

  PreferredSizeWidget _buildAppBar(PosState posState) {
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
          const Text('POS Satış Paneli', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          Text('Aktif Terminal: #01', 
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
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
                        onTap: () => ref.read(posProvider.notifier).addToCart(product),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
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
          hintText: 'Ürün adı, SKU veya barkod okutun...',
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
}
