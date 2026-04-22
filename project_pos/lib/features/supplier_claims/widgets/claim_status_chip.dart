import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/features/supplier_claims/models/supplier_claim.dart';

class ClaimStatusChip extends StatelessWidget {
  final ClaimStatus status;
  final String Function(String) t;

  const ClaimStatusChip({super.key, required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ClaimStatus.open => (t('su.claim_status_open'), AppColors.warning, Icons.warning_amber_rounded),
      ClaimStatus.partiallyResolved => (
          t('su.claim_status_partially_resolved'),
          AppColors.info,
          Icons.timelapse_rounded,
        ),
      ClaimStatus.resolved => (t('su.claim_status_resolved'), AppColors.success, Icons.check_circle_outline),
      ClaimStatus.cancelled => (t('su.claim_status_cancelled'), AppColors.textMuted, Icons.block_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ClaimReasonChip extends StatelessWidget {
  final ClaimReason reason;
  final String Function(String) t;

  const ClaimReasonChip({super.key, required this.reason, required this.t});

  @override
  Widget build(BuildContext context) {
    final label = switch (reason) {
      ClaimReason.shortage => t('su.claim_reason_shortage'),
      ClaimReason.damage => t('su.claim_reason_damage'),
      ClaimReason.wrongItem => t('su.claim_reason_wrong_item'),
      ClaimReason.other => t('common.other'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    );
  }
}
