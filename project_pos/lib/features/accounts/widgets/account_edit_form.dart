import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/providers/accounts_list_provider.dart';
import 'package:project_pos/services/service_locator.dart';

/// Cari hesap oluşturma / düzenleme formu.
///
/// - `initialType` ile varsayılan tip (CUSTOMER / SUPPLIER).
/// - `editingId` + `initialData` dolu ise edit modu.
/// - Başarılı kaydetmede `onSuccess` çağrılır (parent form panelini kapatsın).
class AccountEditForm extends ConsumerStatefulWidget {
  final String initialType;
  final String? editingId;
  final Map<String, dynamic>? initialData;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const AccountEditForm({
    super.key,
    this.initialType = 'CUSTOMER',
    this.editingId,
    this.initialData,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  ConsumerState<AccountEditForm> createState() => _AccountEditFormState();
}

class _AccountEditFormState extends ConsumerState<AccountEditForm> {
  final _formKey = GlobalKey<FormState>();
  late String _type; // CUSTOMER | SUPPLIER
  bool _submitting = false;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _taxNumber;
  late final TextEditingController _taxOffice;
  late final TextEditingController _contactName; // supplier
  late final TextEditingController _website;     // supplier
  late final TextEditingController _creditLimit;
  late final TextEditingController _paymentTerm;
  late final TextEditingController _notes;

  bool get _isEdit => widget.editingId != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final d = widget.initialData ?? const {};
    _name = TextEditingController(text: d['name']?.toString() ?? '');
    _phone = TextEditingController(text: d['phone']?.toString() ?? '');
    _email = TextEditingController(text: d['email']?.toString() ?? '');
    _address = TextEditingController(text: d['address']?.toString() ?? '');
    _taxNumber =
        TextEditingController(text: d['taxNumber']?.toString() ?? '');
    _taxOffice =
        TextEditingController(text: d['taxOffice']?.toString() ?? '');
    _contactName =
        TextEditingController(text: d['contactName']?.toString() ?? '');
    _website = TextEditingController(text: d['website']?.toString() ?? '');
    _creditLimit = TextEditingController(
        text: (d['creditLimit'] ?? 0).toString());
    _paymentTerm = TextEditingController(
        text: (d['paymentTermDays'] ?? 30).toString());
    _notes = TextEditingController(text: d['notes']?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _taxNumber.dispose();
    _taxOffice.dispose();
    _contactName.dispose();
    _website.dispose();
    _creditLimit.dispose();
    _paymentTerm.dispose();
    _notes.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final base = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'taxNumber': _taxNumber.text.trim().isEmpty
          ? null
          : _taxNumber.text.trim(),
      'taxOffice': _taxOffice.text.trim().isEmpty
          ? null
          : _taxOffice.text.trim(),
      'creditLimit': double.tryParse(_creditLimit.text.trim()) ?? 0,
      'paymentTermDays': int.tryParse(_paymentTerm.text.trim()) ?? 30,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'isActive': true,
    };
    if (_type == 'SUPPLIER') {
      base['contactName'] = _contactName.text.trim().isEmpty
          ? null
          : _contactName.text.trim();
      base['website'] = _website.text.trim().isEmpty
          ? null
          : _website.text.trim();
    }
    return base;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final payload = _buildPayload();
      if (_type == 'CUSTOMER') {
        final svc = ref.read(customerServiceProvider);
        if (_isEdit) {
          await svc.updateCustomer(widget.editingId!, payload);
        } else {
          await svc.createCustomer(payload);
        }
      } else {
        final svc = ref.read(supplierServiceProvider);
        if (_isEdit) {
          await svc.updateSupplier(widget.editingId!, payload);
        } else {
          await svc.createSupplier(payload);
        }
      }
      if (!mounted) return;
      // Cari listesini yenile
      await ref.read(accountsListProvider.notifier).load();
      if (!mounted) return;
      AppToast.success(context,
          _isEdit ? 'Güncellendi' : 'Oluşturuldu');
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final isSupplier = _type == 'SUPPLIER';
    final accent = isSupplier ? AppColors.orange : AppColors.info;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: başlık + kapat
            Row(
              children: [
                Icon(
                  isSupplier ? Icons.business_outlined : Icons.person_outline,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isEdit
                        ? t('accounts.edit_title')
                        : t('accounts.new_title'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _submitting ? null : widget.onCancel,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tip seçimi — sadece create mode'da
            if (!_isEdit)
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'CUSTOMER',
                    label: Text(t('accounts.customer_label')),
                    icon: const Icon(Icons.person_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: 'SUPPLIER',
                    label: Text(t('accounts.supplier_label')),
                    icon: const Icon(Icons.business_outlined, size: 16),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _submitting
                    ? null
                    : (s) => setState(() => _type = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 12)),
                ),
              ),
            if (!_isEdit) const SizedBox(height: 10),

            // Alanlar
            _field(_name, t('accounts.field_name'),
                required: true, icon: Icons.badge_outlined),
            const SizedBox(height: 8),

            if (isSupplier) ...[
              _field(_contactName, t('accounts.field_contact_name'),
                  icon: Icons.person_outline),
              const SizedBox(height: 8),
            ],

            Row(children: [
              Expanded(
                  child: _field(_phone, t('accounts.field_phone'),
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone)),
              const SizedBox(width: 8),
              Expanded(
                  child: _field(_email, t('accounts.field_email'),
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress)),
            ]),
            const SizedBox(height: 8),

            _field(_address, t('accounts.field_address'),
                icon: Icons.location_on_outlined, maxLines: 2),
            const SizedBox(height: 8),

            Row(children: [
              Expanded(
                  child: _field(_taxNumber, t('accounts.field_tax_number'),
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(
                  child: _field(_taxOffice, t('accounts.field_tax_office'),
                      icon: Icons.account_balance_outlined)),
            ]),
            const SizedBox(height: 8),

            if (isSupplier) ...[
              _field(_website, t('accounts.field_website'),
                  icon: Icons.language),
              const SizedBox(height: 8),
            ],

            Row(children: [
              Expanded(
                  child: _field(_creditLimit, t('accounts.field_credit_limit'),
                      icon: Icons.credit_score,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ])),
              const SizedBox(width: 8),
              Expanded(
                  child: _field(_paymentTerm, t('accounts.field_payment_term'),
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ])),
            ]),
            const SizedBox(height: 8),

            _field(_notes, t('accounts.field_notes'),
                icon: Icons.note_alt_outlined, maxLines: 2),
            const SizedBox(height: 12),

            // Aksiyon butonları
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : widget.onCancel,
                  child: Text(t('common.cancel')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(_isEdit ? Icons.save_outlined : Icons.check),
                  label: Text(_isEdit
                      ? t('common.save')
                      : t('accounts.create_action')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '*' : null
          : null,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, size: 16, color: AppColors.textMuted)
            : null,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
