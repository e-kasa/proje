package com.sedcore.model;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PartSearchResponse {

    private String productId;
    private String productName;
    private String variantId;
    private String variantSku;
    private String variantName;
    private String brand;
    private BigDecimal salePrice;
    private BigDecimal purchasePrice;
    private String shelfLocationCode;
    private Integer minStockLevel;
    private List<OemNumberResponse> oemNumbers;
    private List<CrossReferenceResponse> crossReferences;
    private List<String> barcodes;
    private List<CompatibleVehicleSummary> compatibleVehicles;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CompatibleVehicleSummary {
        private String vehicleId;
        private String make;
        private String model;
        private Integer yearStart;
        private Integer yearEnd;
    }
}
