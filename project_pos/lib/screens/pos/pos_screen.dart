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
}