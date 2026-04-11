package com.sedcore.catalog.model;

import com.sedcore.catalog.entity.CategoryVariant;
import com.sedcore.common.enums.AttributeType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * CategoryVariant Response DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryVariantResponse {
    private Long id; // Varyantın benzersiz kimliği
    private String variantKey; // Varyant anahtarı
    private String variantName; // Varyant adı
    private String variantNameEn; // Varyant adı (İngilizce)
    private AttributeType variantType; // Varyant tipi
    private Boolean isRequired; // Zorunlu mu?
    private Integer displayOrder; // Görüntüleme sırası
    private List<String> options; // Varyant seçenekleri
}
