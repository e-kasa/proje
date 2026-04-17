package com.sedcore.product.service.impl.invoice;

import java.util.*;

/**
 * Fatura / irsaliye / satış notu metnindeki tablo başlık satırını tespit eder.
 *
 * <p>Strateji: Satır küçük harfe çevrilerek her {@link ColumnType} için tanımlı
 * anahtar sözcük listesiyle karşılaştırılır ({@code String.contains} ile).
 * Eşleşen sütun tipi sayısı ≥ {@value #MATCH_THRESHOLD} ise başlık satırı kabul edilir.
 *
 * <p>Desteklenen belge türleri (Türkçe + İngilizce):
 * <ul>
 *   <li>e-Fatura / e-Arşiv Fatura (GİB standardı)</li>
 *   <li>e-İrsaliye / Sevk İrsaliyesi</li>
 *   <li>Proforma Fatura</li>
 *   <li>Satış Notu / Sipariş Fişi / Teklif</li>
 *   <li>Alış Faturası / Tedarikçi Faturası</li>
 *   <li>İngilizce uluslararası faturalar</li>
 *   <li>ERP çıktıları (SAP, Logo, Netsis, Mikro, Luca, Paraşüt, Uyumsoft…)</li>
 * </ul>
 */
public class InvoiceHeaderDetector {

    /** Başlık kabulü için gereken minimum sütun tipi eşleşmesi (normal mod). */
    private static final int MATCH_THRESHOLD = 3;

    /** Gevşek başlık kabulü için minimum sütun tipi eşleşmesi (fallback). */
    private static final int MATCH_THRESHOLD_RELAXED = 2;

    /** Sütun tipi → anahtar sözcük listesi */
    private static final Map<ColumnType, List<String>> KEYWORDS = new LinkedHashMap<>();

    static {

        // ── ROW_NUMBER ────────────────────────────────────────────────────────
        // Satır numarası / sıra numarası sütunu.
        // Türkçe ERP çıktıları, e-Fatura standardı, elle oluşturulmuş belgeler.
        KEYWORDS.put(ColumnType.ROW_NUMBER, List.of(
                // Türkçe
                "sıra no", "sira no", "sıra", "sira",
                "satır no", "satir no",
                "kalem no", "kalem",
                "poz.", "poz", "pozisyon",
                "s.no", "s.n.", "s/n",
                // Kısa
                "no.", "no",
                // İngilizce
                "line no", "line#", "line #", "item no",
                "pos.", "pos", "position",
                "seq", "seq.", "sequence",
                "row", "row no", "#"
        ));

        // ── CODE ──────────────────────────────────────────────────────────────
        // Ürün kodu / barkod / OEM / SKU / stok kodu sütunu.
        // Dikkat: "no" tek başına ROW_NUMBER ile çakışır — burada bileşik ifadeler kullanılır.
        KEYWORDS.put(ColumnType.CODE, List.of(
                // Türkçe — ürün kodu
                "ürün kodu", "urun kodu",
                "ürün no", "urun no",
                "malzeme kodu", "malzeme no",
                "stok kodu", "stok no",
                "parça kodu", "parca kodu",
                "parça no", "parca no",
                "katalog no", "katalog kodu", "kat.no", "kat. no",
                "model kodu", "model no",
                "sipariş kodu", "siparis kodu",
                "referans kodu", "ref kodu",
                "ref.no", "ref no", "ref.",
                // Barkod
                "barkod", "barcode", "barkod no",
                "ean", "ean13", "ean-13",
                "gtin",
                // OEM / Teknik
                "oem", "oem no", "oem kodu",
                "orjinal no", "orijinal no",
                // ERP standartları
                "sku", "article no", "article code", "artikelno", "artikel",
                "item code", "item number",
                "product code", "product no",
                "part no", "part number", "part code",
                "stock code", "stock no",
                // Genel kısa
                "code", "kod"
        ));

        // ── DESCRIPTION ───────────────────────────────────────────────────────
        // Ürün / hizmet adı ve açıklaması sütunu.
        // En geniş keyword seti — farklı belgeler çok farklı isim kullanır.
        KEYWORDS.put(ColumnType.DESCRIPTION, List.of(
                // Türkçe — açıklama
                "açıklama", "aciklama",
                "ürün açıklaması", "urun aciklamasi",
                "mal açıklaması", "mal aciklamasi",
                "kalem açıklaması", "kalem aciklamasi",
                // Türkçe — ürün adı
                "ürün adı", "urun adi",
                "ürün adı/açıklaması", "urun adi aciklamasi",
                "ürün ismi", "urun ismi",
                "ürün bilgisi",
                "ürün tanımı", "urun tanimi",
                "ürün detayı",
                // Türkçe — mal hizmet (e-Fatura / e-Arşiv GİB standardı)
                "mal hizmet", "mal/hizmet",
                "mal ve hizmet", "mal veya hizmet",
                "malın adı", "malin adi",
                "mal adı", "mal adi",
                "mal tanımı", "mal tanimi",
                // Türkçe — hizmet
                "hizmet adı", "hizmet adi",
                "hizmet tanımı", "hizmet tanimi",
                "iş tanımı", "is tanimi",
                // Türkçe — stok
                "stok adı", "stok adi",
                "stok tanımı", "stok tanimi",
                // Türkçe — malzeme
                "malzeme adı", "malzeme adi",
                "malzeme tanımı", "malzeme tanimi",
                "malzeme",
                // Türkçe — parça
                "parça adı", "parca adi",
                "parça tanımı", "parca tanimi",
                // Türkçe — mamul/ürün/kısaltma
                "ürün/hizmet", "urun/hizmet",
                "ürün/malzeme",
                "mamul adı",
                "tanım", "tanim",
                // İngilizce
                "description", "item description",
                "product description", "goods description",
                "product name", "item name",
                "article description", "article name",
                "name", "details", "narrative",
                "service description", "service name",
                "particulars"
        ));

        // ── QUANTITY ──────────────────────────────────────────────────────────
        // Miktar / adet sütunu.
        KEYWORDS.put(ColumnType.QUANTITY, List.of(
                // Türkçe
                "miktar", "miktarı", "miktari",
                "miktar/adet", "adet/miktar",
                "sipariş miktarı", "siparis miktari",
                "teslim miktarı", "teslim miktari",
                "sevk miktarı", "sevk miktari",
                "gönderilen miktar",
                "kalan miktar",
                "iade miktarı", "iade miktari",
                "toplam miktar",
                "adet", "adt",
                "tane",
                "mik.", "mik",
                // İngilizce
                "quantity", "qty", "qty.",
                "q.ty", "q'ty", "q.",
                "pieces", "pcs",
                "count", "no. of units",
                "units", "unit qty",
                "ordered qty", "shipped qty",
                "amount" // bazı İngilizce faturalarda quantity için kullanılır
        ));

        // ── UNIT_PRICE ────────────────────────────────────────────────────────
        // Birim fiyat sütunu.
        // UNIT'ten ÖNCE tanımlanmalı: "Birim Fiyat" hücresi hem "birim" (UNIT) hem
        // "birim fiyat" (UNIT_PRICE) ile eşleşir. LinkedHashMap sırası = öncelik sırası;
        // UNIT_PRICE önce gelirse detect() → iterator().next() doğru tipi döner.
        KEYWORDS.put(ColumnType.UNIT_PRICE, List.of(
                // Türkçe — birim fiyat (bileşik — önce bunlar kontrol edilmeli)
                "birim fiyat", "birim fiyatı", "birim fiyati",
                "birim satış fiyatı", "birim satis fiyati",
                "birim alış fiyatı", "birim alis fiyati",
                "birim liste fiyatı", "birim liste fiyati",
                "birim bedel",
                "b. fiyat", "b.fiyat", "b fiyat",
                "birim f.", "birim f",
                "br. fiyat", "br fiyat",
                "bf",
                // Türkçe — satış fiyatı
                "satış fiyatı", "satis fiyati",
                "satış f.", "satiş f.",
                "liste fiyatı", "liste fiyati",
                "net fiyat",
                "kdv hariç fiyat", "kdv haric fiyat",
                "kdvsiz fiyat",
                // Türkçe — alış fiyatı
                "alış fiyatı", "alis fiyati",
                // Türkçe — genel
                "fiyat", "fiyatı", "fiyati",
                "bedel",
                "değer", "deger",
                // İngilizce
                "unit price", "unit cost",
                "price", "price each",
                "cost", "cost price",
                "selling price", "sales price",
                "rate", "rate per unit",
                "p/u", "u.price", "uprice",
                "list price", "net price"
        ));

        // ── UNIT ──────────────────────────────────────────────────────────────
        // Birim / ölçü birimi sütunu.
        // UNIT_PRICE'tan SONRA tanımlanmalı — "birim" içeren bileşik ifadeler
        // (birim fiyat, birim adı vb.) önce UNIT_PRICE ile eşleşsin.
        KEYWORDS.put(ColumnType.UNIT, List.of(
                // Türkçe
                "birim", "birimi",
                "birim adı", "birim adi",
                "ölçü birimi", "olcu birimi",
                "ölçü", "olcu",
                "ölçü br", "ölçü br.",
                "br.", "br",
                "brm",
                // İngilizce
                "unit", "unit of measure", "uom",
                "measure", "u/m", "u.m.",
                "um"
        ));

        // ── VAT ───────────────────────────────────────────────────────────────
        // KDV oranı veya tutarı sütunu.
        // Dikkat: "kdv tutarı" hem VAT hem TOTAL ile çakışabilir — VAT önce gelir.
        KEYWORDS.put(ColumnType.VAT, List.of(
                // Türkçe — oran
                "kdv oranı", "kdv orani",
                "kdv %", "kdv%",
                "%kdv",
                "vergi oranı", "vergi orani",
                "vergi %", "vergi%",
                "v.%",
                // Türkçe — tutar
                "kdv tutarı", "kdv tutari",
                "kdv bedeli",
                "vergi tutarı", "vergi tutari",
                "vergi bedeli",
                "kdv matrahı", "kdv matrahi",
                // Türkçe — kısa
                "kdv", "vergisi", "vergi",
                // Diğer Türkiye vergileri
                "ötv", "otv", "ötv oranı",
                "stopaj",
                // İngilizce
                "vat", "vat%", "vat rate", "vat amount",
                "tax", "tax%", "tax rate", "tax amount",
                "gst", "hst", "gst/hst",
                "sales tax"
        ));

        // ── TOTAL ─────────────────────────────────────────────────────────────
        // Satır toplamı / tutar sütunu.
        // TableRowParser'da "en sağdaki kazanır" kuralı → iskonto tutarı değil asıl toplam alınır.
        KEYWORDS.put(ColumnType.TOTAL, List.of(
                // Türkçe — satır tutarı
                "satır tutarı", "satir tutari",
                "satır toplamı", "satir toplami",
                "satır bedeli", "satir bedeli",
                "kalem tutarı", "kalem tutari",
                "kalem toplamı", "kalem toplami",
                // Türkçe — mal hizmet tutarı (e-Fatura GİB)
                "mal hizmet tutarı", "mal hizmet tutari",
                "mal tutarı", "mal tutari",
                "hizmet tutarı", "hizmet tutari",
                // Türkçe — net / brüt
                "net tutar", "net toplam",
                "brüt tutar", "brut tutar",
                "kdv dahil tutar", "kdv dahil toplam",
                "kdv dahil",
                "toplam tutar",
                "toplam fiyat", "toplam bedel",
                "toplam değer", "toplam deger",
                "uzatılmış tutar", "uzatilmis tutar",
                "uzatma",
                "fatura tutarı", "fatura tutari",
                // Türkçe — kısa
                "tutar", "toplam",
                "t. tutar", "t.tutar",
                "tt",
                // İngilizce
                "line total", "line amount",
                "total price", "total amount",
                "ext. price", "ext price",
                "extended price", "extended amount",
                "net amount", "gross amount",
                "amount due",
                "total", "amount",
                "subtotal"
        ));
    }

    /**
     * Verilen satırdaki anahtar sözcüklere göre eşleşen {@link ColumnType} setini döner.
     *
     * @param line ham satır metni (büyük/küçük harf duyarsız)
     * @return eşleşen sütun tipleri; boş set → başlık değil
     */
    public static Set<ColumnType> detect(String line) {
        if (line == null || line.isBlank()) return Collections.emptySet();

        String lower = line.toLowerCase().trim();
        Set<ColumnType> matched = new LinkedHashSet<>();

        for (Map.Entry<ColumnType, List<String>> entry : KEYWORDS.entrySet()) {
            for (String keyword : entry.getValue()) {
                if (lower.contains(keyword)) {
                    matched.add(entry.getKey());
                    break; // bu tip eşleşti, sonraki tipe geç
                }
            }
        }

        return matched;
    }

    /**
     * Eşleşen sütun tipi sayısı ≥ {@value #MATCH_THRESHOLD} ise başlık satırı (katı mod).
     */
    public static boolean isHeader(String line) {
        return detect(line).size() >= MATCH_THRESHOLD;
    }

    /**
     * Gevşek başlık tespiti: ≥ {@value #MATCH_THRESHOLD_RELAXED} sütun tipi eşleşmesi yeterli.
     *
     * <p>Sade fatura formatlarında (örn: yalnızca "Ürün Adı | Adet | Fiyat" gibi 2 sütunlu)
     * katı mod başlık bulamazsa bu metod fallback olarak kullanılır.
     */
    public static boolean isHeaderRelaxed(String line) {
        return detect(line).size() >= MATCH_THRESHOLD_RELAXED;
    }
}
