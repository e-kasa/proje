import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/utils/app_logger.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/print/print_service.dart';
import 'package:project_pos/services/print/print_settings.dart';

/// Sprint 22 — POS yazıcı ayarları (USB tarama, kağıt genişliği, test, header/footer).
class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState
    extends ConsumerState<PrinterSettingsScreen> {
  String Function(String) get t => i18nOf(ref);

  List<UsbDeviceInfo> _devices = [];
  bool _isScanning = false;
  bool _isPrinting = false;

  late final TextEditingController _headerCtl;
  late final TextEditingController _footerCtl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(printSettingsProvider);
    _headerCtl = TextEditingController(text: s.headerText);
    _footerCtl = TextEditingController(text: s.footerText);

    // Sprint 29-fix-5: Önceden kayıtlı sanal yazıcıyı (Microsoft Print to PDF
    // gibi) otomatik temizle — kullanıcı yanlışlıkla seçmiş olabilir, fiş
    // basamayacağı için silinmeli.
    final name = s.deviceName ?? '';
    if (name.isNotEmpty && PrintService.isVirtualPrinterName(name)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(printSettingsProvider.notifier).clearDevice();
        if (mounted) {
          AppToast.warning(
            context,
            'Önceki seçim "$name" sanal bir yazıcıydı (PDF/OneNote/Fax) — '
            'temizlendi. Lütfen gerçek termal cihaz seçin.',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _headerCtl.dispose();
    _footerCtl.dispose();
    super.dispose();
  }

  Future<void> _scanDevices() async {
    if (kIsWeb) {
      AppToast.error(context, t('printer.web_unsupported_scan'));
      return;
    }
    setState(() => _isScanning = true);
    try {
      final service = ref.read(printServiceProvider);
      final devices = await service.discoverDevices();
      setState(() => _devices = devices);
      if (mounted && devices.isEmpty) {
        AppToast.info(context, t('printer.no_devices_found'));
      }
    } catch (e, st) {
      AppLogger.error('USB tarama hatası', error: e, stackTrace: st);
      if (mounted) {
        final msg = e.toString();
        final friendly = msg.contains('MissingPlugin')
            ? t('printer.scan_unsupported_platform')
            : (msg.contains('Permission') || msg.contains('access denied'))
                ? t('printer.scan_permission_denied')
                : t('printer.scan_error').replaceAll('{0}', msg);
        AppToast.error(context, friendly);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _selectDevice(UsbDeviceInfo device) async {
    await ref.read(printSettingsProvider.notifier).updateDevice(
          vendorId: device.vendorId,
          productId: device.productId,
          deviceName: device.displayName,
        );
    if (mounted) {
      AppToast.success(
        context,
        t('printer.device_selected').replaceAll('{0}', device.displayName),
      );
    }
  }

  Future<void> _testPrint() async {
    if (kIsWeb) {
      AppToast.error(context, t('printer.web_unsupported_test'));
      return;
    }
    setState(() => _isPrinting = true);
    final service = ref.read(printServiceProvider);
    final result = await service.printTestPage();
    if (!mounted) return;
    setState(() => _isPrinting = false);
    if (result.success) {
      AppToast.success(context, t('printer.test_printed'));
    } else {
      AppToast.error(context, result.error ?? t('printer.print_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printSettingsProvider);
    final notifier = ref.read(printSettingsProvider.notifier);

    return BaseScaffold(
      appBar: AppAppBar.standard(title: t('printer.title')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sprint 29-fix-5 — Bilgi banner: Windows yazıcı kurulum rehberi
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Yazıcı listede yoksa: Windows Ayarlar → Bluetooth ve cihazlar → '
                    'Yazıcılar ve tarayıcılar → Cihaz ekle → POSA cihazınızı seçin '
                    '(veya manuel: Generic / Text Only sürücüsü). Sanal yazıcılar '
                    '(PDF/OneNote/Fax) bu listede gizlidir.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          // ── Bağlı yazıcı durumu ────────────────────────────────────────────
          AppSectionCard(
            title: t('printer.connected_printer'),
            icon: Icons.print,
            children: [
              if (settings.isConfigured)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle, color: AppColors.success),
                  title: Text(settings.deviceName ?? t('printer.usb_printer')),
                  subtitle: Text(
                    'VID: ${settings.vendorId}  PID: ${settings.productId}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    tooltip: t('printer.remove_connected'),
                    onPressed: () => notifier.clearDevice(),
                  ),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline, color: AppColors.warning),
                  title: Text(t('printer.no_device_selected')),
                  subtitle: Text(t('printer.scan_hint')),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      text: _isScanning
                          ? t('printer.scanning')
                          : t('printer.scan_usb_devices'),
                      icon: Icons.usb,
                      onPressed: _isScanning ? null : _scanDevices,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (settings.isConfigured)
                    AppButton.primary(
                      text: _isPrinting ? '...' : t('printer.test_print'),
                      icon: Icons.print,
                      onPressed: _isPrinting ? null : _testPrint,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Tarama sonuçları ──────────────────────────────────────────────
          if (_devices.isNotEmpty)
            AppSectionCard(
              title: t('printer.found_devices')
                  .replaceAll('{0}', '${_devices.length}'),
              icon: Icons.list,
              children: _devices.map((d) {
                final isSelected = settings.vendorId == d.vendorId &&
                    settings.productId == d.productId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.print,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(d.displayName),
                  subtitle: Text('VID: ${d.vendorId}  PID: ${d.productId}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(Icons.chevron_right),
                  onTap: () => _selectDevice(d),
                );
              }).toList(),
            ),
          if (_devices.isNotEmpty) const SizedBox(height: 16),

          // ── Kağıt genişliği ────────────────────────────────────────────────
          AppSectionCard(
            title: t('printer.paper_settings'),
            icon: Icons.description,
            children: [
              Row(
                children: PaperWidth.values.map((width) {
                  final isSelected = settings.paperWidth == width;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${width.mm}mm'),
                        selected: isSelected,
                        onSelected: (_) => notifier.updatePaperWidth(width),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                t('printer.paper_hint'),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Davranış ──────────────────────────────────────────────────────
          AppSectionCard(
            title: t('printer.behavior'),
            icon: Icons.settings,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t('printer.auto_print_on_sale')),
                subtitle: Text(t('printer.auto_print_subtitle')),
                value: settings.autoPrintOnSale,
                onChanged: notifier.updateAutoPrint,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Fiş başlığı / alt yazı ────────────────────────────────────────
          AppSectionCard(
            title: t('printer.receipt_text'),
            icon: Icons.text_fields,
            children: [
              AppInput(
                controller: _headerCtl,
                label: t('printer.receipt_header_label'),
                hint: 'SEDCORE POS',
                prefixIcon: Icons.title,
                onChanged: (v) => notifier.updateText(header: v),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _footerCtl,
                label: t('printer.receipt_footer_label'),
                hint: t('printer.footer_hint'),
                prefixIcon: Icons.short_text,
                maxLines: 2,
                onChanged: (v) => notifier.updateText(footer: v),
              ),
              const SizedBox(height: 8),
              Text(
                t('printer.ascii_note'),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
