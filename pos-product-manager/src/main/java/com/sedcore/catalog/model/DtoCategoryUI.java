package com.sedcore.catalog.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.sedcore.common.enums.ProductStatus;
import com.towpen.base.restservice.model.DtoCrudModel;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.AccessLevel;

import java.util.List;
import java.util.Map;

@Data
@RequiredArgsConstructor
public class DtoCategoryUI extends DtoCrudModel {
    @NotBlank(message = "Kategori adı boş olamaz")
    @Size(max = 200, message = "Kategori adı en fazla 200 karakter olabilir")
    private String name; // Kategori adı

    @Size(max = 200, message = "Slug en fazla 200 karakter olabilir")
    private String slug; // URL dostu isim

    @Size(max = 2000, message = "Açıklama en fazla 2000 karakter olabilir")
    private String description; // Kategori açıklaması

    @Size(max = 1000, message = "Görsel URL en fazla 1000 karakter olabilir")
    private String imageUrl; // Kategori görseli URL

    @Size(max = 100, message = "Simge en fazla 100 karakter olabilir")
    private String icon; // Kategori simgesi

    @PositiveOrZero(message = "Sıralama negatif olamaz")
    private Integer sortOrder; // Kategorinin sıralama numarası

    @PositiveOrZero(message = "Seviye negatif olamaz")
    private Integer level; // Kategori seviyesi

    private String path; // Kategori yolu
    private Boolean isSoftDeleted; // Kategori silinmiş mi?
    private ProductStatus status; // Kategori durumu (DRAFT, ACTIVE, INACTIVE, ARCHIVED)
    private Map<String, Object> metadata; // Esnek özellikler

    @Size(max = 200, message = "SEO başlığı en fazla 200 karakter olabilir")
    private String metaTitle; // SEO başlığı

    @Size(max = 500, message = "SEO açıklaması en fazla 500 karakter olabilir")
    private String metaDescription; // SEO açıklaması

    @Size(max = 500, message = "SEO anahtar kelimeleri en fazla 500 karakter olabilir")
    private String metaKeywords; // SEO anahtar kelimeleri

    // Parent ID - Frontend'den Integer veya String olarak gelebilir
    // Jackson için ignore, Lombok getter/setter oluşturmasın
    @JsonProperty("parentId")
    @JsonIgnore  // Jackson bu field'ı görmezden gelsin
    @Getter(AccessLevel.NONE)  // Lombok getter oluşturmasın
    @Setter(AccessLevel.NONE)  // Lombok setter oluşturmasın
    private Object parentIdRaw;

    private List<CategoryVariantRequest> variants; // Kategori varyantları

    /**
     * Parent ID'yi String olarak döndür
     * Frontend'den Integer veya String gelebilir, her ikisini de handle eder
     */
    @JsonProperty("parentId")  // Jackson bu metodu kullanacak
    public String getParentId() {
        if (parentIdRaw == null) {
            return null;
        }
        if (parentIdRaw instanceof String) {
            String strValue = (String) parentIdRaw;
            return strValue.isEmpty() ? null : strValue;
        }
        if (parentIdRaw instanceof Number) {
            return String.valueOf(parentIdRaw);
        }
        return parentIdRaw.toString();
    }

    /**
     * Parent ID'yi set et
     */
    @JsonProperty("parentId")  // Jackson bu metodu kullanacak
    public void setParentId(Object parentId) {
        this.parentIdRaw = parentId;
    }
}
