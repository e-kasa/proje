package com.sedcore.purchase.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Satin Alma Iade Request DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseReturnRequest {

    private String reason;
    private String reasonLabel;
    private String notes;
    private BigDecimal totalReturnAmount;
    private String stockMovementType;

    private List<PurchaseReturnItemRequest> items;
}
