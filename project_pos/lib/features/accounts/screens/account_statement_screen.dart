import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/features/accounts/services/statement_pdf_service.dart';
import 'package:project_pos/services/service_locator.dart';
import 'payment_record_modal.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class AccountStatementScreen extends ConsumerStatefulWidget {
  final String? accountType;
  final String? accountId;
  final String? accountName;

  const AccountStatementScreen({
    super.key,
    this.accountType,
    this.accountId,
    this.accountName,
  });

  @override
  ConsumerState<AccountStatementScreen> createState() =>
      _AccountStatementScreenState();
}

class _AccountStatementScreenState
    extends ConsumerState<AccountStatementScreen> {
  String Function(String) get t => i18nOf(ref);

  String? get _accountType => ref.watch(accountStatementProvider).accountType;
  String? get _accountId => ref.watch(accountStatementProvider).accountId;
  String? get _accountName => ref.watch(accountStatementProvider).accountName;
  DateTimeRange get _dateRange => DateTimeRange(
        start: ref.watch(accountStatementProvider).startDate,
        end: ref.watch(accountStatementProvider).endDate,
      );
  Map<String, dynamic>? get _statement =>
      ref.watch(accountStatementProvider).statement;
  bool get _loading => ref.watch(accountStatementProvider).isLoading;
  String? get _error => ref.watch(accountStatementProvider).error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.accountId != null && widget.accountId!.isNotEmpty) {
        ref.read(accountStatementProvider.notifier).setAccount(
              accountType: widget.accountType!,
              accountId: widget.accountId!,
              accountName: widget.accountName,
            );
      } else {
        _showAccountSelect();
      }
    });
  }

  Future<void> _showAccountSelect() async {
    final result = await AccountSelectDialog.show(
      context,
      loadCustomers: () => ref.read(customerServiceProvider).getCustomers(),
      loadSuppliers: () => ref.read(supplierServiceProvider).getSuppliers(),
    );
    if (result != null && mounted) {
      ref.read(accountStatementProvider.notifier).setAccount(
            accountType: result['accountType']!.toString(),
            accountId: result['accountId']!.toString(),
            accountName: result['accountName']?.toString(),
          );
    }
  }

  Future<void> _loadStatement() =>
      ref.read(accountStatementProvider.notifier).load();

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref
          .read(accountStatementProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccount = _accountId != null && _accountId!.isNotEmpty;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: hasAccount
            ? '${t('accounts.statement')} - ${_accountName ?? ''}'
            : t('accounts.statement'),
        actions: [
          if (hasAccount && _statement != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.textPrimary),
              tooltip: t('accounts.export_pdf'),
              onPressed: _exportPdf,
            ),
          if (hasAccount)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: AppColors.textPrimary),
              tooltip: t('accounts.change_account'),
              onPressed: _showAccountSelect,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: hasAccount ? _buildBody() : _buildEmptyState(),
    );
  }

  Future<void> _exportPdf() async {
    final s = _statement;
    if (s == null) return;
    try {
      await StatementPdfService.show(
        accountName: _accountName ?? '-',
        accountType: _accountType ?? 'CUSTOMER',
        startDate: _dateRange.start,
        endDate: _dateRange.end,
        openingBalance: (s['openingBalance'] ?? 0).toDouble(),
        closingBalance: (s['closingBalance'] ?? 0).toDouble(),
        totalDebit: (s['totalDebit'] ?? 0).toDouble(),
        totalCredit: (s['totalCredit'] ?? 0).toDouble(),
        transactions: List<Map<String, dynamic>>.from(s['transactions'] ?? []),
      );
    } catch (e) {
      if (mounted) AppToast.error(context, '${t('common.error')}: $e');
    }
  }

  Widget _buildEmptyState() {
    return AppEmptyState.noData(
      title: t('accounts.title'),
      description: t('common.no_data'),
      actionText: t('accounts.title'),
      onAction: _showAccountSelect,
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadStatement,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return AppEmptyState.error(
      title: t('common.error'),
      description: _error ?? '',
      actionText: t('common.refresh'),
      onAction: _loadStatement,
    );
  }

  Widget _buildContent() {
    final openingBalance =
        (_statement?['openingBalance'] ?? 0).toDouble();
    final closingBalance =
        (_statement?['closingBalance'] ?? 0).toDouble();
    final totalDebit = (_statement?['totalDebit'] ?? 0).toDouble();
    final totalCredit = (_statement?['totalCredit'] ?? 0).toDouble();
    final transactions =
        List<Map<String, dynamic>>.from(_statement?['transactions'] ?? []);

    return ListView(
      padding: AppConstants.pagePadding,
      children: [
        _buildDateRangeBar(),
        const SizedBox(height: 16),
        _buildOpeningBalanceCard(openingBalance),
        const SizedBox(height: 16),
        _buildTransactionTable(transactions),
        const SizedBox(height: 16),
        _buildSummaryCard(totalDebit, totalCredit, closingBalance),
      ],
    );
  }

  Widget _buildDateRangeBar() {
    return GestureDetector(
      onTap: _pickDateRange,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing12,
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              '${_formatDate(_dateRange.start)}  -  ${_formatDate(_dateRange.end)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(Icons.edit_calendar, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningBalanceCard(double openingBalance) {
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppConstants.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: const Icon(Icons.account_balance,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('accounts.balance'), // TODO: i18n 'Açılış Bakiyesi'
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(openingBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTable(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 8),
              Text(t('common.no_records'),
                  style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppConstants.borderRadiusMedium,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
            columnSpacing: 16,
            horizontalMargin: 12,
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            columns: [
              const DataColumn(label: Text('Tarih')), // TODO: i18n
              const DataColumn(label: Text('Açıklama')), // TODO: i18n
              const DataColumn(label: Text('Borç'), numeric: true), // TODO: i18n
              const DataColumn(label: Text('Alacak'), numeric: true), // TODO: i18n
              DataColumn(label: Text(t('accounts.balance')), numeric: true),
            ],
            rows: transactions.map((tx) {
              final date = tx['transactionDate']?.toString() ?? '-';
              final description = tx['description']?.toString() ?? '-';
              final debit = (tx['debitAmount'] ?? 0).toDouble();
              final credit = (tx['creditAmount'] ?? 0).toDouble();
              final balance = (tx['runningBalance'] ?? 0).toDouble();

              return DataRow(cells: [
                DataCell(Text(
                  date.length >= 10 ? date.substring(0, 10) : date,
                  style: const TextStyle(fontSize: 11),
                )),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      description,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                DataCell(Text(
                  debit > 0 ? _formatCurrency(debit) : '-',
                  style: TextStyle(
                    fontSize: 11,
                    color: debit > 0 ? AppColors.danger : AppColors.textMuted,
                    fontWeight: debit > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                )),
                DataCell(Text(
                  credit > 0 ? _formatCurrency(credit) : '-',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        credit > 0 ? AppColors.success : AppColors.textMuted,
                    fontWeight:
                        credit > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                )),
                DataCell(Text(
                  _formatCurrency(balance),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      double totalDebit, double totalCredit, double closingBalance) {
    return AppCard(
      padding: AppConstants.cardPadding,
      child: Column(
        children: [
          _summaryRow(
            'Toplam Borç', // TODO: i18n
            _formatCurrency(totalDebit),
            AppColors.danger,
            Icons.arrow_upward,
          ),
          const Divider(height: 20),
          _summaryRow(
            'Toplam Alacak', // TODO: i18n
            _formatCurrency(totalCredit),
            AppColors.success,
            Icons.arrow_downward,
          ),
          const Divider(height: 20),
          _summaryRow(
            t('accounts.balance'), // Kapanış Bakiyesi
            _formatCurrency(closingBalance),
            AppColors.primary,
            Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppConstants.borderRadiusSmall,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted TL';
  }
}