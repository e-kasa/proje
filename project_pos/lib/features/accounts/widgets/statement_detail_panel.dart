import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/formatters.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/features/accounts/models/statement_args.dart';
import 'package:project_pos/features/accounts/providers/selected_account_provider.dart';
import 'package:project_pos/features/accounts/services/statement_pdf_service.dart';

/// Hub'ın sağ paneli — seçili cariye ait ekstre.
/// Boş durumda placeholder gösterir.
class StatementDetailPanel extends ConsumerWidget {
  /// Mobile push akışı için: geri butonu göstermek istiyor muyuz?
  final bool showBackButton;
  const StatementDetailPanel({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final selected = ref.watch(selectedAccountProvider);
    final st = ref.watch(accountStatementProvider);

    if (selected == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AppEmptyState.noData(
            title: t('accounts.statement_select_prompt'),
            description: t('accounts.statement_select_hint'),
          ),
        ),
      );
    }

    if (st.isLoading) return const Center(child: CircularProgressIndicator());
    if (st.error != null) {
      return AppEmptyState.error(
        title: t('common.error'),
        description: st.error ?? '',
        actionText: t('common.refresh'),
        onAction: () => ref.read(accountStatementProvider.notifier).load(),
      );
    }

    final s = st.statement;
    if (s == null) return const SizedBox.shrink();

    final opening = (s['openingBalance'] ?? 0).toDouble();
    final closing = (s['closingBalance'] ?? 0).toDouble();
    final debit = (s['totalDebit'] ?? 0).toDouble();
    final credit = (s['totalCredit'] ?? 0).toDouble();
    final transactions =
        List<Map<String, dynamic>>.from(s['transactions'] ?? []);
    final dateRange = DateTimeRange(start: st.startDate, end: st.endDate);

    return RefreshIndicator(
      onRefresh: () => ref.read(accountStatementProvider.notifier).load(),
      child: ListView(
        padding: AppConstants.pagePadding,
        children: [
          _Header(
            account: selected,
            dateRange: dateRange,
            showBackButton: showBackButton,
            onBack: () {
              ref.read(selectedAccountProvider.notifier).state = null;
              if (showBackButton) Navigator.pop(context);
            },
            onPickRange: () => _pickDateRange(context, ref, dateRange),
            onPdf: () => StatementPdfService.show(
              accountName: selected.accountName,
              accountType: selected.accountType,
              startDate: dateRange.start,
              endDate: dateRange.end,
              openingBalance: opening,
              closingBalance: closing,
              totalDebit: debit,
              totalCredit: credit,
              transactions: transactions,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryGrid(
            opening: opening,
            debit: debit,
            credit: credit,
            closing: closing,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.receipt_long,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(t('accounts.transactions'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('${transactions.length}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            AppEmptyState.noData(
                title: t('common.no_records'), description: '')
          else
            ...transactions.map((tx) => _TxRow(tx: tx)),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(
      BuildContext context, WidgetRef ref, DateTimeRange current) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: current,
    );
    if (picked != null) {
      ref
          .read(accountStatementProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }
}

class _Header extends ConsumerWidget {
  final StatementArgs account;
  final DateTimeRange dateRange;
  final bool showBackButton;
  final VoidCallback onBack;
  final VoidCallback onPickRange;
  final VoidCallback onPdf;

  const _Header({
    required this.account,
    required this.dateRange,
    required this.showBackButton,
    required this.onBack,
    required this.onPickRange,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final dateFmt = DateFormat('dd.MM.yyyy');
    final isCustomer = account.accountType == 'CUSTOMER';
    final accent = isCustomer ? AppColors.info : AppColors.orange;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (showBackButton) const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
                child: Icon(
                  isCustomer
                      ? Icons.person_outline
                      : Icons.business_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.accountName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      isCustomer
                          ? t('accounts.customer_label')
                          : t('accounts.supplier_label'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.textPrimary),
                tooltip: t('accounts.export_pdf'),
                onPressed: onPdf,
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onPickRange,
            borderRadius: AppConstants.borderRadiusSmall,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: AppConstants.borderRadiusSmall,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFmt.format(dateRange.start)}  —  ${dateFmt.format(dateRange.end)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends ConsumerWidget {
  final double opening, debit, credit, closing;
  const _SummaryGrid({
    required this.opening,
    required this.debit,
    required this.credit,
    required this.closing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final tiles = [
      _StatTile(
        label: t('accounts.opening_balance'),
        value: appCurrencyFmt.format(opening),
        icon: Icons.flag_outlined,
        color: AppColors.info,
      ),
      _StatTile(
        label: t('accounts.total_debt'),
        value: appCurrencyFmt.format(debit),
        icon: Icons.arrow_upward,
        color: AppColors.danger,
      ),
      _StatTile(
        label: t('accounts.total_collection'),
        value: appCurrencyFmt.format(credit),
        icon: Icons.arrow_downward,
        color: AppColors.success,
      ),
      _StatTile(
        label: t('accounts.closing_balance'),
        value: appCurrencyFmt.format(closing),
        icon: Icons.assessment_outlined,
        color: AppColors.primary,
      ),
    ];
    return LayoutBuilder(
      builder: (ctx, c) {
        final isWide = c.maxWidth >= 600;
        final cols = isWide ? 4 : 2;
        const sp = 10.0;
        final w = (c.maxWidth - sp * (cols - 1)) / cols;
        return Wrap(
          spacing: sp,
          runSpacing: sp,
          children: tiles
              .map((t) => SizedBox(width: w, height: 92, child: t))
              .toList(),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final date = shortDateString(tx['transactionDate']?.toString());
    final desc = tx['description']?.toString() ?? '-';
    final debit = (tx['debitAmount'] ?? 0).toDouble();
    final credit = (tx['creditAmount'] ?? 0).toDouble();
    final balance = (tx['runningBalance'] ?? 0).toDouble();
    final isDebit = debit > 0;
    final color = isDebit ? AppColors.danger : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isDebit
                      ? '-${appCurrencyFmt.format(debit)}'
                      : '+${appCurrencyFmt.format(credit)}',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: color),
                ),
                Text(appCurrencyFmt.format(balance),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
