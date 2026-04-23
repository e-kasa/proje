package com.sedcore.inventory.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import lombok.*;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.Subselect;
import org.hibernate.annotations.Synchronize;

/**
 * InventoryView — stock_movements'ten hesaplanan salt-okunur stok özeti.
 *
 * @Subselect kullanılır (@Table değil) — Hibernate bu entity için DDL üretmez,
 * sorguyu doğrudan aşağıdaki query'den alır. Aksi halde ddl-auto=create moduyla
 * aynı isimde TABLE yaratılır ve data.sql'deki CREATE VIEW ile çakışır.
 *
 * Gerçek zamanlı bakiye için StockLevel tablosunu kullan — bu view raporlama
 * ve hareket tarihçesi içindir.
 */
@Entity
@Immutable
@Subselect("""
        SELECT
            gen_random_uuid()::text   AS id,
            sm.company_code,
            'SYSTEM'::varchar         AS create_user,
            CURRENT_TIMESTAMP         AS create_time,
            CURRENT_TIMESTAMP         AS last_modified_time,
            NULL::varchar             AS update_user,
            sm.variant_id,
            sm.location_id,
            sm.location_type,
            SUM(CASE WHEN sm.movement_type IN ('PURCHASE_IN','SALE_RETURN_IN','SALE_CANCEL_IN','TRANSFER_IN','ADJUSTMENT_IN')
                     THEN sm.quantity ELSE 0 END) -
            SUM(CASE WHEN sm.movement_type IN ('SALE_OUT','PURCHASE_RETURN_OUT','TRANSFER_OUT','ADJUSTMENT_OUT')
                     THEN sm.quantity ELSE 0 END) AS physical_quantity
        FROM stock_movements sm
        GROUP BY sm.company_code, sm.variant_id, sm.location_id, sm.location_type
        """)
@Synchronize({"stock_movements"})
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
