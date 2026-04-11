package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import com.sedcore.inventory.model.InitialStocksRequest;
import java.util.Map;

/**
 * Varyant Request DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductVariantRequest {

        private String sku;
        private String name;
        private String shelfLocationCode;
        private Map<String, String> attributes;
        private PricingRequest pricing;
        private List<BarcodeRequest> barcodes;
        private List<InitialStocksRequest> initialStocks;
        private String notes;
    

}
