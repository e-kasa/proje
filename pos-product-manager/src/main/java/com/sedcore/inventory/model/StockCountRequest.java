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
public class StockCountRequest {

    @NotBlank(message = "Lokasyon ID zorunludur")
    private String locationId;

    /** "STORE" veya "WAREHOUSE" */
    private String locationType;

    @Valid
    @NotEmpty(message = "En az bir ürün kalemi girilmelidir")
    private List<StockCountItemRequest> items;

    private String notes;
}
