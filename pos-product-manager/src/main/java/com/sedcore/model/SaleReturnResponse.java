package com.sedcore.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Satış İade Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SaleReturnResponse {

    private String saleId;
    private String saleNumber;
    private String customerName;
    private String reason;
    private String reasonLabel;
    private String notes;
    private BigDecimal totalReturnAmount;
    private LocalDateTime returnDate;
    private List<ReturnItemResponse> items;
    private String message;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ReturnItemResponse {
        private String variantId;
        private String variantSku;
        private String productName;
        private Integer quantity;
        private BigDecimal unitPrice;
        private BigDecimal lineTotal;
    }
}
