import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/app_app_bar.dart';
import 'adaptive_sidebar.dart';
import 'adaptive_bottom_nav.dart';
import 'right_menu_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/i18n_provider.dart';

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

// Route → bundle kodu eşlemesi. i18n provider ile çözümlenir.
const _routeTitleBundles = <String, String>{
  '/dashboard': 'menu.dashboard',
  '/menu': 'menu.menu_list',
  '/profile': 'nav.profile',
  '/settings': 'menu.settings',
  '/settings/users': 'menu.user_management',
  '/settings/company': 'menu.company_settings',
  '/part-search': 'menu.part_search',
  '/vehicles': 'menu.vehicles',
  '/pos': 'menu.pos',
  '/sales': 'menu.sales_history',
  '/scanner': 'menu.barcode_scanner',
  '/stock': 'menu.stock',
  '/stock/multi-warehouse': 'menu.multi_warehouse_stock',
  '/stock/transfer': 'menu.stock_transfer',
  '/stock/transfer-review': 'menu.transfer_review',
  '/stock/count-review': 'menu.stock_count',
  '/stock/movements': 'menu.movement_history',
  '/stock/alerts': 'menu.stock_alerts',
  '/stock/value-report': 'menu.stock_value_report',
  '/inventory': 'inventory.title',
  '/inventory/products': 'menu.products',
  '/inventory/add-product': 'inventory.add_product',
  '/inventory/batch-entry': 'menu.batch_entry',
  '/inventory/categories': 'menu.categories',
  '/inventory/brands': 'menu.brands',
  '/inventory/units': 'menu.units',
  '/inventory/barcodes': 'menu.barcodes',
  '/categories/company-setup': 'menu.categories',
  '/bulk-import': 'bulk.title',
  '/bulk-import/review': 'bulk.review',
  '/bulk-import/supplier': 'bulk.supplier_import',
  '/bulk-import/supplier-wizard': 'bulk.supplier_import',
  '/bulk-import/supplier-upload': 'bulk.supplier_import',
  '/purchases': 'menu.purchases',
  '/purchases/create': 'menu.new_purchase',
  '/customers': 'menu.customers',
  '/customers/add': 'customer.add',
  '/suppliers': 'menu.suppliers',
  '/suppliers/add': 'supplier.add',
  '/accounts': 'accounts.title',
  '/accounts/statement': 'accounts.statement',
  '/accounts/overdue': 'accounts.overdue',
  '/warehouses': 'menu.warehouses',
  '/warehouses/add': 'warehouse.add',
  '/stores': 'menu.stores',
  '/stores/add': 'store.add',
  '/finance': 'menu.finance',
  '/finance/expenses': 'finance.expenses',
  '/finance/expenses/add': 'finance.add_expense',
  '/finance/add-income': 'finance.add_income',
  '/finance/payments': 'finance.payments',
  '/finance/cash-flow': 'finance.cash_flow',
  '/hrm/employees': 'hrm.employees',
  '/hrm/employees/add': 'hrm.add_employee',
  '/reports': 'menu.reports',
  '/reports/daily-summary': 'reports.daily_summary',
  '/reports/sales-summary': 'reports.sales_summary',
  '/reports/product-analysis': 'reports.product_analysis',
  '/reports/customer-analysis': 'reports.customer_analysis',
  '/reports/profit-overview': 'reports.profit_overview',
  '/settings/sector': 'settings.sector_settings',
};

/// Route icin bundle kodunu bulur, i18n state ile cevirir.
String _getPageTitle(String location, I18nState i18n) {
  final bundleCode = _routeTitleBundles[location] ?? _routeTitleBundles.entries
      .where((e) => location.startsWith(e.key))
      .fold<String?>('Panel', (_, e) => e.value);
  if (bundleCode == null || bundleCode == 'Panel') return 'Panel';
  return i18n.isLoaded ? i18n.bundle(bundleCode) : bundleCode;
}

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

  // Fallback menü — backend'den veri gelene kadar gösterilir
  static final List<NavigationItem> _defaultWebNavItems = [
    NavigationItem(icon: Icons.dashboard_outlined, label: 'Ana Sayfa', route: '/dashboard', sectionLabel: 'GENEL'),
    NavigationItem(icon: Icons.grid_view_outlined, label: 'Menü Listesi', route: '/menu'),
    NavigationItem(icon: Icons.search_outlined, label: 'Parça Ara', route: '/part-search'),
    NavigationItem(icon: Icons.point_of_sale_outlined, label: 'Satış / POS', route: '/pos', sectionLabel: 'SATIŞ'),
    NavigationItem(icon: Icons.history_outlined, label: 'Satış Geçmişi', route: '/sales'),
    NavigationItem(icon: Icons.list_alt_outlined, label: 'Ürünler', route: '/inventory/products', sectionLabel: 'ÜRÜN KATALOĞU'),
    NavigationItem(icon: Icons.category_outlined, label: 'Kategoriler', route: '/inventory/categories'),
    NavigationItem(icon: Icons.inventory_2_outlined, label: 'Stok Durumu', route: '/stock', sectionLabel: 'STOK YÖNETİMİ'),
    NavigationItem(icon: Icons.warehouse_outlined, label: 'Depolar', route: '/warehouses'),
    NavigationItem(icon: Icons.shopping_cart_outlined, label: 'Satın Alma', route: '/purchases', sectionLabel: 'TEDARİK'),
    NavigationItem(icon: Icons.business_outlined, label: 'Tedarikçiler', route: '/suppliers'),
    NavigationItem(icon: Icons.people_outlined, label: 'Müşteriler', route: '/customers', sectionLabel: 'CARİ HESAPLAR'),
    NavigationItem(icon: Icons.account_balance_wallet_outlined, label: 'Cari Hesaplar', route: '/accounts'),
    NavigationItem(icon: Icons.account_balance_outlined, label: 'Finans', route: '/finance', sectionLabel: 'FİNANS'),
    NavigationItem(icon: Icons.analytics_outlined, label: 'Raporlar', route: '/reports'),
    NavigationItem(icon: Icons.settings_outlined, label: 'Ayarlar', route: '/settings', sectionLabel: 'YÖNETİM'),
  ];

  static final List<NavigationItem> _defaultMobileNavItems = [
    NavigationItem(icon: Icons.dashboard_outlined, label: 'Ana Sayfa', route: '/dashboard'),
    NavigationItem(icon: Icons.search_outlined, label: 'Parça Ara', route: '/part-search'),
    NavigationItem(icon: Icons.inventory_2_outlined, label: 'Stok', route: '/stock'),
    NavigationItem(icon: Icons.point_of_sale_outlined, label: 'Satış', route: '/pos'),
  ];

  bool _menuLoaded = false;

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

    // Menü ve i18n verilerini backend'den yükle (bir kere)
    final menuState = ref.watch(menuProvider);
    final i18nState = ref.watch(i18nProvider);
    if (!_menuLoaded && !menuState.isLoading && menuState.categories.isEmpty) {
      _menuLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(menuProvider.notifier).loadMenus();
        if (!i18nState.isLoaded) {
          ref.read(i18nProvider.notifier).loadTranslations();
        }
      });
    }

    // Dinamik menü öğeleri — backend'den geldiyse i18n ile çevir, yoksa fallback
    final webNavItems = menuState.categories.isNotEmpty
        ? ref.read(menuProvider.notifier).toSidebarItems(i18n: i18nState)
        : _defaultWebNavItems;
    final mobileNavItems = menuState.categories.isNotEmpty
        ? ref.read(menuProvider.notifier).toMobileItems(i18n: i18nState)
        : _defaultMobileNavItems;

    // Menü sayfasındaysak ve Desktop modundaysak Sidebar'ı tamamen gizle
    final hideSidebarOnDesktop = location == '/menu' && !isMobile;

    if (context.shouldShowSidebar && !hideSidebarOnDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        body: Row(
          children: [
            AdaptiveSidebar(
              items: webNavItems,
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
        items: mobileNavItems,
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
        final pageTitle = _getPageTitle(location, ref.read(i18nProvider));

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
                // Dil değiştirme butonu
                _buildLanguageToggle(ref),
                const SizedBox(width: 4),
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
        if (value == 'logout') {
          ref.read(menuProvider.notifier).clearMenus();
          ref.read(authProvider.notifier).logout();
        }
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
      itemBuilder: (_) {
        final t = ref.read(i18nProvider);
        return [
          PopupMenuItem(value: 'profile', child: Text(t.isLoaded ? t.bundle('nav.profile') : 'Profil')),
          PopupMenuItem(value: 'logout', child: Text(t.isLoaded ? t.bundle('nav.logout') : 'Çıkış Yap')),
        ];
      },
    );
  }

  Widget _buildLanguageToggle(WidgetRef ref) {
    final currentLang = ref.watch(i18nProvider).lang;
    final isTr = currentLang == 'TR';
    return GestureDetector(
      onTap: () {
        final newLang = isTr ? 'EN' : 'TR';
        ref.read(i18nProvider.notifier).changeLanguage(newLang);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              isTr ? 'TR' : 'EN',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(String location) {
    return AppAppBar.standard(
      title: _getPageTitle(location, ref.read(i18nProvider)),
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
                                                                                                              