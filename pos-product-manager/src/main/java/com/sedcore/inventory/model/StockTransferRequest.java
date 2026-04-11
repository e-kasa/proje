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

    @NotBlank(message = "Kaynak mağaza ID zorunludur")
    private String fromStoreId;

    @NotBlank(message = "Kaynak depo ID zorunludur")
    private String fromWarehouseId;

    @NotBlank(message = "Hedef mağaza ID zorunludur")
    private String toStoreId;

    @NotBlank(message = "Hedef depo ID zorunludur")
    private String toWarehouseId;

    @Valid
    @NotEmpty(message = "En az bir ürün kalemi girilmelidir")
    private List<StockTransferItemRequest> items;

    private String notes;
}
