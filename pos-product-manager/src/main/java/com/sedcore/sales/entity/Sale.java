package com.sedcore.sales.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerVehicle;
import com.sedcore.inventory.entity.StockMovement;

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

    @Column(name = "subtotal_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal subtotalAmount = BigDecimal.ZERO; // İndirim öncesi brüt

    @Column(name = "total_discount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal totalDiscount = BigDecimal.ZERO;

    @Column(name = "total_tax", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal totalTax = BigDecimal.ZERO;

    /** Toplam ÖTV tutarı — Sprint 2026-05-25. Σ(SaleItem.otvAmount). */
    @Column(name = "total_otv", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal totalOtv = BigDecimal.ZERO;

    @Column(name = "total_amount", precision = 15, scale = 2, nullable = false)
    private BigDecimal totalAmount; // Nihai ödenecek tutar (subtotal - discount + otv + tax)

    @Column(name = "paid_amount", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal paidAmount = BigDecimal.ZERO; // Ödenen tutar

    // ===== SATIŞ KALEMLERİ =====

    @OneToMany(mappedBy = "sale", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SaleItem> items;

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

    // ===== LOKASYON =====

    /**
     * Satışın yapıldığı lokasyon: genellikle Store.code
     * Kasiyer JWT'deki storeId'den alınır.
     */
    @Column(name = "location_id", length = 50)
    private String locationId;

    /** "STORE" veya "WAREHOUSE" */
    @Column(name = "location_type", length = 10)
    private String locationType;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    // ===== PLAKA TAKİBİ (Sprint 9 — Opsiyon C) =====

    /**
     * Sprint 9 — parçacı sektör senaryosu için müşteri-plaka FK.
     * Nullable: peşin satış / butik sektör / plaka seçilmediği durumda null.
     * UI: companySettingProvider.sectorType == 'autoParts' + customer != null → picker görünür.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_vehicle_id")
    private CustomerVehicle customerVehicle;

    /**
     * Denormalize cache: müşteri-plakadan plate_normalized snapshot.
     * Search performansı + tarihsel kayıt (CustomerVehicle silinse bile bu değer kalır).
     * Reconcile invariant: customerVehicle != null → vehiclePlateSnapshot = customerVehicle.plateNormalized.
     */
    @Column(name = "vehicle_plate_snapshot", length = 20)
    private String vehiclePlateSnapshot;

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

    @Version
    private Long version;
}
