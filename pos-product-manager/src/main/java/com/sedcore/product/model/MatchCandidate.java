package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Doküman analizi NAME eşleşmesinde alternatif aday.
 * Kullanıcı "yanlış ürün" derse sheet UI'dan başka bir aday seçebilir.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MatchCandidate {
    private String productId;
    private String variantId;
    private String productName;
    private String sku;
    private BigDecimal salePrice;
    private Double currentStock;
    /** 0.3-0.6 arası — NAME match için kaba benzerlik skoru */
    private Double confidence;
}
