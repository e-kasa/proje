package com.sedcore.service;

import com.sedcore.entity.CategoryAttribute;
import com.sedcore.enums.AttributeType;
import com.towpen.base.security.BaseDbService;

import java.util.List;

/**
 * CategoryAttribute Service
 * Kategori özellik tanımlarını yöneten servis
 */
public interface CategoryAttributeService extends BaseDbService<CategoryAttribute> {

    /**
     * Kategoriye özellik ekle
     */
    CategoryAttribute addAttributeToCategory(String categoryId, String attributeKey,
                                             String attributeName, AttributeType attributeType);

    /**
     * Kategori özelliğini güncelle
     */
    CategoryAttribute updateCategoryAttribute(String attributeId, CategoryAttribute updates);

    /**
     * Kategori özelliğini sil
     */
    void deleteCategoryAttribute(String attributeId);

    /**
     * Kategorinin tüm özelliklerini getir
     */
    List<CategoryAttribute> getCategoryAttributes(String categoryId);

    /**
     * Kategorinin zorunlu özelliklerini getir
     */
    List<CategoryAttribute> getRequiredAttributes(String categoryId);

    /**
     * Kategorinin filtrelenebilir özelliklerini getir
     */
    List<CategoryAttribute> getFilterableAttributes(String categoryId);

    /**
     * Özellik anahtarına göre getir
     */
    CategoryAttribute getAttributeByKey(String categoryId, String attributeKey);

    /**
     * Özellik seçeneklerini güncelle (SELECT tipi için)
     */
    void updateAttributeOptions(String attributeId, List<String> options);

    /**
     * Özelliği zorunlu/opsiyonel yap
     */
    void toggleRequired(String attributeId, Boolean isRequired);

    /**
     * Özelliği filtrelenebilir yap
     */
    void toggleFilterable(String attributeId, Boolean isFilterable);

    /**
     * Özelliği aranabilir yap
     */
    void toggleSearchable(String attributeId, Boolean isSearchable);

    /**
     * Özellik sıralamasını güncelle
     */
    void updateDisplayOrder(String attributeId, Integer displayOrder);

    /**
     * Özellik varlığını kontrol et
     */
    boolean attributeExists(String categoryId, String attributeKey);

    /**
     * Kategorinin özellik sayısını getir
     */
    long getAttributeCountForCategory(String categoryId);

    /**
     * Birden fazla kategori için tüm özellikleri batch query ile getir
     * N+1 query problemi çözümü için
     */
    List<CategoryAttribute> findByCategoryIds(List<String> categoryIds);
}
