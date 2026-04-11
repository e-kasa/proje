package com.sedcore.finance.entity;

import com.sedcore.common.enums.PaymentType;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Payment Entity - Ödeme kayıtları
 * Müşterilerden alınan ödemelerin detaylı kaydı
 */
@Entity
@Table(name = "payments", indexes = {
    @Index(name = "idx_payment_type", columnList = "payment_type"),
    @Index(name = "idx_reference_number", columnList = "reference_number")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Payment extends TOpenSimpleCompanyEntity {

    // ===== MÜŞTERİ İLİŞKİSİ =====

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private Customer customer; // Müşteri (null = tedarikçi ödemesi)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "supplier_id")
    private Supplier supplier; // Tedarikçi (null = müşteri tahsilatı)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_id")
    private Sale sale; // İlgili satış (varsa)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "purchase_id")
    private Purchase purchase; // İlgili satın alma (varsa)

    // ===== ÖDEME BİLGİLERİ =====

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_type", nullable = false, length = 30)
    private PaymentType paymentType; // Ödeme tipi

    @Column(name = "amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal amount; // Ödeme tutarı

    @Column(name = "payment_date", nullable = false)
    private LocalDateTime paymentDate; // Ödeme tarihi

    // ===== REFERANS BİLGİLERİ =====

    @Column(name = "reference_number", length = 100)
    private String referenceNumber; // Referans numarası (dekont no, çek no, vb.)

    @Column(name = "bank_name", length = 100)
    private String bankName; // Banka adı (havale/çek için)

    @Column(name = "account_number", length = 50)
    private String accountNumber; // Hesap numarası

    @Column(name = "check_number", length = 50)
    private String checkNumber; // Çek numarası

    @Column(name = "check_date")
    private LocalDateTime checkDate; // Çek tarihi

    // ===== AÇIKLAMA =====

    @Column(name = "description", columnDefinition = "TEXT")
    private String description; // Ödeme açıklaması

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes; // Ek notlar

    // ===== İLİŞKİLİ İŞLEM =====

    @Column(name = "account_transaction_id", length = 36)
    private String accountTransactionId; // İlgili cari hesap hareketi ID'si

    // ===== DURUM =====

    @Column(name = "is_cancelled")
    @Builder.Default
    private Boolean isCancelled = false; // İptal edildi mi?

    @Column(name = "cancelled_date")
    private LocalDateTime cancelledDate; // İptal tarihi

    @Column(name = "cancelled_reason", length = 500)
    private String cancelledReason; // İptal nedeni

    @Column(name = "is_verified")
    @Builder.Default
    private Boolean isVerified = false; // Onaylandı mı? (banka ödemeleri için)

    @Column(name = "verified_date")
    private LocalDateTime verifiedDate; // Onay tarihi

    @Column(name = "verified_by")
    private String verifiedBy; // Onaylayan kullanıcı

    // ===== HELPER METODLAR =====

    /**
     * Ödemeyi iptal et
     */
    public void cancel(String reason) {
        this.isCancelled = true;
        this.cancelledDate = LocalDateTime.now();
        this.cancelledReason = reason;
    }

    /**
     * Ödemeyi onayla
     */
    public void verify(String userId) {
        this.isVerified = true;
        this.verifiedDate = LocalDateTime.now();
        this.verifiedBy = userId;
    }

    /**
     * Nakit ödeme mi?
     */
    public boolean isCashPayment() {
        return paymentType == PaymentType.CASH;
    }

    /**
     * Kredi kartı ödemesi mi?
     */
    public boolean isCreditCardPayment() {
        return paymentType == PaymentType.CREDIT_CARD || paymentType == PaymentType.DEBIT_CARD;
    }
}
