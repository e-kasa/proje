import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validation_helper.dart';
import '../../services/finance_service.dart';
import '../../core/api/api_client.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final int? expenseId;

  const AddExpenseScreen({super.key, this.expenseId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late FinanceService _financeService;
  bool _isLoading = false;
  bool _isSaving = false;

  // Form controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vendorController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCategory;
  String _selectedStatus = 'pending';
  String _selectedPaymentMethod = 'Nakit';
  List<Map<String, dynamic>> _categories = [];

  final _statusOptions = [
    {'value': 'pending', 'label': 'Bekliyor'},
    {'value': 'paid', 'label': 'Ödendi'},
    {'value': 'cancelled', 'label': 'İptal'},
  ];

  final _paymentMethods = [
    'Nakit',
    'Kredi Kartı',
    'Banka Transferi',
    'Çek',
    'Otomatik Ödeme',
  ];

  @override
  void initState() {
    super.initState();
    _financeService = FinanceService(ApiClient());
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadCategories();
    if (widget.expenseId != null) {
      _loadExpense();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _vendorController.dispose();
    _invoiceNumberController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _financeService.getExpenseCategories();
      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = _categories.first['name'];
        }
      });
    } catch (e) {
      AppToast.error(context, 'Kategoriler yüklenemedi');
    }
  }

  Future<void> _loadExpense() async {
    setState(() => _isLoading = true);
    try {
      final expense = await _financeService.getExpenseById(widget.expenseId!);
      setState(() {
        _amountController.text = expense['amount'].toString();
        _descriptionController.text = expense['description'] ?? '';
        _vendorController.text = expense['vendor'] ?? '';
        _invoiceNumberController.text = expense['invoiceNumber'] ?? '';
        _dateController.text = expense['date'] ?? '';
        _selectedCategory = expense['category'];
        _selectedStatus = expense['status'] ?? 'pending';
        _selectedPaymentMethod = expense['paymentMethod'] ?? 'Nakit';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.error(context, 'Gider yüklenemedi');
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'category': _selectedCategory,
        'categoryIcon': _categories.firstWhere(
          (c) => c['name'] == _selectedCategory,
          orElse: () => {'icon': '💰'},
        )['icon'],
        'amount': double.parse(_amountController.text.trim()),
        'currency': 'TRY',
        'description': _descriptionController.text.trim(),
        'vendor': _vendorController.text.trim(),
        'invoiceNumber': _invoiceNumberController.text.trim(),
        'date': _dateController.text.trim(),
        'paymentMethod': _selectedPaymentMethod,
        'status': _selectedStatus,
        'createdBy': 'Admin',
      };

      if (widget.expenseId != null) {
        await _financeService.updateExpense(widget.expenseId!, data);
        if (mounted) {
          AppToast.success(context, 'Gider güncellendi');
          context.go('/finance/expenses');
        }
      } else {
        await _financeService.createExpense(data);
        if (mounted) {
          AppToast.success(context, 'Gider eklendi');
          context.go('/finance/expenses');
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppToast.error(context, 'Gider kaydedilemedi: $e');
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
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppAppBar.primary(
        title: widget.expenseId != null ? 'Gider Düzenle' : 'Yeni Gider',
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
                    AppSectionCard(
                      title: 'Genel Bilgiler',
                      children: [
                        // Category
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori *',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _categories.map<DropdownMenuItem<String>>((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['name'] as String,
                              child: Text('${cat['icon']} ${cat['name']}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                          validator: (value) =>
                              ValidationHelper.required(value, fieldName: 'Kategori'),
                        ),

                        const SizedBox(height: AppConstants.formFieldSpacing),

                        // Amount
                        AppInput(
                          controller: _amountController,
                          label: 'Tutar *',
                          prefixIcon: Icons.money,
                          keyboardType: TextInputType.number,
                          validator: ValidationHelper.positiveNumber,
                        ),

                        const SizedBox(height: AppConstants.formFieldSpacing),

                        // Description
                        AppInput(
                          controller: _descriptionController,
                          label: 'Açıklama *',
                          hint: 'Gider açıklaması...',
                          prefixIcon: Icons.description,
                          maxLines: 3,
                          validator: (value) =>
                              ValidationHelper.required(value, fieldName: 'Açıklama'),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.formFieldSpacing),

                    AppSectionCard(
                      title: 'Ödeme Bilgileri',
                      children: [
                        // Vendor
                        AppInput(
                          controller: _vendorController,
                          label: 'Satıcı / Tedarikçi',
                          prefixIcon: Icons.store,
                        ),

                        const SizedBox(height: AppConstants.formFieldSpacing),

                        // Payment Method
                        DropdownButtonFormField<String>(
                          value: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Ödeme Yöntemi *',
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

                        const SizedBox(height: AppConstants.formFieldSpacing),

                        // Invoice Number
                        AppInput(
                          controller: _invoiceNumberController,
                          label: 'Fatura No',
                          prefixIcon: Icons.receipt,
                        ),

                        const SizedBox(height: AppConstants.formFieldSpacing),

                        // Date
                        AppInput(
                          controller: _dateController,
                          label: 'Tarih *',
                          prefixIcon: Icons.calendar_today,
                          validator: ValidationHelper.date,
                          enabled: false,
                        ),
                        // Add a GestureDetector to handle date picking
                        SizedBox(
                          height: 48,
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: Padding(
                              padding: const EdgeInsets.only(top: AppConstants.formFieldSpacing),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: AppConstants.borderRadiusMedium,
                                ),
                                child: const SizedBox(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.formFieldSpacing),

                        // Status
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Durum *',
                            prefixIcon: Icon(Icons.check_circle),
                          ),
                          items: _statusOptions.map<DropdownMenuItem<String>>((status) {
                            return DropdownMenuItem<String>(
                              value: status['value'],
                              child: Text(status['label'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStatus = value!);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.formFieldSpacing),

                    // Save Button
                    AppButton.primary(
                      text: _isSaving
                          ? 'Kaydediliyor...'
                          : (widget.expenseId != null ? 'Güncelle' : 'Kaydet'),
                      onPressed: _isSaving ? null : _saveExpense,
                      icon: Icons.save,
                      isLoading: _isSaving,
                      fullWidth: true,
                      size: ButtonSize.large,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
