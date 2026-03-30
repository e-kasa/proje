package com.sedcore.model.product;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.sedcore.entity.ProductMedia;
import com.towpen.base.restservice.model.DtoCrudModel;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

@Data
public class DtoProductUI extends DtoCrudModel {


  @NotBlank(message = "Ürün adı zorunludur")
    @JsonProperty("productName")
    private String name;

    @NotBlank(message = "Slug zorunludur")
    private String slug;

    @NotNull(message = "Kategori ID zorunludur")
    private Integer categoryId;

    private String brand;

    @NotNull(message = "Fiyat zorunludur")
    private BigDecimal basePrice;

    private String description;

    // Stok & Konum bilgileri
    private String storeId;
    private String warehouseId;
    private String stockLocation;
    private String shelfNumber;

    // Müşteri bilgileri (Objenin aynısı)
    private CustomerRequest customer;

    // Varyantlar
    private List<ProductVariantRequest> variants;

    // Tarih
    private Instant createdAt;

    // ---- İç sınıflar ---- //

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CustomerRequest {
        private String name;
        private String phone;
        private String email;
        private String address;
        private String notes;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProductVariantRequest {

        private String sku;
        private String name;
        private BigDecimal additionalPrice;

        private Map<String, Object> attributes;

        private InventoryRequest inventory;

        private List<BarcodeRequest> barcodes;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InventoryRequest {
        private String warehouseCode;
        private Integer physicalQuantity;
        private Integer minStockLevel;
        private Integer reorderPoint;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BarcodeRequest {
        private String barcodeCode;
        private String barcodeType;
        private Boolean isPrimary;
    }


}
