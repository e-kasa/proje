package com.sedcore.inventory.model;

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
public class StockValueSummary {
    private BigDecimal totalStockValue;
    private Long totalSkuCount;
    private BigDecimal averageItemValue;
    private List<WarehouseBreakdown> warehouseBreakdowns;
    private List<CategoryBreakdown> categoryBreakdowns;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WarehouseBreakdown {
        private String warehouseId;
        private String warehouseName;
        private Long itemCount;
        private Integer totalQuantity;
        private BigDecimal totalValue;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryBreakdown {
        private String categoryId;
        private String categoryName;
        private Long itemCount;
        private Integer totalQuantity;
        private BigDecimal totalValue;
    }
}
