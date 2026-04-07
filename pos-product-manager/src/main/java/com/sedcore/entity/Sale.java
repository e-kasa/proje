package com.sedcore.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Sale Entity - Satış kayıtları
 * Müşteriye yapılan satışların detaylı kaydı
 */
@Entity
@Table(name = "sales", indexes = {
    @Index(name = "idx_sale_customer", columnList = "customer_id,sale_date"),
    @Index(name = "idx_sale_number", columnList = "sale_number")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Sale extends TOpenSimpleCompanyEntity {

    @Column(name = "sale_number", unique = true, nullable = false)
    private String saleNumber;

    @Column(name = "sale_date", nullable = false)
    private LocalDateTime saleDate;

    // ===== MÜŞTERİ İLİŞKİSİ =====

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private Customer customer; // Hangi müşteriye satış (null = peşin satış)

    // ===== TUTAR BİLGİLERİ =====

    @Column(name = "total_amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal totalAmount; // Toplam tutar

    @Column(name = "paid_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal paidAmount = BigDecimal.ZERO; // Ödenen tutar

    // ===== STOK HAREKETLERİ =====

    @OneToMany(mappedBy = "sale", cascade = CascadeType.ALL)
    private List<StockMovement> movements;

    // ===== DURUM =====

    @Column(name = "is_cancelled")
    @Builder.Default
    private Boolean isCancelled = false;

    @Column(name = "cancel_reason", length = 500)
    private String cancelReason;

    @Column(name = "cancel_date")
    private LocalDateTime cancelDate;

    // ===== İADE TAKİBİ =====

    @Column(name = "returned_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal returnedAmount = BigDecimal.ZERO; // Toplam iade edilen tutar

    @Column(name = "has_return")
    @Builder.Default
    private Boolean hasReturn = false; // İade kaydı var mı? (hızlı sorgu için)

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    // ===== HELPER METHODS =====

    /**
     * Kalan borç tutarı
     */
    public BigDecimal getRemainingAmount() {
        return totalAmount.subtract(paidAmount);
    }

    /**
     * Veresiye mi?
     */
    public boolean isOnCredit() {
        return customer != null && getRemainingAmount().compareTo(BigDecimal.ZERO) > 0;
    }
}
