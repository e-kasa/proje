package com.sedcore.supplier.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * SupplierAccount Entity - Tedarikçi cari hesap özet bilgileri
 * Bu tablo tedarikçinin güncel bakiye durumunu tutar
 */
@Entity
@Table(name = "supplier_accounts")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SupplierAccount extends TOpenSimpleCompanyEntity {

    // ===== TEDARİKÇİ İLİŞKİSİ =====

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "supplier_id", nullable = false, unique = true)
    private Supplier supplier;

    // ===== BAKİYE BİLGİLERİ =====

    @Column(name = "current_balance", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal currentBalance = BigDecimal.ZERO; // Güncel bakiye (+ bizim borç, - bizim alacak)

    @Column(name = "total_debt", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalDebt = BigDecimal.ZERO; // Toplam borç tutarı (biz borçluyuz)

    @Column(name = "total_credit", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalCredit = BigDecimal.ZERO; // Toplam ödeme tutarı

    @Column(name = "overdue_amount", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal overdueAmount = BigDecimal.ZERO; // Vadesi geçmiş ödemeler

    // ===== İSTATİSTİKLER =====

    @Column(name = "total_transaction_count")
    @Builder.Default
    private Long totalTransactionCount = 0L; // Toplam hareket sayısı

    @Column(name = "last_transaction_date")
    private LocalDateTime lastTransactionDate; // Son hareket tarihi

    @Column(name = "last_payment_date")
    private LocalDateTime lastPaymentDate; // Son ödeme tarihi

    @Column(name = "last_purchase_date")
    private LocalDateTime lastPurchaseDate; // Son alım tarihi

    // ===== RİSK & KONTROL =====

    @Column(name = "available_credit_limit", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal availableCreditLimit = BigDecimal.ZERO; // Kullanılabilir kredi (tedarikçinin bize verdiği)

    @Column(name = "is_credit_limit_exceeded")
    @Builder.Default
    private Boolean isCreditLimitExceeded = false; // Kredi limiti aşıldı mı?

    // ===== HESAPLAMA METODları =====

    /**
     * Kullanılabilir kredi limitini hesapla
     * Tedarikçinin bize verdiği Limit - Güncel Bakiye = Kullanılabilir Limit
     */
    public BigDecimal calculateAvailableCreditLimit() {
        BigDecimal creditLimit = supplier != null ? supplier.getCreditLimit() : BigDecimal.ZERO;
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
