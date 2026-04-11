package com.sedcore.sales.model;

import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Müşteri Satış Analizi — Java 25 Record
 */
@Builder
public record CustomerSalesAnalysis(
        String customerId,
        String customerName,
        String customerType,
        Long totalPurchases,
        BigDecimal totalSpent,
        BigDecimal averageOrderValue,
        LocalDateTime lastPurchaseDate
) {}
