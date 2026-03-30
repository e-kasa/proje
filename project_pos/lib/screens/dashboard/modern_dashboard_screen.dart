import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/service_locator.dart';

class ModernDashboardScreen extends ConsumerStatefulWidget {
  const ModernDashboardScreen({super.key});

  @override
  ConsumerState<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends ConsumerState<ModernDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardStats = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final reportService = ref.read(reportServiceProvider);
      final stats = await reportService.getDashboardStats();

      setState(() {
        _dashboardStats = stats;
        _isLoading = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aynı menüye ikinci tıklanınca refresh tetikle
    ref.listen(navigationRefreshProvider, (prev, next) {
      if (next.route == '/dashboard') _loadDashboardData();
    });

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: _isLoading
          ? _buildSkeleton()
          : _error.isNotEmpty
              ? AppEmptyState.error(
                  description: _error,
                  onAction: _loadDashboardData,
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: AppConstants.paddingMedium,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: AppConstants.spacing24),
                        _buildQuickActions(context),
                        const SizedBox(height: AppConstants.spacing24),
                        _buildQuickStats(),
                        const SizedBox(height: AppConstants.spacing24),
                        _buildAlerts(),
                        const SizedBox(height: AppConstants.spacing24),
                        _buildModuleCards(context),
                        const SizedBox(height: AppConstants.spacing24),
                        _buildRecentActivity(),
                      ],
                    ),
                  ),
                ),
    );
  }

  // -------------------------------------------------------------------------
  // Skeleton yükleme ekranı
  // -------------------------------------------------------------------------
  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: AppConstants.paddingMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          AppShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonItem(width: 120, height: 18),
                const SizedBox(height: 8),
                AppSkeletonItem(width: 220, height: 32),
                const SizedBox(height: 6),
                AppSkeletonItem(width: 150, height: 14),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),

          // Quick stats skeleton
          Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: const AppSkeletonStatCard(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),

          // Quick actions skeleton
          AppShimmer(
            child: AppSkeletonItem(width: 160, height: 20),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: List.generate(
              6,
              (_) => AppShimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppConstants.borderRadiusMedium,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),

          // Module cards skeleton
          Row(
            children: List.generate(
              2,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppShimmer(
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: AppConstants.borderRadiusLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? '🌅 Günaydın'
        : now.hour < 18
            ? '☀️ İyi günler'
            : '🌙 İyi akşamlar';

    final user = ref.watch(authProvider).user;
    final name = user?.displayName ?? 'Admin';
    final company = user?.selectedCompanyCode ?? '';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacing8),
              const Text(
                'Yönetim Paneli',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacing4),
              Text(
                '${now.day} ${_getMonthName(now.month)} ${now.year}'
                '${company.isNotEmpty ? '  •  $company' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        // Yenile butonu
        IconButton(
          onPressed: _loadDashboardData,
          icon: const Icon(
            Icons.refresh_outlined,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Verileri Yenile',
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı Aksiyonlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacing16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _buildQuickActionCard(
              icon: Icons.qr_code_scanner,
              label: 'Barkod\nTara',
              color: AppColors.primary,
              onTap: () => context.go('/scanner'),
            ),
            _buildQuickActionCard(
              icon: Icons.add_shopping_cart,
              label: 'Hızlı\nSatış',
              color: AppColors.success,
              onTap: () => context.go('/pos'),
            ),
            _buildQuickActionCard(
              icon: Icons.receipt_long,
              label: 'Satış\nGeçmişi',
              color: AppColors.info,
              onTap: () => context.go('/sales'),
            ),
            _buildQuickActionCard(
              icon: Icons.warning_amber,
              label: 'Kritik\nStok',
              color: AppColors.danger,
              onTap: () => context.go('/stock'),
            ),
            _buildQuickActionCard(
              icon: Icons.inventory,
              label: 'Stok\nSayım',
              color: Colors.purple,
              onTap: () => context.go('/stock'),
            ),
            _buildQuickActionCard(
              icon: Icons.add_box,
              label: 'Yeni\nÜrün',
              color: Colors.teal,
              onTap: () => context.go('/inventory/add-product'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppConstants.borderRadiusMedium,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlerts() {
    final lowStockCount = _dashboardStats['lowStockProducts'] ?? 0;

    if (lowStockCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uyarılar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacing12),
        Container(
          padding: AppConstants.paddingMedium,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: AppConstants.borderRadiusMedium,
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Düşük Stok Uyarısı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$lowStockCount ürün kritik stok seviyesinde',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.go('/stock'),
                icon: const Icon(Icons.arrow_forward, color: AppColors.warning),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final totalSales = _dashboardStats['totalSales'] ?? 0;
    final totalRevenue = _dashboardStats['totalRevenue'] ?? 0.0;
    final totalProducts = _dashboardStats['totalProducts'] ?? 0;
    final totalCustomers = _dashboardStats['totalCustomers'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            title: 'Toplam Satış',
            value: totalSales.toString(),
            icon: Icons.shopping_cart,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppConstants.spacing12),
        Expanded(
          child: AppStatCard(
            title: 'Toplam Gelir',
            value: '₺${totalRevenue.toStringAsFixed(0)}',
            icon: Icons.attach_money,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppConstants.spacing12),
        Expanded(
          child: AppStatCard(
            title: 'Ürünler',
            value: totalProducts.toString(),
            icon: Icons.inventory_2,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hızlı Erişim',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                _buildQuickStatChip(
                  'Müşteri',
                  (_dashboardStats['totalCustomers'] ?? 0).toString(),
                  Icons.people,
                  AppColors.info,
                ),
                const SizedBox(width: 8),
                _buildQuickStatChip(
                  'Düşük Stok',
                  (_dashboardStats['lowStockProducts'] ?? 0).toString(),
                  Icons.warning_amber,
                  AppColors.warning,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacing16),

        // Row 1: POS + Ürünler
        Row(
          children: [
            Expanded(
              child: _buildModuleCard(
                context: context,
                title: 'POS Satış',
                subtitle: 'Hızlı satış işlemleri',
                icon: Icons.point_of_sale,
                gradient: AppGradients.primaryGradient,
                onTap: () => context.go('/pos'),
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: _buildModuleCard(
                context: context,
                title: 'Ürünler',
                subtitle: '${_dashboardStats['totalProducts'] ?? 0} ürün',
                icon: Icons.shopping_bag,
                gradient: AppGradients.coralGradient,
                onTap: () => context.go('/inventory/products'),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacing12),

        // Row 2: Kategoriler + Müşteriler
        Row(
          children: [
            Expanded(
              child: _buildModuleCard(
                context: context,
                title: 'Kategoriler',
                subtitle: 'Kategori yönetimi',
                icon: Icons.category,
                gradient: AppGradients.purpleGradient,
                onTap: () => context.go('/inventory/categories'),
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: _buildModuleCard(
                context: context,
                title: 'Müşteriler',
                subtitle: '${_dashboardStats['totalCustomers'] ?? 0} müşteri',
                icon: Icons.people_outline,
                gradient: AppGradients.blueGradient,
                onTap: () => context.go('/customers'),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spacing12),

        // Row 3: Stok + Raporlar
        Row(
          children: [
            Expanded(
              child: _buildModuleCard(
                context: context,
                title: 'Stok Yönetimi',
                subtitle: '${_dashboardStats['lowStockProducts'] ?? 0} düşük stok',
                icon: Icons.inventory,
                gradient: AppGradients.mintGradient,
                onTap: () => context.go('/stock'),
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              child: _buildModuleCard(
                context: context,
                title: 'Raporlar',
                subtitle: 'Analiz ve raporlar',
                icon: Icons.analytics,
                gradient: AppGradients.sunsetGradient,
                onTap: () => context.go('/reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppConstants.borderRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppConstants.borderRadiusLarge,
          child: Padding(
            padding: AppConstants.paddingMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: AppConstants.borderRadiusMedium,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppConstants.spacing4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentSales = _dashboardStats['recentSales'] as List? ?? [];
    final lowStockItems = _dashboardStats['lowStockItems'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/reports'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacing12),
        AppCard(
          child: Column(
            children: [
              if (recentSales.isNotEmpty)
                ...recentSales.take(3).map((sale) => Column(
                      children: [
                        _buildActivityItem(
                          icon: Icons.shopping_cart,
                          title: 'Yeni satış',
                          subtitle:
                              'SAT-${sale['id']} - ₺${(sale['totalAmount'] ?? 0).toStringAsFixed(2)}',
                          time: _getTimeAgo(sale['date']),
                          iconColor: AppColors.success,
                        ),
                        if (sale != recentSales.take(3).last)
                          const Divider(height: 1),
                      ],
                    ))
              else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Henüz satış yok',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              if (lowStockItems.isNotEmpty) ...[
                const Divider(height: 1),
                ...lowStockItems.take(2).map((product) => Column(
                      children: [
                        _buildActivityItem(
                          icon: Icons.warning_amber,
                          title: 'Düşük stok',
                          subtitle:
                              '${product['name']} - ${product['stock']} adet kaldı',
                          time: 'Şimdi',
                          iconColor: AppColors.warning,
                        ),
                        if (product != lowStockItems.take(2).last)
                          const Divider(height: 1),
                      ],
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color iconColor,
  }) {
    return Padding(
      padding: AppConstants.paddingMedium,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: AppConstants.borderRadiusMedium,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Bilinmiyor';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Şimdi';
      }
    } catch (e) {
      return 'Bilinmiyor';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month - 1];
  }
}
