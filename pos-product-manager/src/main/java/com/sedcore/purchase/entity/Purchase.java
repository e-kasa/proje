package com.sedcore.purchase.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import com.sedcore.common.enums.PurchaseStatus;
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

    /**
     * Faturadaki brüt toplam (tüm kalemler × invoiceQty × birimFiyat).
     * Eksik teslimat olsa bile faturanın tam tutarıdır.
     */
    @Column(name = "invoice_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal invoiceAmount = BigDecimal.ZERO;

    /**
     * Gerçekte depoya/mağazaya giren mal tutarı (receivedQty × birimFiyat).
     * Cari hesaba yansıyan borç bu tutardır — invoiceAmount'tan farklı olabilir.
     */
    @Column(name = "total_amount", precision = 15, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalAmount = BigDecimal.ZERO;

    @Column(name = "paid_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal paidAmount = BigDecimal.ZERO;

    /**
     * Tedarikçi iskontosu/kredi notu ile kapatılan toplam tutar.
     * applyDiscount() çağrıldıkça birikimli artar.
     */
    @Column(name = "discount_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal discountAmount = BigDecimal.ZERO;

    /**
     * Henüz çözüme kavuşturulmamış eksik teslimat tutarı.
     * invoiceAmount - totalAmount ile başlar; iskonto/teslimat ile azalır, 0'da kapanır.
     */
    @Column(name = "shortage_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal shortageAmount = BigDecimal.ZERO;

    // ===== STOK HAREKETLERİ =====

    @OneToMany(mappedBy = "purchase", cascade = CascadeType.ALL)
    private List<StockMovement> movements;

    // ===== LOKASYON =====

    /**
     * Malın teslim alındığı lokasyon: Store.code veya Warehouse.code
     * Örn: "WH-01" (depoya giriş) veya "STORE-01" (direkt mağazaya)
     */
    @Column(name = "location_id", length = 50)
    private String locationId;

    /** "STORE" veya "WAREHOUSE" */
    @Column(name = "location_type", length = 10)
    private String locationType;

    // ===== DURUM =====

    @Enumerated(EnumType.STRING)
    @Column(name = "purchase_status", length = 20)
    @Builder.Default
    private PurchaseStatus purchaseStatus = PurchaseStatus.COMPLETED;

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
