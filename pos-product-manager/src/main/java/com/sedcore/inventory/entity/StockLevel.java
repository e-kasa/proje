package com.sedcore.inventory.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * StockLevel — Anlık stok bakiyesi tablosu (per varyant, per lokasyon).
 *
 * Her (variant_id, location_id, company_code) kombinasyonu için tek bir kayıt tutar.
 * Stok hareketlerinde (satış, alım, transfer) bu tablo atomic olarak güncellenir.
 *
 * locationId: Store.code veya Warehouse.code string değeri
 * locationType: 'STORE' veya 'WAREHOUSE'
 *
 * quantity <= 0 olduğunda kritik stok alarmı tetiklenebilir.
 * minQuantity: per-lokasyon alarm eşiği (null ise global ProductVariant.minStockLevel kullanılır)
 */
@Entity
@Table(
    name = "stock_levels",
    indexes = {
        @Index(name = "idx_sl_variant_location", columnList = "variant_id, location_id"),
        @Index(name = "idx_sl_location", columnList = "location_id"),
        @Index(name = "idx_sl_company", columnList = "company_code"),
        @Index(name = "idx_sl_critical", columnList = "company_code, quantity, min_quantity")
    },
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_sl_variant_location_company",
            columnNames = {"variant_id", "location_id", "company_code"}
        )
    }
)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StockLevel extends TOpenSimpleCompanyEntity {

    /** Hangi ürün varyantı — plain String FK (performans için join yok) */
    @Column(name = "variant_id", nullable = false, length = 36)
    private String variantId;

    /**
     * Lokasyon kodu: Store.code veya Warehouse.code
     * Örn: "STORE-01", "WH-01"
     */
    @Column(name = "location_id", nullable = false, length = 50)
    private String locationId;

    /** STORE veya WAREHOUSE */
    @Column(name = "location_type", nullable = false, length = 10)
    private String locationType;

    /** Anlık stok miktarı — her harekette +/- güncellenir */
    @Column(name = "quantity", nullable = false)
    @Builder.Default
    private Integer quantity = 0;

    /**
     * Per-lokasyon kritik stok eşiği.
     * null ise ProductVariant.minStockLevel global değeri kullanılır.
     */
    @Column(name = "min_quantity")
    @Builder.Default
    private Integer minQuantity = 5;

    /** Optimistic locking — eşzamanlı güncelleme koruması */
    @Version
    private Long version;
}
