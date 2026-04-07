package com.sedcore.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Satış İade Request DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SaleReturnRequest {

    private String reason;
    private String reasonLabel;
    private String notes;
    private BigDecimal totalReturnAmount;
    private String stockMovementType;

    private List<SaleReturnItemRequest> items;
}
