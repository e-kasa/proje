import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Müşteri yüklenemedi: $e')),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Müşteri güncellendi'),
                backgroundColor: AppColors.success),
          );
        }
      } else {
        await svc.createCustomer(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Müşteri oluşturuldu'),
                backgroundColor: AppColors.success),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Hata: $e'),
              backgroundColor: AppColors.danger),
        );
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

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(isEdit ? 'Müşteri Düzenle' : 'Yeni Müşteri'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            ),
        ],
      ),
      body: _isLoading && isEdit && widget.customer == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Müşteri Tipi ─────────────────────────────────
                  _buildCard(
                    title: 'Müşteri Tipi',
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
                                color: selected ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                    color: selected ? AppColors.primary : AppColors.border,
                                    width: selected ? 1.5 : 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(type.icon, size: 15,
                                      color: selected ? Colors.white : AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(type.label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: selected ? Colors.white : AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // ── Temel Bilgiler ────────────────────────────────
                  _buildCard(
                    title: 'Temel Bilgiler',
                    icon: Icons.person_outline,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Ad Soyad *',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad Soyad zorunludur' : null,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Telefon',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'E-posta',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty &&
                              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Adres',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),

                  // ── Vergi / Kurumsal Bilgiler ─────────────────────
                  if (_customerType == 'CORPORATE' || _customerType == 'DEALER' || _customerType == 'WHOLESALER')
                    _buildCard(
                      title: 'Kurumsal Bilgiler',
                      icon: Icons.receipt_long_outlined,
                      children: [
                        _buildTextField(
                          controller: _taxNumberController,
                          label: 'Vergi Numarası',
                          icon: Icons.numbers_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          controller: _taxOfficeController,
                          label: 'Vergi Dairesi',
                          icon: Icons.account_balance_outlined,
                        ),
                      ],
                    ),

                  // ── Notlar ────────────────────────────────────────
                  _buildCard(
                    title: 'Notlar',
                    icon: Icons.note_outlined,
                    children: [
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notlar (opsiyonel)',
                        icon: Icons.edit_note_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),

                  // ── Durum ─────────────────────────────────────────
                  _buildStatusCard(),

                  const SizedBox(height: 8),

                  // ── Kaydet ────────────────────────────────────────
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveCustomer,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'Kaydediliyor...' : (isEdit ? 'Güncelle' : 'Kaydet'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppColors.bgLight,
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (_isActive ? AppColors.success : AppColors.textMuted).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: _isActive ? AppColors.success : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Müşteri Durumu',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    _isActive ? 'Aktif — satış ve işlemlerde kullanılabilir'
                              : 'Pasif — işlemlerde görünmez',
                    style: TextStyle(fontSize: 12,
                        color: _isActive ? AppColors.success : AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusBtn('Aktif',  _isActive,  AppColors.success, () => setState(() => _isActive = true)),
                const SizedBox(width: 6),
                _statusBtn('Pasif', !_isActive, AppColors.danger,  () => setState(() => _isActive = false)),
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
          border: Border.all(color: selected ? color : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
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
