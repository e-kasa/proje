package com.sedcore.product.service;

import com.sedcore.product.entity.ProductCategoryAttribute;
import com.towpen.base.security.BaseDbService;

import java.util.List;
import java.util.Map;

/**
 * ProductCategoryAttribute Service
 * Ürün-kategori özellik değerlerini yöneten servis
 */
public interface ProductCategoryAttributeService extends BaseDbService<ProductCategoryAttribute> {

    /**
     * Ürün için kategori özelliği ekle/güncelle
     */
    ProductCategoryAttribute setProductAttribute(String productId, String categoryId,
                                                 String categoryAttributeId, Object value);

    /**
     * Ürün özelliğini sil
     */
    void deleteProductAttribute(String productId, String categoryId, String categoryAttributeId);

    /**
     * Ürünün belirli kategorideki tüm özelliklerini getir
     */
    List<ProductCategoryAttribute> getProductAttributesInCategory(String productId, String categoryId);

    /**
     * Ürünün tüm özelliklerini getir (tüm kategoriler)
     */
    List<ProductCategoryAttribute> getAllProductAttributes(String productId);

    /**
     * Kategorideki tüm ürün özelliklerini getir
     */
    List<ProductCategoryAttribute> getCategoryProductAttributes(String categoryId);

    /**
     * Özellik anahtarına göre değer getir
     */
    ProductCategoryAttribute getAttributeByKey(String productId, String categoryId, String attributeKey);

    /**
     * Ürün özelliğini doğrula
     */
    void verifyAttribute(String attributeId, Boolean isVerified);

    /**
     * Toplu özellik güncelleme
     */
    void bulkSetAttributes(String productId, String categoryId, Map<String, String> attributes);

    /**
     * Kategorideki ürünleri özelliğe göre filtrele
     */
    List<String> filterProductsByAttribute(String categoryId, String attributeKey, Object value);

    /**
     * Sayısal değer aralığına göre ürünleri filtrele
     */
    List<String> filterProductsByNumberRange(String categoryId, String attributeKey,
                                             Double minValue, Double maxValue);

    /**
     * Ürünün özellik sayısını getir
     */
    long getAttributeCountForProduct(String productId, String categoryId);
}
