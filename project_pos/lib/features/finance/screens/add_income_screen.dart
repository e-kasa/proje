import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/templates/form_screen_template.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/utils/validation_helper.dart';
import 'package:project_pos/services/finance_service.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/providers/auth_provider.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  final int? incomeId;

  const AddIncomeScreen({super.key, this.incomeId});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late FinanceService _financeService;
  bool _isSaving = false;

  // Form controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedCategory = 'Satis';
  String _selectedStatus = 'received';
  String _selectedPaymentMethod = 'Nakit';

  final _categoryOptions = [
    {'value': 'Satis', 'label': 'Satis'},
    {'value': 'Hizmet', 'label': 'Hizmet'},
    {'value': 'Kira', 'label': 'Kira'},
    {'value': 'Komisyon', 'label': 'Komisyon'},
    {'value': 'Diger', 'label': 'Diger'},
  ];

  final _statusOptions = [
    {'value': 'received', 'label': 'Alindi'},
    {'value': 'pending', 'label': 'Beklemede'},
  ];

  final _paymentMethods = [
    'Nakit',
    'Kredi Karti',
    'Havale/EFT',
    'Cek',
  ];

  @override
  void initState() {
    super.initState();
    _financeService = ref.read(financeServiceProvider);
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text.trim()),
        'currency': 'TRY',
        'description': _descriptionController.text.trim(),
        'date': _dateController.text.trim(),
        'paymentMethod': _selectedPaymentMethod,
        'status': _selectedStatus,
        'createdBy': ref.read(authProvider).user?.username ?? 'system',
      };

      await _financeService.createRevenue(data);
      if (mounted) {
        AppToast.success(context, i18nOf(ref)('common.success'));
        context.go('/finance');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppToast.error(context, '${i18nOf(ref)('common.error')}: $e');
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    return FormScreenTemplate(
      title: t('finance.add_income'),
      formKey: _formKey,
      isSaving: _isSaving,
      onSave: _saveIncome,
      saveLabel: _isSaving ? t('common.loading') : t('common.save'),
      sections: [
        FormSection(
          title: t('finance.general_info'),
          fields: [
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tutar *',
                prefixIcon: Icon(Icons.money),
                suffixText: '₺',
              ),
              validator: ValidationHelper.positiveNumber,
            ),
            const SizedBox(height: 16),
            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori *',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categoryOptions.map<DropdownMenuItem<String>>((cat) {
                return DropdownMenuItem<String>(
                  value: cat['value'],
                  child: Text(cat['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),
            // Description
            AppInput(
              controller: _descriptionController,
              label: 'Aciklama',
              prefixIcon: Icons.description,
              hint: 'Gelir aciklamasi...',
              maxLines: 3,
            ),
          ],
        ),
        FormSection(
          title: t('finance.payment_info'),
          fields: [
            // Date
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Tarih *',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _selectDate,
              validator: ValidationHelper.date,
            ),
            const SizedBox(height: 16),
            // Payment Method
            DropdownButtonFormField<String>(
              initialValue: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Odeme Yontemi *',
                prefixIcon: Icon(Icons.payment),
              ),
              items: _paymentMethods.map<DropdownMenuItem<String>>((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
              },
            ),
            const SizedBox(height: 16),
            // Status
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Durum *',
                prefixIcon: Icon(Icons.check_circle),
              ),
              items: _statusOptions.map<DropdownMenuItem<String>>((status) {
                return DropdownMenuItem<String>(
                  value: status['value'],
                  child: Text(status['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
              },
            ),
          ],
        ),
      ],
    );
  }
}
