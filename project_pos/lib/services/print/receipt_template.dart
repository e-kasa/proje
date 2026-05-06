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
    // Sprint 29-fix-7: Türkiye fiş standardı — her item yanında KDV oran
    // göstergesi (*20 = %20). Footer'da oran bazlı KDV breakdown.
    final items = (sale['items'] as List?) ?? const [];
    // taxRate → {netSum, taxSum} aggregator (footer breakdown için)
    final Map<int, _TaxBucket> taxBuckets = {};

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
      // KDV oranı (%): integer (1, 8, 10, 18, 20). Item'da yoksa 20 varsay.
      final taxRateRaw = (item['taxRate'] as num?)?.toDouble() ?? 20.0;
      final taxRate = taxRateRaw.round();

      // Aggregator: line için net + tax hesapla
      // lineTotal = net * (1 + rate/100)  →  net = lineTotal / (1 + rate/100)
      final divisor = 1 + (taxRate / 100.0);
      final lineNet = divisor > 0 ? lineTotal / divisor : lineTotal;
      final lineTax = lineTotal - lineNet;
      final bucket = taxBuckets.putIfAbsent(taxRate, () => _TaxBucket());
      bucket.netSum += lineNet;
      bucket.taxSum += lineTax;

      // Ürün adı (max line)
      bytes.addAll(gen.text(name, styles: const PosStyles(bold: true)));

      // Miktar x birim fiyat → toplam *KDV oranı (sağa yaslı)
      final qtyStr = qty == qty.toInt() ? qty.toInt().toString() : qty.toStringAsFixed(2);
      // *20 formatı — Türkiye fişlerinde standart KDV göstergesi
      final lineRight = '${_money.format(lineTotal)} *$taxRate';
      bytes.addAll(gen.row([
        PosColumn(text: '  $qtyStr x ${_money.format(unitPrice)}', width: 6),
        PosColumn(
          text: lineRight,
          width: 6,
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
    // Sprint 29-fix-7: KDV oran bazlı breakdown (Türkiye fiş standardı)
    // Eğer item'lardan toplanmış bucket varsa onu kullan; yoksa eski tek
    // "KDV: TL X" satırı.
    if (taxBuckets.isNotEmpty) {
      // Sıralı çıktı (oran küçükten büyüğe)
      final sortedRates = taxBuckets.keys.toList()..sort();
      for (final rate in sortedRates) {
        final bucket = taxBuckets[rate]!;
        if (bucket.taxSum <= 0) continue;
        bytes.addAll(gen.row([
          PosColumn(text: 'KDV %$rate:', width: 7),
          PosColumn(
            text: _money.format(bucket.taxSum),
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]));
      }
    } else if (tax != null && tax > 0) {
      // Fallback: items içinde taxRate bilgisi yoksa toplam KDV göster
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

    // ── KDV TABLOSU (Türkiye fiş standardı) ────────────────────────────────
    // Sprint 29-fix-7: Her oran için Matrah + KDV detay satırı.
    // Birden fazla farklı oran varsa (örn. %1 gıda + %20 genel) ayrı satır.
    if (taxBuckets.isNotEmpty) {
      bytes.addAll(gen.feed(1));
      bytes.addAll(gen.text(
        'KDV TABLOSU',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ));
      bytes.addAll(gen.hr());
      // Sütun başlıkları
      bytes.addAll(gen.row([
        PosColumn(text: 'Oran',  width: 2, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Matrah', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
        PosColumn(text: 'KDV',    width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]));
      final sortedRates = taxBuckets.keys.toList()..sort();
      for (final rate in sortedRates) {
        final bucket = taxBuckets[rate]!;
        bytes.addAll(gen.row([
          PosColumn(text: '%$rate', width: 2),
          PosColumn(
            text: _money.format(bucket.netSum),
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: _money.format(bucket.taxSum),
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]));
      }
      bytes.addAll(gen.hr());
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

/// Sprint 29-fix-7 — KDV oran bazlı aggregator.
/// Items içinde her satırın net + tax tutarını oran (%X) bazında topla.
class _TaxBucket {
  double netSum = 0.0;
  double taxSum = 0.0;
}
