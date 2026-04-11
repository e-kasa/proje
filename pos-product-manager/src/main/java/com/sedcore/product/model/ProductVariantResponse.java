package com.sedcore.product.model;

import com.sedcore.common.enums.ProductStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import com.sedcore.inventory.model.InventoryResponse;
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

    /** Toplam stok (geriye dönük uyumluluk için — tüm lokasyonların toplamı) */
    private InventoryResponse inventory;

    /** Lokasyon bazlı stok listesi — Flutter çok-mağaza görünümü için */
    private List<InventoryResponse> inventories;
}
