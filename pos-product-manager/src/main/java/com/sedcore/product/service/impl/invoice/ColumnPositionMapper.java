package com.sedcore.product.service.impl.invoice;

import java.util.*;

/**
 * Başlık satırındaki her sütunun karakter offset'ini tespit eder.
 *
 * Örnek başlık:
 *   "Sıra  Ürün Kodu  Açıklama          Miktar  Birim  Birim Fiyat  KDV%  Toplam"
 *    0     6          17                 35      43     50           62    67
 *
 * Her ColumnType → (startOffset, endOffset) aralığı.
 */
public class ColumnPositionMapper {

    /** Sütun tipi → başlangıç ve bitiş karakter offset'i */
    private final List<ColumnBounds> bounds = new ArrayList<>();

    /** Sütun → karakter sınırları */
    public record ColumnBounds(ColumnType type, int start, int end) {}

    /**
     * Başlık satırını analiz ederek sütun pozisyonlarını hesaplar.
     *
     * @param headerLine   Tespit edilen başlık satırı
     * @param matchedTypes InvoiceHeaderDetector'ın döndürdüğü eşleşen sütun tipleri
     */
    public ColumnPositionMapper(String headerLine, Set<ColumnType> matchedTypes) {
        if (headerLine == null || matchedTypes.isEmpty()) return;

        String lower = headerLine.toLowerCase();
        Map<ColumnType, List<String>> KEYWORDS = buildKeywordMap();

        // Her eşleşen sütun tipi için başlık satırında arama yap
        Map<ColumnType, Integer> startPositions = new LinkedHashMap<>();
        for (ColumnType type : matchedTypes) {
            List<String> keywords = KEYWORDS.getOrDefault(type, List.of());
            for (String kw : keywords) {
                int idx = lower.indexOf(kw);
                if (idx >= 0) {
                    startPositions.put(type, idx);
                    break;
                }
            }
        }

        // Start offset'e göre sırala
        List<Map.Entry<ColumnType, Integer>> sorted = new ArrayList<>(startPositions.entrySet());
        sorted.sort(Map.Entry.comparingByValue());

        // Her sütunun bitiş offset'i = bir sonraki sütunun başlangıcı - 1 (veya satır sonu)
        for (int i = 0; i < sorted.size(); i++) {
            int start = sorted.get(i).getValue();
            int end = (i + 1 < sorted.size())
                    ? sorted.get(i + 1).getValue()
                    : headerLine.length();
            bounds.add(new ColumnBounds(sorted.get(i).getKey(), start, end));
        }
    }

    /**
     * Veri satırından belirtilen sütun değerini çıkarır.
     * ±2 karakter tolerans uygulanır.
     *
     * @param dataLine  Başlık satırı hizasındaki veri satırı
     * @param type      İstenen sütun tipi
     * @return Çıkarılan değer (trim edilmiş) veya null
     */
    public String extract(String dataLine, ColumnType type) {
        if (dataLine == null) return null;

        for (ColumnBounds b : bounds) {
            if (b.type() == type) {
                int start = Math.max(0, b.start() - 2);
                int end = Math.min(dataLine.length(), b.end() + 2);
                if (start >= end) return null;
                String val = dataLine.substring(start, end).trim();
                return val.isEmpty() ? null : val;
            }
        }
        return null;
    }

    public boolean isEmpty() {
        return bounds.isEmpty();
    }

    private Map<ColumnType, List<String>> buildKeywordMap() {
        Map<ColumnType, List<String>> m = new LinkedHashMap<>();
        m.put(ColumnType.ROW_NUMBER, List.of("sıra", "sira", "no", "s.no", "#"));
        m.put(ColumnType.CODE, List.of(
                "ürün kodu", "urun kodu", "stok kodu", "part no", "part number",
                "ref.no", "ref no", "oem", "code", "kod", "barkod", "barcode",
                "ürün no", "urun no", "malzeme kodu", "stok no"
        ));
        m.put(ColumnType.DESCRIPTION, List.of(
                "açıklama", "aciklama", "ürün adı", "urun adi", "malzeme",
                "stok adı", "stok adi", "tanım", "tanim", "description",
                "item", "parça adı", "parca adi", "product name", "ürün", "urun"
        ));
        m.put(ColumnType.QUANTITY, List.of("miktar", "mik.", "mik", "qty", "quantity", "adet", "adt"));
        m.put(ColumnType.UNIT, List.of("birim", "br.", "br", "unit", "uom", "ölçü birimi"));
        m.put(ColumnType.UNIT_PRICE, List.of(
                "birim fiyat", "b.fiyat", "b fiyat", "fiyat", "price",
                "unit price", "birim f."
        ));
        m.put(ColumnType.VAT, List.of("kdv%", "kdv %", "kdv oranı", "kdv", "tax%", "vat"));
        m.put(ColumnType.TOTAL, List.of("toplam", "tutar", "total", "genel toplam", "amount"));
        return m;
    }
}
