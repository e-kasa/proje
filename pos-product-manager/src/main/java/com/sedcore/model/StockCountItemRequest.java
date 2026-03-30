package com.sedcore.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockCountItemRequest {

    @NotBlank(message = "Varyant ID zorunludur")
    private String variantId;

    /** Fiili sayım sonucu — sistemdeki fiziksel stok ile karşılaştırılır */
    @NotNull(message = "Sayılan miktar zorunludur")
    @Min(value = 0, message = "Sayılan miktar sıfır veya daha fazla olmalıdır")
    private Integer physicalCount;

    private String notes;
}
