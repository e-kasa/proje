import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/service_locator.dart';
import '../../core/utils/i18n_helper.dart';

class ModernDashboardScreen extends ConsumerStatefulWidget {
  const ModernDashboardScreen({super.key});

  @override
  ConsumerState<ModernDashboardScreen> createState() =>
      _ModernDashboardScreenState();
}

class _ModernDashboardScreenState
    extends ConsumerState<ModernDashboardScreen> {
  String Function(String) get t => i18nOf(ref);
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await ref.read(reportServiceProvider).getDashboardStats();
      if (mounted) setState(() { _stats = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(navigationRefreshProvider, (_, next) {
      if (next.route == '/dashboard') _load();
    });

    if (_isLoading) return _buildSkeleton();
    if (_error.isNotEmpty) {
      return AppEmptyState.error(description: _error, onAction: _load);
    }

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader()),
            SliverToBoxAdapter(child: _buildKpiRow()),
            SliverToBoxAdapter(child: _buildSectionTitle('Hızlı Aksiyonlar')), // TODO: i18n
            SliverToBoxAdapter(child: _buildQuickActions()),
            SliverToBoxAdapter(child: _buildSectionTitle('Modüller')), // TODO: i18n
            SliverToBoxAdapter(child: _buildModules()),
            SliverToBoxAdapter(child: _buildSectionTitle('Son Aktiviteler')), // TODO: i18n
            SliverToBoxAdapter(child: _buildActivity()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ── HERO HEADER ─────────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? t('dashboard.good_morning') // TODO: i18n key
        : hour < 18
            ? t('dashboard.good_day') // TODO: i18n key
            : t('dashboard.good_evening'); // TODO: i18n key
    final icon = hour < 12 ? '🌅' : hour < 18 ? '☀️' : '🌙';
    final user = ref.watch(authProvider).user;
    final name = user?.displayName ?? 'Admin';
    final company = user?.selectedCompanyCode ?? '';
    final dateStr = DateFormat('d MMMM yyyy', 'tr_TR').format(now);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$icon $greeting,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          if (company.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.business_outlined,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              company,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Refresh + avatar
                Column(
                  children: [
                    _headerIconButton(
                      icon: Icons.refresh_outlined,
                      onTap: _load,
                      tooltip: t('common.refresh'), // TODO: i18n key common.refresh
                    ),
                    const SizedBox(height: 10),
                    _headerIconButton(
                      icon: Icons.person_outline,
                      onTap: () => context.go('/profile'),
                      tooltip: t('profile.title'),
                      hasBorder: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool hasBorder = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: hasBorder
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  )
                : null,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ── KPI ROW ─────────────────────────────────────────────────────────────────
  Widget _buildKpiRow() {
    final revenue = (_stats['totalRevenue'] as num?)?.toDouble() ?? 0;
    final sales = (_stats['totalSales'] as num?)?.toInt() ?? 0;
    final customers = (_stats['totalCustomers'] as num?)?.toInt() ?? 0;
    final lowStock = (_stats['lowStockProducts'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _kpiCard(
              label: t('dashboard.sales_today'),
              value: '₺${_fmt(revenue)}',
              icon: Icons.payments_outlined,
              color: AppColors.success,
              gradient: AppGradients.successGradient,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _kpiCard(
              label: 'Satış Adedi', // TODO: i18n
              value: sales.toString(),
              icon: Icons.shopping_cart_outlined,
              color: AppColors.primary,
              gradient: AppGradients.primaryGradient,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _kpiCard(
              label: 'Müşteriler', // TODO: i18n
              value: customers.toString(),
              icon: Icons.people_outline,
              color: AppColors.info,
              gradient: AppGradients.infoGradient,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _kpiCard(
              label: 'Düşük Stok', // TODO: i18n
              value: lowStock.toString(),
              icon: Icons.warning_amber_outlined,
              color: lowStock > 0 ? AppColors.danger : AppColors.success,
              gradient: lowStock > 0
                  ? AppGradients.dangerGradient
                  : AppGradients.successGradient,
              onTap: () => context.go('/stock/alerts'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── QUICK ACTIONS ────────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _Action('POS Satış', Icons.point_of_sale, AppGradients.successGradient, '/pos'), // TODO: i18n
      _Action('Barkod Tara', Icons.qr_code_scanner, AppGradients.primaryGradient, '/scanner'), // TODO: i18n
      _Action('Satış Geçmişi', Icons.receipt_long_outlined, AppGradients.infoGradient, '/sales'), // TODO: i18n
      _Action('Stok Durumu', Icons.inventory_2_outlined, AppGradients.mintGradient, '/stock'), // TODO: i18n
      _Action('Yeni Ürün', Icons.add_box_outlined, AppGradients.purpleGradient, '/inventory/add-product'), // TODO: i18n
      _Action('Raporlar', Icons.bar_chart_rounded, AppGradients.sunsetGradient, '/reports'), // TODO: i18n
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (_, i) => _quickActionTile(actions[i]),
      ),
    );
  }

  Widget _quickActionTile(_Action a) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go(a.route),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: a.gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(a.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MODULES ──────────────────────────────────────────────────────────────────
  Widget _buildModules() {
    final products = (_stats['totalProducts'] as num?)?.toInt() ?? 0;
    final customers = (_stats['totalCustomers'] as num?)?.toInt() ?? 0;
    final lowStock = (_stats['lowStockProducts'] as num?)?.toInt() ?? 0;

    final modules = [
      _Module(t('dashboard.total_products'), '$products ürün', Icons.shopping_bag_outlined, // TODO: i18n subtitle
          AppGradients.coralGradient, '/inventory/products'),
      _Module('Müşteriler', '$customers kayıt', Icons.people_outline, // TODO: i18n
          AppGradients.blueGradient, '/customers'),
      _Module('Tedarikçiler', 'Hesap yönetimi', Icons.local_shipping_outlined, // TODO: i18n
          AppGradients.primaryGradient, '/suppliers'),
      _Module('Stok Alarmları', '$lowStock ürün kritik', Icons.notifications_active_outlined, // TODO: i18n
          lowStock > 0 ? AppGradients.dangerGradient : AppGradients.mintGradient,
          '/stock/alerts'),
      _Module('Cari Hesaplar', 'Bakiye takibi', Icons.account_balance_wallet_outlined, // TODO: i18n
          AppGradients.warningGradient, '/accounts'),
      _Module('Satış Analizi', 'Günlük rapor', Icons.analytics_outlined, // TODO: i18n
          AppGradients.sunsetGradient, '/reports/sales-summary'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: modules.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.7,
        ),
        itemBuilder: (_, i) => _moduleTile(modules[i]),
      ),
    );
  }

  Widget _moduleTile(_Module m) {
    return Container(
      decoration: BoxDecoration(
        gradient: m.gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (m.gradient.colors.first).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.go(m.route),
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(m.icon, size: 60,
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.icon, color: Colors.white, size: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ACTIVITY ─────────────────────────────────────────────────────────────────
  Widget _buildActivity() {
    final recentSales = _stats['recentSales'] as List? ?? [];
    final lowStockItems = _stats['lowStockItems'] as List? ?? [];

    final items = <_ActivityItem>[];

    for (final s in recentSales.take(4)) {
      final amount = (s['totalAmount'] as num?)?.toDouble() ?? 0;
      items.add(_ActivityItem(
        icon: Icons.shopping_cart_checkout,
        color: AppColors.success,
        title: 'Satış tamamlandı', // TODO: i18n
        subtitle: 'SAT-${s['id']} — ₺${amount.toStringAsFixed(2)}',
        time: _timeAgo(s['date']),
      ));
    }
    for (final p in lowStockItems.take(3)) {
      items.add(_ActivityItem(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        title: 'Düşük stok uyarısı', // TODO: i18n
        subtitle: '${p['name']} — ${p['stock']} adet kaldı', // TODO: i18n
        time: 'Şimdi', // TODO: i18n
      ));
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: AppEmptyState.noData(
          title: t('common.no_data'),
          description: 'Satış yapıldığında ve stok durumu değiştiğinde burada görünecek.', // TODO: i18n
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Son Aktiviteler', // TODO: i18n
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go('/reports'),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Tümünü gör →', // TODO: i18n
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : AppColors.border),
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _activityRow(item),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: AppColors.border.withValues(alpha: isDark ? 0.2 : 0.5),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _activityRow(_ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(item.time,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              )),
        ],
      ),
    );
  }

  // ── SECTION TITLE ────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ── SKELETON ─────────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer(
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(4, (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppShimmer(
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            AppShimmer(child: AppSkeletonItem(width: 150, height: 18)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: List.generate(6, (_) => AppShimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────
  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}B';
    return v.toStringAsFixed(0);
  }

  String _timeAgo(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr.toString());
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 0) return '${diff.inDays}g önce';
      if (diff.inHours > 0) return '${diff.inHours}s önce';
      if (diff.inMinutes > 0) return '${diff.inMinutes}dk';
      return 'Şimdi';
    } catch (_) {
      return '';
    }
  }
}

// ── MODELS ───────────────────────────────────────────────────────────────────
class _Action {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final String route;
  const _Action(this.label, this.icon, this.gradient, this.route);
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  const _Module(this.title, this.subtitle, this.icon, this.gradient, this.route);
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}