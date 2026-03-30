package com.sedcore.model.stats;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * Gelir grafiği verisi — periyot bazında gelir ve sipariş trendi.
 * Frontend ApexCharts area/bar chart için kullanılır.
 */
@Data
@Builder
public class RevenueDataResponse {

    /** Periyot: "daily" | "weekly" | "monthly" | "yearly" */
    private String period;

    /** X ekseni etiketleri (örn. ["Oca", "Şub", "Mar"]) */
    private List<String> labels;

    /** Gelir serisi — labels ile aynı boyutta */
    private List<BigDecimal> revenue;

    /** Sipariş sayısı serisi */
    private List<Long> orders;

    /** Gider serisi */
    private List<BigDecimal> expenses;
}
