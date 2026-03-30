import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'adaptive_sidebar.dart';
import 'adaptive_bottom_nav.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/navigation_provider.dart';

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final String label;
  final String route;
  final int? badge;

  /// Sidebar'da bu item'dan önce bir bölüm başlığı gösterir.
  /// Yalnızca genişletilmiş sidebar'da görünür.
  final String? sectionLabel;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
    this.sectionLabel,
  });
}

/// Route → sayfa başlığı eşlemesi (AppBar ve breadcrumb için)
const _routeTitles = <String, String>{
  '/dashboard': 'Ana Sayfa',
  '/pos': 'Satış / POS',
  '/stock': 'Stok Yönetimi',
  '/stock/multi-warehouse': 'Çok Depo Stok',
  '/stock/transfer-review': 'Stok Transfer',
  '/stock/count-review': 'Stok Sayım',
  '/bulk-import': 'Toplu Ürün Yükleme',
  '/categories/company-setup': 'Kategori Tanımla',
  '/menu': 'Menü',
  '/sales': 'Satışlar',
  '/inventory': 'Envanter',
  '/inventory/products': 'Ürünler',
  '/inventory/add-product': 'Ürün Ekle',
  '/inventory/categories': 'Kategoriler',
  '/inventory/brands': 'Markalar',
  '/inventory/units': 'Birimler',
  '/inventory/barcodes': 'Barkodlar',
  '/customers': 'Müşteriler',
  '/customers/add': 'Müşteri Ekle',
  '/suppliers': 'Tedarikçiler',
  '/suppliers/add': 'Tedarikçi Ekle',
  '/warehouses': 'Depolar',
  '/warehouses/add': 'Depo Ekle',
  '/stores': 'Mağazalar',
  '/stores/add': 'Mağaza Ekle',
  '/finance': 'Finans',
  '/finance/expenses': 'Giderler',
  '/finance/expenses/add': 'Gider Ekle',
  '/hrm/employees': 'Çalışanlar',
  '/reports': 'Raporlar',
  '/profile': 'Profil',
  '/settings': 'Ayarlar',
};

String _getPageTitle(String location) =>
    _routeTitles[location] ?? _routeTitles.entries
        .where((e) => location.startsWith(e.key))
        .fold('Panel', (_, e) => e.value);

/// Main responsive layout — desktop sidebar, mobile bottom nav
class ResponsiveLayout extends ConsumerStatefulWidget {
  final Widget child;

  const ResponsiveLayout({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends ConsumerState<ResponsiveLayout> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<NavigationItem> _webNavItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      label: 'Ana Sayfa',
      route: '/dashboard',
      sectionLabel: 'GENEL',
    ),
    NavigationItem(
      icon: Icons.point_of_sale_outlined,
      label: 'Satış / POS',
      route: '/pos',
    ),
    NavigationItem(
      icon: Icons.inventory_2_outlined,
      label: 'Stok',
      route: '/stock',
      sectionLabel: 'OPERASYONLAR',
    ),
    NavigationItem(
      icon: Icons.upload_file_outlined,
      label: 'Toplu Yükleme',
      route: '/bulk-import',
    ),
    NavigationItem(
      icon: Icons.tune_outlined,
      label: 'Kategori Tanımla',
      route: '/categories/company-setup',
    ),
    NavigationItem(
      icon: Icons.grid_view_rounded,
      label: 'Menü',
      route: '/menu',
      sectionLabel: 'DİĞER',
    ),
  ];

  final List<NavigationItem> _mobileNavItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      label: 'Ana Sayfa',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.point_of_sale_outlined,
      label: 'Satış',
      route: '/pos',
    ),
    // CENTER: Barkod FAB (harici)
    NavigationItem(
      icon: Icons.inventory_2_outlined,
      label: 'Stok',
      route: '/stock',
    ),
    NavigationItem(
      icon: Icons.grid_view_rounded,
      label: 'Menü',
      route: '/menu',
    ),
  ];

  /// Menü öğesine tıklanınca:
  /// - Farklı route → git
  /// - Aynı route → refresh sinyali gönder (servis çağrısını tetikler)
  void _onNavigationItemSelected(int index, String route) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    if (currentLocation == route) {
      // Aynı sayfadayız — GoRouter'ı çağırmak rebuild yapmaz,
      // bunun yerine refresh provider üzerinden ekrana sinyal gönder.
      ref.read(navigationRefreshProvider.notifier).refresh(route);
      return;
    }

    setState(() => _selectedIndex = index);
    context.go(route);
  }

  void _toggleSidebar() {
    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !context.shouldShowSidebar;
    final navItems = isMobile ? _mobileNavItems : _webNavItems;

    // Aktif route'a göre seçili index'i güncelle
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = navItems.indexWhere((item) => item.route == location);
    if (currentIndex != -1 && currentIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = currentIndex);
      });
    }

    if (context.shouldShowSidebar) {
      return Scaffold(
        body: Row(
          children: [
            AdaptiveSidebar(
              items: _webNavItems,
              selectedIndex: _selectedIndex,
              isExpanded: _isSidebarExpanded,
              onItemSelected: _onNavigationItemSelected,
              onToggle: _toggleSidebar,
            ),
            Expanded(
              child: Column(
                children: [
                  _buildWebAppBar(location),
                  Expanded(
                    child: Container(
                      color: AppColors.bgLight,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobil
    return Scaffold(
      appBar: _buildMobileAppBar(location),
      body: Container(
        color: AppColors.bgLight,
        child: widget.child,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onBarcodeScanPressed,
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AdaptiveBottomNav(
        items: _mobileNavItems,
        selectedIndex: _selectedIndex,
        onItemSelected: _onNavigationItemSelected,
        hasNotch: true,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WEB APP BAR
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildWebAppBar(String location) {
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(authProvider).user;
        final themeSettings = ref.watch(themeProvider);
        final isDark = themeSettings.themeMode == AppThemeMode.dark;
        final displayName = user?.displayName ?? 'Admin';
        final companyCode = user?.selectedCompanyCode ?? '';
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
        final pageTitle = _getPageTitle(location);

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Sayfa başlığı (breadcrumb gibi)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pageTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      companyCode.isNotEmpty ? companyCode : 'E-Kasa Panel',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Arama
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Hızlı ara...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_outlined,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Tema toggle
                _AppBarIconBtn(
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: isDark ? 'Açık Tema' : 'Koyu Tema',
                  onPressed: () => ref.read(themeProvider.notifier).setThemeMode(
                        isDark ? AppThemeMode.light : AppThemeMode.dark,
                      ),
                ),

                // Bildirimler (badge ile)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _AppBarIconBtn(
                      icon: Icons.notifications_outlined,
                      tooltip: 'Bildirimler',
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),

                // Profil
                _buildProfileMenu(ref, displayName, companyCode, initial),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMenu(
    WidgetRef ref,
    String displayName,
    String companyCode,
    String initial,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.go('/profile');
          case 'settings':
            context.go('/settings');
          case 'logout':
            ref.read(authProvider.notifier).logout();
        }
      },
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'profile',
          child: _popupItem(Icons.person_outline, 'Profil', AppColors.textPrimary),
        ),
        PopupMenuItem(
          value: 'settings',
          child:
              _popupItem(Icons.settings_outlined, 'Ayarlar', AppColors.textPrimary),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child:
              _popupItem(Icons.logout_outlined, 'Çıkış Yap', AppColors.danger),
        ),
      ],
    );
  }

  Widget _popupItem(IconData icon, String label, Color color) => Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      );

  // ──────────────────────────────────────────────────────────────────────────
  // MOBİL APP BAR
  // ──────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildMobileAppBar(String location) {
    final pageTitle = _getPageTitle(location);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.shopping_bag, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            pageTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final isDark = ref.watch(themeProvider).themeMode == AppThemeMode.dark;
            return _AppBarIconBtn(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              onPressed: () => ref.read(themeProvider.notifier).setThemeMode(
                    isDark ? AppThemeMode.light : AppThemeMode.dark,
                  ),
            );
          },
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _AppBarIconBtn(
              icon: Icons.notifications_outlined,
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BARKOD
  // ──────────────────────────────────────────────────────────────────────────

  void _onBarcodeScanPressed() {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    if (currentRoute == '/pos') {
      _showBarcodeScanDialog('Ürün Ekle', 'POS sepetine eklemek için barkod okutun');
    } else if (currentRoute == '/stock') {
      _showBarcodeActionSheet();
    } else if (currentRoute.contains('/inventory')) {
      _showBarcodeScanDialog('Ürün Ara', 'Ürün detaylarını görmek için barkod okutun');
    } else {
      _showBarcodeActionSheet();
    }
  }

  void _showBarcodeScanDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner,
                size: 72, color: AppColors.primary.withOpacity(0.25)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/scanner');
            },
            icon: const Icon(Icons.camera_alt, size: 17),
            label: const Text('Tara'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBarcodeActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Barkod İşlemleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _barcodeAction(
                Icons.shopping_cart_outlined, 'Hızlı Satış', 'Ürünü tara ve sat',
                AppColors.success, () {
              Navigator.pop(ctx);
              context.go('/pos');
            }),
            _barcodeAction(
                Icons.search_outlined, 'Stok Sorgula', 'Ürün stok durumunu gör',
                AppColors.info, () {
              Navigator.pop(ctx);
              context.go('/stock');
            }),
            _barcodeAction(
                Icons.edit_outlined, 'Ürün Düzenle', 'Ürün bilgilerini güncelle',
                AppColors.warning, () {
              Navigator.pop(ctx);
              context.go('/inventory/products');
            }),
          ],
        ),
      ),
    );
  }

  Widget _barcodeAction(IconData icon, String title, String subtitle, Color color,
      VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// AppBar'da küçük icon buton
class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _AppBarIconBtn({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppColors.textSecondary),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
