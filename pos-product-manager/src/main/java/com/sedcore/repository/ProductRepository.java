package com.sedcore.repository;

import com.sedcore.entity.Product;
import com.sedcore.enums.ProductStatus;
import com.towpen.base.db.repository.BaseDaoRepository;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends BaseDaoRepository<Product> {

    // Temel sorgular
    Optional<Product> findByIdAndIsDeleted(String id, Boolean isDeleted);

    Optional<Product> findBySlugAndIsDeleted(String slug, Boolean isDeleted);

    Page<Product> findByIsDeleted(Boolean isDeleted, Pageable pageable);

    Page<Product> findByStatusAndIsDeleted(
         ProductStatus status, Boolean isDeleted, Pageable pageable
    );

    // Kategori bazlı
    Page<Product> findByCategoryIdAndIsDeleted(
            String categoryId, Boolean isDeleted, Pageable pageable
    );

    List<Product> findByCategoryIdAndStatusAndIsDeleted(
            String categoryId,ProductStatus status, Boolean isDeleted
    );

    // Arama (pageable)
    @Query("SELECT p FROM Product p WHERE " +
            " (LOWER(p.name) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "OR LOWER(p.brand) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND p.isDeleted = false")
    Page<Product> searchProducts(
            @Param("keyword") String keyword,
            Pageable pageable
    );

    // Arama (pageable'siz — PartSearchService icin)
    @Query("SELECT p FROM Product p WHERE " +
            " (LOWER(p.name) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "OR LOWER(p.sku) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "OR LOWER(p.brand) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND p.isDeleted = false")
    List<Product> searchProducts(
            @Param("keyword") String keyword
    );

    // Validasyon
    boolean existsBySlugAndIdNot(String slug, String id);

    boolean existsBySlug(@NotBlank(message = "Slug zorunludur") @Pattern(regexp = "^[a-z0-9-]+$", message = "Slug sadece küçük harf, rakam ve tire içerebilir") String slug);
}
