import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/utils/app_logger.dart';

/// Sprint 30 — USB HID barkod okuyucu için global tuş dinleyici.
///
/// USB HID barkod okuyucular Windows'ta klavye gibi davranır: cihaz okuduğu
/// her karakteri sırayla yazar + sonunda Enter (veya Tab) gönderir. Bu widget
/// uygulamanın herhangi bir TextField'ı focus'lu olmadığı sürece tuş akışını
/// dinler ve şu paterni algılar:
///
/// - Kısa süre içinde (default 100ms) **çoklu karakter** girişi
/// - Sonunda **Enter** veya **Tab**
/// - Buffer 4+ karakter ise **barkod** kabul edilir → `onScan` çağrılır
///
/// Klavye yazımıyla ayrım: insan parmak hızı ~5-10 char/sn, barkod okuyucu
/// 100+ char/sn. Timeout buffer'ı insan girişine karşı sıfırlar.
///
/// Kullanım:
/// ```dart
/// BarcodeScannerListener(
///   onScan: (code) => ref.read(posProvider.notifier).addToCartByBarcode(code),
///   child: PosScreen(),
/// )
/// ```
///
/// `Focus`/`TextField` aktif olduğunda otomatik **devre dışı** — kullanıcı
/// arama kutusuna yazarken çakışma olmaz. Detay: `_shouldHandleKeyEvent`.
///
/// Sprint 30 backlog: ayar ekranı (timeout/min length/suffix) henüz yok;
/// pragmatik default'lar ile çalışır.
class BarcodeScannerListener extends StatefulWidget {
  /// Barkod algılandığında çağrılır (4+ karakter, sonunda Enter/Tab).
  final void Function(String code) onScan;

  /// Wrap edilen widget tree.
  final Widget child;

  /// İki tuş arası max gecikme (ms). Bu süreyi aşan girişler insan kabul
  /// edilir, buffer sıfırlanır. USB HID okuyucular tipik <50ms ile yazar;
  /// yavaş cihazlar / Bluetooth okuyucular için 200ms tampon.
  final Duration interKeyTimeout;

  /// Barkod minimum uzunluğu (kısa metinleri tek char tuş basışlarından ayırır).
  /// Test EAN-8 = 8, Code39 = 4-6, kısa SKU = 3+
  final int minBarcodeLength;

  /// Devre dışı bırakmak için (örn. test ekranı, ayarlar).
  final bool enabled;

  const BarcodeScannerListener({
    super.key,
    required this.onScan,
    required this.child,
    this.interKeyTimeout = const Duration(milliseconds: 200),
    this.minBarcodeLength = 3,
    this.enabled = true,
  });

  @override
  State<BarcodeScannerListener> createState() => _BarcodeScannerListenerState();
}

class _BarcodeScannerListenerState extends State<BarcodeScannerListener> {
  final StringBuffer _buffer = StringBuffer();
  DateTime _lastKeyAt = DateTime.fromMicrosecondsSinceEpoch(0);
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }

  @override
  void didUpdateWidget(covariant BarcodeScannerListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        HardwareKeyboard.instance.addHandler(_handleKeyEvent);
      } else {
        HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
        _reset();
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _resetTimer?.cancel();
    super.dispose();
  }

  /// Aktif TextField/EditableText varsa kullanıcı yazıyor demek; HID akışını
  /// onlara bırak. POS arama kutusu, dialog, vs. çakışma olmasın.
  bool _shouldHandleKeyEvent() {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return true;
    // EditableText subtree'sinde bir focus varsa = TextField yazıyor
    final ctx = focused.context;
    if (ctx == null) return true;
    final inEditable = ctx.findAncestorStateOfType<EditableTextState>() != null;
    return !inEditable;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final pass = _shouldHandleKeyEvent();
    if (!pass) {
      AppLogger.info(
        'Scanner skip — TextField focus aktif',
        tag: 'BarcodeScanner',
      );
      return false;
    }

    final now = DateTime.now();
    final delta = now.difference(_lastKeyAt);
    _lastKeyAt = now;

    // İki tuş arası timeout aşıldıysa = yeni input başlangıcı, buffer sıfır
    if (delta > widget.interKeyTimeout && _buffer.isNotEmpty) {
      AppLogger.info(
        'Scanner buffer reset (delta ${delta.inMilliseconds}ms > ${widget.interKeyTimeout.inMilliseconds}ms)',
        tag: 'BarcodeScanner',
      );
      _buffer.clear();
    }

    final key = event.logicalKey;

    // Enter / Tab → barkod sonu
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      final code = _buffer.toString().trim();
      _buffer.clear();
      _resetTimer?.cancel();
      AppLogger.info(
        'Scanner suffix (${key.debugName}) — buffer=${code.length}ch "$code"',
        tag: 'BarcodeScanner',
      );
      if (code.length >= widget.minBarcodeLength) {
        widget.onScan(code);
        return true; // event'i yut → başka handler tetiklenmesin
      }
      return false;
    }

    // Karakter logu — printable ASCII
    final ch = event.character;
    if (ch != null && ch.isNotEmpty && ch.codeUnitAt(0) >= 0x20) {
      _buffer.write(ch);
      AppLogger.info(
        'Scanner key "$ch" buffer=${_buffer.length}ch',
        tag: 'BarcodeScanner',
      );
      // Auto-reset (kullanıcı yarıda bıraktıysa buffer sızıntısı olmasın)
      _resetTimer?.cancel();
      _resetTimer = Timer(widget.interKeyTimeout * 5, _reset);
    } else {
      AppLogger.info(
        'Scanner non-char event ${key.debugName} (char=${ch ?? "null"})',
        tag: 'BarcodeScanner',
      );
    }
    return false;
  }

  void _reset() {
    _buffer.clear();
    _resetTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
