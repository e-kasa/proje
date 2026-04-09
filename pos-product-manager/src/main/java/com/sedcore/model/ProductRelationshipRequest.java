package com.sedcore.model;

import com.sedcore.enums.ProductRelationType;
import jakarta.validation.constraints.*;
import lombok.*;

/**
 * Ürün İlişkisi Oluşturma/Güncelleme Request DTO
 *
 * Admin panelinden yöneticinin benzer ürün eklemesi için
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductRelationshipRequest {

    /**
     * Kaynak ürün ID (ana ürün)
     */
    @NotBlank(message = "Kaynak ürün ID boş olamaz")
    @Size(min = 1, max = 255, message = "Ürün ID 1-255 karakter arasında olmalı")
    private String sourceProductId;

    /**
     * Hedef ürün ID (önerilecek ürün)
     */
    @NotBlank(message = "Hedef ürün ID boş olamaz")
    @Size(min = 1, max = 255, message = "Ürün ID 1-255 karakter arasında olmalı")
    private String targetProductId;

    /**
     * İlişki tipi (SIMILAR, ALTERNATIVE, COMPLEMENTARY)
     */
    @NotNull(message = "İlişki tipi zorunlu")
    private ProductRelationType relationType;

    /**
     * Ağırlık (1-10)
     * 1 = düşük öncelik
     * 10 = yüksek öncelik
     */
    @NotNull(message = "Ağırlık zorunlu")
    @Min(value = 1, message = "Ağırlık minimum 1 olmalı")
    @Max(value = 10, message = "Ağırlık maximum 10 olmalı")
    private Integer weight;

    /**
     * Aktif/Pasif durumu
     */
    @NotNull(message = "Aktif durumu zorunlu")
    private Boolean isActive;

    /**
     * İşlemi yapan admin username (otomatik set edilir)
     */
    private String createdBy;

    /**
     * Açıklama (opsiyonel)
     */
    @Size(max = 500, message = "Açıklama 500 karakteri geçemez")
    private String description;

    /**
     * Toplu ekleme için (admin CSV importu vb.)
     */
    private Boolean isBulkImport;
}
