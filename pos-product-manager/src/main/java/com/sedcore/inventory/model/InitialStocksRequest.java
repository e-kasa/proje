package com.sedcore.inventory.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InitialStocksRequest {

    /** Lokasyon kodu: Store.code veya Warehouse.code (örn. "STORE-01", "WH-01") */
    private String locationId;
    /** "STORE" veya "WAREHOUSE" */
    private String locationType;
    private int quantity;
}
