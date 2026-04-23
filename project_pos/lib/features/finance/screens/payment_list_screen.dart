import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/finance/di/finance_di.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  String Function(String) get t => i18nOf(ref);

  List<Map<String, dynamic>> get _payments =>
      ref.watch(paymentListProvider).payments;
  bool get _isLoading => ref.watch(paymentListProvider).isLoading;
  String get _selectedType => ref.watch(paymentListProvider).selectedType;
  String get _searchQuery => ref.watch(paymentListProvider).searchQuery;
  double get _totalIncome => ref.watch(paymentListProvider).totalIncome;
  double get _totalExpense => ref.watch(paymentListProvider).totalExpense;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() =>
      ref.read(paymentListProvider.notifier).load();

  List<Map<String, dynamic>> get _filteredPayments {
    var list = _payments;
    if (_selectedType != 'all') {
      list = list.where((p) => p['type'] == _selectedType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final party = (p['relatedParty'] ?? '').toString().toLowerCase();
        final desc = (p['description'] ?? '').toString().toLowerCase();
        final refNo = (p['referenceNo'] ?? '').toString().toLowerCase();
        return party.contains(q) || desc.contains(q) || refNo.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');
    final net = _totalIncome - _totalExpense;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('finance.payments'),
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: t('finance.total_collection'), // TODO: i18n key: finance.total_collection
                          value: currencyFormat.format(_totalIncome),
                          color: AppColors.success,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          label: t('finance.total_payment'), // TODO: i18n key: finance.total_payment
                          value: currencyFormat.format(_totalExpense),
                          color: AppColors.danger,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          label: t('finance.net'), // TODO: i18n key: finance.net
                          value: currencyFormat.format(net),
                          color: net >= 0 ? AppColors.success : AppColors.danger,
                          icon: net >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Type toggle
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                                value: 'all', label: Text(t('common.all'))),
                            ButtonSegment(
                                value: 'income', label: Text(t('finance.collection'))), // TODO: i18n key: finance.collection
                            ButtonSegment(
                                value: 'expense', label: Text(t('finance.payment'))), // TODO: i18n key: finance.payment
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: (selection) {
                            ref
                                .read(paymentListProvider.notifier)
                                .setType(selection.first);
                          },
                          style: SegmentedButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: t('finance.search_hint'), // TODO: i18n key: finance.search_hint
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(paymentListProvider.notifier)
                                    .setSearch('');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) =>
                        ref.read(paymentListProvider.notifier).setSearch(value),
                  ),
                ),

                const SizedBox(height: 8),

                // Payment list
                Expanded(
                  child: _filteredPayments.isEmpty
                      ? AppEmptyState.noData(
                          title: t('common.no_records'),
                          description: t('finance.no_payments'), // TODO: i18n key: finance.no_payments
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = _filteredPayments[index];
                            return _PaymentCard(payment: payment);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isIncome = payment['type'] == 'income';
    final color = isIncome ? AppColors.success : AppColors.danger;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final currencyFormat =
        NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment['relatedParty'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payment['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        payment['date'] ?? '',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.payment,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          payment['paymentMethod'] ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${currencyFormat.format(amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                if (payment['referenceNo'] != null)
                  Text(
                    payment['referenceNo'],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}