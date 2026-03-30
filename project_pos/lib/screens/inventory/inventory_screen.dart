import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/section_header.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeInDown(
                child: const SectionHeader(
                  title: 'Inventory',
                  subtitle: 'Manage your products and stock',
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
                      title: 'Products',
                      subtitle: 'Manage all products',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.primaryColor,
                      onTap: () => context.go('/inventory/products'),
                    ),
                    _buildQuickActionCard(
                      context,
                      title: 'Categories',
                      subtitle: 'Organize categories',
                      icon: Icons.category_outlined,
                      color: AppTheme.secondaryColor,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      context,
                      title: 'Brands',
                      subtitle: 'Manage brands',
                      icon: Icons.local_offer_outlined,
                      color: AppTheme.successColor,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      context,
                      title: 'Stock Alert',
                      subtitle: 'Low stock items',
                      icon: Icons.warning_amber_outlined,
                      color: AppTheme.warningColor,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      context,
                      title: 'Warehouse',
                      subtitle: 'Manage warehouses',
                      icon: Icons.warehouse_outlined,
                      color: AppTheme.accentColor,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      context,
                      title: 'Stock Transfer',
                      subtitle: 'Transfer stock',
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
    return Card(
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
                  color: color.withOpacity(0.1),
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
