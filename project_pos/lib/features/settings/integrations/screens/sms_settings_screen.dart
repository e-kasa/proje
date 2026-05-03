import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/notification/notification_models.dart';
import 'package:project_pos/services/notification/notification_service.dart';
import 'package:project_pos/services/notification/notification_settings.dart';

/// Sprint 23 — SMS entegrasyonu — Skeleton.
///
/// **TODO Sprint 24+:** Gerçek SMS provider entegrasyonu (Netgsm/Twilio).
/// Şu an UI iskeleti hazır; backend hookup gelince provider seçimi +
/// API key + sender ID gerçekten kaydedilecek.
class SmsSettingsScreen extends ConsumerStatefulWidget {
  const SmsSettingsScreen({super.key});

  @override
  ConsumerState<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends ConsumerState<SmsSettingsScreen> {
  String Function(String) get t => i18nOf(ref);

  final _apiKeyCtl = TextEditingController();
  final _senderIdCtl = TextEditingController();
  final _testNumberCtl = TextEditingController();

  String _provider = 'netgsm';
  bool _obscureKey = true;
  bool _isTesting = false;  // Sprint 27: test send loading state

  // Provider id'leri (i18n için name/description bundle'dan okunur)
  static const _providerIds = ['netgsm', 'twilio', 'iletimerkezi'];

  @override
  void dispose() {
    _apiKeyCtl.dispose();
    _senderIdCtl.dispose();
    _testNumberCtl.dispose();
    super.dispose();
  }

  /// Sprint 27 — Test SMS gönderim. Backend SMS kanalı NOOP default
  /// (Sprint 26-A); Twilio aktive değilse log'a yazar, gerçek SMS gitmez.
  /// `notification.sms.provider=twilio` set edildiğinde gerçek gönderim olur.
  Future<void> _sendTestSms() async {
    final to = _testNumberCtl.text.trim();
    if (to.isEmpty) {
      AppToast.error(context, 'Önce test telefon numarası alanını doldurun.');
      return;
    }
    setState(() => _isTesting = true);
    final result = await ref.read(notificationServiceProvider).send(
          NotificationRequest(
            eventType: 'TEST_SMS',
            channel: NotificationChannel.sms,
            recipient: to,
            body: 'SEDCORE POS — Test SMS. Sprint 26-A NOOP/Twilio entegrasyonu.',
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
    final notifSettings = ref.watch(notificationSettingsProvider);
    return BaseScaffold(
      appBar: AppAppBar.standard(title: t('sms_settings.title')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sprint 28 — Otomatik satış SMS toggle (üstte, hemen görünür)
          AppSectionCard(
            title: 'Otomatik Gönderim',
            icon: Icons.auto_awesome,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Satış sonrası müşteriye otomatik SMS'),
                subtitle: const Text(
                  'Satış tamamlandığında, müşteri telefonu kayıtlıysa fiş özeti '
                  'otomatik SMS olarak gönderilir.',
                  style: TextStyle(fontSize: 11),
                ),
                value: notifSettings.smsAutoOnSale,
                onChanged: (v) => ref
                    .read(notificationSettingsProvider.notifier)
                    .updateSmsAutoOnSale(v),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    t('sms_settings.skeleton_banner'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Provider seçimi
          AppSectionCard(
            title: t('sms_settings.provider_section'),
            icon: Icons.business,
            children: _providerIds.map((id) {
              final isSelected = _provider == id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => setState(() => _provider = id),
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : null,
                  borderColor: isSelected ? AppColors.primary : AppColors.border,
                  borderWidth: isSelected ? 2 : 1,
                  hasShadow: false,
                  child: Row(
                    children: [
                      Icon(
                        Icons.sms,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('sms_settings.provider_$id'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t('sms_settings.provider_${id}_desc'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // API Credentials
          AppSectionCard(
            title: t('sms_settings.credentials_section'),
            icon: Icons.vpn_key,
            children: [
              AppInput(
                controller: _apiKeyCtl,
                label: t('sms_settings.api_key_label'),
                hint: t('sms_settings.api_key_hint'),
                prefixIcon: Icons.key,
                obscureText: _obscureKey,
                suffixIcon: _obscureKey ? Icons.visibility : Icons.visibility_off,
                onSuffixTap: () =>
                    setState(() => _obscureKey = !_obscureKey),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _senderIdCtl,
                label: t('sms_settings.sender_id_label'),
                hint: 'SEDCORE',
                prefixIcon: Icons.label,
              ),
              const SizedBox(height: 8),
              Text(
                t('sms_settings.sender_id_hint'),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Kullanım alanları
          AppSectionCard(
            title: t('sms_settings.usage_section'),
            icon: Icons.checklist,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt, size: 20, color: AppColors.textMuted),
                title: Text(
                  t('sms_settings.usage_receipt'),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  t('sms_settings.usage_receipt_sub'),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Switch(value: false, onChanged: null),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active, size: 20, color: AppColors.textMuted),
                title: Text(
                  t('sms_settings.usage_reminder'),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  t('sms_settings.usage_reminder_sub'),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Switch(value: false, onChanged: null),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.campaign, size: 20, color: AppColors.textMuted),
                title: Text(
                  t('sms_settings.usage_campaign'),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  t('sms_settings.usage_campaign_sub'),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Switch(value: false, onChanged: null),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test SMS
          AppSectionCard(
            title: t('sms_settings.test_section'),
            icon: Icons.send,
            children: [
              AppInput(
                controller: _testNumberCtl,
                label: t('sms_settings.test_number_label'),
                hint: '+90 555 123 45 67',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton.outline(
                  text: _isTesting ? '...' : t('sms_settings.test_send'),
                  icon: Icons.send,
                  onPressed: _isTesting ? null : _sendTestSms,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              text: t('common.save'),
              icon: Icons.save,
              onPressed: () => AppToast.info(
                context,
                t('sms_settings.save_coming_soon'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
