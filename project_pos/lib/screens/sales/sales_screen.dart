import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/section_header.dart';
import '../../core/widgets/widgets.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

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
                  title: 'Sales',
                  subtitle: 'Manage your sales and orders',
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
                  children: const [
                    StatCard(
                      title: 'Today Sales',
                      value: '\$12,345',
                      change: '+15.3%',
                      isPositive: true,
                      icon: Icons.trending_up,
                      color: AppTheme.successColor,
                    ),
                    StatCard(
                      title: 'Orders',
                      value: '234',
                      change: '+8.1%',
                      isPositive: true,
                      icon: Icons.shopping_cart,
                      color: AppTheme.primaryColor,
                    ),
                    StatCard(
                      title: 'Pending',
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Sales',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.filter_list, size: 18),
                                  label: const Text('Filter'),
                                ),
                                const SizedBox(width: 12),
                                AppButton.primary(
                                  text: 'New Sale',
                                  icon: Icons.add, size: 18,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSalesTable(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          AppTheme.backgroundColor,
        ),
        columns: const [
          DataColumn(label: Text('Order ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
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
                _buildStatusChip(index % 3 == 0 ? 'Completed' : 'Pending'),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      onPressed: () {},
                      tooltip: 'View',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () {},
                      tooltip: 'Edit',
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

  Widget _buildStatusChip(String status) {
    final isCompleted = status == 'Completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isCompleted ? AppTheme.successColor : AppTheme.warningColor)
            .withOpacity(0.1),
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
