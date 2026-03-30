package com.sedcore.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Stok Request DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryRequest {

    @NotBlank(message = "Depo kodu zorunludur")
    private String warehouseCode;

    private String warehouseName;

    @NotNull(message = "Fiziksel stok miktarı zorunludur")
    @Min(value = 0, message = "Stok miktarı 0'dan küçük olamaz")
    private Integer physicalQuantity;

    private Integer minStockLevel;
    private Integer maxStockLevel;
    private Integer reorderPoint;
    private Integer reorderQuantity;
    private String location;
    private String notes;
}