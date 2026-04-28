import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);

    // Sprint 16-B: Custom hub layout (banner + hero + sections) — template fit yok.
    // AppScaffold → BaseScaffold swap'iyle AsyncValue desteğine altyapı kazandırıldı.
    return BaseScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(t),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── İki büyük hero kart ──────────────────────────────
                  _buildHeroRow(context, t),
                  const SizedBox(height: 28),

                  // ── Ürün kataloğu ────────────────────────────────────
                  _buildSectionHeader(t('inventory.product_management')),
                  const SizedBox(height: 12),
                  _buildCatalogRow(context, t),
                  const SizedBox(height: 28),

                  // ── Stok operasyonları ───────────────────────────────
                  _buildSectionHeader(t('inventory.stock_management')),
                  const SizedBox(height: 12),
                  _buildStockList(context, t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner ──────────────────────────────────────────────────────────────────

  Widget _buildBanner(String Function(String) t) {
    return SizedBox(
      width: double.infinity,
      height: 116,
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A3C7A), AppColors.primary, Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox.expand(),
          ),
          // Dekoratif daireler
          Positioned(right: -28, top: -28, child: _circle(130, 0.07)),
          Positioned(right: 55, bottom: -42, child: _circle(90, 0.05)),
          Positioned(right: 140, top: -20, child: _circle(55, 0.04)),
          // İçerik
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t('inventory.title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        t('inventory.manage_products_stock'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero kartlar (Ürünler + Stok) ──────────────────────────────────────────

  Widget _buildHeroRow(BuildContext context, String Function(String) t) {
    return Row(
      children: [
        Expanded(
          child: _buildHeroCard(
            context,
            title: t('menu.products'),
            subtitle: t('inventory.manage_products'),
            icon: Icons.inventory_2_rounded,
            colors: const [Color(0xFF1565C0), AppColors.primary],
            route: '/inventory/products',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHeroCard(
            context,
            title: t('stock.stock'),
            subtitle: t('stock.stock_overview'),
            icon: Icons.analytics_rounded,
            colors: const [Color(0xFF00838F), Color(0xFF0097A7)],
            route: '/stock',
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required String route,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 128,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Dekoratif daireler
              Positioned(right: -14, bottom: -14, child: _circle(80, 0.12)),
              Positioned(right: 18, top: -20, child: _circle(48, 0.08)),
              // Büyük arka plan ikonu
              Positioned(
                right: 8,
                top: 10,
                child: Icon(
                  icon,
                  size: 52,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              // İçerik
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Ok işareti (sağ alt)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bölüm başlığı ───────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }

  // ── Yatay katalog satırı ────────────────────────────────────────────────────

  Widget _buildCatalogRow(BuildContext context, String Function(String) t) {
    final items = [
      _CItem(t('menu.categories'),         Icons.category_rounded,     AppColors.info,    '/inventory/categories'),
      _CItem(t('menu.brands'),             Icons.local_offer_rounded,   AppColors.success, '/inventory/brands'),
      _CItem(t('menu.units'),              Icons.straighten_rounded,    AppColors.warning, '/inventory/units'),
      _CItem(t('inventory.barcodes'),      Icons.qr_code_2_rounded,     AppColors.orange,  '/inventory/barcodes'),
      _CItem(t('batch.bulk_product_entry'),Icons.upload_file_rounded,   AppColors.pink,    '/inventory/batch-entry'),
    ];

    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _buildCatalogCard(context, items[i]),
      ),
    );
  }

  Widget _buildCatalogCard(BuildContext context, _CItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.09),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stok operasyonları listesi ──────────────────────────────────────────────

  Widget _buildStockList(BuildContext context, String Function(String) t) {
    final items = [
      _SItem(t('menu.warehouses'),    t('inventory.manage_warehouses'),   Icons.warehouse_rounded,      AppColors.info,    '/warehouses'),
      _SItem(t('menu.stock_transfer'),t('stock.transfer'),                Icons.sync_alt_rounded,       AppColors.success, '/stock/transfer'),
      _SItem(t('stock.alerts'),       t('stock.low_stock'),               Icons.warning_amber_rounded,  AppColors.warning, '/stock/alerts'),
      _SItem(t('stock.movements'),    t('stock.movement_history'),        Icons.history_rounded,        AppColors.orange,  '/stock/movements'),
      _SItem(t('stock.value_report'), t('stock.value_report_subtitle'),   Icons.assessment_rounded,     AppColors.pink,    '/stock/value-report'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildStockTile(context, items[i], isFirst: i == 0, isLast: i == items.length - 1),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 64, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStockTile(
    BuildContext context,
    _SItem item, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.45),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Yardımcı ─────────────────────────────────────────────────────────────────

  Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

// ── Veri modelleri ──────────────────────────────────────────────────────────────

class _CItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  const _CItem(this.title, this.icon, this.color, this.route);
}

class _SItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _SItem(this.title, this.subtitle, this.icon, this.color, this.route);
}
