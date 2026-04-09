import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/i18n_provider.dart';
import '../../core/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _fillQuickLogin(String username, String password) {
    _emailController.text = username;
    _passwordController.text = password;
    _handleLogin();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, ref.read(i18nProvider).bundle('auth.login_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: isDesktop
          ? _buildDesktopLayout(authState)
          : _buildMobileLayout(authState),
    );
  }

  // ── DESKTOP: Left brand panel + Right form ────────────────────────────────
  Widget _buildDesktopLayout(AuthState authState) {
    return Row(
      children: [
        // Left: Brand Panel
        Expanded(
          flex: 5,
          child: _buildBrandPanel(),
        ),
        // Right: Form Panel
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.white,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 56, vertical: 40),
                  child: _buildForm(authState, maxWidth: 440),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── MOBILE: Full screen gradient header + form card ───────────────────────
  Widget _buildMobileLayout(AuthState authState) {
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
            // Top branding
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.auto_fix_high_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AutoPOS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Araç Parçaları Yönetim Sistemi',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom form sheet
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildForm(authState),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BRAND PANEL (desktop left side) ──────────────────────────────────────
  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: 120,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.auto_fix_high_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 32),
                const Text(
                  'AutoPOS',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Araç Parçaları\nYönetim Sistemi',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                // Feature list
                ...[
                  _Feature(Icons.point_of_sale_outlined, 'Hızlı POS Satışı'),
                  _Feature(Icons.inventory_2_outlined, 'Stok Yönetimi'),
                  _Feature(Icons.bar_chart_rounded, 'Analiz & Raporlar'),
                  _Feature(Icons.account_balance_wallet_outlined,
                      'Cari Hesap Takibi'),
                ].map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(f.icon, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 32),
                Text(
                  '© 2025 AutoPOS v1.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FORM ─────────────────────────────────────────────────────────────────
  Widget _buildForm(AuthState authState, {double? maxWidth}) {
    final i18n = ref.watch(i18nProvider);
    String t(String code) => i18n.isLoaded ? i18n.bundle(code) : code;

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('auth.welcome'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('auth.login_subtitle'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 36),

          // Email
          _label(t('auth.username_email')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            enabled: !authState.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: _fieldDecor(
              hint: 'ornek@firma.com',
              icon: Icons.alternate_email_rounded,
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? t('validation.username_required') : null,
          ),
          const SizedBox(height: 20),

          // Password
          _label(t('form.password')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !authState.isLoading,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: _fieldDecor(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: authState.isLoading
                    ? null
                    : () => setState(
                        () => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? t('validation.password_required') : null,
          ),
          const SizedBox(height: 16),

          // Remember me
          Row(
            children: [
              SizedBox(
                height: 22,
                width: 22,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: authState.isLoading
                      ? null
                      : (v) => setState(() => _rememberMe = v ?? false),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(t('auth.remember_me'),
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 28),

          // Login button
          _GradientButton(
            text: t('auth.login'),
            isLoading: authState.isLoading,
            onPressed: authState.isLoading ? null : _handleLogin,
          ),

          const SizedBox(height: 16),

          // ── Şirket Kaydı Linki ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${t('auth.no_account')} ',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => context.go('/register'),
                child: Text(t('auth.create_company'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    )),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Hızlı Giriş ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  t('auth.quick_login'),
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border, thickness: 1)),
            ],
          ),
          const SizedBox(height: 10),

          // Oto / Parça sektörü
          _buildSectorLabel(Icons.car_repair, 'Yedek Parça'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _QuickUserCard(
                  name: 'Admin',
                  role: 'Yönetici',
                  icon: Icons.admin_panel_settings_outlined,
                  color: const Color(0xFF667eea),
                  isLoading: authState.isLoading,
                  onTap: () => _fillQuickLogin('admin', 'admin123'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickUserCard(
                  name: 'Kasiyer',
                  role: 'Satış',
                  icon: Icons.point_of_sale_outlined,
                  color: const Color(0xFF11998e),
                  isLoading: authState.isLoading,
                  onTap: () => _fillQuickLogin('kasiyer', 'kasiyer123'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickUserCard(
                  name: 'Depo',
                  role: 'Stok',
                  icon: Icons.warehouse_outlined,
                  color: const Color(0xFFf7971e),
                  isLoading: authState.isLoading,
                  onTap: () => _fillQuickLogin('depo', 'depo123'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Giyim sektörü
          _buildSectorLabel(Icons.checkroom_outlined, 'Giyim / Tekstil'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _QuickUserCard(
                  name: 'Mağaza',
                  role: 'Yönetici',
                  icon: Icons.storefront_outlined,
                  color: const Color(0xFFe91e8c),
                  isLoading: authState.isLoading,
                  onTap: () => _fillQuickLogin('sedcore1', 'admin123'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickUserCard(
                  name: 'Kasiyer',
                  role: 'Satış',
                  icon: Icons.shopping_bag_outlined,
                  color: const Color(0xFF9c27b0),
                  isLoading: authState.isLoading,
                  onTap: () => _fillQuickLogin('giyimkasiyer', 'kasiyer123'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickUserCard(
                  name: 'Depo',
                  role: 'Stok',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFFff6b6b),
                  isLoading: authState.isLoading,
                  onTap: () => _fillQuickLogin('giyimdepo', 'depo123'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              t('auth.system_name'),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: form,
      );
    }
    return form;
  }

  Widget _buildSectorLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _fieldDecor({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: AppColors.textMuted, size: 20),
      ),
      prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFFE8E9F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.danger, width: 1.8),
      ),
    );
  }
}

// ── GRADIENT BUTTON ──────────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GradientButton(
      {required this.text, required this.isLoading, this.onPressed});

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
                ? const LinearGradient(
                    colors: [Color(0xFFaab0d4), Color(0xFFaab0d4)])
                : const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── QUICK USER CARD ──────────────────────────────────────────────────────────
class _QuickUserCard extends StatefulWidget {
  final String name;
  final String role;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _QuickUserCard({
    required this.name,
    required this.role,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_QuickUserCard> createState() => _QuickUserCardState();
}

class _QuickUserCardState extends State<_QuickUserCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: _pressed
                ? widget.color.withValues(alpha: 0.08)
                : widget.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: _pressed ? 0.5 : 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 19, color: widget.color),
              ),
              const SizedBox(height: 6),
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              Text(
                widget.role,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────────────────
class _Feature {
  final IconData icon;
  final String label;
  const _Feature(this.icon, this.label);
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      