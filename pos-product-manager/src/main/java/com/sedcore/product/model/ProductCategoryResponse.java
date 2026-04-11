package com.sedcore.product.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ProductCategory Response DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductCategoryResponse {
    private String id;
    private String productId;
    private String categoryId;
    private String categoryName;
    private String categoryPath;
    private Boolean isPrimary;
    private Boolean isFeatured;
    private Integer displayOrder;
    private String customName;
    private String customDescription;
    private Boolean isActive;
    private String createdAt;
    private String updatedAt;
}
