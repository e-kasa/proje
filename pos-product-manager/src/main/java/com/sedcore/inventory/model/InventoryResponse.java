package com.sedcore.inventory.model;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Stok Response DTO — InventoryView entity ile birebir eşleşir.
 *
 * physicalQuantity = SUM(IN hareketler) - SUM(OUT hareketler)
 * Tek varyant için tüm depolar toplanarak veya depo bazında döndürülür.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryResponse extends DtoBaseModel {

    private String id;

    /** Hangi varyanta ait */
    private String variantId;

    /** Lokasyon kodu: Store.code veya Warehouse.code */
    private String locationId;

    /** "STORE" veya "WAREHOUSE" */
    private String locationType;

    /** Fiziksel stok: SUM(IN hareketler) - SUM(OUT hareketler) */
    private Integer physicalQuantity;

    /** Minimum stok seviyesi — ProductVariant'tan gelir, Flutter düşük stok alarmı için */
    private Integer minStockLevel;
}
