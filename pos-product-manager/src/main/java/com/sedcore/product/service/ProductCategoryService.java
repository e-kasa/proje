package com.sedcore.product.service;

import com.sedcore.product.entity.ProductCategory;
import com.towpen.base.security.BaseDbService;

import java.util.List;

/**
 * ProductCategory Service
 * Ürün-Kategori ilişkilerini yöneten servis
 */
public interface ProductCategoryService extends BaseDbService<ProductCategory> {

    /**
     * Ürüne kategori ekle
     */
    ProductCategory addCategoryToProduct(String productId, String categoryId, Boolean isPrimary);

    /**
     * Üründen kategori çıkar
     */
    void removeCategoryFromProduct(String productId, String categoryId);

    /**
     * Ürünün ana kategorisini değiştir
     */
    void changePrimaryCategory(String productId, String newPrimaryCategoryId);

    /**
     * Ürünün tüm kategorilerini getir
     */
    List<ProductCategory> getProductCategories(String productId);

    /**
     * Ürünün ana kategorisini getir
     */
    ProductCategory getPrimaryCategory(String productId);

    /**
     * Kategorideki tüm ürünleri getir
     */
    List<ProductCategory> getCategoryProducts(String categoryId);

    /**
     * Kategorideki öne çıkan ürünleri getir
     */
    List<ProductCategory> getFeaturedProductsInCategory(String categoryId);

    /**
     * Ürünü kategoride öne çıkar
     */
    void featureProductInCategory(String productId, String categoryId, Boolean featured);

    /**
     * Ürünün kategori sıralamasını güncelle
     */
    void updateDisplayOrder(String productId, String categoryId, Integer displayOrder);

    /**
     * Ürün-kategori ilişkisini aktif/pasif yap
     */
    void toggleProductCategoryStatus(String productId, String categoryId, Boolean isActive);

    /**
     * Kategorideki ürün sayısını getir
     */
    long getProductCountInCategory(String categoryId);

    /**
     * Ürünün kategori sayısını getir
     */
    long getCategoryCountForProduct(String productId);

    /**
     * Ürün-kategori ilişkisini kontrol et
     */
    boolean isProductInCategory(String productId, String categoryId);

    /**
     * Bir kategoriye bağlı tüm aktif ürün-kategori ilişkilerini pasifleştirir.
     * Kategori soft-delete edildiğinde orphan ProductCategory satırlarını
     * temizlemek için kullanılır.
     *
     * @param categoryId Soft-delete edilen kategori ID
     * @return Pasifleştirilen kayıt sayısı
     */
    int deactivateAllForCategory(String categoryId);
}
