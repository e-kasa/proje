package com.sedcore.model;

import com.sedcore.enums.ProductStatus;
import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import java.util.List;
import java.util.Map;

/**
 * Category DTO - Hiyerarşik ve İlişkisel Yapı
 * Category kendi children'larını, varyantlarını ve attribute'larını içerir
 */
@Data
@RequiredArgsConstructor
public class DtoCategory extends DtoBaseModel {
    private String id; // Kategorinin benzersiz kimliği (UUID)
    private String name; // Kategori adı
    private String slug; // URL dostu isim
    private String description; // Kategori açıklaması
    private String imageUrl; // Kategori görseli URL
    private String icon; // Kategori simgesi
    private Integer sortOrder; // Kategorinin sıralama numarası
    private Integer level; // Kategori seviyesi
    private String path; // Kategori yolu
    private Boolean isSoftDeleted; // Kategori silinmiş mi?
    private ProductStatus status; // Kategori durumu
    private Map<String, Object> metadata; // Esnek özellikler
    private String metaTitle; // SEO başlığı
    private String metaDescription; // SEO açıklaması
    private String metaKeywords; // SEO anahtar kelimeleri

    private String parentId; // Üst kategori ID'si (UUID)

    private List<DtoCategory> children; // Alt kategoriler
    private List<CategoryVariantResponse> variants; // Kategori varyantları
    private List<CategoryAttributeResponse> attributes; // Kategori özellikleri

    /**
     * Firma-kategori seçim ekranı için:
     * Bu kategori mevcut firmanın seçtiği kategorilerden mi?
     * getAllCategoriesWithSelection() endpoint'i tarafından doldurulur.
     * Veritabanına kaydedilmez — sadece response'da kullanılır.
     */
    private Boolean isSelected;
}

