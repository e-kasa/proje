package com.sedcore.inventory.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockTransferItemRequest {

    @NotBlank(message = "Varyant ID zorunludur")
    private String variantId;

    @NotNull(message = "Miktar zorunludur")
    @Min(value = 1, message = "Miktar en az 1 olmalıdır")
    private Integer quantity;

    private String notes;
}
