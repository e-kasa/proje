import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/data_providers.dart';
import '../../providers/navigation_provider.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class EnhancedStockScreen extends ConsumerStatefulWidget {
  const EnhancedStockScreen({super.key});

  @override
  ConsumerState<EnhancedStockScreen> createState() => _EnhancedStockScreenState();
}

class _EnhancedStockScreenState extends ConsumerState<EnhancedStockScreen> {
  final _searchController = TextEditingController();
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    // Ekrana her dönüşte (navigate-back dahil) veriyi yenile.
    // stockProvider non-autoDispose → constructor tekrar çalışmaz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> all) {
    var filtered = all;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        return (p['name']?.toString().toLowerCase() ?? '').contains(query) ||
            (p['barcode']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    }

    switch (_filterType) {
      case 'critical':
        filtered = filtered.where((p) {
          final s = p['stock'] as num? ?? 0;
          return s > 0 && s <= 5;
        }).toList();
        break;
      case 'low':
        filtered = filtered.where((p) {
          final s = p['stock'] as num? ?? 0;
          return s > 5 && s <= 20;
        }).toList();
        break;
      case 'out':
        filtered = filtered.where((p) => (p['stock'] as num? ?? 0) == 0).toList();
        break;
      case 'good':
        filtered = filtered.where((p) => (p['stock'] as num? ?? 0) > 20).toList();
        break;
    }

    return filtered;
  }

  Color _getStockColor(num stock) {
    if (stock == 0) return AppColors.danger;
    if (stock <= 5) return AppColors.warning;
    if (stock <= 20) return AppColors.info;
    return AppColors.success;
  }

  String _getStockLabel(num stock) {
    final t = i18nOf(ref);
    if (stock == 0) return t('stock.out_of_stock');
    if (stock <= 5) return t('stock.critical');
    if (stock <= 20) return t('stock.low_stock');
    return t('stock.good');
  }

  void _onQuickSell(Map<String, dynamic> product) {
    final t = i18nOf(ref);
    context.go('/pos');
    AppToast.success(context, '${product['name']} ${t('stock.added_to_pos')}');
  }

  void _onEditProduct(Map<String, dynamic> product) {
    final t = i18nOf(ref);
    final stockController = TextEditingController(text: '${product['stock'] ?? 0}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${t('stock.edit_stock')} - ${product['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
              controller: stockController,
              label: t('stock.new_stock_quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          AppButton.outline(
            onPressed: () => Navigator.pop(context),
            text: t('common.cancel'),
          ),
          AppButton.primary(
            onPressed: () async {
              final newQty = int.tryParse(stockController.text);
              if (newQty == null || newQty < 0) return;
              Navigator.pop(context);

              final productId = product['id']?.toString();
              if (productId == null) return;

              final success = await ref.read(stockProvider.notifier).adjustStock(
                    productId: productId,
                    newQuantity: newQty,
                    reason: 'manual_adjustment',
                  );

              if (!mounted) return;
              if (success) {
                AppToast.success(context, t('stock.stock_updated'));
              } else {
                AppToast.error(context, t('stock.update_failed'));
              }
            },
            text: t('common.save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aynı menüye ikinci tıklamada yenile
    ref.listen(navigationRefreshProvider, (prev, next) {
      if (next.route == '/stock') ref.read(stockProvider.notifier).load();
    });

    final t = i18nOf(ref);
    final stockState = ref.watch(stockProvider);
    final filtered = _applyFilters(stockState.products);

    return AppScaffold(
      body: Column(
        children: [
          // Header with filters
          Container(
            color: Colors.white,
            padding: AppConstants.paddingMedium,
            child: Column(
              children: [
                // Search Bar
                AppSearchInput(
                  controller: _searchController,
                  hint: '${t('stock.search_product')}...',
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 12),

                // Quick Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(t('common.all'), 'all', Icons.grid_view),
                      const SizedBox(width: 8),
                      _buildFilterChip(t('stock.critical'), 'critical', Icons.warning_amber, AppColors.bgDanger,
                      const SizedBox(width: 8),
                      _buildFilterChip(t('stock.low_stock'), 'low', Icons.trending_down, AppColors.bgWarning,
                      const SizedBox(width: 8),
                      _buildFilterChip(t('stock.out_of_stock'), 'out', Icons.close, AppColors.bgDanger,
                      const SizedBox(width: 8),
                      _buildFilterChip(t('stock.good'), 'good', Icons.check_circle, AppColors.bgSuccess,
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stock Stats Summary
          Container(
            color: Colors.white,
            padding: AppConstants.paddingHorizontalMedium.copyWith(bottom: AppConstants.spacing16),
            child: Row(
              children: [
                _buildStatCard(
                  t('common.total'),
                  '${stockState.totalCount}',
                  AppColors.info,
                  Icons.inventory_2,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  t('stock.critical'),
                  '${stockState.criticalCount}',
                  AppColors.danger,
                  Icons.warning_amber,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  t('stock.low_stock'),
                  '${stockState.lowCount}',
                  AppColors.warning,
                  Icons.trending_down,
                ),
              ],
            ),
          ),

          // Quick Report Links
          Container(
            color: Colors.white,
            padding: AppConstants.paddingHorizontalMedium.copyWith(bottom: AppConstants.spacing8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildReportLink(t('stock.movement_history'), Icons.history, '/stock/movements', AppColors.bgInfo,
                  const SizedBox(width: 8),
                  _buildReportLink(t('stock.alerts'), Icons.notifications_active, '/stock/alerts', AppColors.bgDanger,
                  const SizedBox(width: 8),
                  _buildReportLink(t('stock.value_report'), Icons.bar_chart, '/stock/value-report', AppColors.bgSuccess,
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Product List
          Expanded(
            child: stockState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stockState.error != null
                    ? AppEmptyState(
                        icon: Icons.error_outline,
                        title: t('common.error'),
                        description: stockState.error!,
                        actionText: t('stock.retry'),
                        onAction: () => ref.read(stockProvider.notifier).load(),
                      )
                    : filtered.isEmpty
                        ? AppEmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: t('stock.no_product_found'),
                            description: t('stock.no_matching_product'),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(stockProvider.notifier).load(),
                            child: ListView.builder(
                              padding: AppConstants.paddingHorizontalMedium,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildProductCard(filtered[index]),
                            ),
                          ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppToast.warning(context, t('stock.count_feature_coming_soon'));
        },
        icon: const Icon(Icons.inventory),
        label: Text(t('stock.stock_count')),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildReportLink(String label, IconData icon, String route, Color color) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      backgroundColor: color.withValues(alpha: 0.05),
      onPressed: () => context.push(route),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, [Color? color]) {
    final isSelected = _filterType == value;
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : chipColor),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterType = value),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: chipColor),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: AppConstants.paddingSmall,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: AppConstants.paddingSmall,
              decoration: BoxDecoration(color: color, borderRadius: AppConstants.borderRadiusSmall),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(label, style: TextStyle(fontSize: 11, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final t = i18nOf(ref);
    final stock = product['stock'] as num? ?? 0;
    final stockColor = _getStockColor(stock);
    final stockLabel = _getStockLabel(stock);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacing8),
      child: Dismissible(
        key: Key(product['id'].toString()),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _onQuickSell(product);
          } else {
            _onEditProduct(product);
          }
          return false;
        },
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: AppConstants.spacing16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(t('stock.quick_sell'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: AppColors.info,
            borderRadius: AppConstants.borderRadiusMedium,
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppConstants.spacing16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(t('common.edit'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        child: AppCard(
          child: Padding(
            padding: AppConstants.paddingMedium,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.1),
                    borderRadius: AppConstants.borderRadiusMedium,
                  ),
                  child: Icon(Icons.inventory_2, color: stockColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AppBadge(
                            text: stockLabel,
                            color: stockColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${stock.toInt()} ${t('stock.unit_piece')}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (product['barcode'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${t('stock.barcode')}: ${product['barcode']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
