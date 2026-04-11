package com.sedcore.catalog.service;

import com.sedcore.catalog.entity.CategoryVariant;
import com.sedcore.common.enums.AttributeType;
import com.towpen.base.security.BaseDbService;

import java.util.List;

/**
 * CategoryVariant Service
 * Kategori varyant tanımlarını yöneten servis
 */
public interface CategoryVariantService extends BaseDbService<CategoryVariant> {

    /**
     * Kategoriye varyant ekle
     */
    CategoryVariant addVariantToCategory(String categoryId, String variantKey,
                                        String variantName, AttributeType variantType);

    /**
     * Kategori varyantını güncelle
     */
    CategoryVariant updateCategoryVariant(String variantId, CategoryVariant updates);

    /**
     * Kategori varyantını sil
     */
    void deleteCategoryVariant(String variantId);

    /**
     * Kategorinin tüm varyantlarını getir
     */
    List<CategoryVariant> getCategoryVariants(String categoryId);

    /**
     * Kategorinin zorunlu varyantlarını getir
     */
    List<CategoryVariant> getRequiredVariants(String categoryId);

    /**
     * Varyant anahtarına göre getir
     */
    CategoryVariant getVariantByKey(String categoryId, String variantKey);

    /**
     * Varyant seçeneklerini güncelle
     */
    void updateVariantOptions(String variantId, List<String> options);

    /**
     * Fiyatı etkileyen varyantları getir
     */
    List<CategoryVariant> getPriceAffectingVariants(String categoryId);

    /**
     * Stoğu etkileyen varyantları getir
     */
    List<CategoryVariant> getStockAffectingVariants(String categoryId);

    /**
     * Varyantı zorunlu/opsiyonel yap
     */
    void toggleRequired(String variantId, Boolean isRequired);

    /**
     * Varyant sıralamasını güncelle
     */
    void updateDisplayOrder(String variantId, Integer displayOrder);

    /**
     * Varyant varlığını kontrol et
     */
    boolean variantExists(String categoryId, String variantKey);

    /**
     * Kategorinin varyant sayısını getir
     */
    long getVariantCountForCategory(String categoryId);

    /**
     * Birden fazla kategori için tüm varyantları batch query ile getir
     * N+1 query problemi çözümü için
     */
    List<CategoryVariant> findByCategoryIds(List<String> categoryIds);
}
