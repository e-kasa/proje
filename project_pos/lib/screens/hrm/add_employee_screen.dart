import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../services/hrm_service.dart';
import '../../services/service_locator.dart';
import '../../core/utils/i18n_helper.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  final int? employeeId;
  const AddEmployeeScreen({super.key, this.employeeId});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  String Function(String) get t => i18nOf(ref);
  final _formKey = GlobalKey<FormState>();
  late HrmService _hrmService;
  bool _isLoading = false;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _department = 'Satis';
  DateTime _hireDate = DateTime.now();
  bool _isActive = true;

  bool get _isEditing => widget.employeeId != null;

  final _departments = [
    'Yonetim',
    'Satis',
    'Depo',
    'Muhasebe',
    'IT',
  ];

  @override
  void initState() {
    super.initState();
    _hrmService = ref.read(hrmServiceProvider);
    if (_isEditing) _loadEmployee();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _positionCtrl.dispose();
    _salaryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployee() async {
    setState(() => _isLoading = true);
    try {
      final data = await _hrmService.getEmployeeById(widget.employeeId!);
      if (data.isNotEmpty) {
        _nameCtrl.text =
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        _emailCtrl.text = data['email']?.toString() ?? '';
        _phoneCtrl.text = data['phone']?.toString() ?? '';
        _positionCtrl.text = data['position']?.toString() ?? '';
        _salaryCtrl.text = (data['salary'] ?? '').toString();
        _notesCtrl.text = data['notes']?.toString() ?? '';
        _department = data['department']?.toString() ?? 'Satis';
        _isActive = data['status'] == 'active';
        if (data['hireDate'] != null) {
          _hireDate = DateTime.tryParse(data['hireDate']) ?? DateTime.now();
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(context, t('common.error'));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final nameParts = _nameCtrl.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final data = {
        'firstName': firstName,
        'lastName': lastName,
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'department': _department,
        'position': _positionCtrl.text.trim(),
        'hireDate': DateFormat('yyyy-MM-dd').format(_hireDate),
        'salary': double.tryParse(_salaryCtrl.text.trim()) ?? 0,
        'status': _isActive ? 'active' : 'inactive',
        'notes': _notesCtrl.text.trim(),
      };

      if (_isEditing) {
        await _hrmService.updateEmployee(widget.employeeId!, data);
      } else {
        await _hrmService.createEmployee(data);
      }

      if (mounted) {
        AppToast.success(context, t('common.saved'));
        context.pop(true);
      }
    } catch (e) {
      if (mounted) AppToast.error(context, t('common.error'));
    }
    setState(() => _isSaving = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _hireDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: _isEditing ? t('hrm.title') : t('hrm.add_employee'), // TODO: i18n edit_employee key
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t('common.save'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppConstants.pagePadding,
                children: [
                  _sectionTitle('Kisisel Bilgiler'), // TODO: i18n
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Ad Soyad *',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailCtrl,
                    label: 'E-posta',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'Telefon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Is Bilgileri'), // TODO: i18n
                  const SizedBox(height: 12),
                  _buildDepartmentDropdown(),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _positionCtrl,
                    label: 'Pozisyon',
                    icon: Icons.work_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _salaryCtrl,
                    label: 'Maas',
                    icon: Icons.attach_money,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    suffixText: '\u20BA',
                  ),
                  const SizedBox(height: 12),
                  _buildStatusToggle(),
                  const SizedBox(height: 20),
                  _sectionTitle('Ek Bilgiler'), // TODO: i18n
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _notesCtrl,
                    label: 'Notlar',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  AppButton.primary(
                    text: _isSaving
                        ? 'Kaydediliyor...' // TODO: i18n saving key
                        : _isEditing
                            ? t('common.save') // TODO: i18n update key
                            : t('common.save'),
                    onPressed: _isSaving ? null : _save,
                    fullWidth: true,
                    isLoading: _isSaving,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixText: suffixText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMedium,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMedium,
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: _departments.contains(_department) ? _department : _departments.first,
      decoration: InputDecoration(
        labelText: 'Departman',
        prefixIcon: const Icon(Icons.business, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMedium,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusMedium,
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      items: _departments
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _department = v);
      },
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Ise Baslama Tarihi',
            prefixIcon:
                const Icon(Icons.calendar_today, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: AppConstants.borderRadiusMedium,
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppConstants.borderRadiusMedium,
              borderSide: BorderSide(color: AppColors.border),
            ),
            hintText: DateFormat('dd.MM.yyyy').format(_hireDate),
          ),
          controller:
              TextEditingController(text: DateFormat('dd.MM.yyyy').format(_hireDate)),
        ),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppConstants.borderRadiusMedium,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(
              _isActive ? Icons.check_circle : Icons.cancel,
              color: _isActive ? AppColors.success : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Durum: ${_isActive ? "Aktif" : "Pasif"}',
                style: const TextStyle(fontSize: 14)),
          ]),
          Switch(
            value: _isActive,
            activeColor: AppColors.success,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }
}
