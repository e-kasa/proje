import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/service_locator.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? supplier;
  final String? supplierId; // String (UUID)

  const AddSupplierScreen({super.key, this.supplier, this.supplierId});

  @override
  ConsumerState<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends ConsumerState<AddSupplierScreen> {
  String Function(String) get t => i18nOf(ref);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _contactNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _taxNumberController;
  late TextEditingController _taxOfficeController;

  bool _isActive = true;
  bool _isLoading = false;

  Map<String, dynamic>? _accountData;
  bool _accountLoading = false;

  String? get _editId =>
      (widget.supplier?['id'] ?? widget.supplierId)?.toString();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.supplierId != null && widget.supplier == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSupplier());
    }
    if (widget.supplier != null || widget.supplierId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccountData());
    }
  }

  void _initializeControllers() {
    final supp = widget.supplier;
    _companyNameController = TextEditingController(text: supp?['name'] ?? '');
    _contactNameController =
        TextEditingController(text: supp?['contactName'] ?? '');
    _phoneController = TextEditingController(text: supp?['phone'] ?? '');
    _emailController = TextEditingController(text: supp?['email'] ?? '');
    _addressController = TextEditingController(text: supp?['address'] ?? '');
    _websiteController = TextEditingController(text: supp?['website'] ?? '');
    _taxNumberController =
        TextEditingController(text: supp?['taxNumber'] ?? '');
    _taxOfficeController =
        TextEditingController(text: supp?['taxOffice'] ?? '');
    if (supp != null) {
      _isActive = supp['isActive'] == true;
    }
  }

  Future<void> _loadSupplier() async {
    setState(() => _isLoading = true);
    try {
      final supplierService = ref.read(supplierServiceProvider);
      final supplier =
          await supplierService.getSupplierById(widget.supplierId!);
      if (supplier != null && mounted) {
        setState(() {
          _companyNameController.text = supplier['name'] ?? '';
          _contactNameController.text = supplier['contactName'] ?? '';
          _phoneController.text = supplier['phone'] ?? '';
          _emailController.text = supplier['email'] ?? '';
          _addressController.text = supplier['address'] ?? '';
          _websiteController.text = supplier['website'] ?? '';
          _taxNumberController.text = supplier['taxNumber'] ?? '';
          _taxOfficeController.text = supplier['taxOffice'] ?? '';
          _isActive = supplier['isActive'] == true;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('suppliers.load_error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAccountData() async {
    if (_editId == null) return;
    setState(() => _accountLoading = true);
    try {
      final data = await ref
          .read(supplierServiceProvider)
          .getSupplierAccount(_editId!);
      if (mounted) setState(() => _accountData = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _accountLoading = false);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _companyNameController.text.trim(),
      'contactName': _contactNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'website': _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      'taxNumber': _taxNumberController.text.trim().isEmpty
          ? null
          : _taxNumberController.text.trim(),
      'taxOffice': _taxOfficeController.text.trim().isEmpty
          ? null
          : _taxOfficeController.text.trim(),
      'isActive': _isActive,
    };

    try {
      final supplierService = ref.read(supplierServiceProvider);
      final isEdit =
          widget.supplier != null || widget.supplierId != null;

      if (isEdit) {
        final id = (widget.supplier?['id'] ?? widget.supplierId).toString();
        await supplierService.updateSupplier(id, data);
        if (mounted) {
          AppToast.success(context, t('suppliers.updated'));
        }
      } else {
        await supplierService.createSupplier(data);
        if (mounted) {
          AppToast.success(context, t('suppliers.created'));
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Cari hesap durumu kartı (edit modunda)
  Widget _buildAccountCard() {
    if (_accountLoading) {
      return AppCard(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final balance = (_accountData?['currentBalance'] as num?)?.toDouble();
    final debt    = (_accountData?['totalDebt']      as num?)?.toDouble();
    final paid    = (_accountData?['totalCredit']    as num?)?.toDouble();
    final limit   = (_accountData?['creditLimit']    as num?)?.toDouble();

    // Hesap henüz oluşturulmamış
    if (balance == null && debt == null) {
      return AppCard(
        child: Padding(
          padding: AppConstants.paddingMedium,
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.1),
                  borderRadius: AppConstants.borderRadiusMedium,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.textMuted, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('suppliers.account'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(t('suppliers.no_purchase_records'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final available = (limit != null && balance != null) ? (limit - balance) : null;
    final isExceeded = available != null && available < 0;

    String fmt(double? v) =>
        v == null ? '—' : '₺${v.abs().toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return AppCard(
      borderColor: isExceeded ? AppColors.danger.withValues(alpha: 0.4) : null,
      borderWidth: isExceeded ? 1.5 : null,
      child: Padding(
        padding: AppConstants.paddingMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    color: isExceeded ? AppColors.danger : AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(t('suppliers.account_status'),
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: isExceeded ? AppColors.danger : AppColors.textPrimary)),
                if (isExceeded) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t('suppliers.limit_exceeded'),
                        style: const TextStyle(fontSize: 11, color: AppColors.danger,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: _accountRow(
                    Icons.account_balance_outlined, t('suppliers.current_balance'), fmt(balance),
                    balance != null && balance > 0 ? AppColors.danger : AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _accountRow(
                    Icons.trending_up_outlined, t('suppliers.total_debt'), fmt(debt), AppColors.danger)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _accountRow(
                    Icons.check_circle_outline, t('suppliers.total_payment'), fmt(paid), AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _accountRow(
                    Icons.credit_card_outlined, t('suppliers.available_limit'), fmt(available),
                    isExceeded ? AppColors.danger : AppColors.info)),
              ],
            ),
            if (limit != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('${t('suppliers.credit_limit')}: ${fmt(limit)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const Spacer(),
                  Text(
                    '${((balance ?? 0) / limit * 100).clamp(0, 100).toStringAsFixed(0)}% ${t('suppliers.used')}',
                    style: TextStyle(
                        fontSize: 11,
                        color: isExceeded ? AppColors.danger : AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: AppConstants.borderRadiusMedium,
                child: LinearProgressIndicator(
                  value: limit > 0 ? ((balance ?? 0) / limit).clamp(0.0, 1.0) : 0.0,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isExceeded ? AppColors.danger : AppColors.primary),
                ),
              ),
            ],
            // İşlem butonları
            const Divider(height: 20),
            Row(
              children: [
                Expanded(child: _cardActionBtn(
                  icon: Icons.payments_outlined,
                  label: t('suppliers.make_payment'),
                  color: AppColors.success,
                  onTap: _showPaymentDialog,
                )),
                const SizedBox(width: 8),
                Expanded(child: _cardActionBtn(
                  icon: Icons.receipt_long_outlined,
                  label: t('suppliers.movements'),
                  color: AppColors.primary,
                  onTap: _showTransactionsSheet,
                )),
                const SizedBox(width: 8),
                Expanded(child: _cardActionBtn(
                  icon: Icons.tune_outlined,
                  label: t('suppliers.edit_limit'),
                  color: AppColors.info,
                  onTap: _showCreditLimitDialog,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppConstants.borderRadiusMedium,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _accountRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppConstants.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
                Text(value,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ödeme Kaydet Dialog ────────────────────────────────────────────────────
  void _showPaymentDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'CASH';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text(t('suppliers.record_payment')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${t('suppliers.amount')} (₺) *',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(labelText: t('suppliers.payment_method')),
                items: [
                  DropdownMenuItem(value: 'CASH', child: Text(t('suppliers.cash'))),
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text(t('suppliers.bank_transfer'))),
                  DropdownMenuItem(value: 'CREDIT_CARD', child: Text(t('suppliers.credit_card'))),
                  DropdownMenuItem(value: 'CHECK', child: Text(t('suppliers.check'))),
                  DropdownMenuItem(value: 'OTHER', child: Text(t('common.other'))),
                ],
                onChanged: (v) => setDs(() => selectedType = v ?? 'CASH'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(labelText: t('suppliers.description_optional')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('common.cancel')),
            ),
            StatefulBuilder(
              builder: (ctx2, setSaving) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                          final amount = double.tryParse(
                              amountCtrl.text.trim().replaceAll(',', '.'));
                          if (amount == null || amount <= 0) return;
                          setSaving(() => saving = true);
                          try {
                            await ref.read(supplierServiceProvider).recordPayment(
                              _editId!,
                              {
                                'amount': amount,
                                'paymentType': selectedType,
                                if (descCtrl.text.trim().isNotEmpty)
                                  'description': descCtrl.text.trim(),
                              },
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadAccountData();
                            if (mounted) {
                              AppToast.success(context, t('suppliers.payment_saved'));
                            }
                          } catch (e) {
                            setSaving(() => saving = false);
                            if (ctx.mounted) {
                              AppToast.error(context, '$e');
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(t('common.save')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Kredi Limiti Güncelle Dialog ───────────────────────────────────────────
  void _showCreditLimitDialog() {
    final limitCtrl = TextEditingController(
      text: (_accountData?['creditLimit'] as num?)?.toStringAsFixed(2) ?? '',
    );
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) {
          return AlertDialog(
            title: Text(t('suppliers.edit_credit_limit')),
            content: TextField(
              controller: limitCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${t('suppliers.new_credit_limit')} (₺)',
                prefixIcon: const Icon(Icons.credit_card_outlined),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t('common.cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white),
                onPressed: () async {
                        final limit = double.tryParse(
                            limitCtrl.text.trim().replaceAll(',', '.'));
                        if (limit == null || limit < 0) return;
                        setDs(() => saving = true);
                        try {
                          await ref
                              .read(supplierServiceProvider)
                              .updateCreditLimit(_editId!, limit);
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadAccountData();
                          if (mounted) {
                            AppToast.success(context, t('suppliers.credit_limit_updated'));
                          }
                        } catch (e) {
                          setDs(() => saving = false);
                          if (ctx.mounted) {
                            AppToast.error(context, '$e');
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(t('common.save')),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Hesap Hareketleri Bottom Sheet ─────────────────────────────────────────
  void _showTransactionsSheet() {
    final suppId = _editId;
    if (suppId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) =>
            FutureBuilder<List<Map<String, dynamic>>>(
          future: ref
              .read(supplierServiceProvider)
              .getSupplierTransactions(suppId),
          builder: (ctx, snap) => Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(t('suppliers.account_movements'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(),
              if (snap.connectionState == ConnectionState.waiting)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (snap.data == null || snap.data!.isEmpty)
                Expanded(
                    child: Center(child: Text(t('suppliers.no_movements'))))
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: snap.data!.length,
                    itemBuilder: (ctx, i) {
                      final tx = snap.data![i];
                      final debit =
                          (tx['debitAmount'] as num?)?.toDouble() ?? 0;
                      final credit =
                          (tx['creditAmount'] as num?)?.toDouble() ?? 0;
                      final isDebit = debit > 0;
                      final amount = isDebit ? debit : credit;
                      final color =
                          isDebit ? AppColors.danger : AppColors.success;
                      final sign = isDebit ? '+' : '-';
                      final date = tx['transactionDate']
                              ?.toString()
                              .substring(0, 10) ??
                          '';
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Icon(
                              isDebit
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16, color: color),
                        ),
                        title: Text(
                          tx['transactionTypeLabel'] ??
                              tx['transactionType'] ?? '',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          tx['description'] ?? date,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$sign₺${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                            if (tx['balance'] != null)
                              Text(
                                '${t('suppliers.balance')}: ₺${(tx['balance'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Aktif / Pasif toggle kartı
  Widget _buildStatusCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (_isActive ? AppColors.success : AppColors.textMuted)
                    .withValues(alpha: 0.12),
                borderRadius: AppConstants.borderRadiusMedium,
              ),
              child: Icon(
                _isActive
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color:
                    _isActive ? AppColors.success : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('suppliers.status'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    _isActive
                        ? t('suppliers.active_description')
                        : t('suppliers.passive_description'),
                    style: TextStyle(
                        fontSize: 12,
                        color: _isActive
                            ? AppColors.success
                            : AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Aktif / Pasif seçim düğmeleri
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusButton(
                  label: t('common.active'),
                  selected: _isActive,
                  color: AppColors.success,
                  onTap: () => setState(() => _isActive = true),
                ),
                const SizedBox(width: 6),
                _statusButton(
                  label: t('common.passive'),
                  selected: !_isActive,
                  color: AppColors.danger,
                  onTap: () => setState(() => _isActive = false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(
              color: selected ? color : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isEdit =
        widget.supplier != null || widget.supplierId != null;

    return AppScaffold(
      appBar: AppAppBar.primary(
        title: isEdit ? t('suppliers.edit') : t('suppliers.add'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && isEdit && widget.supplier == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppConstants.pagePadding,
                children: [
                  // ── Cari Hesap Durumu (sadece edit modunda) ──────
                  if (isEdit) ...[
                    _buildAccountCard(),
                    const SizedBox(height: AppConstants.formFieldSpacing),
                  ],

                  // ── Firma Bilgileri ──────────────────────────────
                  AppSectionCard(
                    title: t('suppliers.company_info'),
                    icon: Icons.business,
                    children: [
                      AppInput(
                        controller: _companyNameController,
                        label: '${t('suppliers.company_name')} *',
                        hint: 'Örn: ABC Tedarik Ltd. Şti.',
                        prefixIcon: Icons.business_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? t('suppliers.company_name_required')
                            : null,
                      ),
                      const SizedBox(height: AppConstants.formFieldSpacing),
                      AppInput(
                        controller: _contactNameController,
                        label: '${t('suppliers.contact_person')} *',
                        hint: 'Örn: Ahmet Yılmaz',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? t('suppliers.contact_required')
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.formFieldSpacing),

                  // ── İletişim Bilgileri ───────────────────────────
                  AppSectionCard(
                    title: t('suppliers.contact_info'),
                    icon: Icons.contact_phone,
                    children: [
                      AppInput(
                        controller: _phoneController,
                        label: '${t('suppliers.phone')} *',
                        hint: '0212 345 67 89',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? t('suppliers.phone_required')
                            : null,
                      ),
                      const SizedBox(height: AppConstants.formFieldSpacing),
                      AppInput(
                        controller: _emailController,
                        label: t('suppliers.email'),
                        hint: 'ornek@sirket.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v)) {
                              return t('suppliers.email_invalid');
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.formFieldSpacing),
                      AppInput(
                        controller: _addressController,
                        label: t('suppliers.address'),
                        hint: 'Tam adres...',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppConstants.formFieldSpacing),
                      AppInput(
                        controller: _websiteController,
                        label: t('suppliers.website'),
                        hint: 'https://www.tedarikci.com/katalog',
                        prefixIcon: Icons.language_outlined,
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.formFieldSpacing),

                  // ── Vergi Bilgileri ──────────────────────────────
                  AppSectionCard(
                    title: t('suppliers.tax_info'),
                    icon: Icons.receipt_long,
                    children: [
                      AppInput(
                        controller: _taxNumberController,
                        label: t('suppliers.tax_number'),
                        hint: '1234567890',
                        prefixIcon: Icons.numbers,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppConstants.formFieldSpacing),
                      AppInput(
                        controller: _taxOfficeController,
                        label: t('suppliers.tax_office'),
                        hint: 'Örn: Kadıköy',
                        prefixIcon: Icons.account_balance_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.formFieldSpacing),

                  // ── Durum (Aktif / Pasif) ────────────────────────
                  _buildStatusCard(),

                  const SizedBox(height: AppConstants.formFieldSpacing),

                  // ── Kaydet Butonu ────────────────────────────────
                  AppButton.primary(
                    text: _isLoading
                        ? t('common.saving')
                        : (isEdit ? t('common.update') : t('common.save')),
                    onPressed: _isLoading ? null : _saveSupplier,
                    icon: Icons.save,
                    isLoading: _isLoading,
                    fullWidth: true,
                    size: ButtonSize.large,
                  ),
                ],
              ),
            ),
    );
  }
}