import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/section_header.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/i18n_helper.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

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
                  title: t('sales.title'),
                  subtitle: t('sales.subtitle'), // TODO: i18n key: sales.subtitle
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      title: t('sales.today_sales'), // TODO: i18n key: sales.today_sales
                      value: '\$12,345',
                      change: '+15.3%',
                      isPositive: true,
                      icon: Icons.trending_up,
                      color: AppTheme.successColor,
                    ),
                    StatCard(
                      title: t('sales.orders'), // TODO: i18n key: sales.orders
                      value: '234',
                      change: '+8.1%',
                      isPositive: true,
                      icon: Icons.shopping_cart,
                      color: AppTheme.primaryColor,
                    ),
                    StatCard(
                      title: t('sales.pending'), // TODO: i18n key: sales.pending
                      value: '12',
                      change: '-5.2%',
                      isPositive: false,
                      icon: Icons.schedule,
                      color: AppTheme.warningColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recent Sales Table
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t('sales.recent_sales'), // TODO: i18n key: sales.recent_sales
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Row(
                              children: [
                                AppButton.outline(
                                  text: t('common.filter'),
                                  icon: Icons.filter_list,
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 12),
                                AppButton.primary(
                                  text: t('sales.new_sale'), // TODO: i18n key: sales.new_sale
                                  icon: Icons.add,
                                  size: ButtonSize.small,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSalesTable(context, t),
                      ],
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesTable(BuildContext context, String Function(String) t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          AppTheme.backgroundColor,
        ),
        columns: [
          DataColumn(label: Text(t('sales.order_id'))), // TODO: i18n key: sales.order_id
          DataColumn(label: Text(t('sales.customer'))),
          DataColumn(label: Text(t('sales.date'))),
          DataColumn(label: Text(t('sales.amount'))), // TODO: i18n key: sales.amount
          DataColumn(label: Text(t('sales.status'))), // TODO: i18n key: sales.status
          DataColumn(label: Text(t('common.actions'))), // TODO: i18n key: common.actions
        ],
        rows: List.generate(
          10,
          (index) => DataRow(
            cells: [
              DataCell(Text('#ORD-${1000 + index}')),
              DataCell(Text('Customer ${index + 1}')),
              DataCell(Text('2024-01-${(index % 28) + 1}')),
              DataCell(
                Text(
                  '\$${(index + 1) * 150}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              DataCell(
                _buildStatusChip(index % 3 == 0 ? t('sales.completed') : t('sales.pending_status'), t), // TODO: i18n keys: sales.completed, sales.pending_status
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      onPressed: () {},
                      tooltip: t('common.view'), // TODO: i18n key: common.view
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () {},
                      tooltip: t('common.edit'),
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

  Widget _buildStatusChip(String status, String Function(String) t) {
    final completedLabel = t('sales.completed'); // TODO: i18n key: sales.completed
    final isCompleted = status == completedLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isCompleted ? AppTheme.successColor : AppTheme.warningColor)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
        ),
      ),
    );
  }
}