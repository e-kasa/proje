package com.sedcore.sales.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Satış İade Kalemi Request DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SaleReturnItemRequest {

    /** Varyant ID (Flutter'da productId olarak gönderilir) */
    private String productId;

    private String productName;
    @NotNull(message = "Miktar zorunludur")
    @Min(value = 1, message = "Miktar en az 1 olmalıdır")
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal discount;
    private BigDecimal taxRate;
    private String reason;
}
