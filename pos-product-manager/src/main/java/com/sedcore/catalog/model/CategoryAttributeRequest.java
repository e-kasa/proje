package com.sedcore.catalog.model;

import com.sedcore.common.enums.AttributeType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * CategoryAttribute Request DTO
 * Kategori özellik tanımı oluşturma/güncelleme için
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryAttributeRequest {
    private String attributeKey; // Özellik anahtarı
    private String attributeName; // Özellik adı
    private String attributeNameEn; // Özellik adı (İngilizce)
    private AttributeType attributeType; // Özellik tipi
    private Boolean isRequired; // Zorunlu mu?
    private Boolean isFilterable; // Filtrelenebilir mi?
}
