package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * CustomerAccount Entity - Müşteri cari hesap özet bilgileri
 * Bu tablo müşterinin güncel bakiye durumunu tutar
 */
@Entity
@Table(name = "customer_accounts")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerAccount extends TOpenSimpleCompanyEntity {

    // ===== MÜŞTERİ İLİŞKİSİ =====

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false, unique = true)
    private Customer customer;

    // ===== BAKİYE BİLGİLERİ =====

    @Column(name = "current_balance", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal currentBalance = BigDecimal.ZERO; // Güncel bakiye (+ borç, - alacak)

    @Column(name = "total_debt", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalDebt = BigDecimal.ZERO; // Toplam borç tutarı

    @Column(name = "total_credit", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalCredit = BigDecimal.ZERO; // Toplam alacak tutarı

    @Column(name = "overdue_amount", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal overdueAmount = BigDecimal.ZERO; // Vadesi geçmiş tutar

    // ===== İSTATİSTİKLER =====

    @Column(name = "total_transaction_count")
    @Builder.Default
    private Long totalTransactionCount = 0L; // Toplam hareket sayısı

    @Column(name = "last_transaction_date")
    private LocalDateTime lastTransactionDate; // Son hareket tarihi

    @Column(name = "last_payment_date")
    private LocalDateTime lastPaymentDate; // Son ödeme tarihi

    @Column(name = "last_sale_date")
    private LocalDateTime lastSaleDate; // Son satış tarihi

    // ===== RİSK & KONTROL =====

    @Column(name = "available_credit_limit", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal availableCreditLimit = BigDecimal.ZERO; // Kullanılabilir kredi limiti

    @Column(name = "is_credit_limit_exceeded")
    @Builder.Default
    private Boolean isCreditLimitExceeded = false; // Kredi limiti aşıldı mı?

    // ===== HESAPLAMA METODları =====

    /**
     * Kullanılabilir kredi limitini hesapla
     * Limit - Güncel Bakiye = Kullanılabilir Limit
     */
    public BigDecimal calculateAvailableCreditLimit() {
        BigDecimal creditLimit = customer != null ? customer.getCreditLimit() : BigDecimal.ZERO;
        return creditLimit.subtract(currentBalance);
    }

    /**
     * Kredi limiti aşım kontrolü
     */
    public boolean checkCreditLimitExceeded() {
        BigDecimal availableCredit = calculateAvailableCreditLimit();
        return availableCredit.compareTo(BigDecimal.ZERO) < 0;
    }

    /**
     * Bakiye güncellemesi sonrası otomatik hesaplamalar
     */
    public void updateCalculatedFields() {
        this.availableCreditLimit = calculateAvailableCreditLimit();
        this.isCreditLimitExceeded = checkCreditLimitExceeded();
    }
}
