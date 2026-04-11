import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/store_service.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/i18n_helper.dart';

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
    _storeService = StoreService(ApiClient());
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppConstants.borderRadiusMedium,
                            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
                          ),
                          child: InkWell(
                            onTap: () => setState(() => _selectedType = type['value']),
                            borderRadius: AppConstants.borderRadiusMedium,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(type['icon'], color: isSelected ? AppColors.primary : AppColors.textMuted),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(t(type['labelKey'] as String), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.textPrimary))),
                                  if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
                                ],
                              ),
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
                            Expanded(child: TextFormField(controller: _codeController, decoration: InputDecoration(labelText: t('stores.code_required'), hintText: 'STR-001', prefixIcon: const Icon(Icons.qr_code)), validator: (v) => v == null || v.trim().isEmpty ? t('stores.code_required_msg') : null)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _employeeCountController, decoration: InputDecoration(labelText: t('stores.employee_count_required'), prefixIcon: const Icon(Icons.people), suffixText: t('stores.person_suffix')), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v == null || v.trim().isEmpty ? t('stores.employee_count_required_msg') : null)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(controller: _nameController, decoration: InputDecoration(labelText: t('stores.name_required'), hintText: t('stores.name_hint'), prefixIcon: const Icon(Icons.store)), validator: (v) => v == null || v.trim().isEmpty ? t('stores.name_required_msg') : null),
                        const SizedBox(height: 16),
                        TextFormField(controller: _managerController, decoration: InputDecoration(labelText: t('stores.manager_required'), hintText: t('stores.manager_hint'), prefixIcon: const Icon(Icons.person)), validator: (v) => v == null || v.trim().isEmpty ? t('stores.manager_required_msg') : null),
                        const SizedBox(height: 16),
                        TextFormField(controller: _openingHoursController, decoration: InputDecoration(labelText: t('stores.opening_hours_required'), hintText: '09:00 - 22:00', prefixIcon: const Icon(Icons.access_time)), validator: (v) => v == null || v.trim().isEmpty ? t('stores.opening_hours_required_msg') : null),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: t('stores.location_info'),
                      icon: Icons.location_on,
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _cityController, decoration: InputDecoration(labelText: t('stores.city_required'), hintText: t('stores.city_hint'), prefixIcon: const Icon(Icons.location_city)), validator: (v) => v == null || v.trim().isEmpty ? t('stores.city_required_msg') : null)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _districtController, decoration: InputDecoration(labelText: t('stores.district_required'), hintText: t('stores.district_hint'), prefixIcon: const Icon(Icons.place)), validator: (v) => v == null || v.trim().isEmpty ? t('stores.district_required_msg') : null)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(controller: _addressController, decoration: InputDecoration(labelText: t('stores.address_required'), hintText: t('stores.address_hint'), prefixIcon: const Icon(Icons.home)), maxLines: 2, validator: (v) => v == null || v.trim().isEmpty ? t('stores.address_required_msg') : null),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: t('stores.contact_info'),
                      icon: Icons.phone,
                      children: [
                        TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: t('stores.phone_required'), hintText: '+90 (216) 555-0201', prefixIcon: const Icon(Icons.phone_android)), keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? t('stores.phone_required_msg') : null),
                        const SizedBox(height: 16),
                        TextFormField(controller: _emailController, decoration: InputDecoration(labelText: t('stores.email'), hintText: 'merkez@magaza.com', prefixIcon: const Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: t('stores.area_info'),
                      icon: Icons.square_foot,
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _totalAreaController, decoration: InputDecoration(labelText: t('stores.total_area'), prefixIcon: const Icon(Icons.aspect_ratio), suffixText: 'm²'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _salesAreaController, decoration: InputDecoration(labelText: t('stores.sales_area'), prefixIcon: const Icon(Icons.shopping_cart), suffixText: 'm²'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
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