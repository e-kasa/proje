package com.sedcore.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

/**
 * ProductCategoryAttribute Response DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductCategoryAttributeResponse {
    private String id;
    private String productId;
    private String categoryId;
    private String categoryAttributeId;
    private String attributeKey;
    private String attributeName;

    // Değer alanları
    private String valueText;
    private Double valueNumber;
    private Boolean valueBoolean;
    private LocalDate valueDate;
    private List<String> valueSelect;
    private Double valueMin;
    private Double valueMax;

    private String unit;
    private String displayValue;
    private Boolean isVerified;
    private Integer sortOrder;
    private String createdAt;
    private String updatedAt;
}
