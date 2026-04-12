import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/services/warehouse_service.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class AddWarehouseScreen extends ConsumerStatefulWidget {
  final String? warehouseId;

  const AddWarehouseScreen({super.key, this.warehouseId});

  @override
  ConsumerState<AddWarehouseScreen> createState() => _AddWarehouseScreenState();
}

class _AddWarehouseScreenState extends ConsumerState<AddWarehouseScreen> {
  String Function(String) get t => i18nOf(ref);

  final _formKey = GlobalKey<FormState>();
  late WarehouseService _warehouseService;

  // Controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _capacityController = TextEditingController();

  String _selectedType = 'main';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _warehouseTypes = [
    {'value': 'main', 'labelKey': 'warehouses.type_main', 'icon': Icons.warehouse},
    {'value': 'regional', 'labelKey': 'warehouses.type_regional', 'icon': Icons.location_city},
    {'value': 'backup', 'labelKey': 'warehouses.type_backup', 'icon': Icons.inventory_2},
  ];

  @override
  void initState() {
    super.initState();
    _warehouseService = ref.read(warehouseServiceProvider);
    if (widget.warehouseId != null) {
      _loadWarehouse();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    _managerNameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouse() async {
    setState(() => _isLoading = true);
    try {
      final warehouse = await _warehouseService.getWarehouseById(widget.warehouseId!);

      setState(() {
        _codeController.text = warehouse['code'] ?? '';
        _nameController.text = warehouse['name'] ?? '';
        _addressController.text = warehouse['address'] ?? '';
        _cityController.text = warehouse['city'] ?? '';
        _districtController.text = warehouse['district'] ?? '';
        _phoneController.text = warehouse['phone'] ?? '';
        _managerNameController.text = warehouse['managerName'] ?? '';
        _capacityController.text = warehouse['capacity']?.toString() ?? '';
        _selectedType = warehouse['type'] ?? 'main';
        _isActive = warehouse['isActive'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, t('warehouses.load_error'));
      }
    }
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'code': _codeController.text.trim(),
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'phone': _phoneController.text.trim(),
      'managerName': _managerNameController.text.trim(),
      'capacity': int.tryParse(_capacityController.text) ?? 0,
      'type': _selectedType,
      'isActive': _isActive,
    };

    try {
      if (widget.warehouseId != null) {
        await _warehouseService.updateWarehouse(widget.warehouseId!, data);
        if (mounted) {
          AppToast.success(context, t('warehouses.updated_success'));
          context.pop();
        }
      } else {
        await _warehouseService.createWarehouse(data);
        if (mounted) {
          AppToast.success(context, t('warehouses.created_success'));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, t('warehouses.save_error'));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: widget.warehouseId != null ? t('warehouses.edit') : t('warehouses.add'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppConstants.pagePadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Depo Tipi Seçimi
                    _buildSectionCard(
                      title: t('warehouses.warehouse_type'),
                      icon: Icons.category,
                      children: _warehouseTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppConstants.borderRadiusMedium,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => setState(() => _selectedType = type['value']),
                            borderRadius: AppConstants.borderRadiusMedium,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    type['icon'],
                                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      t(type['labelKey'] as String),
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Temel Bilgiler
                    _buildSectionCard(
                      title: t('warehouses.basic_info'),
                      icon: Icons.info,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _codeController,
                                decoration: InputDecoration(
                                  labelText: t('warehouses.code_required'),
                                  hintText: 'WH-001',
                                  prefixIcon: Icon(Icons.qr_code),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return t('warehouses.code_required_msg');
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _capacityController,
                                decoration: InputDecoration(
                                  labelText: t('warehouses.capacity_required'),
                                  hintText: '5000',
                                  prefixIcon: Icon(Icons.inventory),
                                  suffixText: t('warehouses.unit'),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return t('warehouses.capacity_required_msg');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: t('warehouses.name_required'),
                            hintText: t('warehouses.name_hint'),
                            prefixIcon: Icon(Icons.warehouse),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t('warehouses.name_required_msg');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _managerNameController,
                          decoration: InputDecoration(
                            labelText: t('warehouses.manager_required'),
                            hintText: t('warehouses.manager_hint'),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t('warehouses.manager_required_msg');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Konum Bilgileri
                    _buildSectionCard(
                      title: t('warehouses.location_info'),
                      icon: Icons.location_on,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  labelText: t('warehouses.city_required'),
                                  hintText: t('warehouses.city_hint'),
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return t('warehouses.city_required_msg');
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _districtController,
                                decoration: InputDecoration(
                                  labelText: t('warehouses.district_required'),
                                  hintText: t('warehouses.district_hint'),
                                  prefixIcon: Icon(Icons.place),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return t('warehouses.district_required_msg');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: t('warehouses.address_required'),
                            hintText: t('warehouses.address_hint'),
                            prefixIcon: Icon(Icons.home),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t('warehouses.address_required_msg');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // İletişim Bilgileri
                    _buildSectionCard(
                      title: t('warehouses.contact_info'),
                      icon: Icons.phone,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: t('warehouses.phone_required'),
                            hintText: '+90 (212) 555-0101',
                            prefixIcon: Icon(Icons.phone_android),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return t('warehouses.phone_required_msg');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Durum
                    _buildSectionCard(
                      title: t('warehouses.status'),
                      icon: Icons.toggle_on,
                      children: [
                        SwitchListTile(
                          value: _isActive,
                          onChanged: (value) => setState(() => _isActive = value),
                          title: Text(t('common.active')),
                          subtitle: Text(
                            _isActive ? t('warehouses.currently_active') : t('warehouses.currently_passive'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          secondary: Icon(
                            _isActive ? Icons.check_circle : Icons.cancel,
                            color: _isActive ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Kaydet Butonu
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        text: _isSaving
                            ? t('common.saving')
                            : widget.warehouseId != null
                                ? t('common.update')
                                : t('common.save'),
                        icon: _isSaving ? null : Icons.save,
                        onPressed: _isSaving ? null : _saveWarehouse,
                      ),
                    ),
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
    return AppSectionCard(
      title: title,
      icon: icon,
      children: children,
    );
  }
}