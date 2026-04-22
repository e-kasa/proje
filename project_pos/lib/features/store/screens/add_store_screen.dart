import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/store_service.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class AddStoreScreen extends ConsumerStatefulWidget {
  final String? storeId;

  const AddStoreScreen({super.key, this.storeId});

  @override
  ConsumerState<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends ConsumerState<AddStoreScreen> {
  String Function(String) get t => i18nOf(ref);

  final _formKey = GlobalKey<FormState>();
  late StoreService _storeService;

  // Controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _managerController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _salesAreaController = TextEditingController();
  final _employeeCountController = TextEditingController();

  String _selectedType = 'branch';
  bool _hasWarehouse = false;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _storeTypes = [
    {'value': 'flagship', 'labelKey': 'stores.type_flagship', 'icon': Icons.store},
    {'value': 'branch', 'labelKey': 'stores.type_branch', 'icon': Icons.storefront},
    {'value': 'outlet', 'labelKey': 'stores.type_outlet', 'icon': Icons.local_mall},
  ];

  @override
  void initState() {
    super.initState();
    _storeService = ref.read(storeServiceProvider);
    if (widget.storeId != null) _loadStore();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _managerController.dispose();
    _openingHoursController.dispose();
    _totalAreaController.dispose();
    _salesAreaController.dispose();
    _employeeCountController.dispose();
    super.dispose();
  }

  Future<void> _loadStore() async {
    setState(() => _isLoading = true);
    try {
      final store = await _storeService.getStoreById(widget.storeId!);
      setState(() {
        _codeController.text = store['code'] ?? '';
        _nameController.text = store['name'] ?? '';
        _addressController.text = store['address'] ?? '';
        _cityController.text = store['city'] ?? '';
        _districtController.text = store['district'] ?? '';
        _phoneController.text = store['phone'] ?? '';
        _emailController.text = store['email'] ?? '';
        _managerController.text = store['managerName'] ?? '';
        _openingHoursController.text = store['openingHours'] ?? '';
        _totalAreaController.text = store['totalArea']?.toString() ?? '';
        _salesAreaController.text = store['salesArea']?.toString() ?? '';
        _employeeCountController.text = store['employeeCount']?.toString() ?? '';
        _selectedType = store['type'] ?? 'branch';
        _hasWarehouse = store['hasWarehouse'] ?? false;
        _isActive = store['isActive'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AppToast.error(context, t('stores.load_error'));
    }
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'managerName': _managerController.text.trim(),
      'openingHours': _openingHoursController.text.trim(),
      'totalArea': int.tryParse(_totalAreaController.text) ?? 0,
      'salesArea': int.tryParse(_salesAreaController.text) ?? 0,
      'employeeCount': int.tryParse(_employeeCountController.text) ?? 0,
      'type': _selectedType,
      'hasWarehouse': _hasWarehouse,
      'isActive': _isActive,
    };

    try {
      if (widget.storeId != null) {
        await _storeService.updateStore(widget.storeId!, data);
        if (mounted) {
          AppToast.success(context, t('stores.updated_success'));
          context.pop();
        }
      } else {
        await _storeService.createStore(data);
        if (mounted) {
          AppToast.success(context, t('stores.created_success'));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(context, t('stores.save_error'));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: widget.storeId != null ? t('stores.edit') : t('stores.add'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppConstants.pagePadding,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppSectionCard(
                      title: t('stores.store_type'),
                      icon: Icons.category,
                      children: _storeTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            onTap: () => setState(() => _selectedType = type['value']),
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                            borderColor: isSelected ? AppColors.primary : AppColors.border,
                            borderWidth: isSelected ? 2 : 1,
                            hasShadow: false,
                            child: Row(
                              children: [
                                Icon(type['icon'], color: isSelected ? AppColors.primary : AppColors.textMuted),
                                const SizedBox(width: 12),
                                Expanded(child: Text(t(type['labelKey'] as String), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.textPrimary))),
                                if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: t('stores.basic_info'),
                      icon: Icons.info,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppInput(
                                controller: _codeController,
                                label: t('stores.code_required'),
                                hint: 'STR-001',
                                prefixIcon: Icons.qr_code,
                                validator: (v) => v == null || v.trim().isEmpty ? t('stores.code_required_msg') : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppInput(
                                controller: _employeeCountController,
                                label: t('stores.employee_count_required'),
                                prefixIcon: Icons.people,
                                suffixText: t('stores.person_suffix'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (v) => v == null || v.trim().isEmpty ? t('stores.employee_count_required_msg') : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          controller: _nameController,
                          label: t('stores.name_required'),
                          hint: t('stores.name_hint'),
                          prefixIcon: Icons.store,
                          validator: (v) => v == null || v.trim().isEmpty ? t('stores.name_required_msg') : null,
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          controller: _managerController,
                          label: t('stores.manager_required'),
                          hint: t('stores.manager_hint'),
                          prefixIcon: Icons.person,
                          validator: (v) => v == null || v.trim().isEmpty ? t('stores.manager_required_msg') : null,
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          controller: _openingHoursController,
                          label: t('stores.opening_hours_required'),
                          hint: '09:00 - 22:00',
                          prefixIcon: Icons.access_time,
                          validator: (v) => v == null || v.trim().isEmpty ? t('stores.opening_hours_required_msg') : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: t('stores.location_info'),
                      icon: Icons.location_on,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppInput(
                                controller: _cityController,
                                label: t('stores.city_required'),
                                hint: t('stores.city_hint'),
                                prefixIcon: Icons.location_city,
                                validator: (v) => v == null || v.trim().isEmpty ? t('stores.city_required_msg') : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppInput(
                                controller: _districtController,
                                label: t('stores.district_required'),
                                hint: t('stores.district_hint'),
                                prefixIcon: Icons.place,
                                validator: (v) => v == null || v.trim().isEmpty ? t('stores.district_required_msg') : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          controller: _addressController,
                          label: t('stores.address_required'),
                          hint: t('stores.address_hint'),
                          prefixIcon: Icons.home,
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty ? t('stores.address_required_msg') : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: t('stores.contact_info'),
                      icon: Icons.phone,
                      children: [
                        AppInput(
                          controller: _phoneController,
                          label: t('stores.phone_required'),
                          hint: '+90 (216) 555-0201',
                          prefixIcon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.trim().isEmpty ? t('stores.phone_required_msg') : null,
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          controller: _emailController,
                          label: t('stores.email'),
                          hint: 'merkez@magaza.com',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: t('stores.area_info'),
                      icon: Icons.square_foot,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppInput(
                                controller: _totalAreaController,
                                label: t('stores.total_area'),
                                prefixIcon: Icons.aspect_ratio,
                                suffixText: 'm²',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppInput(
                                controller: _salesAreaController,
                                label: t('stores.sales_area'),
                                prefixIcon: Icons.shopping_cart,
                                suffixText: 'm²',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: t('stores.features'),
                      icon: Icons.settings,
                      children: [
                        SwitchListTile(value: _hasWarehouse, onChanged: (v) => setState(() => _hasWarehouse = v), title: Text(t('stores.has_warehouse')), subtitle: Text(_hasWarehouse ? t('stores.has_warehouse_yes') : t('stores.has_warehouse_no'), style: const TextStyle(fontSize: 12)), secondary: Icon(_hasWarehouse ? Icons.warehouse : Icons.store, color: _hasWarehouse ? AppColors.success : AppColors.textMuted)),
                        const Divider(),
                        SwitchListTile(value: _isActive, onChanged: (v) => setState(() => _isActive = v), title: Text(t('common.active')), subtitle: Text(_isActive ? t('stores.currently_active') : t('stores.currently_passive'), style: const TextStyle(fontSize: 12)), secondary: Icon(_isActive ? Icons.check_circle : Icons.cancel, color: _isActive ? AppColors.success : AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: AppButton.primary(text: _isSaving ? t('common.saving') : widget.storeId != null ? t('common.update') : t('common.save'), icon: _isSaving ? null : Icons.save, onPressed: _isSaving ? null : _saveStore)),
                  ],
                ),
              ),
            ),
    );
  }
}