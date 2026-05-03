import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/notification/notification_models.dart';
import 'package:project_pos/services/notification/notification_service.dart';
import 'package:project_pos/services/notification/notification_config_service.dart';

/// Sprint 23 — E-posta (SMTP) entegrasyonu — Skeleton.
///
/// **TODO Sprint 24+:** Gerçek SMTP gönderim servisi
/// (`mailer` veya backend SMTP relay endpoint).
/// Şu an UI iskeleti hazır, SharedPreferences-backed credential storage
/// hazır; backend entegrasyonu sonraki adım.
class EmailSettingsScreen extends ConsumerStatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  ConsumerState<EmailSettingsScreen> createState() =>
      _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends ConsumerState<EmailSettingsScreen> {
  String Function(String) get t => i18nOf(ref);

  final _hostCtl = TextEditingController();
  final _portCtl = TextEditingController(text: '587');
  final _usernameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _fromCtl = TextEditingController();

  bool _useTls = true;
  bool _obscure = true;
  bool _isTesting = false;  // Sprint 27: test send loading state
  bool _isSaving = false;   // Sprint 29: save loading state
  bool _passwordMasked = false; // Sprint 29: backend mask göstergesi

  @override
  void initState() {
    super.initState();
    // Sprint 29: backend'den mevcut config yükle
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfig());
  }

  @override
  void dispose() {
    _hostCtl.dispose();
    _portCtl.dispose();
    _usernameCtl.dispose();
    _passwordCtl.dispose();
    _fromCtl.dispose();
    super.dispose();
  }

  /// Sprint 29 — Backend'den mevcut email config'i yükle ve controller'lara
  /// doldur. Password backend'den maskeli ("****") gelir.
  Future<void> _loadConfig() async {
    final cfg = await ref.read(notificationConfigServiceProvider).loadEmail();
    if (!mounted || cfg == null) return;
    setState(() {
      _hostCtl.text = cfg.host ?? '';
      _portCtl.text = cfg.port?.toString() ?? '587';
      _useTls = cfg.useTls ?? true;
      _usernameCtl.text = cfg.username ?? '';
      // Maskeli ise placeholder göster, kullanıcı yeni şifre girerse override
      _passwordCtl.text = cfg.isPasswordMasked ? '••••••••' : '';
      _passwordMasked = cfg.isPasswordMasked;
      _fromCtl.text = cfg.from ?? '';
    });
  }

  /// Sprint 29 — Email config'i kaydet. Password mask değişmediyse omit edilir
  /// (backend kısmi update — mevcut password korunur).
  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      // Password değişmediyse (hala mask) → omit; aksi halde gönder
      String? passwordToSend;
      final pw = _passwordCtl.text;
      if (pw.isNotEmpty && pw != '••••••••') {
        passwordToSend = pw;
      }
      final dto = EmailConfigDto(
        host: _hostCtl.text.trim(),
        port: int.tryParse(_portCtl.text.trim()) ?? 587,
        useTls: _useTls,
        username: _usernameCtl.text.trim(),
        password: passwordToSend,
        from: _fromCtl.text.trim(),
      );
      final saved = await ref.read(notificationConfigServiceProvider).saveEmail(dto);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        if (saved != null) {
          _passwordMasked = saved.isPasswordMasked;
          if (_passwordMasked) _passwordCtl.text = '••••••••';
        }
      });
      AppToast.success(
        context,
        'Kaydedildi. (Şifreler dev ortamda plain text saklanır — Sprint 30 Vault entegrasyonu önerilir.)',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(context, 'Kayıt başarısız: $e');
    }
  }

  /// Sprint 27 — Test e-posta gönderim. Backend EMAIL kanalı real (Sprint 25);
  /// `mail.enabled=false` ise FAILED dönecek (errorMessage UI'da gösterilir).
  Future<void> _sendTestEmail() async {
    final to = _usernameCtl.text.trim();
    if (to.isEmpty) {
      AppToast.error(context, 'Önce kullanıcı adı/e-posta alanını doldurun.');
      return;
    }
    setState(() => _isTesting = true);
    final result = await ref.read(notificationServiceProvider).send(
          NotificationRequest(
            eventType: 'TEST_EMAIL',
            channel: NotificationChannel.email,
            recipient: to,
            subject: 'SEDCORE POS — Test E-postası',
            body: 'Bu bir test e-postasıdır. Sprint 25 EMAIL kanalı çalışıyor.',
          ),
        );
    if (!mounted) return;
    setState(() => _isTesting = false);
    if (result.success) {
      AppToast.success(
        context,
        'Test isteği kuyruğa alındı (durum: ${result.dto?.status.apiValue ?? "?"}).',
      );
    } else {
      AppToast.error(context, 'Test başarısız: ${result.error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      appBar: AppAppBar.standard(title: t('email_settings.title')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner — bu ekran skeleton
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.construction, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('email_settings.skeleton_banner'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          AppSectionCard(
            title: t('email_settings.smtp_section'),
            icon: Icons.dns,
            children: [
              AppInput(
                controller: _hostCtl,
                label: t('email_settings.host_label'),
                hint: 'smtp.gmail.com',
                prefixIcon: Icons.cloud,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      controller: _portCtl,
                      label: t('email_settings.port_label'),
                      hint: '587',
                      prefixIcon: Icons.tag,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        t('email_settings.tls_label'),
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: _useTls,
                      onChanged: (v) => setState(() => _useTls = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          AppSectionCard(
            title: t('email_settings.credentials_section'),
            icon: Icons.lock_outline,
            children: [
              AppInput(
                controller: _usernameCtl,
                label: t('email_settings.username_label'),
                hint: t('email_settings.username_hint'),
                prefixIcon: Icons.person,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _passwordCtl,
                label: t('email_settings.password_label'),
                hint: t('email_settings.password_hint'),
                prefixIcon: Icons.key,
                obscureText: _obscure,
                suffixIcon:
                    _obscure ? Icons.visibility : Icons.visibility_off,
                onSuffixTap: () => setState(() => _obscure = !_obscure),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _fromCtl,
                label: t('email_settings.from_label'),
                hint: 'SEDCORE POS',
                prefixIcon: Icons.email,
              ),
            ],
          ),
          const SizedBox(height: 16),

          AppSectionCard(
            title: t('email_settings.usage_section'),
            icon: Icons.checklist,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt, size: 20, color: AppColors.textMuted),
                title: Text(
                  t('email_settings.usage_receipt'),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  t('email_settings.usage_receipt_sub'),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Switch(value: false, onChanged: null),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.assessment, size: 20, color: AppColors.textMuted),
                title: Text(
                  t('email_settings.usage_daily_report'),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  t('email_settings.usage_daily_sub'),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Switch(value: false, onChanged: null),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning, size: 20, color: AppColors.textMuted),
                title: Text(
                  t('email_settings.usage_stock_alerts'),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  t('email_settings.usage_stock_sub'),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Switch(value: false, onChanged: null),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: AppButton.outline(
                  text: _isTesting ? '...' : t('email_settings.test_send'),
                  icon: Icons.send,
                  onPressed: _isTesting ? null : _sendTestEmail,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton.primary(
                  text: _isSaving ? '...' : t('common.save'),
                  icon: Icons.save,
                  onPressed: _isSaving ? null : _saveConfig,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
