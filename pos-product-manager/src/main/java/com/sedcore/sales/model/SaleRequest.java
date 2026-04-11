package com.sedcore.sales.model;

import jakarta.validation.Valid;
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

    // Opsiyonel: backend otomatik üretir (POS'tan gönderilmeyebilir)
    private String saleNumber;

    // Opsiyonel: POS, mağaza/depo yapılandırması olmadan çalışabilir
    private String storeId;

    private String warehouseId;

    @Valid
    @NotEmpty(message = "En az bir ürün kalemi girilmelidir")
    private List<SaleItemRequest> items;

    @NotNull(message = "Ödenen tutar zorunludur (peşin satışta toplam tutar girin)")
    private BigDecimal paidAmount;

    private String notes;
}
