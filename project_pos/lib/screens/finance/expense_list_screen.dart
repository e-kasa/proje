import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/finance_service.dart';
import '../../core/api/api_client.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String Function(String) get t => i18nOf(ref);
  late FinanceService _financeService;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _selectedCategory;
  String? _selectedStatus;
  String _searchQuery = '';

  List<Map<String, String?>> _getStatusOptions() {
    return [
      {'value': null, 'label': t('common.all')},
      {'value': 'paid', 'label': t('finance.paid')},
      {'value': 'pending', 'label': t('finance.pending')},
      {'value': 'cancelled', 'label': t('finance.cancelled')},
    ];
  }

  @override
  void initState() {
    super.initState();
    _financeService = FinanceService(ApiClient());
    _loadExpenses();
    _loadCategories();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _financeService.getExpenses(
        category: _selectedCategory,
        status: _selectedStatus,
      );
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, i18nOf(ref)('common.error'));
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _financeService.getExpenseCategories();
      setState(() => _categories = categories);
    } catch (e) {
      // Categories are optional
    }
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final confirmed = await AppConfirmationDialog.showDelete(
      
      context: context,
      title: i18nOf(ref)('finance.delete_expense'),
      message: i18nOf(ref)('common.are_you_sure'),
      itemName: '${expense['category']} - ${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(expense['amount'])}',
    );

    if (!confirmed) return;

    try {
      await _financeService.deleteExpense(expense['id']);
      AppToast.success(context, i18nOf(ref)('common.success'));
      _loadExpenses();
    } catch (e) {
      AppToast.error(context, i18nOf(ref)('common.error'));
    }
  }

  List<Map<String, dynamic>> get _filteredExpenses {
    if (_searchQuery.isEmpty) return _expenses;

    return _expenses.where((expense) {
      final query = _searchQuery.toLowerCase();
      return expense['category'].toString().toLowerCase().contains(query) ||
          expense['description'].toString().toLowerCase().contains(query) ||
          expense['vendor'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('finance.expenses'),
        actions: [
          IconButton(
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const AppSkeletonList(itemCount: 8)
          : Column(
              children: [
                // Stats Section
                _buildStatsSection(),

                const SizedBox(height: 16),

                // Filters & Search
                _buildFiltersSection(isMobile),

                const SizedBox(height: 16),

                // Expense List
                Expanded(
                  child: _filteredExpenses.isEmpty
                      ? AppEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: t('finance.no_expenses'),
                          actionText: t('finance.no_expense_records'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredExpenses.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final expense = _filteredExpenses[index];
                            return _buildExpenseCard(expense, isMobile);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        
        onPressed: () {
          context.go('/finance/expenses/add');
        },
        icon: const Icon(Icons.add),
        label: Text(t('finance.new_expense')),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalExpenses = _expenses.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] as num).toDouble(),
    );
    final paidExpenses = _expenses.where((e) => e['status'] == 'paid').length;
    final pendingExpenses = _expenses.where((e) => e['status'] == 'pending').length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatCard(
            '💰 Toplam',
            NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(totalExpenses),
            'Gider',
            AppColors.danger,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            '✅ Ödendi',
            paidExpenses.toString(),
            'Adet',
            AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            '⏳ Bekliyor',
            pendingExpenses.toString(),
            'Adet',
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Search
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: t('common.search'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: t('finance.category'),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(t('common.all'))),
                    ..._categories.map<DropdownMenuItem<String>>((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['name'] as String,
                        child: Text('${cat['icon']} ${cat['name']}'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                    _loadExpenses();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: t('common.status'),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _getStatusOptions().map<DropdownMenuItem<String>>((opt) {
                    return DropdownMenuItem<String>(
                      value: opt['value'],
                      child: Text(opt['label'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _loadExpenses();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense, bool isMobile) {
    final date = DateTime.parse(expense['date']);
    final amount = (expense['amount'] as num).toDouble();
    final status = expense['status'] as String;

    BadgeVariant statusVariant;
    String statusText;

    switch (status) {
      case 'paid':
        statusVariant = BadgeVariant.success;
        statusText = t('finance.paid');
        break;
      case 'pending':
        statusVariant = BadgeVariant.warning;
        statusText = t('finance.pending');
        break;
      case 'cancelled':
        statusVariant = BadgeVariant.secondary;
        statusText = t('finance.cancelled');
        break;
      default:
        statusVariant = BadgeVariant.secondary;
        statusText = status;
    }

    return AppCard(
      onTap: () {
        // Navigate to edit
        context.go('/finance/expenses/edit/${expense['id']}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    expense['categoryIcon'] ?? '💰',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          expense['category'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppBadge(
                          text: statusText,
                          variant: statusVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(amount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.store, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        expense['vendor'] ?? '-',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              IconButton(
                onPressed: () => _deleteExpense(expense),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}