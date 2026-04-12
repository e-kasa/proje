import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

// CustomerType backend enum değerleri
const _customerTypes = [
  _CustomerTypeOption('INDIVIDUAL', 'Bireysel', Icons.person_outline),
  _CustomerTypeOption('CORPORATE',  'Kurumsal', Icons.business_outlined),
  _CustomerTypeOption('DEALER',     'Bayi',     Icons.store_outlined),
  _CustomerTypeOption('WHOLESALER', 'Toptancı', Icons.inventory_2_outlined),
];

class AddCustomerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? customer;
  final String? customerId;

  const AddCustomerScreen({super.key, this.customer, this.customerId});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  String Function(String) get t => i18nOf(ref);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _taxNumberController;
  late TextEditingController _taxOfficeController;
  late TextEditingController _notesController;

  String _customerType = 'INDIVIDUAL';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.customerId != null && widget.customer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomer());
    }
  }

  void _initializeControllers() {
    final c = widget.customer;
    _nameController       = TextEditingController(text: c?['name'] ?? '');
    _phoneController      = TextEditingController(text: c?['phone'] ?? '');
    _emailController      = TextEditingController(text: c?['email'] ?? '');
    _addressController    = TextEditingController(text: c?['address'] ?? '');
    _taxNumberController  = TextEditingController(text: c?['taxNumber'] ?? '');
    _taxOfficeController  = TextEditingController(text: c?['taxOffice'] ?? '');
    _notesController      = TextEditingController(text: c?['notes'] ?? '');

    if (c != null) {
      final ct = c['customerType']?.toString();
      if (ct != null && _customerTypes.any((t) => t.value == ct)) {
        _customerType = ct;
      }
      _isActive = c['isActive'] == true;
    }
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    try {
      final data = await ref.read(customerServiceProvider).getCustomerById(widget.customerId!);
      if (data != null && mounted) {
        setState(() {
          _nameController.text      = data['name'] ?? '';
          _phoneController.text     = data['phone'] ?? '';
          _emailController.text     = data['email'] ?? '';
          _addressController.text   = data['address'] ?? '';
          _taxNumberController.text = data['taxNumber'] ?? '';
          _taxOfficeController.text = data['taxOffice'] ?? '';
          _notesController.text     = data['notes'] ?? '';
          final ct = data['customerType']?.toString();
          if (ct != null && _customerTypes.any((t) => t.value == ct)) {
            _customerType = ct;
          }
          _isActive = data['isActive'] == true;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('customers.title')} ${t('common.error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name':         _nameController.text.trim(),
      'phone':        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'email':        _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'address':      _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      'taxNumber':    _taxNumberController.text.trim().isEmpty ? null : _taxNumberController.text.trim(),
      'taxOffice':    _taxOfficeController.text.trim().isEmpty ? null : _taxOfficeController.text.trim(),
      'notes':        _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      'customerType': _customerType,
      'isActive':     _isActive,
    };

    try {
      final svc = ref.read(customerServiceProvider);
      final isEdit = widget.customer != null || widget.customerId != null;

      if (isEdit) {
        final id = (widget.customer?['id'] ?? widget.customerId).toString();
        await svc.updateCustomer(id, data);
        if (mounted) {
          AppToast.success(context, t('common.saved'));
        }
      } else {
        await svc.createCustomer(data);
        if (mounted) {
          AppToast.success(context, t('common.saved'));
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null || widget.customerId != null;

    return AppScaffold(
      appBar: AppAppBar.primary(title: isEdit ? t('customers.edit') : t('customers.add')),
      body: _isLoading && isEdit && widget.customer == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppConstants.pagePadding,
                children: [
                  // ── Müşteri Tipi ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                    child: AppSectionCard(
                      title: t('customers.type'),
                      icon: Icons.category_outlined,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: _customerTypes.map((type) {
                            final selected = _customerType == type.value;
                            return GestureDetector(
                              onTap: () => setState(() => _customerType = type.value),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                  border: Border.all(
                                      color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                      width: selected ? 1.5 : 1),
                                  borderRadius: AppConstants.borderRadiusXLarge,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(type.icon, size: 15,
                                        color: selected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color),
                                    const SizedBox(width: 6),
                                    Text(type.label,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: selected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // ── Temel Bilgiler ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                    child: AppSectionCard(
                      title: t('customers.name'), // TODO: i18n key for 'Temel Bilgiler'
                      icon: Icons.person_outline,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                          child: AppInput(
                            label: '${t('customers.name')} *',
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty) ? t('customers.name') : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                          child: AppInput(
                            label: t('customers.phone'),
                            controller: _phoneController,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                          child: AppInput(
                            label: t('customers.email'),
                            controller: _emailController,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty &&
                                  !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                return t('customers.email'); // TODO: i18n 'Geçerli bir e-posta adresi girin'
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                          child: AppInput(
                            label: 'Adres', // TODO: i18n
                            controller: _addressController,
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Vergi / Kurumsal Bilgiler ─────────────────────
                  if (_customerType == 'CORPORATE' || _customerType == 'DEALER' || _customerType == 'WHOLESALER')
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                      child: AppSectionCard(
                        title: 'Kurumsal Bilgiler', // TODO: i18n
                        icon: Icons.receipt_long_outlined,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                            child: AppInput(
                              label: 'Vergi Numarası', // TODO: i18n
                              controller: _taxNumberController,
                              prefixIcon: Icons.numbers_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                            child: AppInput(
                              label: 'Vergi Dairesi', // TODO: i18n
                              controller: _taxOfficeController,
                              prefixIcon: Icons.account_balance_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Notlar ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                    child: AppSectionCard(
                      title: 'Notlar', // TODO: i18n
                      icon: Icons.note_outlined,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                          child: AppInput(
                            label: 'Notlar (opsiyonel)', // TODO: i18n
                            controller: _notesController,
                            prefixIcon: Icons.edit_note_outlined,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Durum ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.formFieldSpacing),
                    child: _buildStatusCard(),
                  ),

                  const SizedBox(height: 8),

                  // ── Kaydet ────────────────────────────────────────
                  AppButton.primary(
                    text: isEdit ? t('common.edit') : t('common.save'),
                    icon: Icons.save,
                    onPressed: _isLoading ? null : _saveCustomer,
                    isLoading: _isLoading,
                    fullWidth: true,
                    size: ButtonSize.large,
                  ),
                ],
              ),
            ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (_isActive ? const Color(0xFF10B981) : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.12),
                borderRadius: AppConstants.borderRadiusMedium,
              ),
              child: Icon(
                _isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: _isActive ? const Color(0xFF10B981) : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Müşteri Durumu', // TODO: i18n
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    _isActive ? 'Aktif — satış ve işlemlerde kullanılabilir' // TODO: i18n
                              : 'Pasif — işlemlerde görünmez', // TODO: i18n
                    style: TextStyle(fontSize: 12,
                        color: _isActive ? const Color(0xFF10B981) : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusBtn(t('common.active'),  _isActive,  const Color(0xFF10B981), () => setState(() => _isActive = true)),
                const SizedBox(width: 6),
                _statusBtn(t('common.passive'), !_isActive, const Color(0xFFEF4444),  () => setState(() => _isActive = false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: selected ? color : Theme.of(context).dividerColor, width: 1.5),
          borderRadius: AppConstants.borderRadiusXLarge,
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color)),
      ),
    );
  }
}

class _CustomerTypeOption {
  final String value;
  final String label;
  final IconData icon;
  const _CustomerTypeOption(this.value, this.label, this.icon);
}