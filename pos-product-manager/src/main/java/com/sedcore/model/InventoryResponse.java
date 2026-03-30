package com.sedcore.model;

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
public class InventoryResponse {

    private String id;

    /** Hangi varyanta ait */
    private String variantId;

    /** Mağaza ID (null → tüm mağazaların toplamı) */
    private String storeId;

    /** Depo ID */
    private String warehouseId;

    /** Fiziksel stok: SUM(IN hareketler) - SUM(OUT hareketler) */
    private Integer physicalQuantity;

    /** Minimum stok seviyesi — ProductVariant'tan gelir, Flutter düşük stok alarmı için */
    private Integer minStockLevel;
}
