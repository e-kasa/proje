package com.sedcore.model;

import com.sedcore.enums.AttributeType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * CategoryAttribute Response DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryAttributeResponse {
    private String id;
    private String categoryId;
    private String categoryName;
    private String attributeKey;
    private String attributeName;
    private String attributeNameEn;
    private AttributeType attributeType;
    private Boolean isRequired;
    private Boolean isFilterable;
    private Boolean isSearchable;
    private Boolean isComparable;
    private Integer displayOrder;
    private String unit;
    private List<String> options;
    private String validationRegex;
    private Double minValue;
    private Double maxValue;
    private String placeholder;
    private String helpText;
    private Boolean isActive;
    private Boolean inheritFromParent;
    private String createdAt;
    private String updatedAt;
}
