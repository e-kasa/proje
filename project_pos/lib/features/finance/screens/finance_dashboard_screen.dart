import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/finance_service.dart';
import 'package:project_pos/services/service_locator.dart';

class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends ConsumerState<FinanceDashboardScreen> {
  late FinanceService _financeService;
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _financeService = ref.read(financeServiceProvider);
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _financeService.getSummary();
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final t = i18nOf(ref);
        AppToast.error(context, t('finance.load_error'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('finance.title'),
        actions: [
          IconButton(
            onPressed: _loadSummary,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: AppConstants.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Stats
                  _buildMainStats(isMobile),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),

                  const SizedBox(height: 24),

                  // Expense by Category
                  if (_summary['expensesByCategory'] != null)
                    _buildCategoryBreakdown(t('finance.expenses_by_category'),
                        _summary['expensesByCategory'], AppColors.danger),

                  const SizedBox(height: 16),

                  // Revenue by Category
                  if (_summary['revenuesByCategory'] != null)
                    _buildCategoryBreakdown(t('finance.income_by_category'),
                        _summary['revenuesByCategory'], AppColors.success),
                ],
              ),
            ),
    );
  }

  Widget _buildMainStats(bool isMobile) {
    final t = i18nOf(ref);
    final totalExpenses = (_summary['totalExpenses'] ?? 0.0) as double;
    final totalRevenues = (_summary['totalRevenues'] ?? 0.0) as double;
    final netIncome = (_summary['netIncome'] ?? 0.0) as double;

    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Column(
      children: [
        // Net Income - Big Card
        AppCard(
          padding: const EdgeInsets.all(20),
          color: netIncome >= 0 ? AppColors.success : AppColors.danger,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    netIncome >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t('finance.net_income'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                currencyFormat.format(netIncome),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                netIncome >= 0 ? t('finance.profitable') : t('finance.in_loss'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Revenue & Expense Cards
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: AppColors.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t('finance.income'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currencyFormat.format(totalRevenues),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                    ),
                    Text(
                      '${_summary['revenueCount'] ?? 0} işlem',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: AppConstants.borderRadiusSmall,
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: AppColors.danger,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t('finance.expenses'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currencyFormat.format(totalExpenses),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                    ),
                    Text(
                      '${_summary['expenseCount'] ?? 0} işlem',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final t = i18nOf(ref);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('finance.quick_actions'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_circle,
                  label: t('finance.add_expense'),
                  color: AppColors.danger,
                  onTap: () => context.go('/finance/expenses/add'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_circle_outline,
                  label: t('finance.add_income'),
                  color: AppColors.success,
                  onTap: () => context.go('/finance/add-income'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.receipt_long,
                  label: t('finance.expenses'),
                  color: AppColors.primary,
                  onTap: () => context.go('/finance/expenses'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.payment,
                  label: t('finance.payments'),
                  color: AppColors.info,
                  onTap: () => context.go('/finance/payments'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.show_chart,
                  label: t('finance.cash_flow'),
                  color: AppColors.warning,
                  onTap: () => context.go('/finance/cash-flow'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.account_balance_wallet_outlined,
                  label: t('accounts.title'),
                  color: Colors.teal,
                  onTap: () => context.go('/accounts'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppConstants.borderRadiusMedium,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
    String title,
    Map<String, dynamic> categories,
    Color color,
  ) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    final total = sortedCategories.fold<double>(
      0,
      (sum, entry) => sum + (entry.value as num).toDouble(),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...sortedCategories.map((entry) {
            final amount = (entry.value as num).toDouble();
            final percentage = total > 0 ? (amount / total * 100) : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        NumberFormat.currency(locale: 'tr_TR', symbol: '₺')
                            .format(amount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppConstants.borderRadiusSmall,
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 6,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}