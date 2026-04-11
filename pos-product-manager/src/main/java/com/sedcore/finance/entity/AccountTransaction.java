package com.sedcore.finance.entity;

import com.sedcore.common.enums.TransactionType;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * AccountTransaction Entity - Cari hesap hareketleri
 * Tüm müşteri işlemlerinin (satış, ödeme, iade vb.) detaylı kaydı
 */
@Entity
@Table(name = "account_transactions", indexes = {
    @Index(name = "idx_customer_date", columnList = "customer_id,transaction_date"),
    @Index(name = "idx_reference", columnList = "reference_type,reference_id"),
    @Index(name = "idx_transaction_type", columnList = "transaction_type")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AccountTransaction extends TOpenSimpleCompanyEntity {

    // ===== MÜŞTERİ/TEDARİKÇİ İLİŞKİSİ =====

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private Customer customer; // Müşteri (satış/tahsilat için)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "supplier_id")
    private Supplier supplier; // Tedarikçi (satın alma/ödeme için)

    // ===== KAYNAK BELGELER =====

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_id")
    private Sale sale; // Satış belgesi

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "purchase_id")
    private Purchase purchase; // Satın alma belgesi

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_id")
    private Payment payment; // Ödeme belgesi

    // ===== HAREKET BİLGİLERİ =====

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 30)
    private TransactionType transactionType; // Hareket tipi

    @Column(name = "debit_amount", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal debitAmount = BigDecimal.ZERO; // Borç tutarı

    @Column(name = "credit_amount", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal creditAmount = BigDecimal.ZERO; // Alacak tutarı

    @Column(name = "balance", precision = 15, scale = 2, nullable = false)
    private BigDecimal balance; // Hareket sonrası bakiye

    // ===== REFERANS BİLGİLERİ =====

    @Column(name = "reference_id", length = 36)
    private String referenceId; // İlgili kaydın ID'si (order_id, payment_id, vb.)

    @Column(name = "reference_type", length = 30)
    private String referenceType; // Referans tipi (ORDER, PAYMENT, INVOICE, vb.)

    @Column(name = "reference_number", length = 100)
    private String referenceNumber; // Belge numarası (fatura no, fiş no, vb.)

    // ===== AÇIKLAMA =====

    @Column(name = "description", columnDefinition = "TEXT")
    private String description; // Hareket açıklaması

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes; // Ek notlar

    // ===== TARİH BİLGİLERİ =====

    @Column(name = "transaction_date", nullable = false)
    private LocalDateTime transactionDate; // Hareket tarihi

    @Column(name = "due_date")
    private LocalDate dueDate; // Vade tarihi (satışlar için)

    @Column(name = "is_overdue")
    @Builder.Default
    private Boolean isOverdue = false; // Vadesi geçti mi?

    // ===== DURUM =====

    @Column(name = "is_cancelled")
    @Builder.Default
    private Boolean isCancelled = false; // İptal edildi mi?

    @Column(name = "cancelled_date")
    private LocalDateTime cancelledDate; // İptal tarihi

    @Column(name = "cancelled_by")
    private String cancelledBy; // İptal eden kullanıcı

    // ===== HELPER METODLAR =====

    /**
     * Net tutarı hesapla (borç - alacak)
     */
    public BigDecimal getNetAmount() {
        return debitAmount.subtract(creditAmount);
    }

    /**
     * Bu hareket borç hareketi mi?
     */
    public boolean isDebitTransaction() {
        return debitAmount.compareTo(BigDecimal.ZERO) > 0;
    }

    /**
     * Bu hareket alacak hareketi mi?
     */
    public boolean isCreditTransaction() {
        return creditAmount.compareTo(BigDecimal.ZERO) > 0;
    }

    /**
     * Vadesi geçmiş mi kontrol et
     */
    public boolean checkOverdue() {
        if (dueDate == null || isCancelled) {
            return false;
        }
        return LocalDate.now().isAfter(dueDate) && debitAmount.compareTo(BigDecimal.ZERO) > 0;
    }

    /**
     * Transaction'ı iptal et
     */
    public void cancel(String userId) {
        this.isCancelled = true;
        this.cancelledDate = LocalDateTime.now();
        this.cancelledBy = userId;
    }
}
