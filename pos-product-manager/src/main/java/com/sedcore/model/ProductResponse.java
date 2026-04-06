package com.sedcore.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.sedcore.enums.ProductStatus;

import jakarta.persistence.Embeddable;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Ürün Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductResponse {

	private String id;
    private String name;
    private String slug;
    private String sku;
    private String categoryId;
    private String categoryName;
    private String brand;
    private String unit;
    private BigDecimal basePrice;
	private ProductStatus status;
    private String description;
    private String sector;
    private Map<String, Object> metadata;

    // Stok & Konum bilgileri
    private String storeId;
    private String warehouseId;
    private String stockLocation;
    private String shelfNumber;

    // Müşteri bilgileri (Objenin aynısı)
    private CustomerResponse customer;

    // Varyantlar
    private List<ProductVariantResponse> variants;


    // ---- İç sınıflar ---- //

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Embeddable
    public static class CustomerResponse {
        private String name;
        private String phone;
        private String email;
        private String address;
        private String notes;
    }

   

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InventoryResponse {
        private String warehouseCode;
        private Integer physicalQuantity;
        private Integer minStockLevel;
        private Integer reorderPoint;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BarcodeResponse {
        private String barcodeCode;
        private String barcodeType;
        private Boolean isPrimary;
    }
}