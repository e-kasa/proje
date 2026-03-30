package com.sedcore.repository;

import com.sedcore.entity.CategoryAttribute;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * CategoryAttribute Repository
 * Kategori özellik tanımları için repository
 */
@Repository
public interface CategoryAttributeRepository extends BaseDaoRepository<CategoryAttribute> {

    // Kategorinin tüm özelliklerini getir
    @Query("SELECT ca FROM CategoryAttribute ca WHERE ca.category.id = :categoryId " +
           "AND ca.isActive = :isActive ORDER BY ca.attributeKey ASC")
    List<CategoryAttribute> findByCategoryIdAndIsActiveOrderByDisplayOrderAsc(
            @Param("categoryId") String categoryId, @Param("isActive") Boolean isActive
    );

    // Kategorinin zorunlu özelliklerini getir
    @Query("SELECT ca FROM CategoryAttribute ca WHERE ca.category.id = :categoryId " +
           "AND ca.isRequired = :isRequired AND ca.isActive = :isActive " +
           "ORDER BY ca.attributeKey ASC")
    List<CategoryAttribute> findByCategoryIdAndIsRequiredAndIsActiveOrderByDisplayOrderAsc(
            @Param("categoryId") String categoryId,
            @Param("isRequired") Boolean isRequired,
            @Param("isActive") Boolean isActive
    );

    // Kategorinin filtrelenebilir özelliklerini getir
    @Query("SELECT ca FROM CategoryAttribute ca WHERE ca.category.id = :categoryId " +
           "AND ca.isFilterable = :isFilterable AND ca.isActive = :isActive " +
           "ORDER BY ca.attributeKey ASC")
    List<CategoryAttribute> findByCategoryIdAndIsFilterableAndIsActiveOrderByDisplayOrderAsc(
            @Param("categoryId") String categoryId,
            @Param("isFilterable") Boolean isFilterable,
            @Param("isActive") Boolean isActive
    );

    // Özellik anahtarına göre getir
    @Query("SELECT ca FROM CategoryAttribute ca WHERE ca.category.id = :categoryId " +
           "AND ca.attributeKey = :attributeKey")
    Optional<CategoryAttribute> findByCategoryIdAndAttributeKey(
            @Param("categoryId") String categoryId,
            @Param("attributeKey") String attributeKey
    );

    // Özellik varlığını kontrol et
    @Query("SELECT COUNT(ca) > 0 FROM CategoryAttribute ca " +
           "WHERE ca.category.id = :categoryId AND ca.attributeKey = :attributeKey")
    boolean existsByCategoryIdAndAttributeKey(
            @Param("categoryId") String categoryId,
            @Param("attributeKey") String attributeKey
    );

    // Tüm aktif özellikler
    List<CategoryAttribute> findByIsActive(Boolean isActive);

    // Kategorinin özellik sayısını getir
    @Query("SELECT COUNT(ca) FROM CategoryAttribute ca " +
            "WHERE ca.category.id = :categoryId AND ca.isActive = true")
    long countByCategoryId(@Param("categoryId") String categoryId);

    // Batch query: Birden fazla kategori için tüm özellikleri tek sorguda getir
    @Query("SELECT ca FROM CategoryAttribute ca WHERE ca.category.id IN :categoryIds " +
            "AND ca.isActive = true ORDER BY ca.category.id, ca.attributeKey ASC")
    List<CategoryAttribute> findByCategoryIdIn(@Param("categoryIds") List<String> categoryIds);
}
