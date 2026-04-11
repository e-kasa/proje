package com.sedcore.product.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.sedcore.product.entity.Barcode;
import com.sedcore.product.entity.ProductMedia;
import com.sedcore.product.entity.ProductVariant;
import com.towpen.base.restservice.model.DtoBaseModel;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
@Getter
@Setter
public class DtoProduct extends DtoBaseModel {

   
     private String id;

    private String name;

    private String slug;

    private Integer categoryId;

    private String brand;

    private BigDecimal basePrice;

    private String description;

    // Stok & Konum bilgileri
    private String storeId;
    private String warehouseId;
    private String stockLocation;
    private String shelfNumber;

    // Müşteri Bilgileri
    private CustomerResponse customer;

    // Varyantlar
    private List<ProductVariantResponse> variants;

    // Oluşturulma tarihi
    private Instant createdAt;


    // ---- Inner Classes ---- //

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
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
    public static class ProductVariantResponse {

        private String sku;
        private String name;
        private BigDecimal additionalPrice;

        private Map<String, Object> attributes;

        private InventoryResponse inventory;

        private List<BarcodeResponse> barcodes;
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
