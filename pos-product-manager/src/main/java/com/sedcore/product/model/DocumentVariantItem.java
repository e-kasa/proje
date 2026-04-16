package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Bir varyant grubunun tek bir üyesini temsil eder.
 *
 * <p>Örnek: "Beymen Modal XL - 5 adet - 400₺" satırından üretilir.
 * Ana {@link DocumentItemResult}'taki ürün eşleşmesini miras alır;
 * sadece beden/renk ve adete özgü alanlar burada tutulur.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentVariantItem {

    /** Varyant değeri — beden, renk veya diğer özellik. Örn: "XL", "Siyah", "42" */
    private String attributeValue;

    /** Özellik tipi: "SIZE" | "COLOR" | "OTHER" */
    private String attributeType;

    /** Bu varyanta ait miktar */
    private Double quantity;

    /**
     * Bu varyanta ait birim fiyat.
     * {@code null} ise ana {@link DocumentItemResult#getExtractedUnitPrice()} kullanılır.
     */
    private Double unitPrice;

    /** Bu varyanta ait barkod (varsa) */
    private String barcode;

    /** Belgeden alınan ham satır metni */
    private String rawText;
}
