import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_constants.dart';
import '../../services/service_locator.dart';
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
  String? _accountType;
  String? _accountId;
  String? _accountName;

  late DateTimeRange _dateRange;
  Map<String, dynamic>? _statement;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accountType = widget.accountType;
    _accountId = widget.accountId;
    _accountName = widget.accountName;

    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );

    if (_accountId != null && _accountId!.isNotEmpty) {
      _loadStatement();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAccountSelect();
      });
    }
  }

  Future<void> _showAccountSelect() async {
    final result = await AccountSelectDialog.show(
      context,
      loadCustomers: () => ref.read(customerServiceProvider).getCustomers(),
      loadSuppliers: () => ref.read(supplierServiceProvider).getSuppliers(),
    );
    if (result != null && mounted) {
      setState(() {
        _accountType = result['accountType']?.toString();
        _accountId = result['accountId']?.toString();
        _accountName = result['accountName']?.toString();
      });
      _loadStatement();
    }
  }

  Future<void> _loadStatement() async {
    if (_accountType == null || _accountId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accountService = ref.read(accountServiceProvider);
      final data = await accountService.getAccountStatement(
        accountType: _accountType!,
        accountId: _accountId!,
        startDate: _formatDate(_dateRange.start),
        endDate: _formatDate(_dateRange.end),
      );
      setState(() {
        _statement = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

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
      setState(() => _dateRange = picked);
      _loadStatement();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccount = _accountId != null && _accountId!.isNotEmpty;

    return AppScaffold(
      appBar: AppAppBar.gradient(
        title: hasAccount ? '${t('accounts.title')} - ${_accountName ?? ''}' : t('accounts.title'),
        actions: [
          if (hasAccount)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Hesap Değiştir', // TODO: i18n
              onPressed: _showAccountSelect,
            ),
        ],
      ),
      body: hasAccount ? _buildBody() : _buildEmptyState(),
    );
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