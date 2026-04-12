package com.sedcore.product.model;

import com.sedcore.autoparts.model.CrossReferenceRequest;
import com.sedcore.autoparts.model.OemNumberRequest;
import lombok.*;

import java.util.List;

/**
 * Toplu ürün girişinde yeni ürün kalemi.
 * Flutter'dan gelen her BatchEntryRow (yeni ürün) bu DTO'ya map'lenir.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchProductItem {

    /**
     * Flutter tarafında BatchEntryRow.id değeri.
     * Sonuçları satırlara geri eşlemek için kullanılır.
     */
    private String tempId;

    private ProductRequest product;

    private List<ProductVariantRequest> variants;

    private List<OemNumberRequest> oemNumbers;

    private List<CrossReferenceRequest> crossReferences;
}
