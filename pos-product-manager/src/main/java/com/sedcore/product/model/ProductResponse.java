package com.sedcore.product.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.sedcore.common.enums.ProductStatus;
import com.towpen.base.restservice.model.DtoBaseModel;

import jakarta.persistence.Embeddable;
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
public class ProductResponse extends DtoBaseModel {

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
    private String locationId;
    private String locationType;
    private String stockLocation;
    private String shelfNumber;

    // Müşteri bilgileri (Objenin aynısı)
    private CustomerResponse customer;

    // Varyantlar
    private List<ProductVariantResponse> variants;

    /**
     * Çoklu kategori listesi (Amazon-style).
     *
     * Eski tek-kategori alanı `categoryId`/`categoryName` legacy kalıyor —
     * yeni istemciler `categories[]` üzerinden tüm bağlı kategorileri görür.
     * Liste, primary kategori başta olmak üzere `displayOrder` sırasıyla döner.
     * `ProductCategory` tablosundan `isActive=true` filtresiyle derlenir.
     */
    private List<ProductCategoryResponse> categories;


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