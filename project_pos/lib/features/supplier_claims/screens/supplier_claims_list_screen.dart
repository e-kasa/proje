import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/supplier_claims/models/supplier_claim.dart';
import 'package:project_pos/features/supplier_claims/providers/supplier_claims_providers.dart';
import 'package:project_pos/features/supplier_claims/widgets/claim_status_chip.dart';

class SupplierClaimsListScreen extends ConsumerStatefulWidget {
  const SupplierClaimsListScreen({super.key});

  @override
  ConsumerState<SupplierClaimsListScreen> createState() =>
      _SupplierClaimsListScreenState();
}

class _SupplierClaimsListScreenState
    extends ConsumerState<SupplierClaimsListScreen> {
  String Function(String) get t => i18nOf(ref);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierClaimsListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierClaimsListProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('su.claim_title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(supplierClaimsListProvider.notifier).load(),
            tooltip: t('common.refresh'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(state),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? AppEmptyState.error(
                        description: state.error,
                        onAction: () =>
                            ref.read(supplierClaimsListProvider.notifier).load(),
                      )
                    : state.claims.isEmpty
                        ? AppEmptyState.noData(
                            title: t('su.claim_list_empty'),
                            description: '',
                          )
                        : _buildList(state.claims, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(SupplierClaimsListState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          _filterChip(t('su.claim_filter_all'), null, state.statusFilter),
          const SizedBox(width: 8),
          _filterChip(t('su.claim_filter_open'), ClaimStatus.open, state.statusFilter),
          const SizedBox(width: 8),
          _filterChip(t('su.claim_filter_resolved'), ClaimStatus.resolved,
              state.statusFilter),
          const SizedBox(width: 8),
          _filterChip(t('su.claim_filter_cancelled'), ClaimStatus.cancelled,
              state.statusFilter),
          const Spacer(),
          Text(
            '${state.claims.length} ${t('common.records')}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, ClaimStatus? value, ClaimStatus? current) {
    final selected = current == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) =>
          ref.read(supplierClaimsListProvider.notifier).setStatusFilter(value),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildList(List<SupplierClaim> items, ThemeData theme) {
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFmt = DateFormat('dd.MM.yyyy');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final c = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: () async {
              await context.push('/supplier-claims/${c.id}');
              if (mounted) ref.read(supplierClaimsListProvider.notifier).load();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: AppConstants.borderRadiusSmall,
                      ),
                      child: const Icon(
                        Icons.report_problem_outlined,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.supplierName ??
                                '${t('su.claim_col_supplier')} #${c.supplierId ?? '-'}',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t('su.claim_col_invoice')}: ${c.sourcePurchaseInvoice ?? '-'}'
                            '  •  ${c.claimDate != null ? dateFmt.format(c.claimDate!) : '-'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmt.format(c.claimAmount),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                        if (c.resolvedAmount > 0)
                          Text(
                            '${t('su.claim_resolved_amount')}: ${fmt.format(c.resolvedAmount)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ClaimReasonChip(reason: c.reason, t: t),
                    const Spacer(),
                    ClaimStatusChip(status: c.status, t: t),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
