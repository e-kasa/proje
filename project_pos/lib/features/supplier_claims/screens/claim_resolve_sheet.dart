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

class ClaimResolveSheet extends ConsumerStatefulWidget {
  final SupplierClaim claim;
  const ClaimResolveSheet({super.key, required this.claim});

  @override
  ConsumerState<ClaimResolveSheet> createState() => _ClaimResolveSheetState();
}

class _ClaimResolveSheetState extends ConsumerState<ClaimResolveSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _creditNoteCtrl = TextEditingController();
  final _deliveryNoteCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final remaining = widget.claim.remainingAmount;
    // _parse() nokta'yı binlik ayraç sayıp siler; virgüllü format kullan
    _amountCtrl.text =
        remaining > 0 ? remaining.toStringAsFixed(2).replaceAll('.', ',') : '';
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amountCtrl.dispose();
    _creditNoteCtrl.dispose();
    _deliveryNoteCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  ClaimResolution get _selectedResolution => switch (_tabs.index) {
        0 => ClaimResolution.discount,
        1 => ClaimResolution.delivery,
        _ => ClaimResolution.refund,
      };

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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${t('common.remaining')}: ${fmt.format(remaining)}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabs,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  icon: const Icon(Icons.discount_outlined, size: 18),
                  text: t('su.resolve_tab_discount'),
                ),
                Tab(
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  text: t('su.resolve_tab_delivery'),
                ),
                Tab(
                  icon: const Icon(Icons.currency_lira, size: 18),
                  text: t('su.resolve_tab_refund'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _tabs,
              builder: (_, __) => _buildTabContent(t, fmt, remaining),
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

  Widget _buildTabContent(
      String Function(String) t, NumberFormat fmt, double remaining) {
    return switch (_tabs.index) {
      0 => _buildDiscountTab(t, remaining),
      1 => _buildDeliveryTab(t),
      _ => _buildRefundTab(t, remaining),
    };
  }

  Widget _buildDiscountTab(String Function(String) t, double remaining) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoBox(AppColors.info, Icons.discount_outlined,
            t('su.claim_resolve_by_discount')),
        const SizedBox(height: 12),
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
          validator: _tabs.index == 0 ? (v) {
            final d = _parse(v);
            if (d == null || d <= 0) return t('common.required');
            if (d > remaining + 0.01) return t('common.exceeds_remaining');
            return null;
          } : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _creditNoteCtrl,
          decoration: InputDecoration(
            labelText: t('su.claim_credit_note_number'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('su.claim_notes'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTab(String Function(String) t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoBox(AppColors.teal, Icons.local_shipping_outlined,
            t('su.claim_resolve_by_delivery')),
        const SizedBox(height: 12),
        TextFormField(
          controller: _deliveryNoteCtrl,
          decoration: InputDecoration(
            labelText: t('su.claim_delivery_note_number'),
            prefixIcon: const Icon(Icons.receipt_outlined, size: 20),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('su.claim_notes'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildRefundTab(String Function(String) t, double remaining) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoBox(AppColors.success, Icons.currency_lira,
            t('su.claim_resolve_by_refund')),
        const SizedBox(height: 12),
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
          validator: _tabs.index == 2 ? (v) {
            final d = _parse(v);
            if (d == null || d <= 0) return t('common.required');
            if (d > remaining + 0.01) return t('common.exceeds_remaining');
            return null;
          } : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('su.claim_notes'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ),
        ],
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
    final resolution = _selectedResolution;

    final resolvedAmount = resolution == ClaimResolution.delivery
        ? widget.claim.remainingAmount
        : (_parse(_amountCtrl.text) ?? 0);

    try {
      await ref.read(supplierClaimsServiceProvider).resolve(
            widget.claim.id,
            ResolveClaimRequest(
              resolution: resolution,
              resolvedAmount: resolvedAmount,
              creditNoteNumber: _creditNoteCtrl.text.trim().isEmpty
                  ? null
                  : _creditNoteCtrl.text.trim(),
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
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
