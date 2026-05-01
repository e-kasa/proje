import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import 'print_settings.dart';

/// Sprint 22 — POS satış fişi ESC/POS byte builder.
///
/// `Sale` data → 80mm/58mm termal kağıda uygun fiş bytes.
///
/// Kullanım:
/// ```dart
/// final bytes = await ReceiptTemplate(settings).buildSaleReceipt(saleData);
/// await usbPrintService.send(bytes);
/// ```
class ReceiptTemplate {
  final PrintSettings settings;
  final NumberFormat _money = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL ');
  final DateFormat _dateFmt = DateFormat('dd.MM.yyyy HH:mm');

  ReceiptTemplate(this.settings);

  /// Sale verisi (`Map<String, dynamic>` — sale_list_screen formatıyla uyumlu).
  ///
  /// Beklenen alanlar:
  /// - `id`, `saleNumber`, `createdAt` / `saleDate`
  /// - `customerName`, `customerPhone` (opsiyonel)
  /// - `paymentMethod` (cash/credit_card/...)
  /// - `items`: [{name, quantity, unitPrice, total}]
  /// - `subtotal`, `taxAmount`, `discountAmount`, `totalAmount`/`grandTotal`
  Future<List<int>> buildSaleReceipt(Map<String, dynamic> sale) async {
    final profile = await CapabilityProfile.load();
    final paperSize = settings.paperWidth == PaperWidth.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final gen = Generator(paperSize, profile);
    final List<int> bytes = [];

    // ── HEADER ─────────────────────────────────────────────────────────────
    bytes.addAll(gen.text(
      settings.headerText,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(gen.feed(1));

    // ── Tarih + fiş no ─────────────────────────────────────────────────────
    final dateStr = sale['createdAt']?.toString() ??
        sale['saleDate']?.toString() ??
        DateTime.now().toIso8601String();
    final dateDisplay = _formatDate(dateStr);
    final saleNo = sale['saleNumber']?.toString() ?? sale['id']?.toString() ?? '-';

    bytes.addAll(gen.row([
      PosColumn(text: 'Fis No:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: '#$saleNo', width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.row([
      PosColumn(text: 'Tarih:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: dateDisplay, width: 8, styles: const PosStyles(align: PosAlign.right)),
    ]));

    // ── Müşteri (varsa) ────────────────────────────────────────────────────
    final customerName = sale['customerName']?.toString();
    if (customerName != null && customerName.isNotEmpty) {
      bytes.addAll(gen.row([
        PosColumn(text: 'Musteri:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(
          text: _ascii(customerName),
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(gen.hr());

    // ── ITEMS ──────────────────────────────────────────────────────────────
    final items = (sale['items'] as List?) ?? const [];
    for (final raw in items) {
      final item = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final name = _ascii(
        (item['variantName'] ?? item['productName'] ?? item['name'] ?? '?').toString(),
      );
      final qty = (item['quantity'] as num?)?.toDouble() ?? 1;
      final unitPrice = (item['unitPrice'] as num?)?.toDouble() ??
          (item['price'] as num?)?.toDouble() ??
          0;
      final lineTotal = (item['total'] as num?)?.toDouble() ??
          (item['lineTotal'] as num?)?.toDouble() ??
          (qty * unitPrice);

      // Ürün adı (max line)
      bytes.addAll(gen.text(name, styles: const PosStyles(bold: true)));

      // Miktar x birim fiyat → toplam (sağa yaslı)
      final qtyStr = qty == qty.toInt() ? qty.toInt().toString() : qty.toStringAsFixed(2);
      bytes.addAll(gen.row([
        PosColumn(text: '  $qtyStr x ${_money.format(unitPrice)}', width: 7),
        PosColumn(
          text: _money.format(lineTotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]));
    }

    bytes.addAll(gen.hr());

    // ── TOTALS ─────────────────────────────────────────────────────────────
    final subtotal = (sale['subtotal'] as num?)?.toDouble();
    final discount = (sale['discountAmount'] as num?)?.toDouble();
    final tax = (sale['taxAmount'] as num?)?.toDouble();
    final total = (sale['totalAmount'] as num?)?.toDouble() ??
        (sale['grandTotal'] as num?)?.toDouble() ??
        0;

    if (subtotal != null && subtotal > 0) {
      bytes.addAll(gen.row([
        PosColumn(text: 'Ara Toplam:', width: 7),
        PosColumn(
          text: _money.format(subtotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    if (discount != null && discount > 0) {
      bytes.addAll(gen.row([
        PosColumn(text: 'Indirim:', width: 7),
        PosColumn(
          text: '-${_money.format(discount)}',
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    if (tax != null && tax > 0) {
      bytes.addAll(gen.row([
        PosColumn(text: 'KDV:', width: 7),
        PosColumn(
          text: _money.format(tax),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(gen.hr(ch: '='));
    bytes.addAll(gen.row([
      PosColumn(
        text: 'TOPLAM',
        width: 6,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: _money.format(total),
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]));
    bytes.addAll(gen.hr(ch: '='));

    // ── Ödeme yöntemi ──────────────────────────────────────────────────────
    final payment = _paymentLabel(sale['paymentMethod']?.toString());
    if (payment.isNotEmpty) {
      bytes.addAll(gen.row([
        PosColumn(text: 'Odeme:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: payment,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(gen.feed(1));

    // ── QR kod (sale ID) ───────────────────────────────────────────────────
    final saleId = sale['id']?.toString();
    if (saleId != null && saleId.isNotEmpty) {
      bytes.addAll(gen.qrcode(saleId, size: QRSize.size4, align: PosAlign.center));
      bytes.addAll(gen.text(
        '#$saleId',
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
      ));
    }

    // ── FOOTER ─────────────────────────────────────────────────────────────
    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.text(
      _ascii(settings.footerText),
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());

    return bytes;
  }

  /// Yazıcı ayar ekranındaki "Test Yazdır" butonu için minimal fiş.
  Future<List<int>> buildTestPage() async {
    final profile = await CapabilityProfile.load();
    final paperSize = settings.paperWidth == PaperWidth.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final gen = Generator(paperSize, profile);
    final List<int> bytes = [];

    bytes.addAll(gen.text(
      'TEST YAZDIRMA',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.text(
      _ascii(settings.headerText),
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.text(
      'Yazici baglantisi BASARILI.',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.text(
      'Kagit: ${settings.paperWidth.mm}mm',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.text(
      _dateFmt.format(DateTime.now()),
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());

    return bytes;
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return _dateFmt.format(dt);
  }

  String _paymentLabel(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash':
        return 'Nakit';
      case 'credit_card':
        return 'Kredi Karti';
      case 'bank_transfer':
        return 'Havale/EFT';
      case 'mixed':
        return 'Karma';
      default:
        return method ?? '';
    }
  }

  /// Türkçe karakterleri ASCII'ye çevir (POSA çoğunlukla CP857 değil ASCII safe).
  /// İleri sürümde codeTable: 'CP857' eklenebilir; şimdilik en uyumlu yol.
  String _ascii(String input) {
    return input
        .replaceAll('Ç', 'C').replaceAll('ç', 'c')
        .replaceAll('Ğ', 'G').replaceAll('ğ', 'g')
        .replaceAll('İ', 'I').replaceAll('ı', 'i')
        .replaceAll('Ö', 'O').replaceAll('ö', 'o')
        .replaceAll('Ş', 'S').replaceAll('ş', 's')
        .replaceAll('Ü', 'U').replaceAll('ü', 'u');
  }
}
