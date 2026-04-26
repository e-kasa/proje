package com.sedcore.finance.model;

import com.sedcore.common.enums.PaymentType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

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

    /**
     * @deprecated Sprint 7+: {@link #allocations} kullanın. Geriye uyum için
     * tek satış senaryosunda hâlâ kabul edilir — service katmanı tek-öğeli
     * allocation listesine çevirir. Sprint 9'da kaldırılacak.
     */
    @Deprecated
    private String saleId;
    private String purchaseId;   // Hangi satın almaya ait

    // ===== ALLOCATION (Sprint 7) =====

    /**
     * Ödemenin satışlara dağıtımı. Sprint 7+ tercih edilen API.
     *
     * <ul>
     *   <li>Boş/null + saleId boş → 1 "genel ödeme" allocation otomatik oluşur (cari bakiyeye).</li>
     *   <li>Boş/null + saleId dolu → geriye uyum: 1 allocation oluşur (saleId, amount).</li>
     *   <li>1 öğe → tek satış için ödeme.</li>
     *   <li>N öğe → toplu ödeme (B3, henüz UI'da yok ama backend kabul eder).</li>
     * </ul>
     *
     * Validation: SUM(allocations.amount) == amount.
     */
    @Valid
    private List<AllocationRequest> allocations;

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
