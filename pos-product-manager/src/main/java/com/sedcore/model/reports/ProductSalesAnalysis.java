package com.sedcore.model.reports;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductSalesAnalysis {
    private String variantId;
    private String variantSku;
    private String variantName;
    private String productName;
    private String categoryName;
    private Integer quantitySold;
    private BigDecimal totalRevenue;
    private BigDecimal averageUnitPrice;
}
