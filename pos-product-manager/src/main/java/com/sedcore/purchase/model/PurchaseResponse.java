package com.sedcore.purchase.model;

import com.sedcore.common.enums.PurchaseStatus;
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
    private BigDecimal invoiceAmount;    // Faturanın brüt toplamı
    private BigDecimal totalAmount;      // Depoya giren mal tutarı (cari borca yansıyan)
    private BigDecimal paidAmount;
    private BigDecimal remainingDebt;
    private BigDecimal discountAmount;   // Uygulanan toplam iskonto
    private BigDecimal shortageAmount;   // Henüz kapatılmamış eksik teslimat tutarı

    // Lokasyon
    private String locationId;
    private String locationType;

    // Durum
    private PurchaseStatus purchaseStatus;
    private Boolean isCancelled;
    private String notes;

    // Açık talep sayısı (opsiyonel, servis doldurmayabilir)
    private Integer openClaimCount;

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
