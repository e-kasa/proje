package com.sedcore.finance.model;

import com.sedcore.common.enums.PaymentType;
import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Ödeme yanıt DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaymentResponse extends DtoBaseModel {

    private String id;

    // ===== İLİŞKİLİ TARAF =====

    private String customerId;
    private String customerName;
    private String supplierId;
    private String supplierName;

    // ===== İLİŞKİLİ BELGELER =====

    private String saleId;
    private String purchaseId;

    // ===== ÖDEME BİLGİLERİ =====

    private PaymentType paymentType;
    private String paymentTypeLabel;
    private BigDecimal amount;
    private LocalDateTime paymentDate;

    // ===== REFERANS =====

    private String referenceNumber;
    private String bankName;
    private String accountNumber;
    private String checkNumber;
    private LocalDateTime checkDate;

    // ===== AÇIKLAMA =====

    private String description;
    private String notes;

    // ===== CARİ HESAP BAĞLANTISI =====

    private String accountTransactionId;

    // ===== DURUM =====

    private Boolean isCancelled;
    private LocalDateTime cancelledDate;
    private String cancelledReason;

    private Boolean isVerified;
    private LocalDateTime verifiedDate;
    private String verifiedBy;
}
