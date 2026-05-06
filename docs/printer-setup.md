# POSA / Termal Yazıcı — Windows Kurulum Rehberi

SEDCORE POS uygulamasında fiş veya etiket basabilmek için termal yazıcının (POSA, Zjiang, Xprinter benzeri) **Windows'a yazıcı olarak yüklü olması** gerekir.

Bu rehber, *"USB Cihazları Tara"* tıkladığında listede yalnız **"Microsoft Print to PDF"** görünüyorsa ya da listede hiçbir cihaz çıkmıyorsa nasıl çözeceğinizi anlatır.

> 📌 Bu rehber Sprint 29-fix-5 sırasında [`printer_settings_screen.dart`](../project_pos/lib/features/settings/screens/printer_settings_screen.dart) ekranındaki bilgi banner'ının uzantısıdır. Wiki: [Sprint 29-fix-5 log entry](../.wiki/log.md).

---

## Neden Bu Rehbere İhtiyacın Var?

Uygulama, USB yazıcıları **doğrudan USB taramasıyla değil**, Windows'un **kayıtlı yazıcı listesi** üzerinden bulur (`flutter_pos_printer_platform_image_3` paketi `EnumPrintersW` kullanıyor). Yani:

- ❌ POSA yazıcıyı USB'ye taktın → uygulamada **görünmez** (Windows'a kayıtlı değilse)
- ✅ POSA'yı Windows'a yazıcı olarak yükledin → uygulamada **görünür** (gerçek baskı RAW ESC/POS)

Sanal yazıcılar (PDF/OneNote/Fax) `print_service.dart`'taki `_virtualPrinterPatterns` blacklist'i ile filtrelenir, listede görünmez.

---

## 1. Tanı — POSA Görünüyor mu?

### Aygıt Yöneticisi Kontrolü

1. `Win + X` → **Aygıt Yöneticisi**
2. **"Yazıcı kuyrukları"** veya **"Yazıcılar"** dalını aç
3. POSA / Zjiang / Xprinter gibi bir kayıt var mı?

| Durum | Anlamı | Bir sonraki adım |
|---|---|---|
| Yazıcılar dalında **var** ✅ | Windows yazıcıyı tanımış | Bölüm 4'e geç (Uygulamada doğrula) |
| **"Belirsiz USB cihazı"** veya sarı ünlem | Driver eksik | Bölüm 3 (Manuel kurulum) |
| **Hiç görünmüyor** | USB tanınmıyor | Bölüm 2 (Plug & Play deneme) |

### Windows Ayarlar Kontrolü

`Win + I` → **Bluetooth ve cihazlar** → **Yazıcılar ve tarayıcılar**

Listede POSA varsa → **Bölüm 4**. Yoksa → **Bölüm 2**.

---

## 2. Yöntem A: Plug & Play (Otomatik)

Windows 10/11 çoğu termal yazıcıyı otomatik tanır.

### Adımlar

1. POSA cihazının **gücünü kapat**
2. USB kablosunu PC'ye tak (USB hub değil, **doğrudan PC portuna**; tercihen USB 2.0 portu)
3. POSA cihazının **gücünü aç**
4. Sağ alt köşede *"Yeni cihaz yükleniyor..."* bildirimi bekle (~30 sn)
5. Bildirim *"Cihazınız hazır"* derse → **Bölüm 4**
6. Bildirim çıkmadıysa veya *"Yüklenemedi"* dediyse → **Bölüm 3 (Manuel)**

### Sorun Giderme

| Belirti | Neden | Çözüm |
|---|---|---|
| `device descriptor request failed` | USB kablosu bozuk veya port arızalı | Farklı kablo/port dene |
| Sağ alt *"Cihaz hazırlanırken hata"* | Driver Windows Update'te yok | Bölüm 3'e geç |
| Yazıcı her takışta yeni COM portu açıyor | Termal yazıcı sürücüsüz mod ('serial') çalışıyor | Bölüm 3'te **Generic / Text Only** seç |

---

## 3. Yöntem B: Manuel Kurulum (Generic / Text Only)

Plug & Play başarısız olduysa, ESC/POS protokolü için Windows'un yerleşik **Generic / Text Only** sürücüsünü kullan.

### Adımlar

1. `Win + I` → **Bluetooth ve cihazlar** → **Yazıcılar ve tarayıcılar**
2. Sağ üst **"Cihaz ekle"** tıkla
3. *"İstediğim yazıcı listede yok"* linkine tıkla
4. **"Manuel ayarlarla yerel yazıcı veya ağ yazıcısı ekle"** seç → **İleri**
5. **"Mevcut bir bağlantı noktası kullan"**: USB001 (Sanal yazıcı bağlantı noktası) seç
   - Eğer USB001 yoksa → **"Yeni bir bağlantı noktası oluştur"** → tür: **Standart TCP/IP Yazıcı Bağlantı Noktası** DEĞİL — *"Local Port"* seç → ad: `POSA_USB`
   - Sonra **İleri**
6. Sürücü seçim ekranında:
   - **Üretici:** `Generic`
   - **Yazıcılar:** `Generic / Text Only`
   - **İleri**
7. Mevcut sürücü kullan → **İleri**
8. **Yazıcı adı:** `POSA-80` (veya istediğin ad — uygulama listede bu adı gösterecek)
9. **"Bu yazıcıyı paylaşma"** seç → **İleri**
10. **"Varsayılan yazıcı olarak ayarlama"** (önemli — sanal PDF varsayılan kalsın istemiyorsun ama POSA da varsayılan olmasın)
11. **"Test sayfası yazdır"** TIKLAMA (ESC/POS yerine düz metin gönderir, kağıt yenir) → **Son**

### Test

Test sayfası basmadan, doğrudan uygulama içinden test et (Bölüm 4).

---

## 4. Uygulamada Doğrula

1. SEDCORE POS'u aç → **Ayarlar → Cihazlar & Entegrasyonlar**
2. **"Fiş Yazıcı"** veya **"Etiket Yazıcı"** kartına tıkla
3. **"USB Cihazları Tara"** butonuna bas
4. Listede `POSA-80` (veya yazıcı adın) görünmeli
5. Tıkla → "Yazıcı seçildi" toast
6. **"Test Yazdır"** butonuna bas
7. Termal yazıcıdan **örnek fiş/etiket** çıkmalı

### Beklenen Çıktı (Fiş Yazıcı için)

```
SEDCORE POS
TEST YAZDIRMA
====================
Tarih: 06.05.2026 ...
Bu bir test fişidir.

Bağlantı: ✓
Codepage: CP857 (TR)
====================

```

(Türkçe karakterler ASCII'ye dönüştürülür — bu beklenen davranış, Sprint 22 [integrations-hub-architecture](../.wiki/syntheses/integrations-hub-architecture.md).)

---

## 5. Sık Karşılaşılan Sorunlar

### A. *"Bulunan Cihazlar (1) — Microsoft Print to PDF"*

**Sebep:** POSA Windows'a yüklenmemiş; sadece sanal yazıcı kayıtlı.

**Çözüm:** Bölüm 2 (Plug & Play) veya Bölüm 3 (Manuel kurulum).

> ℹ️ Sprint 29-fix-5 ile sanal yazıcılar (Print to PDF, OneNote, Fax, FeedMe POS Print Job) tarama listesinden filtrelenir. Listede tek başına Microsoft Print to PDF görüyorsanız bu eski bir build'tir — `flutter clean && flutter pub get` ile yeniden derleyin.

### B. *"USB yazıcı yapılandırılmamış. Ayarlar..."* toast (Sprint 29-fix-6)

**Sebep:** Hiç yazıcı seçilmemiş veya eski kayıt sanal yazıcıydı (otomatik temizlendi).

**Çözüm:** Bu rehberin tüm adımları + Bölüm 4 (Uygulamada Doğrula).

### C. Test yazdırma çalıştı ama Türkçe karakter `?` veya bozuk geliyor

**Sebep:** Yazıcı codepage CP857 (Türkçe) desteklemiyor — `_ascii()` helper Türkçe karakterleri (`ş, ç, ğ, ü, ö, İ`) ASCII karşılıklarına dönüştürür.

**Çözüm:** Beklenen davranış. Yazıcı codepage destekliyorsa [`receipt_template.dart`](../project_pos/lib/services/print/receipt_template.dart) `setGlobalCodeTable('CP857')` aktif edilebilir; varsayılan ASCII güvenli.

### D. Uzun fişin yarısında durdu / kağıt yenmedi

**Sebep:** Cihaz buffer dolu veya USB hub güç düşürüyor.

**Çözüm:**
1. POSA'yı USB hub'tan çıkar, **doğrudan PC USB portuna** tak
2. Yazıcı self-test (genellikle güç açılırken `FEED` butonu basılı tutulur) → uzun şerit basıyorsa donanım sağlam
3. Hâlâ olmuyorsa → farklı USB kablosu

### E. Aynı POSA hem fiş hem etiket olarak kayıtlı + sadece bir tanesi basıyor

**Sebep:** İki slot bağımsız `vendorId/productId` kaydı tutar; Windows print queue'da paralel iki job sırasında **race** olabilir.

**Çözüm:** Tek POSA kullanan KOBİ senaryosunda **yalnız bir slota** kayıt tut (örneğin Fiş Yazıcı). Etiket basma akışı (Sprint 29-fix-2 Case 1.5) otomatik fiş yazıcısını reuse eder. Bu davranış [label-printer-architecture](../.wiki/syntheses/label-printer-architecture.md) K6'da belgelendi.

---

## 6. POSA Yazıcı Üreticisinden Resmi Driver

Üretici tarafından sağlanan resmi sürücü kuracaksanız:

1. POSA üretici sitesi → **Driver / Sürücü** bölümü
2. Modelinize uygun Windows 10/11 sürücüsünü indir
3. `.exe` çalıştır → varsayılan ayarlarla kur
4. Bölüm 4 (Uygulamada Doğrula) ile test et

**Tavsiye:** Generic / Text Only (Bölüm 3) çoğu termal yazıcıda sorunsuz çalışır ve update riski yoktur. Üretici sürücüsü ekstra fonksiyon (örn. cash drawer kick) sağlar — bu özellikleri kullanmıyorsanız Generic yeterli.

---

## İlgili

- Wiki audit: [printer-integrations-i18n-audit](../.wiki/sources/code-refs/2026-05-01-printer-integrations-i18n-audit.md)
- Wiki synthesis: [integrations-hub-architecture](../.wiki/syntheses/integrations-hub-architecture.md)
- Manuel test rehberi: [label-printer-manual-test-guide](../.wiki/sources/code-refs/2026-05-01-label-printer-manual-test-guide.md)
- Sprint 29-fix-5 log: [.wiki/log.md](../.wiki/log.md) (Sanal Yazıcı Filtreleme + Windows Kurulum Rehberi)
- Kod: [`print_service.dart`](../project_pos/lib/services/print/print_service.dart), [`label_print_service.dart`](../project_pos/lib/services/print/label_print_service.dart)

---

**Son güncelleme:** 2026-05-06 (Sprint 30 backlog kalemi — wiki workflow)
