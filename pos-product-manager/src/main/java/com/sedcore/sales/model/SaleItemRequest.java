package com.sedcore.sales.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SaleItemRequest {

    @NotBlank(message = "Varyant ID zorunludur")
    private String variantId;

    @NotNull(message = "Miktar zorunludur")
    @Min(value = 1, message = "Miktar en az 1 olmalıdır")
    private Integer quantity;

    @NotNull(message = "Birim fiyat zorunludur")
    @Positive(message = "Birim fiyat pozitif olmalıdır")
    private BigDecimal unitPrice;

    private BigDecimal discountRate;

    private BigDecimal taxRate;

    private String notes;
}
