import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'adaptive_sidebar.dart';
import 'adaptive_bottom_nav.dart';
import 'right_menu_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/navigation_provider.dart';

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;
  final int? badge;
  final String? sectionLabel;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
    this.sectionLabel,
  });
}

const _routeTitles = <String, String>{
  '/dashboard': 'Ana Sayfa',
  '/menu': 'Menü',
  '/profile': 'Profil',
  '/settings': 'Ayarlar',
  '/settings/users': 'Kullanıcı Yönetimi',
  '/settings/company': 'İşletme Bilgileri',
  '/part-search': 'Parça Arama',
  '/vehicles': 'Araçlar',
  '/pos': 'Satış / POS',
  '/sales': 'Satış Geçmişi',
  '/scanner': 'Barkod Tarayıcı',
  '/stock': 'Stok Yönetimi',
  '/stock/multi-warehouse': 'Çok Depo Stok',
  '/stock/transfer': 'Stok Transfer Oluştur',
  '/stock/transfer-review': 'Transfer Onay',
  '/stock/count-review': 'Stok Sayım',
  '/stock/movements': 'Hareket Geçmişi',
  '/stock/alerts': 'Stok Alarmları',
  '/stock/value-report': 'Stok Değer Raporu',
  '/inventory': 'Envanter',
  '/inventory/products': 'Ürünler',
  '/inventory/add-product': 'Ürün Ekle',
  '/inventory/batch-entry': 'Toplu Ürün Girişi',
  '/inventory/categories': 'Kategoriler',
  '/inventory/brands': 'Markalar',
  '/inventory/units': 'Birimler',
  '/inventory/barcodes': 'Barkodlar',
  '/categories/company-setup': 'Kategori Tanımla',
  '/bulk-import': 'Toplu Ürün Yükleme',
  '/bulk-import/review': 'İçe Aktarma İnceleme',
  '/bulk-import/supplier': 'Tedarikçi İthalatı',
  '/bulk-import/supplier-wizard': 'Tedarikçi İthalatı (Wizard)',
  '/bulk-import/supplier-upload': 'Tedarikçi Dosyası Yükle',
  '/purchases': 'Satın Alma',
  '/purchases/create': 'Yeni Alım',
  '/customers': 'Müşteriler',
  '/customers/add': 'Müşteri Ekle',
  '/suppliers': 'Tedarikçiler',
  '/suppliers/add': 'Tedarikçi Ekle',
  '/accounts': 'Cari Hesap Özeti',
  '/accounts/statement': 'Hesap Ekstresi',
  '/accounts/overdue': 'Vadesi Geçmiş',
  '/warehouses': 'Depolar',
  '/warehouses/add': 'Depo Ekle',
  '/stores': 'Mağazalar',
  '/stores/add': 'Mağaza Ekle',
  '/finance': 'Finans',
  '/finance/expenses': 'Giderler',
  '/finance/expenses/add': 'Gider Ekle',
  '/finance/add-income': 'Gelir Ekle',
  '/finance/payments': 'Ödemeler',
  '/finance/cash-flow': 'Nakit Akışı',
  '/hrm/employees': 'Çalışanlar',
  '/hrm/employees/add': 'Çalışan Ekle',
  '/reports': 'Raporlar',
  '/reports/daily-summary': 'Günlük Özet',
  '/reports/sales-summary': 'Satış Özeti',
  '/reports/product-analysis': 'Ürün Satış Analizi',
  '/reports/customer-analysis': 'Müşteri Satış Analizi',
  '/reports/profit-overview': 'Kâr/Zarar Özeti',
};

String _getPageTitle(String location) =>
    _routeTitles[location] ?? _routeTitles.entries
        .where((e) => location.startsWith(e.key))
        .fold('Panel', (_, e) => e.value);

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<NavigationItem> _webNavItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      label: 'Ana Sayfa',
      route: '/dashboard',
      sectionLabel: 'GENEL',
    ),
    NavigationItem(
      icon: Icons.grid_view_outlined,
      label: 'Menü Listesi',
      route: '/menu',
    ),
    NavigationItem(
      icon: Icons.search_outlined,
      label: 'Parça Ara',
      route: '/part-search',
    ),
    NavigationItem(
      icon: Icons.point_of_sale_outlined,
      label: 'Satış / POS',
      route: '/pos',
      sectionLabel: 'SATIŞ',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      label: 'Satış Geçmişi',
      route: '/sales',
    ),
    NavigationItem(
      icon: Icons.list_alt_outlined,
      label: 'Ürünler',
      route: '/inventory/products',
      sectionLabel: 'ÜRÜN KATALOĞU',
    ),
    NavigationItem(
      icon: Icons.category_outlined,
      label: 'Kategoriler',
      route: '/inventory/categories',
    ),
    NavigationItem(
      icon: Icons.inventory_2_outlined,
      label: 'Stok Durumu',
      route: '/stock',
      sectionLabel: 'STOK YÖNETİMİ',
    ),
    NavigationItem(
      icon: Icons.warehouse_outlined,
      label: 'Depolar',
      route: '/warehouses',
    ),
    NavigationItem(
      icon: Icons.shopping_cart_outlined,
      label: 'Satın Alma',
      route: '/purchases',
      sectionLabel: 'TEDARIK',
    ),
    NavigationItem(
      icon: Icons.business_outlined,
      label: 'Tedarikçiler',
      route: '/suppliers',
    ),
    NavigationItem(
      icon: Icons.people_outlined,
      label: 'Müşteriler',
      route: '/customers',
      sectionLabel: 'CARI HESAPLAR',
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Cari Hesaplar',
      route: '/accounts',
    ),
    NavigationItem(
      icon: Icons.account_balance_outlined,
      label: 'Finans',
      route: '/finance',
      sectionLabel: 'FINANS',
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      label: 'Raporlar',
      route: '/reports',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      label: 'Ayarlar',
      route: '/settings',
      sectionLabel: 'YÖNETİM',
    ),
  ];

  final List<NavigationItem> _mobileNavItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      label: 'Ana Sayfa',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.search_outlined,
      label: 'Parça Ara',
      route: '/part-search',
    ),
    NavigationItem(
      icon: Icons.inventory_2_outlined,
      label: 'Stok',
      route: '/stock',
    ),
    NavigationItem(
      icon: Icons.point_of_sale_outlined,
      label: 'Satış',
      route: '/pos',
    ),
  ];

  void _onNavigationItemSelected(int index, String route) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    if (currentLocation == route) {
      ref.read(navigationRefreshProvider.notifier).refresh(route);
      return;
    }
    setState(() => _selectedIndex = index);
    context.go(route);
  }

  void _toggleSidebar() {
    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
  }

  void _openRightDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isMobile = !context.shouldShowSidebar;
    
    // Menü sayfasındaysak ve Desktop modundaysak Sidebar'ı tamamen gizle (TAM TERSİ MANTIK)
    final hideSidebarOnDesktop = location == '/menu' && !isMobile;

    if (context.shouldShowSidebar && !hideSidebarOnDesktop) {
      return Scaffold(
        key: _scaffoldKey,
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

    // Menü sayfası tam ekran (Sidebar gizli)
    return Scaffold(
      key: _scaffoldKey,
      appBar: isMobile ? _buildMobileAppBar(location) : null,
      body: Container(
        color: AppColors.bgLight,
        child: Column(
          children: [
            if (!isMobile && hideSidebarOnDesktop) _buildWebAppBar(location),
            Expanded(child: widget.child),
          ],
        ),
      ),
      endDrawer: isMobile ? const RightMenuDrawer() : null,
      floatingActionButton: isMobile ? FloatingActionButton(
        onPressed: _onBarcodeScanPressed,
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isMobile ? AdaptiveBottomNav(
        items: _mobileNavItems,
        selectedIndex: _selectedIndex,
        onItemSelected: _onNavigationItemSelected,
        hasNotch: true,
      ) : null,
    );
  }

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
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (location == '/menu') ...[
                   IconButton(
                     icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                     onPressed: () => context.go('/dashboard'),
                   ),
                   const SizedBox(width: 8),
                ],
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
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                _AppBarIconBtn(
                  icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  onPressed: () => ref.read(themeProvider.notifier).setThemeMode(
                        isDark ? AppThemeMode.light : AppThemeMode.dark,
                      ),
                ),
                _buildProfileMenu(ref, displayName, companyCode, initial),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMenu(WidgetRef ref, String displayName, String companyCode, String initial) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'profile') context.go('/profile');
        if (value == 'logout') ref.read(authProvider.notifier).logout();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(width: 8),
            Text(displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'profile', child: Text('Profil')),
        const PopupMenuItem(value: 'logout', child: Text('Çıkış Yap')),
      ],
    );
  }

  PreferredSizeWidget _buildMobileAppBar(String location) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(_getPageTitle(location), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
      actions: [
        IconButton(icon: const Icon(Icons.menu, color: AppColors.textPrimary), onPressed: _openRightDrawer),
      ],
    );
  }

  void _onBarcodeScanPressed() => context.go('/scanner');
}

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _AppBarIconBtn({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) => IconButton(icon: Icon(icon, size: 20, color: AppColors.textSecondary), onPressed: onPressed);
}
