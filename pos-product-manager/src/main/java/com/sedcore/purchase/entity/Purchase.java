package com.sedcore.purchase.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.sedcore.supplier.entity.Supplier;
import com.sedcore.inventory.entity.StockMovement;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Purchase Entity - Satın alma kayıtları
 * Tedarikçiden yapılan alımların detaylı kaydı
 */
@Entity
@Table(name = "purchases", indexes = {
    @Index(name = "idx_purchase_supplier", columnList = "supplier_id,purchase_date"),
    @Index(name = "idx_invoice_number", columnList = "invoice_number")
})
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Purchase extends TOpenSimpleCompanyEntity {

    // ===== TEDARİKÇİ İLİŞKİSİ =====

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "supplier_id", nullable = false)
    private Supplier supplier;

    // ===== BELGE BİLGİLERİ =====

    @Column(name = "purchase_date", nullable = false)
    private LocalDate purchaseDate;

    @Column(name = "delivery_note_number", length = 100)
    private String deliveryNoteNumber; // İrsaliye numarası

    @Column(name = "invoice_number", nullable = false)
    private String invoiceNumber;

    // ===== TUTAR BİLGİLERİ =====

    @Column(name = "total_amount", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalAmount = BigDecimal.ZERO; // Toplam tutar

    @Column(name = "paid_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal paidAmount = BigDecimal.ZERO; // Ödenen tutar

    // ===== STOK HAREKETLERİ =====

    @OneToMany(mappedBy = "purchase", cascade = CascadeType.ALL)
    private List<StockMovement> movements;

    // ===== MAĞAZA =====

    @Column(name = "store_id", length = 36)
    private String storeId; // Alımın yapıldığı mağaza (FK yok — soft ref)

    // ===== DURUM =====

    @Column(name = "is_cancelled")
    @Builder.Default
    private Boolean isCancelled = false;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    // ===== HELPER METHODS =====

    /**
     * Kalan borç tutarı
     */
    public BigDecimal getRemainingDebt() {
        return totalAmount.subtract(paidAmount);
    }

    /**
     * Veresiye mi?
     */
    public boolean isOnCredit() {
        return getRemainingDebt().compareTo(BigDecimal.ZERO) > 0;
    }

    @Version
    private Long version;
}
