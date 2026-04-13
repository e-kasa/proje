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

    /**
     * Malın teslim alındığı lokasyon kodu: Store.code veya Warehouse.code
     * Örn: "WH-01" (depoya), "STORE-01" (direkt mağazaya)
     */
    @NotBlank(message = "Lokasyon ID zorunludur")
    private String locationId;

    /** STORE veya WAREHOUSE */
    private String locationType;

    private List<PurchaseItemRequest> items;

    private String notes;
}
