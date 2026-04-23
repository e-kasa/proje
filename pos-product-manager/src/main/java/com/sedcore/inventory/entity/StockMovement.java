package com.sedcore.inventory.entity;

import com.sedcore.common.enums.StockMovementType;
import com.sedcore.product.entity.ProductVariant;
import com.sedcore.purchase.entity.Purchase;
import com.sedcore.sales.entity.Sale;
import com.towpen.base.db.model.TOpenSimpleCompanyEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * StockMovement — Stok hareketi audit kaydı.
 *
 * Her giriş/çıkış hareketi buraya yazılır (satış, alım, transfer, sayım, iade).
 * Anlık bakiye için StockLevel tablosunu kullan — bu tablo sadece tarihsel kayıt içindir.
 *
 * locationId: Store.code veya Warehouse.code (örn. "STORE-01", "WH-01")
 * locationType: "STORE" veya "WAREHOUSE"
 */
@Entity
@Table(name = "stock_movements",
       indexes = {
           @Index(name = "idx_sm_variant",  columnList = "variant_id"),
           @Index(name = "idx_sm_location", columnList = "location_id"),
           @Index(name = "idx_sm_company",  columnList = "company_code")
       }
)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StockMovement extends TOpenSimpleCompanyEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "variant_id", nullable = false)
    private ProductVariant variant;

    /**
     * Lokasyon kodu — Store.code veya Warehouse.code.
     * Örn: "STORE-01" (mağaza) veya "WH-01" (depo)
     */
    @Column(name = "location_id", length = 50)
    private String locationId;

    /**
     * Lokasyon tipi: "STORE" veya "WAREHOUSE"
     * locationId ile birlikte hangi tip lokasyon olduğunu belirtir.
     */
    @Column(name = "location_type", length = 10)
    private String locationType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StockMovementType movementType;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "unit_price", precision = 15, scale = 2)
    private java.math.BigDecimal unitPrice;

    /**
     * Satır KDV oranı (yüzde olarak — ör. 18, 10, 20).
     * Toplu girişte fatura satırından gelir. Audit amaçlı tutulur;
     * {@link com.sedcore.purchase.entity.Purchase#getTotalAmount()} KDV hariçtir
     * (toplam KDV Purchase.totalVatAmount'ta tutulur — sprint 3).
     */
    @Column(name = "tax_rate", precision = 5, scale = 2)
    private java.math.BigDecimal taxRate;

    // 🔗 KAYNAK BELGELER
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "purchase_id")
    private Purchase purchase;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transfer_id")
    private StockTransfer transfer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sale_id")
    private Sale sale;

    @Version
    private Long version;
}
