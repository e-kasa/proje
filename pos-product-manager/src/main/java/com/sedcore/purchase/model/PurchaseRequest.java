package com.sedcore.purchase.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PurchaseRequest {

    @NotBlank(message = "Tedarikçi ID zorunludur")
    private String supplierId;

    @NotBlank(message = "Fatura numarası zorunludur")
    private String invoiceNumber;

    private String deliveryNoteNumber;

    @NotNull(message = "Satın alma tarihi zorunludur")
    private LocalDate purchaseDate;

    @NotBlank(message = "Mağaza ID zorunludur")
    private String storeId;

    @NotBlank(message = "Depo ID zorunludur")
    private String warehouseId;

    private List<PurchaseItemRequest> items;

    private String notes;
}
