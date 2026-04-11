package com.sedcore.sales.model;

import lombok.Builder;

import java.math.BigDecimal;
import java.util.List;

/**
 * Satış Özeti — Java 25 Record (iç içe record ile)
 */
@Builder
public record SalesSummary(
        Long totalSalesCount,
        BigDecimal totalRevenue,
        BigDecimal averageOrderValue,
        BigDecimal totalPaidAmount,
        BigDecimal totalDebtAmount,
        List<PeriodData> periodData
) {
    /**
     * Dönemsel satış verisi — nested record
     */
    @Builder
    public record PeriodData(
            String period,   // "2026-04-05" veya "2026-04"
            Long salesCount,
            BigDecimal revenue,
            BigDecimal paidAmount
    ) {}
}
