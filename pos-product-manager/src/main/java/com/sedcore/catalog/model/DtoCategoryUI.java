package com.sedcore.catalog.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.sedcore.common.enums.ProductStatus;
import com.towpen.base.restservice.model.DtoCrudModel;
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
    private String name; // Kategori adı
    private String slug; // URL dostu isim
    private String description; // Kategori açıklaması
    private String imageUrl; // Kategori görseli URL
    private String icon; // Kategori simgesi
    private Integer sortOrder; // Kategorinin sıralama numarası
    private Integer level; // Kategori seviyesi
    private String path; // Kategori yolu
    private Boolean isSoftDeleted; // Kategori silinmiş mi?
    private ProductStatus status; // Kategori durumu (DRAFT, ACTIVE, INACTIVE, ARCHIVED)
    private Map<String, Object> metadata; // Esnek özellikler
    private String metaTitle; // SEO başlığı
    private String metaDescription; // SEO açıklaması
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
