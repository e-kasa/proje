import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/store_service.dart';
import '../../core/api/api_client.dart';

class AddStoreScreen extends ConsumerStatefulWidget {
  final String? storeId;

  const AddStoreScreen({super.key, this.storeId});

  @override
  ConsumerState<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends ConsumerState<AddStoreScreen> {
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
    {'value': 'flagship', 'label': '🏢 Merkez Mağaza', 'icon': Icons.store},
    {'value': 'branch', 'label': '🏪 Şube', 'icon': Icons.storefront},
    {'value': 'outlet', 'label': '🏬 Outlet', 'icon': Icons.local_mall},
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
      if (mounted) AppToast.error(context, 'Mağaza bilgileri yüklenirken hata oluştu');
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
          AppToast.success(context, 'Mağaza başarıyla güncellendi');
          context.pop();
        }
      } else {
        await _storeService.createStore(data);
        if (mounted) {
          AppToast.success(context, 'Mağaza başarıyla oluşturuldu');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Mağaza kaydedilirken hata oluştu');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: widget.storeId != null ? 'Mağaza Düzenle' : 'Yeni Mağaza Ekle',
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
                      title: 'Mağaza Tipi',
                      icon: Icons.category,
                      children: _storeTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
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
                                  Expanded(child: Text(type['label'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.textPrimary))),
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
                      title: 'Temel Bilgiler',
                      icon: Icons.info,
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _codeController, decoration: const InputDecoration(labelText: 'Mağaza Kodu *', hintText: 'STR-001', prefixIcon: Icon(Icons.qr_code)), validator: (v) => v == null || v.trim().isEmpty ? 'Mağaza kodu gerekli' : null)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _employeeCountController, decoration: const InputDecoration(labelText: 'Çalışan Sayısı *', prefixIcon: Icon(Icons.people), suffixText: 'kişi'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v == null || v.trim().isEmpty ? 'Çalışan sayısı gerekli' : null)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Mağaza Adı *', hintText: 'Merkez Mağaza', prefixIcon: Icon(Icons.store)), validator: (v) => v == null || v.trim().isEmpty ? 'Mağaza adı gerekli' : null),
                        const SizedBox(height: 16),
                        TextFormField(controller: _managerController, decoration: const InputDecoration(labelText: 'Mağaza Müdürü *', hintText: 'Zeynep Arslan', prefixIcon: Icon(Icons.person)), validator: (v) => v == null || v.trim().isEmpty ? 'Mağaza müdürü gerekli' : null),
                        const SizedBox(height: 16),
                        TextFormField(controller: _openingHoursController, decoration: const InputDecoration(labelText: 'Çalışma Saatleri *', hintText: '09:00 - 22:00', prefixIcon: Icon(Icons.access_time)), validator: (v) => v == null || v.trim().isEmpty ? 'Çalışma saatleri gerekli' : null),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: 'Konum Bilgileri',
                      icon: Icons.location_on,
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Şehir *', hintText: 'İstanbul', prefixIcon: Icon(Icons.location_city)), validator: (v) => v == null || v.trim().isEmpty ? 'Şehir gerekli' : null)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _districtController, decoration: const InputDecoration(labelText: 'İlçe *', hintText: 'Kadıköy', prefixIcon: Icon(Icons.place)), validator: (v) => v == null || v.trim().isEmpty ? 'İlçe gerekli' : null)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Adres *', hintText: 'Bağdat Caddesi No:142/A', prefixIcon: Icon(Icons.home)), maxLines: 2, validator: (v) => v == null || v.trim().isEmpty ? 'Adres gerekli' : null),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: 'İletişim',
                      icon: Icons.phone,
                      children: [
                        TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Telefon *', hintText: '+90 (216) 555-0201', prefixIcon: Icon(Icons.phone_android)), keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Telefon gerekli' : null),
                        const SizedBox(height: 16),
                        TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-posta', hintText: 'merkez@magaza.com', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: 'Alan Bilgileri',
                      icon: Icons.square_foot,
                      children: [
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _totalAreaController, decoration: const InputDecoration(labelText: 'Toplam Alan', prefixIcon: Icon(Icons.aspect_ratio), suffixText: 'm²'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: _salesAreaController, decoration: const InputDecoration(labelText: 'Satış Alanı', prefixIcon: Icon(Icons.shopping_cart), suffixText: 'm²'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSectionCard(
                      title: 'Özellikler',
                      icon: Icons.settings,
                      children: [
                        SwitchListTile(value: _hasWarehouse, onChanged: (v) => setState(() => _hasWarehouse = v), title: const Text('Deposu Var'), subtitle: Text(_hasWarehouse ? 'Mağazanın deposu var' : 'Mağazanın deposu yok', style: const TextStyle(fontSize: 12)), secondary: Icon(_hasWarehouse ? Icons.warehouse : Icons.store, color: _hasWarehouse ? AppColors.success : AppColors.textMuted)),
                        const Divider(),
                        SwitchListTile(value: _isActive, onChanged: (v) => setState(() => _isActive = v), title: const Text('Aktif'), subtitle: Text(_isActive ? 'Mağaza şu anda aktif' : 'Mağaza şu anda pasif', style: const TextStyle(fontSize: 12)), secondary: Icon(_isActive ? Icons.check_circle : Icons.cancel, color: _isActive ? AppColors.success : AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: AppButton.primary(text: _isSaving ? 'Kaydediliyor...' : widget.storeId != null ? 'Güncelle' : 'Kaydet', icon: _isSaving ? null : Icons.save, onPressed: _isSaving ? null : _saveStore)),
                  ],
                ),
              ),
            ),
    );
  }
}
