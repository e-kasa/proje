package com.sedcore.product.repository;

import com.sedcore.product.entity.ProductCategoryAttribute;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

/**
 * ProductCategoryAttribute Repository
 * Ürün-kategori özellik değerleri için repository
 */
public interface ProductCategoryAttributeRepository extends BaseDaoRepository<ProductCategoryAttribute> {

    // Ürünün belirli kategorideki tüm özelliklerini getir
    List<ProductCategoryAttribute> findByProductIdAndCategoryIdOrderBySortOrderAsc(
            String productId, String categoryId
    );

    // Ürünün tüm özelliklerini getir (tüm kategoriler)
    List<ProductCategoryAttribute> findByProductIdOrderBySortOrderAsc(String productId);

    // Kategorinin tüm ürün özelliklerini getir
    List<ProductCategoryAttribute> findByCategoryIdOrderBySortOrderAsc(String categoryId);

    // Belirli bir özellik değerini getir
    Optional<ProductCategoryAttribute> findByProductIdAndCategoryIdAndCategoryAttributeId(
            String productId, String categoryId, String categoryAttributeId
    );

    // Özellik anahtarına göre getir
    Optional<ProductCategoryAttribute> findByProductIdAndCategoryIdAndAttributeKey(
            String productId, String categoryId, String attributeKey
    );

    // Doğrulanmış özellikleri getir
    List<ProductCategoryAttribute> findByProductIdAndCategoryIdAndIsVerifiedOrderBySortOrderAsc(
            String productId, String categoryId, Boolean isVerified
    );

    // Özellik varlığını kontrol et
    boolean existsByProductIdAndCategoryIdAndCategoryAttributeId(
            String productId, String categoryId, String categoryAttributeId
    );

    // Ürünün kategori bazlı özellik sayısı
    @Query("SELECT COUNT(pca) FROM ProductCategoryAttribute pca " +
            "WHERE pca.productId = :productId AND pca.categoryId = :categoryId")
    long countByProductIdAndCategoryId(
            @Param("productId") String productId,
            @Param("categoryId") String categoryId
    );

    // Belirli özellik anahtarına sahip tüm ürünleri getir (filtreleme için)
    @Query("SELECT pca FROM ProductCategoryAttribute pca " +
            "WHERE pca.categoryId = :categoryId AND pca.attributeKey = :attributeKey " +
            "AND pca.valueText = :value")
    List<ProductCategoryAttribute> findByCategoryAndAttributeKeyAndValue(
            @Param("categoryId") String categoryId,
            @Param("attributeKey") String attributeKey,
            @Param("value") String value
    );

    // Sayısal değer aralığına göre ürünleri getir
    @Query("SELECT pca FROM ProductCategoryAttribute pca " +
            "WHERE pca.categoryId = :categoryId AND pca.attributeKey = :attributeKey " +
            "AND pca.valueNumber BETWEEN :minValue AND :maxValue")
    List<ProductCategoryAttribute> findByCategoryAndAttributeKeyAndNumberRange(
            @Param("categoryId") String categoryId,
            @Param("attributeKey") String attributeKey,
            @Param("minValue") Double minValue,
            @Param("maxValue") Double maxValue
    );
}
