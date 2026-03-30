package com.sedcore.model;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class CompanyCategoryResponse {

    private String id;
    private String companyCode;
    private String categoryId;
    private Boolean isActive;
    private Integer displayOrder;

    // Kategori detayları (join ile gelir)
    private String categoryName;
    private String categorySlug;
    private String categoryPath;
    private Integer categoryLevel;
    private String categoryParentId;  // Üst kategori UUID (hiyerarşi için)
    private String categoryImageUrl;
    private String categoryIcon;
    private String categoryStatus;

    // Alt kategoriler (ağaç yapısı için)
    private List<CompanyCategoryResponse> children;
}
