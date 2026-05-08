import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 30 — Kullanıcı gizleme listesi (aktif olmayan yazıcılar).
///
/// Sprint 29-fix-5 sanal yazıcı filtresi (`microsoft print to pdf`, `onenote`,
/// vb.) kalıcı blacklist. Bu provider ise **kullanıcı-yönetimli** ek filtre:
/// listede gözükmesini istemediği eski/dummy cihazları gizler.
///
/// `PrintService.discoverDevices()` ve `LabelPrintService.discoverDevices()`
/// her iki listeden filtrelenir → POS satış akışı + etiket basma akışı için
/// ortak.
///
/// Anahtar: cihaz adı (case-insensitive). Windows EnumPrintersW name'e göre
/// kaydeder; aynı cihaz farklı sürücüyle yeniden kurulursa farklı name alır
/// → o durumda zaten yeni cihaz gibi davranır (gizli kalmaz, doğru).
class HiddenPrinters {
  final Set<String> hiddenNames;
  final bool loaded;

  const HiddenPrinters({
    this.hiddenNames = const {},
    this.loaded = false,
  });

  bool isHidden(String deviceName) {
    return hiddenNames.contains(deviceName.toLowerCase().trim());
  }

  HiddenPrinters copyWith({
    Set<String>? hiddenNames,
    bool? loaded,
  }) {
    return HiddenPrinters(
      hiddenNames: hiddenNames ?? this.hiddenNames,
      loaded: loaded ?? this.loaded,
    );
  }
}

class HiddenPrintersNotifier extends StateNotifier<HiddenPrinters> {
  HiddenPrintersNotifier() : super(const HiddenPrinters());

  static const _kHiddenNames = 'print.hidden_printer_names';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kHiddenNames) ?? const [];
    state = HiddenPrinters(
      hiddenNames: list.map((n) => n.toLowerCase().trim()).toSet(),
      loaded: true,
    );
  }

  Future<void> hide(String deviceName) async {
    final key = deviceName.toLowerCase().trim();
    if (key.isEmpty || state.hiddenNames.contains(key)) return;
    final next = {...state.hiddenNames, key};
    state = state.copyWith(hiddenNames: next);
    await _persist();
  }

  Future<void> unhide(String deviceName) async {
    final key = deviceName.toLowerCase().trim();
    if (!state.hiddenNames.contains(key)) return;
    final next = {...state.hiddenNames}..remove(key);
    state = state.copyWith(hiddenNames: next);
    await _persist();
  }

  Future<void> clearAll() async {
    if (state.hiddenNames.isEmpty) return;
    state = state.copyWith(hiddenNames: const {});
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kHiddenNames, state.hiddenNames.toList());
  }
}

final hiddenPrintersProvider =
    StateNotifierProvider<HiddenPrintersNotifier, HiddenPrinters>(
  (ref) => HiddenPrintersNotifier()..load(),
);
