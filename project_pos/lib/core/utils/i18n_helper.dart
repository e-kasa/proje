import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/i18n_provider.dart';

/// i18n bundle cozumleme extension'i.
///
/// Kullanim:
/// ```dart
/// // ConsumerWidget/ConsumerState icinde:
/// final t = ref.watch(i18nProvider).bundle;
/// Text(t('pos.title'))  // → "POS Satış Paneli" (TR) / "POS Sales Panel" (EN)
/// Text(t('common.save')) // → "Kaydet" (TR) / "Save" (EN)
/// ```
///
/// Bundle kodu bulunamazsa kodu oldugu gibi doner.
/// i18n yuklenmemisse kodu doner (fallback).

/// WidgetRef uzerinden kisa erisim icin helper fonksiyon.
/// ConsumerWidget veya ConsumerState icinde kullanilir.
///
/// ```dart
/// final t = i18nOf(ref);
/// Text(t('common.save'))
/// ```
String Function(String) i18nOf(WidgetRef ref) {
  final state = ref.watch(i18nProvider);
  return (String code) => state.bundle(code);
}

/// Mesaj kodlarini cozumlemek icin helper.
/// Backend hata mesajlari icin kullanilir.
///
/// ```dart
/// final msg = i18nMsgOf(ref);
/// Text(msg('1004'))  // → "Bu kayıt zaten mevcut"
/// ```
String Function(String) i18nMsgOf(WidgetRef ref) {
  final state = ref.watch(i18nProvider);
  return (String code) => state.msg(code);
}
