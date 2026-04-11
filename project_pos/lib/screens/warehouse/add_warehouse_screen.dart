import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/warehouse_service.dart';
import '../../core/api/api_client.dart';

class AddWarehouseScreen extends ConsumerStatefulWidget {
  final String? warehouseId;

  const AddWarehouseScreen({super.key, this.warehouseId});

  @override
  ConsumerState<AddWarehouseScreen> createState() => _AddWarehouseScreenState();
}

class _AddWarehouseScreenState extends ConsumerState<AddWarehouseScreen> {
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
    {'value': 'main', 'label': '🏢 Ana Depo', 'icon': Icons.warehouse},
    {'value': 'regional', 'label': '🏪 Bölge Deposu', 'icon': Icons.location_city},
    {'value': 'backup', 'label': '📦 Yedek Depo', 'icon': Icons.inventory_2},
  ];

  @override
  void initState() {
    super.initState();
    _warehouseService = WarehouseService(ApiClient());
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
        AppToast.error(context, 'Depo bilgileri yüklenirken hata oluştu');
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
          AppToast.success(context, 'Depo başarıyla güncellendi');
          context.pop();
        }
      } else {
        await _warehouseService.createWarehouse(data);
        if (mounted) {
          AppToast.success(context, 'Depo başarıyla oluşturuldu');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Depo kaydedilirken hata oluştu');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: widget.warehouseId != null ? 'Depo Düzenle' : 'Yeni Depo Ekle',
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
                      title: 'Depo Tipi',
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
                                      type['label'],
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
                      title: 'Temel Bilgiler',
                      icon: Icons.info,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Depo Kodu *',
                                  hintText: 'WH-001',
                                  prefixIcon: Icon(Icons.qr_code),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Depo kodu gerekli';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _capacityController,
                                decoration: const InputDecoration(
                                  labelText: 'Kapasite *',
                                  hintText: '5000',
                                  prefixIcon: Icon(Icons.inventory),
                                  suffixText: 'birim',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Kapasite gerekli';
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
                          decoration: const InputDecoration(
                            labelText: 'Depo Adı *',
                            hintText: 'Ana Depo',
                            prefixIcon: Icon(Icons.warehouse),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Depo adı gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _managerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Sorumlu Kişi *',
                            hintText: 'Ahmet Yılmaz',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Sorumlu kişi gerekli';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Konum Bilgileri
                    _buildSectionCard(
                      title: 'Konum Bilgileri',
                      icon: Icons.location_on,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'Şehir *',
                                  hintText: 'İstanbul',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Şehir gerekli';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _districtController,
                                decoration: const InputDecoration(
                                  labelText: 'İlçe *',
                                  hintText: 'Esenyurt',
                                  prefixIcon: Icon(Icons.place),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'İlçe gerekli';
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
                          decoration: const InputDecoration(
                            labelText: 'Adres *',
                            hintText: 'Organize Sanayi Bölgesi, 1. Cadde No:15',
                            prefixIcon: Icon(Icons.home),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Adres gerekli';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // İletişim Bilgileri
                    _buildSectionCard(
                      title: 'İletişim Bilgileri',
                      icon: Icons.phone,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon *',
                            hintText: '+90 (212) 555-0101',
                            prefixIcon: Icon(Icons.phone_android),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Telefon gerekli';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Durum
                    _buildSectionCard(
                      title: 'Durum',
                      icon: Icons.toggle_on,
                      children: [
                        SwitchListTile(
                          value: _isActive,
                          onChanged: (value) => setState(() => _isActive = value),
                          title: const Text('Aktif'),
                          subtitle: Text(
                            _isActive ? 'Depo şu anda aktif' : 'Depo şu anda pasif',
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
                            ? 'Kaydediliyor...'
                            : widget.warehouseId != null
                                ? 'Güncelle'
                                : 'Kaydet',
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
