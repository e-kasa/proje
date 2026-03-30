package com.sedcore.model;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SaleRequest {

    private String customerId; // null = peşin satış

    @NotBlank(message = "Satış numarası zorunludur")
    private String saleNumber;

    @NotBlank(message = "Mağaza ID zorunludur")
    private String storeId;

    @NotBlank(message = "Depo ID zorunludur")
    private String warehouseId;

    @Valid
    @NotEmpty(message = "En az bir ürün kalemi girilmelidir")
    private List<SaleItemRequest> items;

    @NotNull(message = "Ödenen tutar zorunludur (peşin satışta toplam tutar girin)")
    private BigDecimal paidAmount;

    private String notes;
}
