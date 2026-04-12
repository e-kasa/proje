package com.sedcore.product.model;

import lombok.*;

/**
 * Toplu giriş sonucunda tek kalem sonucu.
 * Flutter tempId ile satırları eşler, başarı/hata durumunu gösterir.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchItemResult {

    /** Flutter tarafındaki BatchEntryRow.id */
    private String tempId;

    private boolean success;

    /** Oluşturulan ürün ID (yeni ürünlerde) */
    private String productId;

    /** Oluşturulan/mevcut varyant ID */
    private String variantId;

    /** Hata mesajı (success=false ise dolu) */
    private String message;
}
