import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/service_locator.dart';
import 'package:project_pos/core/widgets/widgets.dart';

class QuickCustomerDialog extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic> newCustomer) onCustomerCreated;

  const QuickCustomerDialog({
    super.key,
    required this.onCustomerCreated,
  });

  /// Shows the dialog and returns the created customer, or null if cancelled.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Function(Map<String, dynamic> newCustomer) onCustomerCreated,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => QuickCustomerDialog(
        onCustomerCreated: onCustomerCreated,
      ),
    );
  }

  @override
  ConsumerState<QuickCustomerDialog> createState() => _QuickCustomerDialogState();
}

class _QuickCustomerDialogState extends ConsumerState<QuickCustomerDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final GlobalKey<FormState> _formKey;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'İsim gereklidir';
    }
    if (value.length < 2) {
      return 'İsim en az 2 karakter olmalıdır';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon gereklidir';
    }
    // Basic phone validation: at least 7 digits
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      return 'Geçerli bir telefon numarası giriniz';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email optional
    }
    // Basic email validation
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Prepare customer data
      final customerData = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty)
          'email': _emailCtrl.text.trim(),
      };

      // Create customer via service
      final customerService = ref.read(customerServiceProvider);
      final newCustomer = await customerService.createCustomer(customerData);

      if (mounted) {
        // Call the callback to notify parent
        widget.onCustomerCreated(newCustomer);
        // Close dialog and return the new customer
        Navigator.pop(context, newCustomer);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Müşteri oluşturulamadı: ${e.toString()}';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.person_add, color: AppColors.primary),
      title: const Text(
        'Yeni Müşteri Ekle',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Name field
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'İsim',
                    hintText: 'Müşteri adını giriniz',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Phone field
                TextFormField(
                  controller: _phoneCtrl,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    hintText: '+90 5xx xxx xx xx',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Email field (optional)
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'E-posta (Opsiyonel)',
                    hintText: 'ornek@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        AppButton.primary(
          text: _isSubmitting ? 'Kaydediliyor...' : 'Müşteri Ekle',
          onPressed: _isSubmitting ? null : _onSubmit,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }
}
