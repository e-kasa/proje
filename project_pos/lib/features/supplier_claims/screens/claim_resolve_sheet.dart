import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/supplier_claims/di/supplier_claims_di.dart';
import 'package:project_pos/features/supplier_claims/models/supplier_claim.dart';
import 'package:project_pos/features/supplier_claims/services/supplier_claims_service.dart';

/// Sprint A — sadece indirim (DISCOUNT) çözümü aktif.
/// Diğer sekmeler (teslim, iade) Sprint B'de açılacak.
class ClaimResolveSheet extends ConsumerStatefulWidget {
  final SupplierClaim claim;
  const ClaimResolveSheet({super.key, required this.claim});

  @override
  ConsumerState<ClaimResolveSheet> createState() => _ClaimResolveSheetState();
}

class _ClaimResolveSheetState extends ConsumerState<ClaimResolveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _creditNoteCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Default: kalan tutar.
    final remaining = widget.claim.remainingAmount;
    _amountCtrl.text = remaining > 0 ? remaining.toStringAsFixed(2) : '';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _creditNoteCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final remaining = widget.claim.remainingAmount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(t('su.claim_resolve'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${t('common.remaining')}: ${fmt.format(remaining)}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.discount_outlined,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t('su.claim_resolve_by_discount'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.info)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: t('su.claim_resolved_amount'),
                prefixText: '₺ ',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final d = _parse(v);
                if (d == null || d <= 0) return t('common.required');
                if (d > remaining + 0.01) {
                  return t('common.exceeds_remaining');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _creditNoteCtrl,
              decoration: InputDecoration(
                labelText: t('su.claim_credit_note_number'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t('su.claim_notes'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: t('common.cancel'),
                    onPressed: _busy ? null : () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.primary(
                    text: t('su.claim_confirm'),
                    icon: Icons.check,
                    isLoading: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double? _parse(String? v) {
    if (v == null) return null;
    final cleaned = v.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final t = i18nOf(ref);
    try {
      await ref.read(supplierClaimsServiceProvider).resolve(
            widget.claim.id,
            ResolveClaimRequest(
              resolution: ClaimResolution.discount,
              resolvedAmount: _parse(_amountCtrl.text)!,
              creditNoteNumber: _creditNoteCtrl.text.trim().isEmpty
                  ? null
                  : _creditNoteCtrl.text.trim(),
              notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            ),
          );
      if (mounted) {
        AppToast.success(context, t('su.claim_toast_resolved'));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
        setState(() => _busy = false);
      }
    }
  }
}
