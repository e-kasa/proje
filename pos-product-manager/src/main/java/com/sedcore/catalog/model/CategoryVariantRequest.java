package com.sedcore.catalog.model;

import com.sedcore.catalog.entity.CategoryVariant;
import com.sedcore.common.enums.AttributeType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

/**
 * CategoryVariant Request DTO
 * Kategori varyant tanımı oluşturma/güncelleme için
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryVariantRequest {
    private String variantKey; // Varyant anahtarı
    private String variantName; // Varyant adı
    private String variantNameEn; // Varyant adı (İngilizce)
    private AttributeType variantType; // Varyant tipi

    @Builder.Default
    private Boolean isRequired = false; // Zorunlu mu? (default: false)

    @Builder.Default
    private Integer displayOrder = 0; // Görüntüleme sırası (default: 0)

    @Builder.Default
    private List<String> options = new ArrayList<>(); // Varyant seçenekleri (default: boş liste)
}
