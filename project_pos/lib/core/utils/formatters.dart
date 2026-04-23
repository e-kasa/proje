import 'package:intl/intl.dart';

/// Tüm cari/tutar gösteriminde kullanılacak ortak TL formatlayıcı.
final NumberFormat appCurrencyFmt =
    NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

/// Backend'den ISO `2026-04-23T...` veya `2026-04-23` formatında gelen tarih
/// string'lerinin sadece `YYYY-MM-DD` kısmını döndürür.
String shortDateString(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  return raw.length >= 10 ? raw.substring(0, 10) : raw;
}
