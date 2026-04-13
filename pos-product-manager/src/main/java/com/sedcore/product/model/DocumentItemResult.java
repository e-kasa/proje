package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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
}
