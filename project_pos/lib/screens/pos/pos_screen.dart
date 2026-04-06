import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'providers/pos_provider.dart';
import 'widgets/product_grid_item.dart';
import 'widgets/cart_panel.dart';
import 'widgets/payment_panel.dart';
import 'widgets/category_filter_bar.dart';

/// Tam fonksiyonel POS Satis Ekrani
///
/// - Desktop (>900px): Sol %60 urun arama + grid, Sag %40 sepet paneli
/// - Mobil (<900px): Ana alan urun listesi, alt sayfa (bottom sheet) sepet
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);

    // Hata mesajlarini dinle
    ref.listen<PosState>(posProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Kapat',
              textColor: Colors.white,
              onPressed: () => ref.read(posProvider.notifier).clearMessages(),
            ),
          ),
        );
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ref.read(posProvider.notifier).clearMessages();
      }
    });

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
      // Mobilde floating sepet butonu
      floatingActionButton: !_isDesktop(context) && posState.totalItems > 0
          ? FloatingActionButton.extended(
              onPressed: () => _showMobileCart(context),
              backgroundColor: AppColors.primary,
              icon: Badge(
                label: Text(
                  '${posState.totalItems}',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: AppColors.danger,
                child:
                    const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
              ),
              label: Text(
                _currencyFormat.format(posState.grandTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(PosState posState) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.point_of_sale,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'POS Satis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        // Yenile butonu
        IconButton(
          onPressed: () => ref.read(posProvider.notifier).refreshProducts(),
          icon: Icon(
            Icons.refresh,
            color: posState.isLoadingProducts
                ? AppColors.textMuted
                : AppColors.textSecondary,
          ),
          tooltip: 'Urunleri Yenile',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Desktop Layout: Sol %60, Sag %40 ───────────────────────────
  Widget _buildDesktopLayout(PosState posState) {
    return Row(
      children: [
        // Sol panel — Urun arama + grid (%60)
        Expanded(
          flex: 6,
          child: _buildProductPanel(posState),
        ),

        // Sag panel — Sepet (%40)
        Expanded(
          flex: 4,
          child: CartPanel(
            onPaymentPressed: () => _showPaymentDialog(context),
            currencyFormat: _currencyFormat,
          ),
        ),
      ],
    );
  }

  // ─── Mobil Layout ────────────────────────────────────────────────
  Widget _buildMobileLayout(PosState posState) {
    return _buildProductPanel(posState);
  }

  // ─── Urun Paneli: Arama + Kategori + Grid ───────────────────────
  Widget _buildProductPanel(PosState posState) {
    final notifier = ref.read(posProvider.notifier);

    return Column(
      children: [
        // Arama cubugu
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: notifier.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Urun adi, SKU veya barkod ara...',
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
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
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
                  icon:
                      const Icon(Icons.qr_code_scanner, color: Colors.white),
                  tooltip: 'Barkod Oku',
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

        // Urun grid / liste
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

  // ─── Bos durum ──────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Urun bulunamadi',
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          const Text(
            'Arama kriterlerini degistirin',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── Urun Grid ──────────────────────────────────────────────────
  Widget _buildProductGrid(PosState posState, PosNotifier notifier) {
    final products = posState.filteredProducts;
    final width = MediaQuery.of(context).size.width;

    // Desktop sol panel genisligi %60, mobilde tam ekran
    final panelWidth = _isDesktop(context) ? width * 0.6 : width;

    final crossAxisCount = panelWidth > 900
        ? 4
        : panelWidth > 600
            ? 3
            : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.35,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductGridItem(
          product: product,
          currencyFormat: _currencyFormat,
          onTap: () => _handleProductTap(product, notifier),
        );
      },
    );
  }

  // ─── Urun tiklandiginda ─────────────────────────────────────────
  void _handleProductTap(
      Map<String, dynamic> product, PosNotifier notifier) {
    final variants =
        (product['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Birden fazla varyant varsa varyant secici goster
    if (variants.length > 1) {
      _showVariantPicker(context, product, variants, notifier);
      return;
    }

    notifier.addToCart(product);
  }

  // ─── Varyant secici dialog ──────────────────────────────────────
  void _showVariantPicker(
    BuildContext context,
    Map<String, dynamic> product,
    List<Map<String, dynamic>> variants,
    PosNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.style, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                product['name']?.toString() ?? 'Varyant Sec',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: variants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final v = variants[index];
              final sku = v['sku']?.toString() ?? '';
              final name = v['name']?.toString() ?? 'Varyant ${index + 1}';
              final additionalPrice =
                  (v['additionalPrice'] as num?)?.toDouble() ?? 0;
              final basePrice =
                  (product['basePrice'] as num?)?.toDouble() ?? 0;
              final totalPrice = basePrice + additionalPrice;
              final inv =
                  v['inventory'] as Map<String, dynamic>? ?? {};
              final stock =
                  (inv['physicalQuantity'] as num?)?.toInt() ?? 0;
              final isOut = stock <= 0;

              return ListTile(
                enabled: !isOut,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isOut ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '$sku  |  Stok: $stock',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOut ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                ),
                trailing: Text(
                  _currencyFormat.format(totalPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOut ? AppColors.textMuted : AppColors.primary,
                  ),
                ),
                onTap: () {
                  // Secilen varyant bilgilerini urune ekle
                  final variantProduct = Map<String, dynamic>.from(product);
                  variantProduct['variantId'] = v['id'];
                  variantProduct['sku'] = sku;
                  variantProduct['sellingPrice'] = totalPrice;
                  variantProduct['basePrice'] = totalPrice;
                  variantProduct['price'] = totalPrice;
                  variantProduct['stock'] = stock;
                  variantProduct['name'] =
                      '${product['name']} - $name';
                  notifier.addToCart(variantProduct);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Iptal'),
          ),
        ],
      ),
    );
  }

  // ─── Barkod girisi dialog ───────────────────────────────────────
  void _showBarcodeInput(BuildContext context, PosNotifier notifier) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            child: const Text('Iptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                notifier.addToCartByBarcode(val);
                Navigator.pop(ctx);
              }
            },
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  // ─── Mobil sepet bottom sheet ───────────────────────────────────
  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Sepet paneli
                Expanded(
                  child: CartPanel(
                    onPaymentPressed: () {
                      Navigator.pop(ctx);
                      _showPaymentDialog(context);
                    },
                    currencyFormat: _currencyFormat,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Odeme dialog ───────────────────────────────────────────────
  void _showPaymentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaymentPanel(),
    );
  }

  // ─── Basarili satis — fis ozeti ─────────────────────────────────
  void _showReceiptSummary(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.bgSuccess,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 44,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Satis Tamamlandi!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Satis basariyla kaydedildi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            // Yazdir butonu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Firsatta yazdir — su an sadece bilgi
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fis yazdirma istegi gonderildi'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Fisi Yazdir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Yeni Satis',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
