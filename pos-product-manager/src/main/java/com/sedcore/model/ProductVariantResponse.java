package com.sedcore.model;

import com.sedcore.enums.ProductStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Varyant Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductVariantResponse {

    private String id;
    private String sku;
    private String name;
    private BigDecimal additionalPrice;
    private BigDecimal salePrice;
    private ProductStatus status;
    private String imageUrl;
    private Map<String, String> attributes;

    private List<BarcodeResponse> barcodes;
    private InventoryResponse inventory;
}
