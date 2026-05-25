package com.sedcore.sales.model;

import lombok.Builder;

import java.math.BigDecimal;
import java.util.List;

/**
 * Satış Özeti — Java 25 Record (iç içe record ile).
 *
 * <p>Sprint 2026-05-25: KDV/ÖTV/iskonto ayrı raporlanır.
 * {@code totalRevenue} = nihai (vergi dahil) tutar; {@code totalVat/totalOtv/totalDiscount}
 * ondan ayrıştırılan parçalardır. {@code totalRevenue - totalVat - totalOtv} ≈ KDV/ÖTV hariç ciro.
 */
@Builder
public record SalesSummary(
        Long totalSalesCount,
        BigDecimal totalRevenue,
        BigDecimal averageOrderValue,
        BigDecimal totalPaidAmount,
        BigDecimal totalDebtAmount,
        /** Σ Sale.totalTax — KDV. */
        BigDecimal totalVat,
        /** Σ Sale.totalOtv — ÖTV. */
        BigDecimal totalOtv,
        /** Σ Sale.totalDiscount — kalem iskontoları toplamı. */
        BigDecimal totalDiscount,
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
            BigDecimal paidAmount,
            /** Dönem KDV toplamı — Sprint 2026-05-25. */
            BigDecimal vat,
            /** Dönem ÖTV toplamı. */
            BigDecimal otv
    ) {}
}
