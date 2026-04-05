package com.sedcore.model.reports;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CriticalStockAlert {
    private String variantId;
    private String variantSku;
    private String variantName;
    private String productName;
    private Integer currentQuantity;
    private Integer minimumThreshold;
    private String warehouseId;
    private String storeId;
    private LocalDateTime lastMovementDate;
    private String alertLevel; // CRITICAL, LOW, OUT_OF_STOCK
}
