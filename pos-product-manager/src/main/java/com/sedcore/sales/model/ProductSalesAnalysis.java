package com.sedcore.sales.model;

import lombok.Builder;

import java.math.BigDecimal;

/**
 * Ürün Satış Analizi — Java 25 Record
 */
@Builder
public record ProductSalesAnalysis(
        String variantId,
        String variantSku,
        String variantName,
        String productName,
        String categoryName,
        Integer quantitySold,
        BigDecimal totalRevenue,
        BigDecimal averageUnitPrice
) {}
