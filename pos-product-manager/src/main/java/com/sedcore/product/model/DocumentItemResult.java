package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Fatura/İrsaliye belgesinden analiz edilen tek bir ürün kalemi.
 * matchStatus: "FOUND" → sistemde var, "NOT_FOUND" → sistemde yok
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentItemResult {

    /** Belgede kaçıncı satır */
    private int rowIndex;

    /** Ham metin — belgeden olduğu gibi alınan satır */
    private String rawText;

    /** Belgeden çıkarılan ürün adı */
    private String extractedName;

    /** Belgeden çıkarılan kod (barkod EAN13 veya OEM numarası) */
    private String extractedCode;

    /** Belgeden çıkarılan miktar */
    private Double extractedQuantity;

    /** Belgeden çıkarılan birim fiyat */
    private Double extractedUnitPrice;

    /** FOUND veya NOT_FOUND */
    private String matchStatus;

    /** Eşleşen ürün ID'si (matchStatus=FOUND ise dolu) */
    private String matchedProductId;

    /** Eşleşen varyant ID'si (matchStatus=FOUND ise dolu) */
    private String matchedVariantId;

    /** Eşleşen ürünün sistemdeki adı */
    private String matchedProductName;

    /** Eşleşen varyantın SKU'su */
    private String matchedSku;

    /** Eşleşme tipi: BARCODE, OEM, NAME */
    private String matchType;

    /** Eşleşen varyantın mevcut stok miktarı */
    private Double matchedCurrentStock;

    /** Belgeden çıkarılan birim (ADET, KG, LT, MT vb.) */
    private String unit;

    /** Belgeden çıkarılan KDV oranı (8.0, 18.0, 20.0 vb.) */
    private Double vatRate;

    /** KDV dahil mi? (null = bilinmiyor) */
    private Boolean vatIncluded;

    /** Satır toplamı (miktar × birim fiyat veya belgeden çıkarılan) */
    private Double totalPrice;

    /** Eşleşme güven skoru: BARCODE=1.0, OEM=0.9, NAME=0.5, NOT_FOUND=0.0 */
    private Double matchConfidence;

    /**
     * Uyarı bayrakları.
     * Olası değerler: "NAME_MATCH_UNCERTAIN", "PRICE_MISMATCH", "NO_PRICE",
     * "DUPLICATE_MERGED", "VARIANT_GROUP", "OCR_PROCESSED"
     */
    private List<String> warningFlags;

    // ── Varyant grup alanları ─────────────────────────────────────────────────

    /**
     * true → bu satır birden fazla varyantın gruplanmış halidir (Durum 2).
     * false → tekil ürün (Durum 1).
     */
    private boolean variantGroup;

    /**
     * Varyant alt satırları. Yalnızca {@code variantGroup=true} olduğunda dolu.
     * Her bir {@link DocumentVariantItem} tek bir beden/renk kombinasyonunu temsil eder.
     */
    private List<DocumentVariantItem> variants;
}
