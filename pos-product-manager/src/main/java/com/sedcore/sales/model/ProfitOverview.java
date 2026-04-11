package com.sedcore.sales.model;

import lombok.Builder;

import java.math.BigDecimal;

/**
 * Kar/Zarar Özeti — Java 25 Record
 * Değiştirilemez (immutable) veri taşıyıcı; Lombok @Builder desteği ile.
 */
@Builder
public record ProfitOverview(
        BigDecimal totalRevenue,
        BigDecimal totalCost,
        BigDecimal grossProfit,
        BigDecimal profitMarginPercent,
        Long totalSalesCount,
        Long totalPurchaseCount
) {}
