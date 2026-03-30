package com.sedcore.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ProductCategory Request DTO
 * Ürün-kategori ilişkisi oluşturma/güncelleme için
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductCategoryRequest {
    private String productId;
    private String categoryId;
    private Boolean isPrimary;
    private Boolean isFeatured;
    private Integer displayOrder;
    private String customName;
    private String customDescription;
    private Boolean isActive;
}
