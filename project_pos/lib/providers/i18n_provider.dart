import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/app_logger.dart';
import '../services/i18n_service.dart';
import '../services/service_locator.dart';

// ── State ───────────────────────────────────────────────────────────────────
class I18nState {
  final String lang;
  final Map<String, String> messages;
  final Map<String, String> bundles;
  final bool isLoading;

  const I18nState({
    this.lang = 'TR',
    this.messages = const {},
    this.bundles = const {},
    this.isLoading = false,
  });

  /// Mesaj kodundan cevirilmis metni doner. Bulunamazsa kodu doner.
  String msg(String code) => messages[code] ?? code;

  /// Bundle kodundan cevirilmis metni doner. Bulunamazsa kodu doner.
  String bundle(String code) => bundles[code] ?? code;

  bool get isLoaded => messages.isNotEmpty;

  I18nState copyWith({
    String? lang,
    Map<String, String>? messages,
    Map<String, String>? bundles,
    bool? isLoading,
  }) {
    return I18nState(
      lang: lang ?? this.lang,
      messages: messages ?? this.messages,
      bundles: bundles ?? this.bundles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Notifier ────────────────────────────────────────────────────────────────
class I18nNotifier extends StateNotifier<I18nState> {
  final I18nService _service;

  I18nNotifier(this._service) : super(const I18nState());

  /// Backend'den tum cevirileri yukler ve cache'ler.
  Future<void> loadTranslations({String lang = 'TR'}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.getAllTranslations(lang: lang);

      final messagesRaw = data['messages'] as Map<String, dynamic>? ?? {};
      final bundlesRaw = data['bundles'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        lang: lang,
        messages: messagesRaw.map((k, v) => MapEntry(k, v.toString())),
        bundles: bundlesRaw.map((k, v) => MapEntry(k, v.toString())),
        isLoading: false,
      );
      AppLogger.info('i18n yuklendi: ${state.messages.length} mesaj, ${state.bundles.length} bundle', tag: 'I18n');
    } catch (e) {
      AppLogger.error('i18n yuklenemedi', tag: 'I18n', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Dili degistir ve yeniden yukle.
  Future<void> changeLanguage(String lang) async {
    await loadTranslations(lang: lang);
  }
}

// ── Provider ────────────────────────────────────────────────────────────────
final i18nProvider = StateNotifierProvider<I18nNotifier, I18nState>((ref) {
  final service = ref.watch(i18nServiceProvider);
  return I18nNotifier(service);
});
