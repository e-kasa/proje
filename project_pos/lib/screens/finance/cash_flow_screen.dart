import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import '../../core/utils/i18n_helper.dart';

class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  String Function(String) get t => i18nOf(ref);

  bool _isLoading = false;
  String _selectedPeriod = 'monthly'; // daily, weekly, monthly

  // Summary
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _netFlow = 0;

  // Period details
  List<Map<String, dynamic>> _periodData = [];

  @override
  void initState() {
    super.initState();
    _loadCashFlow();
  }

  Future<void> _loadCashFlow() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(paymentServiceProvider);
      final summary =
          await service.getCashFlowSummary(period: _selectedPeriod);
      if (summary.isNotEmpty) {
        setState(() {
          _totalIncome = (summary['totalIncome'] as num?)?.toDouble() ?? 0;
          _totalExpense = (summary['totalExpense'] as num?)?.toDouble() ?? 0;
          _netFlow = (summary['netFlow'] as num?)?.toDouble() ?? 0;
          _periodData = List<Map<String, dynamic>>.from(
              summary['periods'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _periodData = [];
          _totalIncome = 0;
          _totalExpense = 0;
          _netFlow = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _periodData = [];
        _totalIncome = 0;
        _totalExpense = 0;
        _netFlow = 0;
        _isLoading = false;
      });
      if (mounted) {
        AppToast.error(context, t('common.error'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('finance.cash_flow'),
        actions: [
          IconButton(
            onPressed: _loadCashFlow,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Center(
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                            value: 'daily', label: Text(t('reports.daily'))), // TODO: i18n key: reports.daily
                        ButtonSegment(
                            value: 'weekly', label: Text(t('reports.weekly'))), // TODO: i18n key: reports.weekly
                        ButtonSegment(
                            value: 'monthly', label: Text(t('reports.monthly'))), // TODO: i18n key: reports.monthly
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedPeriod = selection.first;
                        });
                        _loadCashFlow();
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _FlowCard(
                          label: t('finance.income'),
                          value: currencyFormat.format(_totalIncome),
                          color: AppColors.success,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FlowCard(
                          label: t('finance.expenses'),
                          value: currencyFormat.format(_totalExpense),
                          color: AppColors.danger,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FlowCard(
                          label: t('finance.net_flow'), // TODO: i18n key: finance.net_flow
                          value: currencyFormat.format(_netFlow),
                          color: AppColors.primary,
                          icon: _netFlow >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bar chart visualization
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('finance.income_expense_comparison'), // TODO: i18n key: finance.income_expense_comparison
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._periodData.map((data) {
                          return _BarRow(data: data, periodData: _periodData, incomeLabel: t('finance.income'), expenseLabel: t('finance.expenses'));
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Detail table
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('finance.detail_table'), // TODO: i18n key: finance.detail_table
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: Text(t('finance.period'), // TODO: i18n key: finance.period
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              Expanded(
                                  flex: 2,
                                  child: Text(t('finance.income'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                      textAlign: TextAlign.right)),
                              Expanded(
                                  flex: 2,
                                  child: Text(t('finance.expenses'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                      textAlign: TextAlign.right)),
                              Expanded(
                                  flex: 2,
                                  child: Text(t('finance.net'), // TODO: i18n key: finance.net
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                      textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                        const Divider(),
                        ..._periodData.map((data) {
                          final income =
                              (data['income'] as num).toDouble();
                          final expense =
                              (data['expense'] as num).toDouble();
                          final net = income - expense;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    data['period'] as String,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    currencyFormat.format(income),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    currencyFormat.format(expense),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.danger),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    currencyFormat.format(net),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: net >= 0
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _FlowCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> periodData;
  final String incomeLabel;
  final String expenseLabel;

  const _BarRow({required this.data, required this.periodData, required this.incomeLabel, required this.expenseLabel});

  @override
  Widget build(BuildContext context) {
    final income = (data['income'] as num).toDouble();
    final expense = (data['expense'] as num).toDouble();
    final maxVal = periodData.fold<double>(0, (max, d) {
      final i = (d['income'] as num).toDouble();
      final e = (d['expense'] as num).toDouble();
      return i > max ? i : (e > max ? e : max);
    });
    final incomeFraction = maxVal > 0 ? income / maxVal : 0.0;
    final expenseFraction = maxVal > 0 ? expense / maxVal : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['period'] as String,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          // Income bar
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  incomeLabel,
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: incomeFraction.clamp(0, 1),
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Expense bar
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  expenseLabel,
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: expenseFraction.clamp(0, 1),
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}