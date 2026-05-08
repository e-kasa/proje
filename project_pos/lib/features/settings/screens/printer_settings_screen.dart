import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/utils/app_logger.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/services/print/hidden_printers.dart';
import 'package:project_pos/services/print/label_print_settings.dart';
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
    // Sprint 29-fix-5 sanal yazıcı temizliği build()'e taşındı — initState'te
    // SharedPreferences hidrasyonu henüz tamamlanmamış olabilir, gerçek cihaz
    // adı boş gelir, yanlış pozitif olmaz (Sprint 30 receipt-printer-repeated-pairing).
  }

  /// Sprint 29-fix-5 → Sprint 30: Önceden kayıtlı sanal yazıcıyı (PDF/OneNote/Fax)
  /// hidrasyon tamamlandıktan sonra **bir kez** temizle. Hidrasyondan önce
  /// çalıştırılırsa `deviceName` boş gelip false-negative üretir; daha kötüsü
  /// gerçek yazıcı kaydını silebilir.
  bool _virtualSweepDone = false;
  void _sweepVirtualPrinterIfHydrated(PrintSettings settings) {
    if (_virtualSweepDone || !settings.loaded) return;
    _virtualSweepDone = true;
    final name = settings.deviceName ?? '';
    if (name.isEmpty || !PrintService.isVirtualPrinterName(name)) return;
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

  /// Hidrasyon `initState` sonrası tamamlandığı için controller'lar default
  /// değerlerle doldu — ilk `loaded=true` build'inde gerçek değerlerle senkronize et.
  bool _textControllersHydrated = false;
  void _hydrateTextControllers(PrintSettings settings) {
    if (_textControllersHydrated || !settings.loaded) return;
    _textControllersHydrated = true;
    _headerCtl.text = settings.headerText;
    _footerCtl.text = settings.footerText;
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

  /// Sprint 30 — Tarama listesindeki cihazı kullanıcı blacklist'ine ekler.
  /// Sonraki taramalarda gösterilmez. Geri almak için "Gizli yazıcılar" kartı.
  Future<void> _hideDevice(UsbDeviceInfo device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yazıcıyı listeden gizle'),
        content: Text(
          '"${device.displayName}" cihazı tarama listesinde gösterilmesin mi? '
          'Bu işlem yazıcıyı Windows\'tan kaldırmaz; sadece bu uygulamadaki '
          'tarama listesini sadeleştirir. İstediğiniz zaman geri alabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Gizle'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(hiddenPrintersProvider.notifier).hide(device.displayName);
    if (!mounted) return;
    setState(() {
      _devices.removeWhere((d) =>
          d.displayName.toLowerCase().trim() ==
          device.displayName.toLowerCase().trim());
    });
    AppToast.info(
      context,
      '"${device.displayName}" listeden gizlendi.',
    );
  }

  Future<void> _unhideDevice(String name) async {
    await ref.read(hiddenPrintersProvider.notifier).unhide(name);
    if (mounted) {
      AppToast.info(context, '"$name" geri yüklendi. Tekrar tara.');
    }
  }

  Future<void> _unhideAll() async {
    await ref.read(hiddenPrintersProvider.notifier).clearAll();
    if (mounted) {
      AppToast.info(context, 'Tüm gizli yazıcılar geri yüklendi. Tekrar tara.');
    }
  }

  /// Sprint 30 — Gizli yazıcıların yönetim kartı. Boşsa kart hiç render edilmez.
  Widget _buildHiddenPrintersCard() {
    final hidden = ref.watch(hiddenPrintersProvider);
    if (hidden.hiddenNames.isEmpty) return const SizedBox.shrink();
    final names = hidden.hiddenNames.toList()..sort();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppSectionCard(
        title: 'Gizli yazıcılar (${names.length})',
        icon: Icons.visibility_off,
        children: [
          for (final name in names)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.print_disabled, color: AppColors.textMuted),
              title: Text(name),
              trailing: IconButton(
                icon: const Icon(Icons.restore, color: AppColors.primary),
                tooltip: 'Geri al',
                onPressed: () => _unhideDevice(name),
              ),
            ),
          const SizedBox(height: 8),
          AppButton.outline(
            text: 'Tümünü geri al',
            icon: Icons.restore_page,
            onPressed: _unhideAll,
          ),
        ],
      ),
    );
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

  /// Sprint 30 — Tek tıkla yazıcı kurulum sihirbazı.
  ///
  /// Akış:
  /// 1. USB tara
  /// 2. "Generic / Text Only (Kopya N)" duplikasyonlarını otomatik gizle
  /// 3. POSA / thermal / fiş gibi adlardan en uygununu seç (yoksa ilk gerçek cihaz)
  /// 4. Kağıt 80mm + autoPrintOnSale aç
  /// 5. Kullanıcıyı bilgilendir — test fiş ayrı buton, otomatik basmaz
  ///   (kağıt israfı + sürpriz davranış olmasın)
  Future<void> _quickSetup() async {
    if (kIsWeb) {
      AppToast.error(
        context,
        'Hızlı kurulum tarayıcıda kullanılamaz. Masaüstü uygulamasını açın.',
      );
      return;
    }
    setState(() => _isScanning = true);
    try {
      final service = ref.read(printServiceProvider);
      final hiddenN = ref.read(hiddenPrintersProvider.notifier);
      final settingsN = ref.read(printSettingsProvider.notifier);

      // 1) Tarama
      final initial = await service.discoverDevices();
      if (initial.isEmpty) {
        if (mounted) {
          AppToast.error(
            context,
            'USB cihaz bulunamadı. POSA bağlı/açık mı kontrol edin '
            '(rehber: docs/printer-setup.md).',
          );
        }
        return;
      }

      // 2) Generic / Text Only (Kopya N) duplikasyonlarını otomatik gizle
      int hiddenCount = 0;
      for (final d in initial) {
        final n = d.displayName.toLowerCase();
        if (n.contains('kopya') &&
            (n.contains('generic') || n.contains('text only'))) {
          await hiddenN.hide(d.displayName);
          hiddenCount++;
        }
      }

      // 3) Filtre sonrası tekrar tara
      final visible = await service.discoverDevices();

      // 4) Fiş yazıcı için en uygunu seç — POSA / thermal / fiş öncelikli
      UsbDeviceInfo? receipt;
      const receiptPreferred = ['posa', 'thermal', 'escpos', 'fiş', 'fis', '80mm', '80'];
      for (final keyword in receiptPreferred) {
        for (final d in visible) {
          if (d.displayName.toLowerCase().contains(keyword)) {
            receipt = d;
            break;
          }
        }
        if (receipt != null) break;
      }
      receipt ??= visible.isNotEmpty ? visible.first : null;

      if (receipt == null) {
        if (mounted) {
          AppToast.error(
            context,
            'Gizleme sonrası uygun yazıcı kalmadı. "Tümünü geri al" deneyin.',
          );
        }
        return;
      }

      // 5) Etiket yazıcı için (Senaryo B): kalanlar arasından zebra/label/etiket/
      // barkod öncelikli; yoksa kalan ilk cihaz. Tek cihaz varsa Case 1.5 reuse
      // devreye girer — etiket slotu boş bırakılır.
      UsbDeviceInfo? label;
      final remaining = visible.where((d) =>
          d.displayName.toLowerCase().trim() !=
          receipt!.displayName.toLowerCase().trim()).toList();
      if (remaining.isNotEmpty) {
        const labelPreferred = ['barkod', 'barcode', 'etiket', 'label', 'zebra', 'zpl'];
        for (final keyword in labelPreferred) {
          for (final d in remaining) {
            if (d.displayName.toLowerCase().contains(keyword)) {
              label = d;
              break;
            }
          }
          if (label != null) break;
        }
        // Etiket için preferred bulunamadıysa kalan ilk cihaz (Senaryo B)
        label ??= remaining.first;
      }

      // 6) Fiş yazıcı slotunu yapılandır
      await settingsN.updateDevice(
        vendorId: receipt.vendorId,
        productId: receipt.productId,
        deviceName: receipt.displayName,
      );
      await settingsN.updatePaperWidth(PaperWidth.mm80);
      await settingsN.updateAutoPrint(true);

      // 7) Etiket yazıcı slotunu yapılandır (varsa — Senaryo B)
      if (label != null) {
        final labelN = ref.read(labelPrintSettingsProvider.notifier);
        await labelN.updateDevice(
          vendorId: label.vendorId,
          productId: label.productId,
          deviceName: label.displayName,
        );
        // Sprint 30 — Cihaz adına göre otomatik protokol seç:
        //   "label", "9x10", "tspl" → TSPL (Zjiang LABEL / Argox / TSC)
        //   diğer → ESC/POS (POSA / Zjiang ZJ-58/80 fiş termal)
        final ln = label.displayName.toLowerCase();
        final isTspl = ln.contains('label') ||
            ln.contains('9x10') ||
            ln.contains('9-10') ||
            ln.contains('tspl') ||
            ln.contains('argox') ||
            ln.contains('tsc');
        await labelN
            .updateProtocol(isTspl ? LabelProtocol.tspl : LabelProtocol.escPos);
      }

      if (!mounted) return;
      setState(() => _devices = visible);

      final hiddenSuffix = hiddenCount > 0
          ? ' ($hiddenCount duplikasyon gizlendi)'
          : '';
      final scenario = label != null
          ? 'Senaryo B (2 yazıcı): Fiş = "${receipt.displayName}", '
              'Etiket = "${label.displayName}"'
          : 'Senaryo A (tek yazıcı): "${receipt.displayName}" '
              '(etiket için Case 1.5 reuse)';
      AppToast.success(
        context,
        '$scenario · 80mm · otomatik yazdırma açık$hiddenSuffix. '
        'Şimdi "Test Yazdır" ile doğrulayın.',
      );
    } catch (e, st) {
      AppLogger.error('Hızlı kurulum hatası', error: e, stackTrace: st);
      if (mounted) {
        AppToast.error(context, 'Hızlı kurulum başarısız: $e');
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printSettingsProvider);
    final notifier = ref.read(printSettingsProvider.notifier);
    _sweepVirtualPrinterIfHydrated(settings);
    _hydrateTextControllers(settings);

    if (!settings.loaded) {
      return BaseScaffold(
        appBar: AppAppBar.standard(title: t('printer.title')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          // ── Sprint 30: Hızlı Kurulum (tek tıkla otomatik yapılandırma) ──────
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppButton.primary(
              text: _isScanning ? 'Yapılandırılıyor...' : 'Hızlı Kurulum (Sihirbaz)',
              icon: Icons.auto_awesome,
              onPressed: _isScanning ? null : _quickSetup,
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
                // Sprint 30 fix — Generic / Text Only sürücüsü VID=0 PID=0
                // verir; sadece VID/PID match'i tüm Generic kayıtları "seçili"
                // gösteriyor. Cihaz adını da match'e dahil et.
                final isSelected = settings.vendorId == d.vendorId &&
                    settings.productId == d.productId &&
                    (settings.deviceName ?? '').toLowerCase().trim() ==
                        d.displayName.toLowerCase().trim();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.print,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(d.displayName),
                  subtitle: Text('VID: ${d.vendorId}  PID: ${d.productId}'),
                  // Sprint 30: Seçili olmayan cihazlar için "gizle" butonu;
                  // seçili cihaz check icon. Gizle → confirm dialog → SharedPrefs.
                  // "Bağlı Yazıcı" kartındaki kırmızı ✕ paterni ile aynı (UX tutarlılığı).
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : IconButton(
                          icon: const Icon(Icons.close, color: AppColors.danger),
                          tooltip: 'Listede gösterme',
                          onPressed: () => _hideDevice(d),
                        ),
                  onTap: () => _selectDevice(d),
                );
              }).toList(),
            ),
          if (_devices.isNotEmpty) const SizedBox(height: 16),

          // ── Gizli yazıcılar (Sprint 30 — aktif olmayan yazıcı yönetimi) ─────
          _buildHiddenPrintersCard(),

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
