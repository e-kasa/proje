package com.sedcore.purchase.model;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Satın Alma Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseResponse extends DtoBaseModel {

    private String id;

    // Tedarikçi
    private String supplierId;
    private String supplierName;

    // Belge
    private String invoiceNumber;
    private String deliveryNoteNumber;
    private LocalDate purchaseDate;

    // Tutarlar
    private BigDecimal totalAmount;
    private BigDecimal paidAmount;
    private BigDecimal remainingDebt;

    // Lokasyon
    private String locationId;
    private String locationType;

    // Durum
    private Boolean isCancelled;
    private String notes;

    // Kalemler
    private List<PurchaseItemResponse> items;
    private Integer itemCount;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PurchaseItemResponse {
        private String movementId;
        private String variantId;
        private String variantSku;
        private String variantName;
        private String productName;
        private Integer quantity;
        private BigDecimal unitPrice;
        private BigDecimal lineTotal;
    }
}
