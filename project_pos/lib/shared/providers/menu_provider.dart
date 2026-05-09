import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/layouts/responsive_layout.dart';
import 'package:project_pos/core/utils/app_logger.dart';
import 'package:project_pos/models/menu_models.dart';
import 'package:project_pos/services/menu_service.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/shared/providers/i18n_provider.dart';

// ── Icon string → IconData mapping ──────────────────────────────────────────
const menuIconMap = <String, IconData>{
  'dashboard_outlined': Icons.dashboard_outlined,
  'grid_view_outlined': Icons.grid_view_outlined,
  'search_outlined': Icons.search_outlined,
  'point_of_sale_outlined': Icons.point_of_sale_outlined,
  'history_outlined': Icons.history_outlined,
  'list_alt_outlined': Icons.list_alt_outlined,
  'category_outlined': Icons.category_outlined,
  'inventory_2_outlined': Icons.inventory_2_outlined,
  'warehouse_outlined': Icons.warehouse_outlined,
  'shopping_cart_outlined': Icons.shopping_cart_outlined,
  'business_outlined': Icons.business_outlined,
  'people_outlined': Icons.people_outlined,
  'account_balance_wallet_outlined': Icons.account_balance_wallet_outlined,
  'account_balance_outlined': Icons.account_balance_outlined,
  'analytics_outlined': Icons.analytics_outlined,
  'settings_outlined': Icons.settings_outlined,
  'storefront_outlined': Icons.storefront_outlined,
  'manage_accounts_outlined': Icons.manage_accounts_outlined,
};

// ── State ───────────────────────────────────────────────────────────────────
class MenuState {
  final List<MenuCategoryModel> categories;
  final bool isLoading;
  final String? error;

  MenuState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  /// Tüm menu item link'lerinin flat seti
  Set<String> get allowedRoutes => categories
      .expand((c) => c.menus)
      .expand((m) => m.items)
      .map((i) => i.link)
      .toSet();

  MenuState copyWith({
    List<MenuCategoryModel>? categories,
    bool? isLoading,
    String? error,
  }) {
    return MenuState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ────────────────────────────────────────────────────────────────
class MenuNotifier extends StateNotifier<MenuState> {
  final MenuService _menuService;

  MenuNotifier(this._menuService) : super(MenuState());

  Future<void> loadMenus() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _menuService.getMenusForUser();
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      AppLogger.error('Menu yükleme hatası', tag: 'Menu', error: e);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearMenus() {
    state = MenuState();
  }

  /// Route'un izinli olup olmadığını kontrol eder.
  /// Tam eşleşme veya prefix match yapar.
  bool isRouteAllowed(String route) {
    if (state.categories.isEmpty) return true; // menü yüklenmeden guard yapma
    final allowed = state.allowedRoutes;
    return allowed.any((a) => route == a || route.startsWith('$a/'));
  }

  /// Bundle kodunu çevrilmiş metne dönüştürür. i18n yoksa kodu döner.
  String _t(String bundleCode, I18nState? i18n) {
    if (i18n == null || !i18n.isLoaded) return bundleCode;
    return i18n.bundle(bundleCode);
  }

  /// Backend menu verilerini sidebar NavigationItem listesine dönüştürür.
  /// Label'lar bundle kodu olarak gelir, i18n ile çevrilir.
  ///
  /// Sprint 11i — flatten: her menu'nun **her alt item'ı** ayrı satır olur.
  /// Section label sadece kategorinin ilk item'ında görünür → menu launcher
  /// ekranıyla (`/menu`) sidebar tutarlı; kullanıcı tüm modülleri sidebar'dan
  /// tek tıkla erişir.
  List<NavigationItem> toSidebarItems({I18nState? i18n}) {
    final items = <NavigationItem>[];
    for (final cat in state.categories) {
      bool firstInCategory = true;
      for (final menu in cat.menus) {
        for (final item in menu.items) {
          items.add(NavigationItem(
            icon: menuIconMap[menu.icon] ?? Icons.circle_outlined,
            label: _t(item.label, i18n),
            route: item.link,
            sectionLabel:
                firstInCategory ? _t(cat.label, i18n) : null,
          ));
          firstInCategory = false;
        }
      }
    }
    return items;
  }

  /// Mobil navigasyon için izin verilen 4 menüyü döner.
  List<NavigationItem> toMobileItems({I18nState? i18n}) {
    final allowed = state.allowedRoutes;
    final priority = <_MobileNavDef>[
      _MobileNavDef('/dashboard', Icons.dashboard_outlined, 'menu.dashboard'),
      _MobileNavDef('/pos', Icons.point_of_sale_outlined, 'menu.pos'),
      _MobileNavDef('/stock', Icons.inventory_2_outlined, 'menu.stock'),
      _MobileNavDef('/part-search', Icons.search_outlined, 'menu.part_search'),
    ];
    return priority
        .where((p) => p.route == '/dashboard' || allowed.contains(p.route))
        .take(4)
        .map((p) => NavigationItem(icon: p.icon, label: _t(p.label, i18n), route: p.route))
        .toList();
  }
}

class _MobileNavDef {
  final String route;
  final IconData icon;
  final String label;
  const _MobileNavDef(this.route, this.icon, this.label);
}

// ── Provider ────────────────────────────────────────────────────────────────
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final menuService = ref.watch(menuServiceProvider);
  return MenuNotifier(menuService);
});
