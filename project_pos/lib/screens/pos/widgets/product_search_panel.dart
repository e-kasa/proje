import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../providers/pos_provider.dart';
import 'category_filter_bar.dart';
import 'package:project_pos/core/widgets/widgets.dart';

class ProductSearchPanel extends ConsumerStatefulWidget {
  const ProductSearchPanel({super.key});

  @override
  ConsumerState<ProductSearchPanel> createState() => _ProductSearchPanelState();
}

class _ProductSearchPanelState extends ConsumerState<ProductSearchPanel> {
  final _searchController = TextEditingController();
  final _barcodeFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final t = i18nOf(ref);

    return Column(
      children: [
        // Arama çubuğu
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: t('pos.search_product'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Barkod okuyucu butonu
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showBarcodeInput(context, notifier),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  tooltip: t('pos.scan_barcode'),
                ),
              ),
              const SizedBox(width: 8),
              // Yenile
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  onPressed: notifier.refreshProducts,
                  icon: Icon(
                    Icons.refresh,
                    color: posState.isLoadingProducts
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                  tooltip: t('common.refresh'),
                ),
              ),
            ],
          ),
        ),

        // Kategori filtreleri
        if (posState.categories.isNotEmpty)
          CategoryFilterBar(
            categories: posState.categories,
            selectedCategoryId: posState.selectedCategoryId,
            onCategorySelected: notifier.selectCategory,
          ),

        const SizedBox(height: 8),

        // Ürün grid
        Expanded(
          child: posState.isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : posState.filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildProductGrid(posState, notifier),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Ürün bulunamadı',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Arama kriterlerini değiştirin',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(PosState posState, PosNotifier notifier) {
    final products = posState.filteredProducts;
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 4
        : width > 900
            ? 3
            : width > 600
                ? 2
                : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, notifier);
      },
    );
  }

  /// Ürüne dokunulduğunda varyant sayısına göre davranış belirler.
  void _handleProductTap(
      BuildContext context, Map<String, dynamic> product, PosNotifier notifier) {
    final variants = (product['variants'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [];

    if (variants.length > 1) {
      _showVariantPicker(context, product, variants, notifier);
    } else if (variants.length == 1) {
      notifier.addToCart(product, variant: variants.first);
    } else {
      notifier.addToCart(product);
    }
  }

  /// Birden fazla varyantı olan ürünler için seçim dialogu.
  void _showVariantPicker(
      BuildContext context,
      Map<String, dynamic> product,
      List<Map<String, dynamic>> variants,
      PosNotifier notifier) {
    final basePrice = (product['basePrice'] as num?)?.toDouble()
        ?? (product['sellingPrice'] as num?)?.toDouble()
        ?? 0.0;
    final currencyFormat =
        RegExp(r'\d').hasMatch('₺') ? null : null; // sadece placeholder

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              product['name']?.toString() ?? 'Varyant Seç',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${variants.length} varyant mevcut',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            // Varyant listesi
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: variants.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final v = variants[i];
                  final additionalPrice =
                      (v['additionalPrice'] as num?)?.toDouble() ?? 0.0;
                  final totalPrice = basePrice + additionalPrice;
                  final vStock = _getVariantStock(v);
                  final vName = v['name']?.toString()
                      ?? v['sku']?.toString()
                      ?? 'Varyant ${i + 1}';
                  final attrs = v['attributes'] as Map<String, dynamic>? ?? {};
                  final attrText = attrs.entries
                      .map((e) => '${e.value}')
                      .join(' · ');
                  final isOutOfStock = vStock <= 0;

                  return ListTile(
                    onTap: isOutOfStock ? null : () {
                      Navigator.pop(ctx);
                      notifier.addToCart(product, variant: v);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? AppColors.bgLight
                            : AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: isOutOfStock
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                    title: Text(
                      vName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: attrText.isNotEmpty
                        ? Text(attrText,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted))
                        : null,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${totalPrice.toStringAsFixed(2)} ₺',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isOutOfStock
                                ? AppColors.textMuted
                                : AppColors.primary,
                          ),
                        ),
                        Text(
                          isOutOfStock ? 'Stokta yok' : 'Stok: $vStock',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOutOfStock
                                ? AppColors.danger
                                : vStock <= 5
                                    ? AppColors.warning
                                    : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getVariantStock(Map<String, dynamic> variant) {
    final inv = variant['inventory'] as Map<String, dynamic>?;
    if (inv != null) {
      return (inv['physicalQuantity'] as num?)?.toInt() ?? 0;
    }
    return (variant['stock'] as num?)?.toInt() ?? 0;
  }

  Widget _buildProductCard(
      Map<String, dynamic> product, PosNotifier notifier) {
    final name = product['name']?.toString() ?? '';
    final price = (product['sellingPrice'] as num?)?.toDouble() ??
        (product['basePrice'] as num?)?.toDouble() ??
        0.0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final sku = product['sku']?.toString() ?? '';
    final isOutOfStock = stock <= 0;
    final variants = (product['variants'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [];
    final hasMultiVariant = variants.length > 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOutOfStock
            ? null
            : () => _handleProductTap(context, product, notifier),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isOutOfStock
                ? AppColors.bgLight.withOpacity(0.7)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutOfStock
                  ? AppColors.border
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: İsim + Stok badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? AppColors.bgDanger
                          : stock <= 5
                              ? AppColors.bgWarning
                              : AppColors.bgSuccess,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOutOfStock ? 'Yok' : '$stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOutOfStock
                            ? AppColors.danger
                            : stock <= 5
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // SKU + çoklu varyant ikonu
              Row(
                children: [
                  if (sku.isNotEmpty)
                    Expanded(
                      child: Text(
                        sku,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (hasMultiVariant)
                    Tooltip(
                      message: '${variants.length} varyant',
                      child: Icon(
                        Icons.layers_outlined,
                        size: 14,
                        color: AppColors.primary.withAlpha(180),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // Fiyat
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${price.toStringAsFixed(2)} ₺',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isOutOfStock
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  if (hasMultiVariant)
                    Text(
                      'başlangıç',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted.withAlpha(180),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBarcodeInput(BuildContext context, PosNotifier notifier) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.qr_code_scanner, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Barkod Gir'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Barkodu okutun veya girin...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code),
          ),
          onSubmitted: (val) {
            if (val.isNotEmpty) {
              notifier.addToCartByBarcode(val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          AppButton.primary(
            text: 'Ekle',
            icon: Icons.add_shopping_cart,
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                notifier.addToCartByBarcode(val);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }
}
