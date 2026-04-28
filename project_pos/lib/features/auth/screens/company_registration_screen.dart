import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/providers/auth_provider.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class CompanyRegistrationScreen extends ConsumerStatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  ConsumerState<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState
    extends ConsumerState<CompanyRegistrationScreen> {
  String Function(String) get t => i18nOf(ref);
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 — Şirket bilgileri
  final _companyNameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _taxOfficeController = TextEditingController();

  // Step 2 — Sektör seçimi
  String? _selectedSector;

  // Step 3 — Yönetici hesabı
  final _displayNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _formKeys = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];

  @override
  void dispose() {
    _companyNameController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _displayNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  static const _sectors = [
    _SectorOption('AUTO_PARTS', 'Yedek Parça', Icons.car_repair, Color(0xFF667eea)),
    _SectorOption('GENERAL', 'Genel Perakende', Icons.store, Color(0xFF11998e)),
    _SectorOption('TECHNOLOGY', 'Teknoloji', Icons.devices, Color(0xFFf7971e)),
    _SectorOption('FOOTWEAR', 'Giyim / Tekstil', Icons.checkroom, Color(0xFFe91e8c)),
  ];

  void _nextStep() {
    if (_currentStep == 1) {
      if (_selectedSector == null) {
        AppToast.error(context, 'Lütfen bir sektör seçin'); // TODO: i18n
        return;
      }
      setState(() => _currentStep++);
      return;
    }
    if (_formKeys[_currentStep].currentState!.validate()) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _register() async {
    if (!_formKeys[2].currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final regService = ref.read(registrationServiceProvider);
      final response = await regService.registerCompany(
        companyName: _companyNameController.text.trim(),
        sectorType: _selectedSector!,
        userName: _userNameController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        taxNumber: _taxNumberController.text.trim().isNotEmpty
            ? _taxNumberController.text.trim()
            : null,
        taxOffice: _taxOfficeController.text.trim().isNotEmpty
            ? _taxOfficeController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      );

      await ref.read(authProvider.notifier).loginWithToken(response);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, t('common.error')); // TODO: i18n registration_failed key
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // Sprint 19 W1: AppScaffold → BaseScaffold (3-step wizard, custom split + gradient).
    return BaseScaffold(
      body: isDesktop ? _buildDesktop() : _buildMobile(),
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildBrandPanel()),
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _currentStep > 0 ? _prevStep : () => context.go('/login'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t('auth.register'), // TODO: i18n company_registration key
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress indicator
        _buildStepIndicator(),
        const SizedBox(height: 32),

        // Step content
        if (_currentStep == 0) _buildStep1(),
        if (_currentStep == 1) _buildStep2(),
        if (_currentStep == 2) _buildStep3(),

        const SizedBox(height: 32),

        // Navigation buttons
        _buildNavButtons(),

        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/login'),
            child: Text(
              'Zaten hesabınız var mı? Giriş Yapın',
              style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Şirket', 'Sektör', 'Hesap'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDone || isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.primary
                      : isActive
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : const Color(0xFFF0F0F5),
                  border: Border.all(
                    color: isActive || isDone ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Step 1: Şirket Bilgileri ──────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Şirket Bilgileri',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('İşletmenizin temel bilgilerini girin',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _label('Şirket Adı *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _companyNameController,
            decoration: _fieldDecor(hint: 'Örn: Acme Ticaret A.Ş.', icon: Icons.business),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Şirket adı zorunlu' : null,
          ),
          const SizedBox(height: 20),
          _label('Vergi Numarası'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _taxNumberController,
            decoration: _fieldDecor(hint: 'Opsiyonel', icon: Icons.numbers),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _label('Vergi Dairesi'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _taxOfficeController,
            decoration: _fieldDecor(hint: 'Opsiyonel', icon: Icons.account_balance),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Sektör Seçimi ─────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sektör Seçimi',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('İşletmenizin faaliyet alanını seçin',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: _sectors.map((s) => _buildSectorCard(s)).toList(),
        ),
      ],
    );
  }

  Widget _buildSectorCard(_SectorOption sector) {
    final isSelected = _selectedSector == sector.code;
    return GestureDetector(
      onTap: () => setState(() => _selectedSector = sector.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? sector.color.withValues(alpha: 0.1) : const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? sector.color : const Color(0xFFE8E9F0),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: sector.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(sector.icon, color: sector.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              sector.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? sector.color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Yönetici Hesabı ───────────────────────────────────────────────
  Widget _buildStep3() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yönetici Hesabı',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Şirket yöneticisi olarak kayıt olacaksınız',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _label('Ad Soyad *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _displayNameController,
            decoration: _fieldDecor(hint: 'Örn: Ahmet Yılmaz', icon: Icons.person),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad soyad zorunlu' : null,
          ),
          const SizedBox(height: 20),
          _label('Kullanıcı Adı *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userNameController,
            decoration: _fieldDecor(hint: 'Örn: ahmet.yilmaz', icon: Icons.alternate_email),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Kullanıcı adı zorunlu' : null,
          ),
          const SizedBox(height: 20),
          _label('E-posta'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: _fieldDecor(hint: 'Opsiyonel', icon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _label('Şifre *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _fieldDecor(
              hint: 'En az 6 karakter',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20, color: AppColors.textMuted),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Şifre zorunlu';
              if (v.length < 6) return 'En az 6 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _label('Şifre Tekrar *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: _fieldDecor(
              hint: 'Şifreyi tekrar girin',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20, color: AppColors.textMuted),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v != _passwordController.text) return 'Şifreler eşleşmiyor';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Navigation Buttons ────────────────────────────────────────────────────
  Widget _buildNavButtons() {
    final isLast = _currentStep == 2;
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: AppButton.outline(
              text: 'Geri',
              onPressed: _isLoading ? null : _prevStep,
              icon: Icons.arrow_back,
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _GradientButton(
            text: isLast ? 'Kayıt Ol' : 'İleri',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : (isLast ? _register : _nextStep),
          ),
        ),
      ],
    );
  }

  // ── Brand Panel (desktop) ─────────────────────────────────────────────────
  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/login'),
            ),
            const SizedBox(height: 32),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.business_center_outlined, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 32),
            const Text('Şirket Kaydı',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1)),
            const SizedBox(height: 12),
            Text('İşletmenizi 3 kolay adımda\nkayıt edin ve kullanmaya başlayın.',
                style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
            const Spacer(),
            ...[
              _StepInfo(Icons.business, 'Şirket bilgilerinizi girin'),
              _StepInfo(Icons.category, 'Sektörünüzü seçin'),
              _StepInfo(Icons.admin_panel_settings, 'Yönetici hesabı oluşturun'),
            ].asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: entry.key == _currentStep
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(entry.value.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        entry.value.label,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: entry.key == _currentStep ? 1.0 : 0.6),
                          fontWeight: entry.key == _currentStep ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  InputDecoration _fieldDecor({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: AppColors.textMuted, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE8E9F0), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.8)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 1.8)),
    );
  }
}

// ── Supporting classes ──────────────────────────────────────────────────────
class _SectorOption {
  final String code, label;
  final IconData icon;
  final Color color;
  const _SectorOption(this.code, this.label, this.icon, this.color);
}

class _StepInfo {
  final IconData icon;
  final String label;
  const _StepInfo(this.icon, this.label);
}

class _GradientButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GradientButton({required this.text, required this.isLoading, this.onPressed});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? const LinearGradient(colors: [Color(0xFFaab0d4), Color(0xFFaab0d4)])
                : const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onPressed == null
                ? []
                : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(widget.text,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}
