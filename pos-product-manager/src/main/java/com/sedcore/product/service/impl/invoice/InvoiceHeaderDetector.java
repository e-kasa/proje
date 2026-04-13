package com.sedcore.product.service.impl.invoice;

import java.util.*;

/**
 * Fatura metnindeki başlık satırını tespit eder.
 *
 * Strateji: Her satır için bilinen sütun anahtar sözcükleriyle karşılaştırılır.
 * Eşleşen sütun sayısı eşiği (≥ 3) geçerse başlık satırı kabul edilir.
 */
public class InvoiceHeaderDetector {

    /** Sütun tipi → anahtar sözcük listesi (Türkçe + İngilizce) */
    private static final Map<ColumnType, List<String>> KEYWORDS = new LinkedHashMap<>();

    static {
        KEYWORDS.put(ColumnType.ROW_NUMBER, List.of(
                "sıra", "sira", "no", "s.no", "s/n", "#"
        ));
        KEYWORDS.put(ColumnType.CODE, List.of(
                "ürün kodu", "urun kodu", "stok kodu", "part no", "part number",
                "ref.no", "ref no", "oem", "code", "kod", "barkod", "barcode",
                "ürün no", "urun no", "malzeme kodu", "stok no"
        ));
        KEYWORDS.put(ColumnType.DESCRIPTION, List.of(
                "açıklama", "aciklama", "ürün adı", "urun adi", "malzeme",
                "stok adı", "stok adi", "ürün tanımı", "urun tanimi",
                "tanım", "tanim", "description", "item", "parça adı", "parca adi",
                "product name", "ürün", "urun", "mal adı", "mal adi"
        ));
        KEYWORDS.put(ColumnType.QUANTITY, List.of(
                "miktar", "mik", "mik.", "qty", "quantity", "adet", "adt"
        ));
        KEYWORDS.put(ColumnType.UNIT, List.of(
                "birim", "br", "br.", "unit", "uom", "ölçü birimi", "olcu birimi"
        ));
        KEYWORDS.put(ColumnType.UNIT_PRICE, List.of(
                "birim fiyat", "b.fiyat", "b fiyat", "fiyat", "price",
                "unit price", "birim f.", "birim f", "satış fiyatı",
                "satis fiyati", "alış fiyatı", "alis fiyati"
        ));
        KEYWORDS.put(ColumnType.VAT, List.of(
                "kdv", "kdv%", "kdv oranı", "vergi", "tax", "vat", "tax%", "kdv %"
        ));
        KEYWORDS.put(ColumnType.TOTAL, List.of(
                "toplam", "tutar", "total", "genel toplam", "satır tutarı",
                "satir tutari", "line total", "amount"
        ));
    }

    /**
     * Verilen satırın başlık satırı olup olmadığını kontrol eder.
     *
     * @param line Faturadan alınan ham satır
     * @return Eşleşen sütun tipleri seti; boş → başlık değil
     */
    public static Set<ColumnType> detect(String line) {
        if (line == null || line.isBlank()) return Collections.emptySet();

        String lower = line.toLowerCase().trim();
        Set<ColumnType> matched = new LinkedHashSet<>();

        for (Map.Entry<ColumnType, List<String>> entry : KEYWORDS.entrySet()) {
            for (String keyword : entry.getValue()) {
                if (lower.contains(keyword)) {
                    matched.add(entry.getKey());
                    break;
                }
            }
        }

        return matched;
    }

    /**
     * Eşleşme sayısı ≥ 3 ise başlık satırı olarak kabul edilir.
     */
    public static boolean isHeader(String line) {
        return detect(line).size() >= 3;
    }
}
