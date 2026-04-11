package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * ProductCategoryAttribute Request DTO
 * Ürün özellik değeri kaydetme için
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductCategoryAttributeRequest {
    private String productId;
    private String categoryId;
    private String categoryAttributeId;

    // Değer alanları - tip'e göre uygun alan kullanılır
    private String valueText;
    private Double valueNumber;
    private Boolean valueBoolean;
    private LocalDate valueDate;
    private List<String> valueSelect;
    private Double valueMin;
    private Double valueMax;

    // Toplu özellik güncellemesi için
    private Map<String, Object> bulkAttributes;
}
