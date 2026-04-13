package com.sedcore.inventory.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Immutable;

/**
 * InventoryView — DB View (read-only).
 *
 * stock_movements tablosundan GROUP BY ile hesaplanan stok özeti.
 * Gerçek zamanlı bakiye için StockLevel tablosunu kullan.
 * Bu view raporlama ve hareket tarihçesi için kullanılır.
 *
 * View tanımı data.sql'de:
 *   SELECT company_code, variant_id, location_id, location_type,
 *          SUM(IN_hareketleri) - SUM(OUT_hareketleri) AS physical_quantity
 *   FROM stock_movements GROUP BY company_code, variant_id, location_id, location_type
 */
@Entity
@Table(name = "inventory_view")
@Immutable
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InventoryView extends TOpenSimpleCompanyEntity {

    @Column(name = "variant_id")
    private String variantId;

    /** Store.code veya Warehouse.code */
    @Column(name = "location_id")
    private String locationId;

    /** "STORE" veya "WAREHOUSE" */
    @Column(name = "location_type")
    private String locationType;

    /** SUM(IN) - SUM(OUT) hesaplanan anlık miktar */
    @Column(name = "physical_quantity")
    private Integer physicalQuantity;
}
