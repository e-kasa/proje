package com.sedcore.catalog.model;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompanyCategoryResponse extends DtoBaseModel {

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
