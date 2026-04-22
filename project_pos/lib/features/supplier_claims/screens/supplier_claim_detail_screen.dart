import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/supplier_claims/di/supplier_claims_di.dart';
import 'package:project_pos/features/supplier_claims/models/supplier_claim.dart';
import 'package:project_pos/features/supplier_claims/providers/supplier_claims_providers.dart';
import 'package:project_pos/features/supplier_claims/screens/claim_resolve_sheet.dart';
import 'package:project_pos/features/supplier_claims/widgets/claim_status_chip.dart';

class SupplierClaimDetailScreen extends ConsumerWidget {
  final String claimId;
  const SupplierClaimDetailScreen({super.key, required this.claimId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final async = ref.watch(supplierClaimDetailProvider(claimId));
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('su.claim_detail_title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(supplierClaimDetailProvider(claimId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyState.error(
          description: e.toString(),
          onAction: () => ref.invalidate(supplierClaimDetailProvider(claimId)),
        ),
        data: (claim) => _Content(claim: claim, fmt: fmt, t: t, ref: ref),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final SupplierClaim claim;
  final NumberFormat fmt;
  final String Function(String) t;
  final WidgetRef ref;

  const _Content({
    required this.claim,
    required this.fmt,
    required this.t,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _buildHeaderCard(theme, dateFmt),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    t('su.claim_detail_lines'),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${claim.lines.length} ${t('common.records')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...claim.lines.map((line) => _buildLineRow(theme, line)),
              if (claim.notes != null && claim.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('su.claim_notes'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      const SizedBox(height: 4),
                      Text(claim.notes!, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (claim.isOpen || claim.status == ClaimStatus.partiallyResolved)
          _buildActionBar(context),
      ],
    );
  }

  Widget _buildHeaderCard(ThemeData theme, DateFormat dateFmt) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  claim.supplierName ?? t('su.claim_col_supplier'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ClaimStatusChip(status: claim.status, t: t),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _stat(theme, t('su.claim_col_amount'), fmt.format(claim.claimAmount),
                  color: AppColors.warning),
              if (claim.resolvedAmount > 0)
                _stat(theme, t('su.claim_resolved_amount'),
                    fmt.format(claim.resolvedAmount),
                    color: AppColors.success),
              if (claim.remainingAmount > 0)
                _stat(theme, t('common.remaining'), fmt.format(claim.remainingAmount),
                    color: AppColors.info),
              _stat(theme, t('su.claim_col_date'),
                  claim.claimDate != null ? dateFmt.format(claim.claimDate!) : '-'),
              if (claim.sourcePurchaseInvoice != null)
                _stat(theme, t('su.claim_source_purchase'),
                    claim.sourcePurchaseInvoice!),
              _stat(theme, t('su.claim_col_reason'),
                  _reasonLabel(claim.reason)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildLineRow(ThemeData theme, SupplierClaimLine line) {
    final resolvedRatio = line.lineAmount > 0
        ? (line.resolvedAmount / line.lineAmount).clamp(0, 1).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        borderColor: line.isResolved
            ? AppColors.success.withValues(alpha: 0.3)
            : AppColors.warning.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.productName ?? line.variantSku ?? '-',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (line.variantSku != null)
                        Text(line.variantSku!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                    ],
                  ),
                ),
                Text(
                  fmt.format(line.lineAmount),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniStat(theme, t('su.claim_line_expected'), '${line.expectedQty}'),
                const SizedBox(width: 12),
                _miniStat(theme, t('su.claim_line_received'), '${line.receivedQty}'),
                const SizedBox(width: 12),
                _miniStat(theme, t('su.claim_line_shortage'), '${line.shortageQty}',
                    color: AppColors.warning),
                const SizedBox(width: 12),
                _miniStat(theme, t('su.claim_line_unit_price'),
                    fmt.format(line.unitPrice)),
                const Spacer(),
                ClaimReasonChip(reason: line.reason, t: t),
              ],
            ),
            if (resolvedRatio > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: AppConstants.borderRadiusSmall,
                child: LinearProgressIndicator(
                  value: resolvedRatio,
                  minHeight: 4,
                  backgroundColor: AppColors.bgLight,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${t('su.claim_resolved_amount')}: ${fmt.format(line.resolvedAmount)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.success),
              ),
            ],
            if (line.notes != null && line.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(line.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(ref.context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStat(ThemeData theme, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            )),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton.outline(
                text: t('su.claim_cancel'),
                icon: Icons.close_rounded,
                onPressed: () => _confirmCancel(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton.primary(
                text: t('su.claim_resolve'),
                icon: Icons.check_circle_outline,
                onPressed: () => _openResolve(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openResolve(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClaimResolveSheet(claim: claim),
    );
    if (result == true) {
      ref.invalidate(supplierClaimDetailProvider(claim.id));
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('su.claim_cancel')),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            labelText: t('su.claim_cancel_reason'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('common.cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t('common.confirm'))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(supplierClaimsServiceProvider)
          .cancel(claim.id, reason: reasonCtrl.text.trim());
      ref.invalidate(supplierClaimDetailProvider(claim.id));
      if (context.mounted) {
        AppToast.warning(context, t('su.claim_toast_cancelled'));
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  String _reasonLabel(ClaimReason r) => switch (r) {
        ClaimReason.shortage => t('su.claim_reason_shortage'),
        ClaimReason.damage => t('su.claim_reason_damage'),
        ClaimReason.wrongItem => t('su.claim_reason_wrong_item'),
        ClaimReason.other => t('common.other'),
      };
}
