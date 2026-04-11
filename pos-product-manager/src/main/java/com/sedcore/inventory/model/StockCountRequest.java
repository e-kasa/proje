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

    @NotBlank(message = "Mağaza ID zorunludur")
    private String storeId;

    @NotBlank(message = "Depo ID zorunludur")
    private String warehouseId;

    @Valid
    @NotEmpty(message = "En az bir ürün kalemi girilmelidir")
    private List<StockCountItemRequest> items;

    private String notes;
}
