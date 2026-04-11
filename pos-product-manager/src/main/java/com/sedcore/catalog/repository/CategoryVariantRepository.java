package com.sedcore.catalog.repository;

import com.sedcore.catalog.entity.CategoryVariant;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * CategoryVariant Repository
 * Kategori varyant tanımları için repository
 */
@Repository
public interface CategoryVariantRepository extends BaseDaoRepository<CategoryVariant> {

    // Kategorinin tüm varyantlarını getir
    @Query("SELECT cv FROM CategoryVariant cv WHERE cv.category.id = :categoryId " +
            "AND cv.isActive = :isActive ORDER BY cv.displayOrder ASC")
    List<CategoryVariant> findByCategoryIdAndIsActiveOrderByDisplayOrderAsc(
            @Param("categoryId") String categoryId, @Param("isActive") Boolean isActive
    );

    // Kategorinin zorunlu varyantlarını getir
    @Query("SELECT cv FROM CategoryVariant cv WHERE cv.category.id = :categoryId " +
            "AND cv.isRequired = :isRequired AND cv.isActive = :isActive ORDER BY cv.displayOrder ASC")
    List<CategoryVariant> findByCategoryIdAndIsRequiredAndIsActiveOrderByDisplayOrderAsc(
            @Param("categoryId") String categoryId, @Param("isRequired") Boolean isRequired,
            @Param("isActive") Boolean isActive
    );

    // Varyant anahtarına göre getir
    @Query("SELECT cv FROM CategoryVariant cv WHERE cv.category.id = :categoryId " +
            "AND cv.variantKey = :variantKey")
    Optional<CategoryVariant> findByCategoryIdAndVariantKey(
            @Param("categoryId") String categoryId, @Param("variantKey") String variantKey
    );

    // Varyant varlığını kontrol et
    @Query("SELECT CASE WHEN COUNT(cv) > 0 THEN true ELSE false END FROM CategoryVariant cv " +
            "WHERE cv.category.id = :categoryId AND cv.variantKey = :variantKey")
    boolean existsByCategoryIdAndVariantKey(
            @Param("categoryId") String categoryId, @Param("variantKey") String variantKey
    );

    // Fiyatı etkileyen varyantları getir
 
   

    // Ürün listesinde gösterilecek varyantları getir
   

    // Kategorinin varyant sayısını getir
    @Query("SELECT COUNT(cv) FROM CategoryVariant cv " +
            "WHERE cv.category.id = :categoryId AND cv.isActive = true")
    long countByCategoryId(@Param("categoryId") String categoryId);

    // Tüm aktif varyantlar
    List<CategoryVariant> findByIsActive(Boolean isActive);

    // Batch query: Birden fazla kategori için tüm varyantları tek sorguda getir
    @Query("SELECT cv FROM CategoryVariant cv WHERE cv.category.id IN :categoryIds " +
            "AND cv.isActive = true ORDER BY cv.category.id, cv.displayOrder ASC")
    List<CategoryVariant> findByCategoryIdIn(@Param("categoryIds") List<String> categoryIds);
}
