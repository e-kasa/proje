package com.sedcore.repository;

import com.sedcore.entity.Category;
import com.sedcore.enums.ProductStatus;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CategoryRepository extends BaseDaoRepository<Category> {
    // Temel sorgular
    Optional<Category> findByIdAndIsSoftDeleted(String id, Boolean isSoftDeleted);

    Optional<Category> findBySlugAndIsSoftDeleted(String slug, Boolean isSoftDeleted);

    List<Category> findByIsSoftDeletedOrderBySortOrderAsc(Boolean isSoftDeleted);

    List<Category> findByStatusAndIsSoftDeletedOrderBySortOrderAsc(
            ProductStatus status, Boolean isSoftDeleted
    );

    // Ana kategoriler
    @Query("SELECT c FROM Category c WHERE " +
            "c.parentCategory IS NULL AND c.isSoftDeleted = false " +
            "ORDER BY c.sortOrder ASC")
    List<Category> findRootCategories();

    // Alt kategoriler
    @Query("SELECT c FROM Category c WHERE c.parentCategory.id = :parentId " +
            "AND c.isSoftDeleted = :isSoftDeleted ORDER BY c.sortOrder ASC")
    List<Category> findByParentCategoryAndIsDeletedOrderBySortOrderAsc(
            @Param("parentId") String parentId,
            @Param("isSoftDeleted") Boolean isSoftDeleted
    );

    // Validasyon
    boolean existsBySlugAndIdNot(String slug, String id);

    boolean existsBySlug(String slug);
}
