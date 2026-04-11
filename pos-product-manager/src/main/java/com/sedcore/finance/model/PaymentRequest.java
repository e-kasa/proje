package com.sedcore.finance.model;

import com.sedcore.common.enums.PaymentType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Ödeme oluşturma / güncelleme isteği DTO
 */
@Data
public class PaymentRequest {

    // ===== ZORUNLU ALANLAR =====

    @NotNull(message = "Ödeme tutarı zorunludur")
    @DecimalMin(value = "0.01", message = "Ödeme tutarı 0'dan büyük olmalıdır")
    private BigDecimal amount;

    @NotNull(message = "Ödeme tipi zorunludur")
    private PaymentType paymentType;

    // ===== İLİŞKİLİ TARAF (birisi dolu olmalı) =====

    private String customerId;   // Müşteriden tahsilat
    private String supplierId;   // Tedarikçiye ödeme

    // ===== İLİŞKİLİ BELGELER (opsiyonel) =====

    private String saleId;       // Hangi satışa ait
    private String purchaseId;   // Hangi satın almaya ait

    // ===== ÖDEME BİLGİLERİ =====

    private LocalDateTime paymentDate; // Boşsa şimdiki zaman kullanılır

    private String referenceNumber; // Dekont no, çek no, vb.
    private String bankName;        // Havale/EFT için banka adı
    private String accountNumber;   // Hesap numarası
    private String checkNumber;     // Çek numarası
    private LocalDateTime checkDate; // Çek tarihi

    private String description;
    private String notes;
}
