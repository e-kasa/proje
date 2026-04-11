package com.sedcore.sales.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerSalesAnalysis {
    private String customerId;
    private String customerName;
    private String customerType;
    private Long totalPurchases;
    private BigDecimal totalSpent;
    private BigDecimal averageOrderValue;
    private LocalDateTime lastPurchaseDate;
}
