import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_theme.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeInDown(
                child: SectionHeader(
                  title: t('inventory.title'),
                  subtitle: t('inventory.manage_products_stock'),
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildQuickActionCard(
                      context,
                      title: t('menu.products'),
                      subtitle: t('inventory.manage_products'),
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.primaryColor,
                      onTap: () => context.go('/inventory/products'),
                    ),
                    _buildQuickActionCard(
                      context,
                      title: t('menu.categories'),
                      subtitle: t('inventory.organize_categories'),
                      icon: Icons.category_outlined,
                      color: AppTheme.secondaryColor,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      context,
                      title: t('menu.brands'),
                      subtitle: t('inventory.manage_brands'),
                      icon: Icons.local_offer_outlined,
                      color: AppTheme.successColor,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      context,
                      title: t('stock.alerts'),
                      subtitle: t('stock.low_stock'),
                      icon: Icons.warning_amber_outlined,
                      color: AppTheme.warningColor,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      context,
                      title: t('menu.warehouses'),
                      subtitle: t('inventory.manage_warehouses'),
                      icon: Icons.warehouse_outlined,
                      color: AppTheme.accentColor,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      context,
                      title: t('menu.stock_transfer'),
                      subtitle: t('stock.transfer'),
                      icon: Icons.sync_alt_outlined,
                      color: AppTheme.primaryColor,
                      onTap: () {},
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

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}