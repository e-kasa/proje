package com.sedcore.product.repository;

import com.sedcore.product.entity.ProductCategory;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * ProductCategory Repository
 * Ürün-Kategori ilişkileri için repository
 */
@Repository
public interface ProductCategoryRepository extends BaseDaoRepository<ProductCategory> {

    // Ürünün tüm kategorilerini getir
    List<ProductCategory> findByProductIdAndIsActiveOrderByDisplayOrderAsc(String productId, Boolean isActive);

    // Ürünün ana kategorisini getir
    Optional<ProductCategory> findByProductIdAndIsPrimaryAndIsActive(
            String productId, Boolean isPrimary, Boolean isActive
    );

    // Kategorideki tüm ürünleri getir
    List<ProductCategory> findByCategoryIdAndIsActiveOrderByDisplayOrderAsc(
            String categoryId, Boolean isActive
    );

    // Kategorideki öne çıkan ürünleri getir
    List<ProductCategory> findByCategoryIdAndIsFeaturedAndIsActiveOrderByDisplayOrderAsc(
            String categoryId, Boolean isFeatured, Boolean isActive
    );

    // Ürün-kategori ilişkisini kontrol et
    boolean existsByProductIdAndCategoryId(
            String productId, String categoryId
    );

    // Ürünün kategori sayısını getir
    @Query("SELECT COUNT(pc) FROM ProductCategory pc " +
            "WHERE pc.productId = :productId AND pc.isActive = true")
    long countByProductId(@Param("productId") String productId);

    // Kategorideki ürün sayısını getir
    @Query("SELECT COUNT(pc) FROM ProductCategory pc " +
            "WHERE pc.categoryId = :categoryId AND pc.isActive = true")
    long countByCategoryId(@Param("categoryId") String categoryId);

    // Tüm aktif ürün-kategori ilişkileri
    List<ProductCategory> findByIsActive(Boolean isActive);
}
