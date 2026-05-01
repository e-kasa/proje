import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/widgets/base_scaffold.dart';
import 'package:project_pos/core/utils/app_logger.dart';
import 'package:project_pos/services/print/label_print_service.dart';
import 'package:project_pos/services/print/label_print_settings.dart';
import 'package:project_pos/services/print/print_service.dart' show UsbDeviceInfo;

/// Sprint 24 — Etiket yazıcı ayarları (USB ESC/POS).
///
/// `printer_settings_screen.dart` paterni paralel — ayrı slot, ek alanlar:
/// etiket boyutu (mm), default code type, auto-cut, görüntü field toggle'ları.
class LabelPrinterSettingsScreen extends ConsumerStatefulWidget {
  const LabelPrinterSettingsScreen({super.key});

  @override
  ConsumerState<LabelPrinterSettingsScreen> createState() =>
      _LabelPrinterSettingsScreenState();
}

class _LabelPrinterSettingsScreenState
    extends ConsumerState<LabelPrinterSettingsScreen> {
  List<UsbDeviceInfo> _devices = [];
  bool _isScanning = false;
  bool _isPrinting = false;

  late final TextEditingController _widthCtl;
  late final TextEditingController _heightCtl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(labelPrintSettingsProvider);
    _widthCtl = TextEditingController(text: s.labelWidthMm.toString());
    _heightCtl = TextEditingController(text: s.labelHeightMm.toString());
  }

  @override
  void dispose() {
    _widthCtl.dispose();
    _heightCtl.dispose();
    super.dispose();
  }

  Future<void> _scanDevices() async {
    if (kIsWeb) {
      AppToast.error(context,
          'USB etiket yazıcı tarayıcıda kullanılamaz. Lütfen masaüstü uygulamasını açın.');
      return;
    }
    setState(() => _isScanning = true);
    try {
      final service = ref.read(labelPrintServiceProvider);
      final devices = await service.discoverDevices();
      setState(() => _devices = devices);
      if (mounted && devices.isEmpty) {
        AppToast.info(context, 'USB cihaz bulunamadı. Yazıcıyı takın.');
      }
    } catch (e, st) {
      AppLogger.error('Etiket yazıcı USB tarama hatası',
          error: e, stackTrace: st);
      if (mounted) {
        final msg = e.toString();
        final friendly = msg.contains('MissingPlugin')
            ? 'USB tarama bu platformda desteklenmiyor (yalnız masaüstü).'
            : (msg.contains('Permission') || msg.contains('access denied'))
                ? 'USB cihazlara erişim reddedildi. Yönetici olarak çalıştırın.'
                : 'Tarama hatası: $msg';
        AppToast.error(context, friendly);
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _selectDevice(UsbDeviceInfo device) async {
    await ref.read(labelPrintSettingsProvider.notifier).updateDevice(
          vendorId: device.vendorId,
          productId: device.productId,
          deviceName: device.displayName,
        );
    if (mounted) {
      AppToast.success(context, 'Etiket yazıcı seçildi: ${device.displayName}');
    }
  }

  Future<void> _testPrint() async {
    if (kIsWeb) {
      AppToast.error(context,
          'Test etiketi tarayıcıda yazdırılamaz. Lütfen masaüstü uygulamasını açın.');
      return;
    }
    setState(() => _isPrinting = true);
    final service = ref.read(labelPrintServiceProvider);
    final result = await service.printTestLabel();
    if (!mounted) return;
    setState(() => _isPrinting = false);
    if (result.success) {
      AppToast.success(context, 'Test etiketi yazdırıldı.');
    } else {
      AppToast.error(context, result.error ?? 'Yazdırma başarısız.');
    }
  }

  void _persistDimensions() {
    final w = int.tryParse(_widthCtl.text);
    final h = int.tryParse(_heightCtl.text);
    if (w == null || h == null || w < 10 || h < 10 || w > 200 || h > 200) {
      AppToast.warning(context,
          'Etiket boyutları 10-200 mm aralığında olmalıdır.');
      return;
    }
    ref.read(labelPrintSettingsProvider.notifier).updateDimensions(
          widthMm: w,
          heightMm: h,
        );
    AppToast.success(context, 'Boyutlar kaydedildi.');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(labelPrintSettingsProvider);
    final notifier = ref.read(labelPrintSettingsProvider.notifier);

    return BaseScaffold(
      appBar: AppAppBar.standard(title: 'Etiket Yazıcı Ayarları'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Bilgi banner'ı ─────────────────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Termal etiket yazıcı (Zjiang/POSA tarzı). Yapışkanlı etiket için '
                    'Zebra ZPL desteği Sprint 25+ için planlı.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Bağlı yazıcı durumu ────────────────────────────────────────────
          AppSectionCard(
            title: 'Bağlı Etiket Yazıcı',
            icon: Icons.label,
            children: [
              if (settings.isConfigured)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle,
                      color: AppColors.success),
                  title: Text(settings.deviceName ?? 'USB Etiket Yazıcı'),
                  subtitle: Text(
                    'VID: ${settings.vendorId}  PID: ${settings.productId}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    tooltip: 'Bağlı yazıcıyı kaldır',
                    onPressed: () => notifier.clearDevice(),
                  ),
                )
              else
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.info_outline, color: AppColors.warning),
                  title: Text('Yazıcı seçilmedi'),
                  subtitle: Text('Aşağıdan tara → seç'),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      text: _isScanning
                          ? 'Taranıyor...'
                          : 'USB Cihazları Tara',
                      icon: Icons.usb,
                      onPressed: _isScanning ? null : _scanDevices,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (settings.isConfigured)
                    AppButton.primary(
                      text: _isPrinting ? '...' : 'Test Etiketi',
                      icon: Icons.label_outline,
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
              title: 'Bulunan Cihazlar (${_devices.length})',
              icon: Icons.list,
              children: _devices.map((d) {
                final isSelected = settings.vendorId == d.vendorId &&
                    settings.productId == d.productId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.label,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  title: Text(d.displayName),
                  subtitle: Text('VID: ${d.vendorId}  PID: ${d.productId}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppColors.success)
                      : const Icon(Icons.chevron_right),
                  onTap: () => _selectDevice(d),
                );
              }).toList(),
            ),
          if (_devices.isNotEmpty) const SizedBox(height: 16),

          // ── Etiket Boyutu ──────────────────────────────────────────────────
          AppSectionCard(
            title: 'Etiket Boyutu',
            icon: Icons.aspect_ratio,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Genişlik (mm)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Yükseklik (mm)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.save_outlined,
                        color: AppColors.primary),
                    tooltip: 'Boyutları kaydet',
                    onPressed: _persistDimensions,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Tipik termal etiket: 50×30mm. Çince Zjiang yazıcılar için '
                'rolün gerçek boyutuyla eşleşmelidir.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Barkod Tipi ────────────────────────────────────────────────────
          AppSectionCard(
            title: 'Varsayılan Barkod Tipi',
            icon: Icons.qr_code,
            children: [
              Wrap(
                spacing: 8,
                children: LabelCodeType.values.map((type) {
                  final selected = settings.defaultCodeType == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (_) => notifier.updateCodeType(type),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Davranış ──────────────────────────────────────────────────────
          AppSectionCard(
            title: 'Davranış',
            icon: Icons.tune,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Her etiketten sonra otomatik kes'),
                subtitle: const Text(
                  'ESC/POS GS V kesim komutu — yazıcı destekliyorsa',
                  style: TextStyle(fontSize: 11),
                ),
                value: settings.autoCutAfterEach,
                onChanged: (v) => notifier.updateAutoCut(v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Görüntü Alanları ───────────────────────────────────────────────
          AppSectionCard(
            title: 'Etiket İçeriği',
            icon: Icons.view_quilt,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ürün adı göster'),
                value: settings.showProductName,
                onChanged: (v) => notifier.updateShowFields(name: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('SKU göster'),
                value: settings.showSku,
                onChanged: (v) => notifier.updateShowFields(sku: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fiyat göster'),
                value: settings.showPrice,
                onChanged: (v) => notifier.updateShowFields(price: v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
