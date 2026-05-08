import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/services/company/company_info.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  String Function(String) get t => i18nOf(ref);
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Firma Bilgileri
  final _companyNameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _taxOfficeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  // Fatura Ayarlari
  final _invoicePrefixController = TextEditingController();
  final _defaultVatRateController = TextEditingController();

  // Sistem
  String _selectedCurrency = 'TRY';

  static const _currencies = ['TRY', 'USD', 'EUR'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _invoicePrefixController.dispose();
    _defaultVatRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(userServiceProvider);
      final data = await service.getCompanySettings();
      if (mounted) {
        setState(() {
          _companyNameController.text = data['companyName']?.toString() ?? '';
          _taxNumberController.text = data['taxNumber']?.toString() ?? '';
          _taxOfficeController.text = data['taxOffice']?.toString() ?? '';
          _phoneController.text = data['phone']?.toString() ?? '';
          _emailController.text = data['email']?.toString() ?? '';
          _addressController.text = data['address']?.toString() ?? '';
          _invoicePrefixController.text = data['invoicePrefix']?.toString() ?? '';
          _defaultVatRateController.text = data['defaultVatRate']?.toString() ?? '18';
          _selectedCurrency = data['currency']?.toString() ?? 'TRY';
          if (!_currencies.contains(_selectedCurrency)) {
            _selectedCurrency = 'TRY';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(userServiceProvider);
      await service.updateCompanySettings({
        'companyName': _companyNameController.text.trim(),
        'taxNumber': _taxNumberController.text.trim(),
        'taxOffice': _taxOfficeController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'invoicePrefix': _invoicePrefixController.text.trim(),
        'defaultVatRate': double.tryParse(_defaultVatRateController.text.trim()) ?? 18,
        'currency': _selectedCurrency,
      });
      // Sprint 30: Fiş başlığı için kullanılan CompanyInfo cache'ini güncelle.
      // Backend save tamamlandı → cache invalidate + reload (bir sonraki fiş
      // basımında yeni veri akar; restart gerekmez).
      await ref.read(companyInfoProvider.notifier).refreshFromBackend();
      if (mounted) {
        AppToast.success(context, t('common.saved'));
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppAppBar.standard(
        title: t('settings.company'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(t('common.save')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ─── Firma Bilgileri ────────────────────────────
                    _buildSectionCard(
                      title: t('settings.company'),
                      icon: Icons.business,
                      children: [
                        _buildTextField(
                          controller: _companyNameController,
                          label: 'Firma Adı', // TODO: i18n
                          icon: Icons.business,
                          validator: (v) => (v == null || v.trim().isEmpty) ? t('common.required') : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _taxNumberController,
                                label: 'Vergi No', // TODO: i18n
                                icon: Icons.numbers,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _taxOfficeController,
                                label: 'Vergi Dairesi', // TODO: i18n
                                icon: Icons.account_balance,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _phoneController,
                                label: 'Telefon', // TODO: i18n
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _emailController,
                                label: 'E-posta', // TODO: i18n
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Adres', // TODO: i18n
                          icon: Icons.location_on_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Fatura Ayarları ────────────────────────────
                    _buildSectionCard(
                      title: 'Fatura Ayarları', // TODO: i18n
                      icon: Icons.receipt_long,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _invoicePrefixController,
                                label: 'Seri No Prefix', // TODO: i18n
                                icon: Icons.tag,
                                hintText: 'Orn: INV-',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _defaultVatRateController,
                                label: 'Varsayılan KDV Oranı (%)', // TODO: i18n
                                icon: Icons.percent,
                                keyboardType: TextInputType.number,
                                hintText: '18',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ─── Sistem ─────────────────────────────────────
                    _buildSectionCard(
                      title: 'Sistem', // TODO: i18n
                      icon: Icons.settings,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Varsayılan Para Birimi', // TODO: i18n
                            prefixIcon: Icon(Icons.monetization_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _currencies.map((c) {
                            String label;
                            switch (c) {
                              case 'TRY':
                                label = 'TRY - Türk Lirası'; // TODO: i18n
                                break;
                              case 'USD':
                                label = 'USD - Amerikan Doları'; // TODO: i18n
                                break;
                              case 'EUR':
                                label = 'EUR - Euro';
                                break;
                              default:
                                label = c;
                            }
                            return DropdownMenuItem(value: c, child: Text(label));
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedCurrency = value);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
