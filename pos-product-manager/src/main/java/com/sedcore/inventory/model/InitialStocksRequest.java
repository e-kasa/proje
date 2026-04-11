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

    private String storeId;
    private String warehouseId;
    private int quantity;
}
