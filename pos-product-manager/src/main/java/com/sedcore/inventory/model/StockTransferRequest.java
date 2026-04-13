package com.sedcore.inventory.model;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockTransferRequest {

    /**
     * Kaynak lokasyon kodu: Store.code veya Warehouse.code
     * Örn: "STORE-01", "WH-01"
     */
    @NotBlank(message = "Kaynak lokasyon zorunludur")
    private String fromLocationId;

    /** Kaynak lokasyon tipi: STORE veya WAREHOUSE */
    private String fromLocationType;

    /**
     * Hedef lokasyon kodu: Store.code veya Warehouse.code
     */
    @NotBlank(message = "Hedef lokasyon zorunludur")
    private String toLocationId;

    /** Hedef lokasyon tipi: STORE veya WAREHOUSE */
    private String toLocationType;

    @Valid
    @NotEmpty(message = "En az bir ürün kalemi girilmelidir")
    private List<StockTransferItemRequest> items;

    private String notes;
}
