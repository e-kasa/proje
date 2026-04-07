package com.sedcore.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Satin Alma Iade Kalemi Request DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseReturnItemRequest {

    /** Varyant ID (Flutter'da productId olarak gönderilir) */
    private String productId;

    private String productName;
    private String variantSku;

    private Integer quantity;
    private BigDecimal unitPrice;
    private String reason;
}
