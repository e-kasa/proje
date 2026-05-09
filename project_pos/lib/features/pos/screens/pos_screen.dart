import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/utils/responsive_helper.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/print/print_service.dart';
import 'package:project_pos/services/print/print_settings.dart';
import 'package:project_pos/services/notification/notification_models.dart';
import 'package:project_pos/services/notification/notification_service.dart';
import 'package:project_pos/services/notification/notification_settings.dart';
import 'package:project_pos/services/scanner/barcode_scanner_listener.dart';
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

  /// Responsive breakpoint kontrolü
  /// Desktop: 1200px+ | Tablet: 768-1199px | Mobile: <768px
  bool _isDesktop(BuildContext context) => context.isDesktop;
  bool _isTablet(BuildContext context) => context.isTablet;
  bool _isMobile(BuildContext context) => context.isMobile;

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
      if (!next.isLoadingProducts && next.activeLocationId == null && next.availableLocationIds.length > 1 && !_storePickerShown) {
        _showStorePicker(context, next.availableLocationIds);
      }

      // 4. Çapraz Lokasyon Stok Uyarısı
      if (next.crossLocationAlert != null && previous?.crossLocationAlert == null) {
        _showCrossLocationAlert(context, next.crossLocationAlert!);
      }

      // 5. Sprint 22 — Auto-print receipt: lastSaleData değiştiyse + ayar açıksa
      if (next.lastSaleData != null &&
          next.lastSaleData != previous?.lastSaleData) {
        final settings = ref.read(printSettingsProvider);
        if (settings.autoPrintOnSale && settings.isConfigured) {
          _autoPrintReceipt(next.lastSaleData!);
        }

        // 6. Sprint 28 — Auto-SMS: yeni satış + müşteri telefonu varsa + toggle aktifse
        final notif = ref.read(notificationSettingsProvider);
        if (notif.smsAutoOnSale) {
          final phone = _extractCustomerPhone(next.lastSaleData!);
          if (phone != null) {
            _autoSendSaleSms(next.lastSaleData!, phone);
          }
        }
      }
    });

    final posState = ref.watch(posProvider);

    // Sprint 19-C: Scaffold → BaseScaffold (cart-aware split layout, custom gradient AppBar).
    // Sprint 30: BarcodeScannerListener — USB HID barkod okuyucu global dinleyici.
    // Klavye girişlerinden 100ms+10char/Enter paterniyle ayırt edilen kod
    // posProvider.addToCartByBarcode'a iletilir; başarı/hata posState ile yansır.
    return BarcodeScannerListener(
      enabled: !kIsWeb,
      onScan: (code) {
        // Sprint 30 görsel debug — kullanıcı listener'ın tetiklendiğini
        // ekrandan görsün. posState'in success/error toast'ı sonrasında ayrıca düşer.
        if (mounted) {
          AppToast.info(context, '🔍 Barkod algılandı: $code');
        }
        ref.read(posProvider.notifier).addToCartByBarcode(code);
      },
      child: KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: BaseScaffold(
        appBar: _buildAppBar(posState),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive layout seçimi
            if (context.isDesktop) {
              return _buildDesktopLayout(posState);
            } else if (context.isTablet) {
              return _buildTabletLayout(posState);
            } else {
              return _buildMobileLayout(posState);
            }
          },
        ),
        // FAB: Mobil ve tablet'te sepeti göster
        floatingActionButton: !context.isDesktop && posState.totalItems > 0
            ? FloatingActionButton.extended(
                onPressed: () => _showMobileCart(context),
                backgroundColor: AppColors.primary,
                icon: Badge(label: Text('${posState.totalItems}'), child: const Icon(Icons.shopping_basket_rounded, color: Colors.white)),
                label: Text(_currencyFormat.format(posState.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              )
            : null,
      ),
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
        onTap: posState.availableLocationIds.length > 1
            ? () => _showStorePicker(context, posState.availableLocationIds)
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
                      posState.activeLocationId ?? 'Mağaza Seçilmedi',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    if (posState.availableLocationIds.length > 1) ...[
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
        // Sprint 22 — Son fişi yeniden yazdır (manual)
        if (posState.lastSaleData != null)
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Son Fisi Yazdir',
            onPressed: () => _printLastReceipt(posState.lastSaleData!),
          ),
        IconButton(
          icon: const Icon(Icons.sync, color: Colors.white),
          tooltip: 'Yenile',
          onPressed: () => ref.read(posProvider.notifier).refreshProducts(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Future<void> _autoPrintReceipt(Map<String, dynamic> sale) async {
    final result = await ref.read(printServiceProvider).printSaleReceipt(sale);
    if (!mounted) return;
    if (!result.success) {
      AppToast.error(context, 'Otomatik yazdirma: ${result.error}');
    }
  }

  /// Sprint 28 — pos_provider lastSaleData içindeki customer map'inden
  /// telefon çıkar. Müşteri seçilmemişse null döner (perakende satış).
  String? _extractCustomerPhone(Map<String, dynamic> sale) {
    final customer = sale['customer'];
    if (customer is! Map) return null;
    final candidates = [customer['phone'], customer['phoneNumber']];
    for (final c in candidates) {
      final s = c?.toString().trim();
      if (s != null && s.isNotEmpty && s.length >= 7) return s;
    }
    return null;
  }

  /// Sprint 28 — Otomatik satış SMS'i (fire-and-forget). Backend NOOP/Twilio
  /// kanal seçimine göre gerçek gönderim olur. Hata sessizce toast olarak
  /// gösterilir; satış akışı engellenmiyor.
  Future<void> _autoSendSaleSms(Map<String, dynamic> sale, String phone) async {
    final saleNo = sale['saleNumber']?.toString() ??
        sale['saleId']?.toString() ??
        '-';
    final total = (sale['grandTotal'] as num?)?.toDouble() ?? 0;
    final body = 'SEDCORE POS — Fiş #$saleNo. '
        'Tutar: ₺${total.toStringAsFixed(2)}. Teşekkürler!';
    final result = await ref.read(notificationServiceProvider).send(
          NotificationRequest(
            eventType: 'SALE_AUTO_SMS',
            channel: NotificationChannel.sms,
            recipient: phone,
            body: body,
          ),
        );
    if (!mounted) return;
    if (!result.success) {
      AppToast.error(context, 'Otomatik SMS başarısız: ${result.error}');
    }
  }

  Future<void> _printLastReceipt(Map<String, dynamic> sale) async {
    final settings = ref.read(printSettingsProvider);
    if (!settings.isConfigured) {
      AppToast.error(context, 'Yazici yapilandirilmamis. Ayarlardan secin.');
      return;
    }
    final result = await ref.read(printServiceProvider).printSaleReceipt(sale);
    if (!mounted) return;
    if (result.success) {
      AppToast.success(context, 'Fis yazdirildi.');
    } else {
      AppToast.error(context, result.error ?? 'Yazdirma basarisiz.');
    }
  }

  /// Desktop Layout: 70/30 Master-Detail Panel
  /// - Sol: Ürünler (70%)
  /// - Sağ: Sepet Panel (30%) - Sticky
  Widget _buildDesktopLayout(PosState posState) {
    return Row(
      children: [
        Expanded(
          flex: 70,
          child: _buildProductPanel(posState),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 30,
          child: CartPanel(
            onPaymentPressed: () => _showPaymentDialog(context),
            currencyFormat: _currencyFormat,
          ),
        ),
      ],
    );
  }

  /// Tablet Layout: Vertical Stack
  /// - Üst: Ürünler
  /// - Alt: Sepet Panel (Scrollable)
  Widget _buildTabletLayout(PosState posState) {
    return Column(
      children: [
        Expanded(
          child: _buildProductPanel(posState),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 250,
          child: CartPanel(
            onPaymentPressed: () => _showPaymentDialog(context),
            currencyFormat: _currencyFormat,
          ),
        ),
      ],
    );
  }

  /// Mobile Layout: Ürünler + FAB
  /// - FAB ile sepet erişimi (bottom sheet)
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
          child: _buildProductGrid(posState),
        ),
      ],
    );
  }

  /// Responsive Product Grid
  /// Desktop: 4 kolon | Tablet: 3 kolon | Mobile: 2 kolon
  Widget _buildProductGrid(PosState posState) {
    // Responsive kolon sayısı
    final crossAxis = context.gridColumns;
    final gridGap = context.gridGap;

    if (posState.isLoadingProducts) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AppSkeletonGrid(crossAxisCount: crossAxis, itemCount: crossAxis * 3),
      );
    }

    if (posState.filteredProducts.isEmpty) {
      final hasFilter = (posState.searchQuery).isNotEmpty ||
          posState.selectedCategoryId != null;
      return hasFilter
          ? AppEmptyState.search(
              title: 'Ürün bulunamadı',
              description: 'Arama veya kategori filtresini temizleyip tekrar deneyin.',
            )
          : AppEmptyState.noData(
              title: 'Henüz ürün yok',
              description: 'Bu mağazada satışa hazır ürün bulunmuyor. Stok ekleyin.',
            );
    }

    return GridView.builder(
      padding: EdgeInsets.all(context.horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        mainAxisSpacing: gridGap,
        crossAxisSpacing: gridGap,
        mainAxisExtent: 160,
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