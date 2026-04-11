package com.sedcore.sales.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SalesSummary {
    private Long totalSalesCount;
    private BigDecimal totalRevenue;
    private BigDecimal averageOrderValue;
    private BigDecimal totalPaidAmount;
    private BigDecimal totalDebtAmount;
    private List<PeriodData> periodData;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PeriodData {
        private String period; // "2026-04-05" or "2026-04"
        private Long salesCount;
        private BigDecimal revenue;
        private BigDecimal paidAmount;
    }
}
